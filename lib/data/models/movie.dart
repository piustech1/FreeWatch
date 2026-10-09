import '../../core/constants/api_constants.dart';

/// TMDB Movie model
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
  final double? popularity;
  final bool isTv;

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
    this.popularity,
    this.isTv = false,
  });

  /// Full resolved poster URL (handles full URLs and TMDB relative paths)
  String get posterUrl {
    if (posterPath == null || posterPath!.isEmpty) return '';
    if (posterPath!.startsWith('http')) return posterPath!;
    return '${ApiConstants.posterW500}$posterPath';
  }

  /// Release year shorthand
  String get year => releaseDate != null && releaseDate!.length >= 4
      ? releaseDate!.substring(0, 4)
      : '';

  /// Rounded rating (1 decimal place)
  String get ratingDisplay => voteAverage.toStringAsFixed(1);

  factory Movie.fromJson(Map<String, dynamic> json) {
    final bool isTvShow = json['media_type'] == 'tv' ||
        json['first_air_date'] != null ||
        (json['title'] == null && json['name'] != null);

    return Movie(
      id: json['id'] as int,
      title: (json['title'] ?? json['name'] ?? '') as String,
      overview: json['overview'] as String?,
      posterPath: json['poster_path'] as String?,
      backdropPath: json['backdrop_path'] as String?,
      releaseDate:
          (json['release_date'] ?? json['first_air_date']) as String?,
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0.0,
      voteCount: json['vote_count'] as int?,
      genreIds: (json['genre_ids'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [],
      popularity: (json['popularity'] as num?)?.toDouble(),
      isTv: isTvShow,
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
        'popularity': popularity,
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
