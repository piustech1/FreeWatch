import '../../core/constants/api_constants.dart';
import 'movie.dart';

class CastMember {
  final int id;
  final String name;
  final String? character;
  final String? profilePath;

  const CastMember({
    required this.id,
    required this.name,
    this.character,
    this.profilePath,
  });

  factory CastMember.fromJson(Map<String, dynamic> json) {
    return CastMember(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      character: json['character'] as String?,
      profilePath: json['profile_path'] as String?,
    );
  }

  String? get photoUrl => profilePath != null && profilePath!.isNotEmpty
      ? (profilePath!.startsWith('http')
          ? profilePath!
          : '${ApiConstants.posterW500}$profilePath')
      : null;
}

class TvSeasonData {
  final int id;
  final int seasonNumber;
  final String name;
  final int episodeCount;
  final String? posterPath;
  final String? airDate;

  const TvSeasonData({
    required this.id,
    required this.seasonNumber,
    required this.name,
    required this.episodeCount,
    this.posterPath,
    this.airDate,
  });

  factory TvSeasonData.fromJson(Map<String, dynamic> json) {
    return TvSeasonData(
      id: json['id'] as int? ?? 0,
      seasonNumber: json['season_number'] as int? ?? 1,
      name: json['name'] as String? ?? 'Season ${json['season_number'] ?? 1}',
      episodeCount: json['episode_count'] as int? ?? 0,
      posterPath: json['poster_path'] as String?,
      airDate: json['air_date'] as String?,
    );
  }
}

class TvEpisodeData {
  final int id;
  final int episodeNumber;
  final int seasonNumber;
  final String name;
  final String overview;
  final int runtime;
  final String? stillPath;
  final double voteAverage;

  const TvEpisodeData({
    required this.id,
    required this.episodeNumber,
    required this.seasonNumber,
    required this.name,
    required this.overview,
    required this.runtime,
    this.stillPath,
    required this.voteAverage,
  });

  String? get stillUrl => stillPath != null && stillPath!.isNotEmpty
      ? (stillPath!.startsWith('http') ? stillPath! : '${ApiConstants.backdropW780}$stillPath')
      : null;

  String get formattedRuntime {
    if (runtime <= 0) return '45m';
    final hours = runtime ~/ 60;
    final minutes = runtime % 60;
    if (hours > 0) {
      return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
    }
    return '${minutes}m';
  }

