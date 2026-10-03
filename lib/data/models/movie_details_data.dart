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

    // 4. Similar / Related movies
    final similarData = json['similar'] as Map<String, dynamic>?;
    final similarResults = (similarData?['results'] as List<dynamic>?)
            ?.take(12)
            .map((m) => Movie.fromJson(m as Map<String, dynamic>))
            .toList() ??
        [];

    return MovieDetailsData(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      overview: json['overview'] as String? ?? '',
      runtime: json['runtime'] as int? ?? 0,
      releaseDate: json['release_date'] as String?,
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0.0,
      voteCount: json['vote_count'] as int? ?? 0,
      genres: genresList,
      certification: cert,
      cast: castList,
      relatedMovies: similarResults,
    );
  }
}
