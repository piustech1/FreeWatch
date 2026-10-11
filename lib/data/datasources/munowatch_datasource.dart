import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/movie.dart';

/// Remote datasource connecting directly to the live MunoWatch API
/// (https://munowatch.ai.studio/)
/// Fetches real-time Luganda-dubbed movies across 13+ categories with live search
/// and on-demand stream resolution.
class MunowatchDatasource {
  static const String _baseUrl = 'https://munowatch.ai.studio';

  final Dio _dio;

  // In-memory caching with TTL
  List<Movie>? _cachedMovies;
  DateTime? _lastFetch;
  static const Duration _cacheTtl = Duration(minutes: 15);

  MunowatchDatasource({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: _baseUrl,
                connectTimeout: const Duration(seconds: 12),
                receiveTimeout: const Duration(seconds: 15),
                headers: {
                  'User-Agent': 'FreeWatch/1.0 (Flutter)',
                  'Accept': 'application/json, text/plain, */*',
                },
              ),
            );

  /// Fetch all movies across all 13 MunoWatch categories
  Future<List<Movie>> getAllMovies({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _cachedMovies != null &&
        _lastFetch != null &&
        DateTime.now().difference(_lastFetch!) < _cacheTtl) {
      return _cachedMovies!;
    }

    try {
      final response = await _dio.get('/api/dashboard');
      if (response.data == null || response.data is! Map) {
        return _cachedMovies ?? [];
      }

      final Map<String, dynamic> data =
          Map<String, dynamic>.from(response.data as Map);

      final Map<int, Movie> movieMap = {};

      // 1. Featured Banner
      if (data['banner'] is Map) {
        final banner = Map<String, dynamic>.from(data['banner'] as Map);
        final int? bId = banner['id'] is int
            ? banner['id'] as int
            : int.tryParse(banner['id']?.toString() ?? '');
        if (bId != null) {
          final movie = _mapToMovie(banner, defaultCategory: 'Featured');
          movieMap[bId] = movie;
        }
      }

      // 2. All Category Rails (Latest, Action, Sci-Fi, Romance, Horror, Drama, etc.)
      if (data['dashboard'] is List) {
        for (final catItem in data['dashboard'] as List) {
          if (catItem is Map) {
            final catName = (catItem['category'] ?? 'General').toString();
            final moviesList = catItem['movies'];
            if (moviesList is List) {
              for (final rawMovie in moviesList) {
                if (rawMovie is Map) {
                  final movieMapItem = Map<String, dynamic>.from(rawMovie);
                  final int? mId = movieMapItem['id'] is int
                      ? movieMapItem['id'] as int
                      : (movieMapItem['vid'] is int
                          ? movieMapItem['vid'] as int
                          : int.tryParse(
                              (movieMapItem['id'] ?? movieMapItem['vid'])
                                      ?.toString() ??
                                  ''));
                  if (mId != null && !movieMap.containsKey(mId)) {
                    movieMap[mId] = _mapToMovie(movieMapItem,
                        defaultCategory: catName);
                  }
                }
              }
            }
          }
        }
      }

      _cachedMovies = movieMap.values.toList();
      _lastFetch = DateTime.now();
      debugPrint('🎬 [MunowatchDatasource] Loaded ${_cachedMovies!.length} movies from MunoWatch');
      return _cachedMovies!;
    } catch (e) {
      debugPrint('⚠️ [MunowatchDatasource] Error fetching dashboard: $e');
      return _cachedMovies ?? [];
    }
  }

  /// Live search directly on MunoWatch API across 10,000+ movie database
  Future<List<Movie>> searchMovies(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return [];

    // Build intelligent search variations (handles 'spider man' -> 'spider-man' / 'spider')
    final Set<String> queryVariations = {cleanQuery};
    if (cleanQuery.contains(' ')) {
      queryVariations.add(cleanQuery.replaceAll(RegExp(r'\s+'), '-'));
      final words = cleanQuery.split(RegExp(r'\s+')).where((w) => w.length > 2).toList();
      if (words.isNotEmpty) {
        queryVariations.add(words.first);
      }
    }

    final Map<int, Movie> resultsMap = {};

    for (final q in queryVariations) {
      try {
        final response = await _dio.get(
          '/api/search',
          queryParameters: {'q': q},
        );

        if (response.data is List) {
          for (final item in response.data as List) {
            if (item is Map) {
              final movie = _mapToMovie(Map<String, dynamic>.from(item));
              if (!resultsMap.containsKey(movie.id)) {
                resultsMap[movie.id] = movie;
              }
            }
          }
        }
      } catch (e) {
        debugPrint('⚠️ [MunowatchDatasource] Live search error for "$q": $e');
      }

      if (resultsMap.length >= 25) break;
    }

    return resultsMap.values.toList();
  }