  factory TvEpisodeData.fromJson(Map<String, dynamic> json) {
    return TvEpisodeData(
      id: json['id'] as int? ?? 0,
      episodeNumber: json['episode_number'] as int? ?? 1,
      seasonNumber: json['season_number'] as int? ?? 1,
      name: json['name'] as String? ?? 'Episode ${json['episode_number'] ?? 1}',
      overview: json['overview'] as String? ?? '',
      runtime: json['runtime'] as int? ?? 0,
      stillPath: json['still_path'] as String?,
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class MovieDetailsData {
  final int id;
  final String title;
  final String overview;
  final int runtime; // in minutes
  final String? releaseDate;
  final double voteAverage;
  final int voteCount;
  final List<String> genres;
  final String certification; // e.g. "PG-13", "R", "PG", "6+"
  final List<CastMember> cast;
  final List<Movie> relatedMovies;
  final bool isTv;
  final int numberOfSeasons;
  final List<TvSeasonData> seasons;

  const MovieDetailsData({
    required this.id,
    required this.title,
    required this.overview,
    required this.runtime,
    this.releaseDate,
    required this.voteAverage,
    required this.voteCount,
    required this.genres,
    required this.certification,
    required this.cast,
    required this.relatedMovies,
    this.isTv = false,
    this.numberOfSeasons = 0,
    this.seasons = const [],
  });

  String get formattedRuntime {
    if (runtime <= 0) return '1h 45min';
    final hours = runtime ~/ 60;
    final minutes = runtime % 60;
    if (hours > 0) {
      return '${hours}h ${minutes.toString().padLeft(2, '0')}min';
    }
    return '${minutes}min';
  }

  String get primaryGenre => genres.isNotEmpty ? genres.first : 'Action';

  String get formattedReleaseDate {
    if (releaseDate == null || releaseDate!.isEmpty) return '2025';
    try {
      final parts = releaseDate!.split('-');
      if (parts.length == 3) {
        final year = parts[0];
        final month = int.tryParse(parts[1]) ?? 1;
        final day = int.tryParse(parts[2]) ?? 1;
        const months = [
          'January', 'February', 'March', 'April', 'May', 'June',
          'July', 'August', 'September', 'October', 'November', 'December'
        ];
        final monthName = months[(month - 1).clamp(0, 11)];
        return '$monthName $day, $year';
      }
    } catch (_) {}
    return releaseDate!;
  }

  String get releaseYear {
    if (releaseDate != null && releaseDate!.length >= 4) {
      return releaseDate!.substring(0, 4);
    }
    return '2024';
  }

  factory MovieDetailsData.fromJson(Map<String, dynamic> json) {
    // 1. Genres
    final genresList = (json['genres'] as List<dynamic>?)
            ?.map((g) => (g as Map<String, dynamic>)['name'] as String? ?? '')
            .where((name) => name.isNotEmpty)
            .toList() ??
        [];

    // 2. Cast
    final credits = json['credits'] as Map<String, dynamic>?;
    final castList = (credits?['cast'] as List<dynamic>?)
            ?.take(16)
            .map((c) => CastMember.fromJson(c as Map<String, dynamic>))
            .toList() ??
        [];

    // 3. Certification from release_dates
    String cert = '';
    final releaseDatesData = json['release_dates'] as Map<String, dynamic>?;
    final releaseResults = releaseDatesData?['results'] as List<dynamic>?;
    if (releaseResults != null) {
      // Look for US release date certification first
      for (final r in releaseResults) {
        final map = r as Map<String, dynamic>;
        if (map['iso_3166_1'] == 'US') {
          final dates = map['release_dates'] as List<dynamic>?;
          if (dates != null) {
            for (final d in dates) {
              final c = (d as Map<String, dynamic>)['certification'] as String?;
              if (c != null && c.trim().isNotEmpty) {
                cert = c.trim();
                break;
              }
            }
          }
          if (cert.isNotEmpty) break;
        }
      }

      // If not in US, look in any country
      if (cert.isEmpty) {
        for (final r in releaseResults) {
          final map = r as Map<String, dynamic>;
          final dates = map['release_dates'] as List<dynamic>?;
          if (dates != null) {
            for (final d in dates) {
              final c = (d as Map<String, dynamic>)['certification'] as String?;
              if (c != null && c.trim().isNotEmpty) {
                cert = c.trim();
                break;
              }
            }
          }
          if (cert.isNotEmpty) break;
        }
      }
    }

    // Default certification if none provided by TMDB
    if (cert.isEmpty) {
      final isAdult = json['adult'] as bool? ?? false;
      if (isAdult) {
        cert = '18+';
      } else {
        final voteAvg = (json['vote_average'] as num?)?.toDouble() ?? 7.0;
        cert = voteAvg >= 8.0 ? '16+' : 'PG-13';
      }
    }

    // 4. Similar / Related movies or TV shows (combine recommendations & similar)
    final recoList = (json['recommendations'] as Map<String, dynamic>?)?['results'] as List<dynamic>? ?? [];
    final simList = (json['similar'] as Map<String, dynamic>?)?['results'] as List<dynamic>? ?? [];
    final combined = [...recoList, ...simList];
    final seenIds = <int>{};
    final List<Movie> similarResults = [];
    for (final item in combined) {
      if (item is Map<String, dynamic>) {
        final parsed = Movie.fromJson(item);
        if (parsed.id != 0 && seenIds.add(parsed.id)) {
          similarResults.add(parsed);
          if (similarResults.length >= 14) break;
        }
      }
    }

    final bool isTvShow = json['number_of_seasons'] != null ||
        json['first_air_date'] != null ||
        (json['title'] == null && json['name'] != null);

    final String title = (json['title'] ?? json['name'] ?? '') as String;
    final String? releaseDate = (json['release_date'] ?? json['first_air_date']) as String?;

    int runtime = json['runtime'] as int? ?? 0;
    if (runtime == 0 && json['episode_run_time'] != null) {
      final epRuns = json['episode_run_time'] as List<dynamic>?;
      if (epRuns != null && epRuns.isNotEmpty) {
        runtime = (epRuns.first as num?)?.toInt() ?? 45;
      }
    }

    final seasonsData = json['seasons'] as List<dynamic>?;
    final List<TvSeasonData> parsedSeasons = seasonsData != null
        ? seasonsData
            .map((s) => TvSeasonData.fromJson(s as Map<String, dynamic>))
            .where((s) => s.seasonNumber > 0)
            .toList()
        : [];

    final int numSeasons = json['number_of_seasons'] as int? ??
        (parsedSeasons.isNotEmpty ? parsedSeasons.length : (isTvShow ? 1 : 0));

    return MovieDetailsData(
      id: json['id'] as int? ?? 0,
      title: title,
      overview: json['overview'] as String? ?? '',
      runtime: runtime,
      releaseDate: releaseDate,
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0.0,
      voteCount: json['vote_count'] as int? ?? 0,
      genres: genresList,
      certification: cert,
      cast: castList,
      relatedMovies: similarResults,
      isTv: isTvShow,
      numberOfSeasons: numSeasons,
      seasons: parsedSeasons,
    );
  }
}
