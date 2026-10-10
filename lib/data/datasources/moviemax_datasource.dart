import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/movie.dart';
import '../models/movie_details_data.dart';

/// Remote datasource connecting directly to the MovieMax Realtime Database
/// (https://moviemax-com-default-rtdb.firebaseio.com/)
/// Fetches live Cloudflare R2 / Pearlpix streaming links for 1,531+ movies and 131+ series.
class MovieMaxDatasource {
  static const String _baseUrl = 'https://moviemax-com-default-rtdb.firebaseio.com';

  final Dio _dio;

  // In-memory caching with TTL to keep UI instantaneous
  List<Movie>? _cachedMovies;
  List<Movie>? _cachedSeries;
  DateTime? _lastMoviesFetch;
  DateTime? _lastSeriesFetch;
  static const Duration _cacheTtl = Duration(minutes: 15);

  // Raw series data cache for fast episode lookup
  Map<String, dynamic>? _rawSeriesMap;

  MovieMaxDatasource({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: _baseUrl,
                connectTimeout: const Duration(seconds: 12),
                receiveTimeout: const Duration(seconds: 15),
              ),
            );

  /// Fetch all published movies from MovieMax RTDB
  Future<List<Movie>> getAllMovies({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _cachedMovies != null &&
        _lastMoviesFetch != null &&
        DateTime.now().difference(_lastMoviesFetch!) < _cacheTtl) {
      return _cachedMovies!;
    }

    try {
      final response = await _dio.get('/movies.json');
      if (response.data == null || response.data is! Map) {
        return _cachedMovies ?? [];
      }

      final Map<String, dynamic> rawMap = Map<String, dynamic>.from(response.data as Map);
      final List<Movie> movies = [];

      rawMap.forEach((key, val) {
        if (val is Map) {
          final map = Map<String, dynamic>.from(val);
          // Only include published movies
          final isPublished = map['isPublished'] != false;
          if (isPublished) {
            if (map['vjName'] == null && map['vj'] != null) {
              map['vjName'] = map['vj'];
            }
            movies.add(Movie.fromJson(map, key: key));
          }
        }
      });

      // Firebase RTDB keys are chronological ascending; reversing presents
      // recently uploaded movies first to users.
      final reversedMovies = movies.reversed.toList();
      _cachedMovies = reversedMovies;
      _lastMoviesFetch = DateTime.now();
      return reversedMovies;
    } catch (e) {
      debugPrint('MovieMax getAllMovies error: $e');
      return _cachedMovies ?? [];
    }
  }

  /// Fetch all published series from MovieMax RTDB
  Future<List<Movie>> getAllSeries({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _cachedSeries != null &&
        _lastSeriesFetch != null &&
        DateTime.now().difference(_lastSeriesFetch!) < _cacheTtl) {
      return _cachedSeries!;
    }

    try {
      final response = await _dio.get('/series.json');
      if (response.data == null || response.data is! Map) {
        return _cachedSeries ?? [];
      }

      final Map<String, dynamic> rawMap = Map<String, dynamic>.from(response.data as Map);
      _rawSeriesMap = rawMap;
      final List<Movie> seriesList = [];

      rawMap.forEach((key, val) {
        if (val is Map) {
          final map = Map<String, dynamic>.from(val);
          final isPublished = map['isPublished'] != false;
          if (isPublished) {
            // Mark as TV series
            map['type'] = 'series';
            map['media_type'] = 'tv';
            if (map['vjName'] == null && map['vj'] != null) {
              map['vjName'] = map['vj'];
            }
            seriesList.add(Movie.fromJson(map, key: key));
          }
        }
      });

      final reversedSeries = seriesList.reversed.toList();
      _cachedSeries = reversedSeries;
      _lastSeriesFetch = DateTime.now();
      return reversedSeries;
    } catch (e) {
      debugPrint('MovieMax getAllSeries error: $e');
      return _cachedSeries ?? [];
    }
  }

  /// Find a movie or series by ID or title
  Future<Movie?> findMovie(int id, {String? title}) async {
    final movies = await getAllMovies();
    final match = movies.firstWhere(
      (m) => m.id == id || (title != null && m.title.toLowerCase() == title.toLowerCase()),
      orElse: () {
        return const Movie(id: -1, title: '', voteAverage: 0);
      },
    );
    if (match.id != -1) return match;

    final series = await getAllSeries();
    final seriesMatch = series.firstWhere(
      (s) => s.id == id || (title != null && s.title.toLowerCase() == title.toLowerCase()),
      orElse: () => const Movie(id: -1, title: '', voteAverage: 0),
    );
    if (seriesMatch.id != -1) return seriesMatch;

    return null;
  }

  /// Get episodes for a given series and season number
  Future<List<TvEpisodeData>> getSeriesEpisodes(int tvId, int seasonNumber, {String? seriesTitle}) async {
    try {
      if (_rawSeriesMap == null) {
        await getAllSeries();
      }

      if (_rawSeriesMap == null) return [];

      // Find series raw entry by id or title
      Map<String, dynamic>? targetSeries;
      for (final entry in _rawSeriesMap!.entries) {
        if (entry.value is Map) {
          final map = Map<String, dynamic>.from(entry.value as Map);
          final tmdbId = map['tmdbId'] is int ? map['tmdbId'] as int : 0;
          final title = (map['title'] ?? '').toString().toLowerCase();
          final keyHash = entry.key.hashCode.abs();

          if (tmdbId == tvId ||
              keyHash == tvId ||
              (seriesTitle != null && title == seriesTitle.toLowerCase())) {
            targetSeries = map;
            break;
          }
        }
      }

      if (targetSeries == null) return [];

      final dynamic seasonsData = targetSeries['seasons'];
      if (seasonsData == null) return [];

      final List<TvEpisodeData> episodes = [];

      // Check if seasons is a List or Map
      if (seasonsData is List) {
        for (int i = 0; i < seasonsData.length; i++) {
          final s = seasonsData[i];
          if (s is Map) {
            final sNum = s['seasonNumber'] is int ? s['seasonNumber'] as int : i;
            if (sNum == seasonNumber) {
              final episodesMap = s['episodes'];
              if (episodesMap is Map) {
                episodesMap.forEach((_, epData) {
                  if (epData is Map) {
                    final epMap = Map<String, dynamic>.from(epData);
                    epMap['seasonNumber'] = seasonNumber;
                    episodes.add(TvEpisodeData.fromJson(epMap));
                  }
                });
              }
            }
          }
        }
      } else if (seasonsData is Map) {
        final sKey = seasonNumber.toString();
        final sVal = seasonsData[sKey] ?? seasonsData['season_$seasonNumber'];
        if (sVal is Map) {
          final episodesMap = sVal['episodes'];
          if (episodesMap is Map) {
            episodesMap.forEach((_, epData) {
              if (epData is Map) {
                final epMap = Map<String, dynamic>.from(epData);
                epMap['seasonNumber'] = seasonNumber;
                episodes.add(TvEpisodeData.fromJson(epMap));
              }
            });
          }
        }
      }

      // Sort episodes ascending by episodeNumber
      episodes.sort((a, b) => a.episodeNumber.compareTo(b.episodeNumber));
      return episodes;
    } catch (e) {
      debugPrint('MovieMax getSeriesEpisodes error: $e');
      return [];
    }
  }
}
