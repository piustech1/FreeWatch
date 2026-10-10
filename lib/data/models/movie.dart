import '../../core/constants/api_constants.dart';

/// Unified Movie model supporting TMDB, Mock Data, and MovieMax Cloudflare R2 streams
class Movie {
  final int id;
  final String title;
  final String? overview;
  final String? posterPath;
  final String? backdropPath;
  final String? releaseDate;
  final double voteAverage;
  final int? voteCount;
  final List<int> genreIds;
  final List<String> genreNames;
  final double? popularity;
  final bool isTv;
  final String? videoUrl;
  final String? vjName;
  final int? runtime;
  final String? firebaseKey;

  const Movie({
    required this.id,
    required this.title,
    this.overview,
    this.posterPath,
    this.backdropPath,
    this.releaseDate,
    required this.voteAverage,
    this.voteCount,
    this.genreIds = const [],
    this.genreNames = const [],
    this.popularity,
    this.isTv = false,
    this.videoUrl,
    this.vjName,
    this.runtime,
    this.firebaseKey,
  });

  /// Full resolved poster URL (handles full URLs and TMDB relative paths)
  String get posterUrl {
    if (posterPath == null || posterPath!.isEmpty) return '';
    if (posterPath!.startsWith('http')) return posterPath!;
    return '${ApiConstants.posterW500}$posterPath';
  }

  /// Full resolved backdrop URL (handles full URLs and TMDB relative paths)
  String get backdropUrl {
    if (backdropPath == null || backdropPath!.isEmpty) return '';
    if (backdropPath!.startsWith('http')) return backdropPath!;
    return '${ApiConstants.backdropW1280}$backdropPath';
  }

  /// Release year shorthand
  String get year {
    if (releaseDate == null || releaseDate!.isEmpty) return '';
    if (releaseDate!.length >= 4) return releaseDate!.substring(0, 4);
    return releaseDate!;
  }

  /// Rounded rating (1 decimal place)
  String get ratingDisplay => voteAverage.toStringAsFixed(1);

  Movie copyWith({
    int? id,
    String? title,
    String? overview,
    String? posterPath,
    String? backdropPath,
    String? releaseDate,
    double? voteAverage,
    int? voteCount,
    List<int>? genreIds,
    List<String>? genreNames,
    double? popularity,
    bool? isTv,
    String? videoUrl,
    String? vjName,
    int? runtime,
    String? firebaseKey,
  }) {
    return Movie(
      id: id ?? this.id,
      title: title ?? this.title,
      overview: overview ?? this.overview,
      posterPath: posterPath ?? this.posterPath,
      backdropPath: backdropPath ?? this.backdropPath,
      releaseDate: releaseDate ?? this.releaseDate,
      voteAverage: voteAverage ?? this.voteAverage,
      voteCount: voteCount ?? this.voteCount,
      genreIds: genreIds ?? this.genreIds,
      genreNames: genreNames ?? this.genreNames,
      popularity: popularity ?? this.popularity,
      isTv: isTv ?? this.isTv,
      videoUrl: videoUrl ?? this.videoUrl,
      vjName: vjName ?? this.vjName,
      runtime: runtime ?? this.runtime,
      firebaseKey: firebaseKey ?? this.firebaseKey,
    );
  }

  factory Movie.fromJson(Map<String, dynamic> json, {String? key}) {
    final bool isTvShow = json['media_type'] == 'tv' ||
        json['type'] == 'series' ||
        json['type'] == 'tv' ||
        json['first_air_date'] != null ||
        json['firstAirYear'] != null ||
        (json['title'] == null && json['name'] != null);

    // Extract ID (handling TMDB integer id, MovieMax tmdbId, or Firebase string key)
    int resolvedId = 0;
    if (json['id'] is int) {
      resolvedId = json['id'] as int;
    } else if (json['tmdbId'] is int && (json['tmdbId'] as int) > 0) {
      resolvedId = json['tmdbId'] as int;
    } else if (key != null && key.isNotEmpty) {
      resolvedId = key.hashCode.abs();
    } else if (json['id'] != null) {
      resolvedId = int.tryParse(json['id'].toString()) ?? json['id'].toString().hashCode.abs();
    } else {
      resolvedId = (json['title'] ?? json['name'] ?? '').toString().hashCode.abs();
    }

    // Genres parsing (handling List<int> and List<String>)
    final List<int> parsedGenreIds = [];
    final List<String> parsedGenreNames = [];

    if (json['genre_ids'] is List) {
      for (final g in json['genre_ids'] as List) {
        if (g is int) parsedGenreIds.add(g);
      }
    }

    if (json['genres'] is List) {
      for (final g in json['genres'] as List) {
        if (g is String) {
          parsedGenreNames.add(g);
        } else if (g is int) {
          parsedGenreIds.add(g);
        }
      }
    }

    return Movie(
      id: resolvedId,
      title: (json['title'] ?? json['name'] ?? '') as String,
      overview: json['overview'] as String?,
      posterPath: (json['poster_path'] ?? json['poster']) as String?,
      backdropPath: (json['backdrop_path'] ?? json['backdrop']) as String?,
      releaseDate: (json['release_date'] ??
              json['releaseYear']?.toString() ??
              json['first_air_date'] ??
              json['firstAirYear']?.toString()) as String?,
      voteAverage: (json['vote_average'] ?? json['rating'] as num?)?.toDouble() ?? 0.0,
      voteCount: json['vote_count'] as int?,
      genreIds: parsedGenreIds,
      genreNames: parsedGenreNames,
      popularity: (json['popularity'] as num?)?.toDouble(),
      isTv: isTvShow,
      videoUrl: json['videoUrl'] as String?,
      vjName: json['vjName'] as String?,
      runtime: json['runtime'] is int ? json['runtime'] as int : null,
      firebaseKey: key ?? json['firebaseKey'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'overview': overview,
        'poster_path': posterPath,
        'backdrop_path': backdropPath,
        'release_date': releaseDate,
        'vote_average': voteAverage,
        'vote_count': voteCount,
        'genre_ids': genreIds,
        'genre_names': genreNames,
        'popularity': popularity,
        'is_tv': isTv,
        'video_url': videoUrl,
        'vj_name': vjName,
        'runtime': runtime,
        'firebase_key': firebaseKey,
      };

  /// Parse a TMDB paginated results list
  static List<Movie> fromJsonList(Map<String, dynamic> json) {
    final results = json['results'] as List<dynamic>? ?? [];
    return results
        .map((e) => Movie.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  bool operator ==(Object other) => other is Movie && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
