import '../../core/constants/api_constants.dart';
import 'movie.dart';

/// Represents an offline movie stored on device storage
class DownloadedMovie {
  final int id;
  final String title;
  final String? posterPath;
  final String? backdropPath;
  final String? releaseDate;
  final double voteAverage;
  final int fileSizeMb;
  final String quality;
  final DateTime downloadedAt;
  final String? vjName;
  final String videoUrl;

  const DownloadedMovie({
    required this.id,
    required this.title,
    this.posterPath,
    this.backdropPath,
    this.releaseDate,
    required this.voteAverage,
    required this.fileSizeMb,
    this.quality = '1080p Full HD',
    required this.downloadedAt,
    this.vjName,
    this.videoUrl =
        'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
  });

  String get posterUrl {
    if (posterPath == null || posterPath!.isEmpty) return '';
    if (posterPath!.startsWith('http')) return posterPath!;
    return '${ApiConstants.posterW500}$posterPath';
  }

  String get formattedFileSize {
    if (fileSizeMb >= 1000) {
      return '${(fileSizeMb / 1024).toStringAsFixed(1)} GB';
    }
    return '$fileSizeMb MB';
  }

  Movie toMovie() {
    return Movie(
      id: id,
      title: title,
      posterPath: posterPath,
      backdropPath: backdropPath,
      releaseDate: releaseDate,
      voteAverage: voteAverage,
    );
  }

  factory DownloadedMovie.fromMovie(
    Movie movie, {
    String? vjName,
    int? fileSizeMb,
    String? quality,
    String? videoUrl,
  }) {
    // Generate realistic movie file size between 720MB and 1450MB if not provided
    final computedSize = fileSizeMb ?? (700 + (movie.id % 800));
    return DownloadedMovie(
      id: movie.id,
      title: movie.title,
      posterPath: movie.posterPath,
      backdropPath: movie.backdropPath,
      releaseDate: movie.releaseDate,
      voteAverage: movie.voteAverage,
      fileSizeMb: computedSize,
      quality: quality ?? '1080p Full HD',
      downloadedAt: DateTime.now(),
      vjName: vjName,
      videoUrl: videoUrl ??
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
    );
  }

  factory DownloadedMovie.fromJson(Map<String, dynamic> json) {
    return DownloadedMovie(
      id: json['id'] as int,
      title: json['title'] as String,
      posterPath: json['poster_path'] as String?,
      backdropPath: json['backdrop_path'] as String?,
      releaseDate: json['release_date'] as String?,
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 7.5,
      fileSizeMb: json['file_size_mb'] as int? ?? 850,
      quality: json['quality'] as String? ?? '1080p Full HD',
      downloadedAt: json['downloaded_at'] != null
          ? DateTime.tryParse(json['downloaded_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      vjName: json['vj_name'] as String?,
      videoUrl: json['video_url'] as String? ??
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'poster_path': posterPath,
        'backdrop_path': backdropPath,
        'release_date': releaseDate,
        'vote_average': voteAverage,
        'file_size_mb': fileSizeMb,
        'quality': quality,
        'downloaded_at': downloadedAt.toIso8601String(),
        'vj_name': vjName,
        'video_url': videoUrl,
      };

  @override
  bool operator ==(Object other) => other is DownloadedMovie && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
