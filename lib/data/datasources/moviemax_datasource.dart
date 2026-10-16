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
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 20),
                headers: {
                  'Accept': 'application/json',
                },
              ),
            );

  /// Fetch all published movies from MovieMax RTDB
  Future<List<Movie>> getAllMovies({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _cachedMovies != null &&
        _cachedMovies!.isNotEmpty &&
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
      debugPrint('🎬 [MovieMaxDatasource] Successfully loaded ${_cachedMovies!.length} movies');
      return reversedMovies;
    } catch (e) {
      debugPrint('⚠️ [MovieMaxDatasource] getAllMovies error: $e');
      return _cachedMovies ?? [];
    }
  }

  /// Fetch all published series from MovieMax RTDB
  Future<List<Movie>> getAllSeries({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _cachedSeries != null &&
        _cachedSeries!.isNotEmpty &&
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
      debugPrint('📺 [MovieMaxDatasource] Successfully loaded ${_cachedSeries!.length} series');
      return reversedSeries;
    } catch (e) {
      debugPrint('⚠️ [MovieMaxDatasource] getAllSeries error: $e');
      return _cachedSeries ?? [];
    }
  }

  /// Find a movie or series by ID or title
  Future<Movie?> findMovie(int id, {String? title}) async {
    final cleanTitle = title?.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

    final movies = await getAllMovies();
    final match = movies.firstWhere(
      (m) {
        if (m.id == id) return true;
        if (cleanTitle != null && cleanTitle.isNotEmpty) {
          final mTitle = m.title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
          if (mTitle == cleanTitle) return true;
        }
        return false;
      },
      orElse: () => const Movie(id: -1, title: '', voteAverage: 0),
    );
    if (match.id != -1) return match;

    final series = await getAllSeries();
    final seriesMatch = series.firstWhere(
      (s) {
        if (s.id == id) return true;
        if (cleanTitle != null && cleanTitle.isNotEmpty) {
          final sTitle = s.title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
          if (sTitle == cleanTitle) return true;
        }
        return false;
      },
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

      final cleanSearchTitle = seriesTitle?.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

      // Find series raw entry by id or title
      Map<String, dynamic>? targetSeries;
      for (final entry in _rawSeriesMap!.entries) {
        if (entry.value is Map) {
          final map = Map<String, dynamic>.from(entry.value as Map);
          final tmdbId = map['tmdbId'] is int ? map['tmdbId'] as int : 0;
          final title = (map['title'] ?? '').toString().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
          final keyHash = entry.key.hashCode.abs();

          if (tmdbId == tvId ||
              keyHash == tvId ||
              (cleanSearchTitle != null && cleanSearchTitle.isNotEmpty && title == cleanSearchTitle)) {
            targetSeries = map;
            break;
          }
        }
      }

      if (targetSeries == null) return [];

      final dynamic seasonsData = targetSeries['seasons'];
      if (seasonsData == null) return [];

      final List<TvEpisodeData> episodes = [];

      void parseEpisodesContainer(dynamic episodesMap, int sNum) {
        if (episodesMap is Map) {
          episodesMap.forEach((_, epData) {
            if (epData is Map) {
              final epMap = Map<String, dynamic>.from(epData);
              epMap['seasonNumber'] = sNum;
              episodes.add(TvEpisodeData.fromJson(epMap));
            }
          });
        } else if (episodesMap is List) {
          for (int i = 0; i < episodesMap.length; i++) {
            final epData = episodesMap[i];
            if (epData is Map) {
              final epMap = Map<String, dynamic>.from(epData);
              epMap['seasonNumber'] = sNum;
              epMap.putIfAbsent('episodeNumber', () => i + 1);
              episodes.add(TvEpisodeData.fromJson(epMap));
            }
          }
        }
      }

      // Check if seasons is a List or Map
      if (seasonsData is List) {
        for (int i = 0; i < seasonsData.length; i++) {
          final s = seasonsData[i];
          if (s is Map) {
            final sNum = s['seasonNumber'] is int ? s['seasonNumber'] as int : i;
            if (sNum == seasonNumber) {
              parseEpisodesContainer(s['episodes'], seasonNumber);
            }
          }
        }
      } else if (seasonsData is Map) {
        final sKey = seasonNumber.toString();
        final sVal = seasonsData[sKey] ?? seasonsData['season_$seasonNumber'];
        if (sVal is Map) {
          parseEpisodesContainer(sVal['episodes'], seasonNumber);
        }
      }

      // Sort episodes ascending by episodeNumber
      episodes.sort((a, b) => a.episodeNumber.compareTo(b.episodeNumber));
      return episodes;
    } catch (e) {
      debugPrint('⚠️ [MovieMaxDatasource] getSeriesEpisodes error: $e');
      return [];
    }
  }
}