  /// Fetch full stream details (direct .mp4 URL, duration, file size, synopsis)
  Future<Map<String, dynamic>?> getStreamDetails(int vid) async {
    try {
      final response = await _dio.post(
        '/api/stream',
        data: {'vid': vid},
      );

      if (response.data is Map) {
        return Map<String, dynamic>.from(response.data as Map);
      }
    } catch (e) {
      debugPrint('⚠️ [MunowatchDatasource] Error fetching stream for ID $vid: $e');
    }
    return null;
  }

  /// Find a movie by ID or title
  Future<Movie?> findMovie(int id, {String? title}) async {
    final movies = await getAllMovies();
    final match = movies.firstWhere(
      (m) =>
          m.id == id ||
          (title != null && m.title.toLowerCase() == title.toLowerCase()),
      orElse: () => const Movie(id: -1, title: '', voteAverage: 0),
    );
    if (match.id != -1) return match;
    return null;
  }

  /// Map raw MunoWatch dictionary to FreeWatch unified Movie model
  Movie _mapToMovie(Map<String, dynamic> json, {String defaultCategory = ''}) {
    final int id = json['id'] is int
        ? json['id'] as int
        : (json['vid'] is int
            ? json['vid'] as int
            : int.tryParse((json['id'] ?? json['vid'])?.toString() ?? '0') ??
                0);

    final String rawTitle =
        (json['video_title'] ?? json['title'] ?? '').toString().trim();
    final String cleanTitle =
        rawTitle.replaceAll(RegExp(r'\s+'), ' ').trim();

    final String category = (json['category'] ?? defaultCategory).toString();

    // Map category name to TMDB genre IDs
    final genreMapping = _mapCategoryToGenres(category);

    final String? image = (json['thumbnail'] ?? json['image'])?.toString();
    final String? playingUrl =
        (json['playingUrl'] ?? json['playingurl'])?.toString();
    final String? description = json['description']?.toString();

    // Clean VJ Name
    String? rawVj = (json['vjname'] ?? json['vj'])?.toString().trim();
    if (rawVj != null && rawVj.isNotEmpty) {
      if (!rawVj.toUpperCase().startsWith('VJ ') &&
          !rawVj.toUpperCase().startsWith('VJ.')) {
        rawVj = 'VJ $rawVj';
      }
    } else {
      rawVj = 'VJ Junior';
    }

    final bool isTvShow = cleanTitle.toLowerCase().contains('episode') ||
        cleanTitle.toLowerCase().contains('season') ||
        cleanTitle.toLowerCase().contains('series') ||
        cleanTitle.toLowerCase().contains('eps ');

    return Movie(
      id: id,
      title: cleanTitle.isNotEmpty ? cleanTitle : 'Movie',
      overview: description?.isNotEmpty == true ? description : null,
      posterPath: image?.isNotEmpty == true ? image : null,
      backdropPath: image?.isNotEmpty == true ? image : null,
      releaseDate: json['timestamp']?.toString().split(' ').first ?? '2026',
      voteAverage: 8.4,
      voteCount: 150,
      genreIds: genreMapping.ids,
      genreNames: genreMapping.names,
      isTv: isTvShow,
      videoUrl: playingUrl?.isNotEmpty == true ? playingUrl : null,
      vjName: rawVj,
      firebaseKey: 'munowatch_$id',
    );
  }

  /// Helper to map category names to TMDB genre IDs and names
  _GenreData _mapCategoryToGenres(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('action')) {
      return const _GenreData([28], ['Action']);
    } else if (lower.contains('sci') || lower.contains('fiction')) {
      return const _GenreData([878], ['Science Fiction']);
    } else if (lower.contains('romance')) {
      return const _GenreData([10749], ['Romance']);
    } else if (lower.contains('horror')) {
      return const _GenreData([27], ['Horror']);
    } else if (lower.contains('drama')) {
      return const _GenreData([18], ['Drama']);
    } else if (lower.contains('animation') || lower.contains('anime')) {
      return const _GenreData([16], ['Animation']);
    } else if (lower.contains('comedy')) {
      return const _GenreData([35], ['Comedy']);
    } else if (lower.contains('thriller')) {
      return const _GenreData([53], ['Thriller']);
    } else if (lower.contains('adventure')) {
      return const _GenreData([12], ['Adventure']);
    } else if (lower.contains('family')) {
      return const _GenreData([10751], ['Family']);
    }
    return const _GenreData([28, 12], ['Action', 'Adventure']);
  }
}

class _GenreData {
  final List<int> ids;
  final List<String> names;
  const _GenreData(this.ids, this.names);
}
