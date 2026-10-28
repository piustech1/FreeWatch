import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/movie.dart';
import '../models/movie_details_data.dart';

/// High-speed REST datasource connecting to the FreeWatch Backend API
/// (https://freewatchug.online/api/v1)
/// Serves edge-cached, pre-enriched Luganda releases with zero client search loops.
class FreewatchApiDatasource {
  static final FreewatchApiDatasource _instance = FreewatchApiDatasource._internal();
  factory FreewatchApiDatasource({Dio? dio}) {
    if (dio != null) _instance._dio = dio;
    return _instance;
  }
  FreewatchApiDatasource._internal();

  static const String _baseUrl = 'https://freewatchug.online/api/v1';
  static const String _fallbackBaseUrl = 'https://www.freewatchug.online/api/v1';

  Dio _dio = Dio(
    BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 7),
      headers: {
        'User-Agent': 'FreeWatch-App/2.0 (Flutter)',
        'Accept': 'application/json',
      },
    ),
  );

  // In-memory cache for sub-millisecond retrieval
  final Map<int, Movie> _catalog = {};
  final Map<String, List<Movie>> _byCategory = {};
  final Map<String, List<Movie>> _byVj = {};
  final List<Movie> _latestMovies = [];
  final List<Movie> _continueWatching = [];
  Movie? _featuredMovie;

  bool _isInitialized = false;
  Completer<void>? _initCompleter;

  Movie? get featuredMovie => _featuredMovie;
  List<Movie> get latestMovies => List.unmodifiable(_latestMovies);
  List<Movie> get continueWatching => List.unmodifiable(_continueWatching);

  /// Initialize and fetch high-speed dashboard feed
  Future<void> initialize({bool forceRefresh = false}) async {
    if (!forceRefresh && _isInitialized) return;
    if (_initCompleter != null && !_initCompleter!.isCompleted) {
      return _initCompleter!.future;
    }

    _initCompleter = Completer<void>();

    try {
      Response? response;
      try {
        response = await _dio.get('/dashboard');
      } catch (e) {
        debugPrint('⚠️ [FreewatchApiDatasource] Primary API fetch notice: $e');
        // Try fallback baseUrl
        final fallbackDio = Dio(
          BaseOptions(
            baseUrl: _fallbackBaseUrl,
            connectTimeout: const Duration(seconds: 5),
            receiveTimeout: const Duration(seconds: 7),
          ),
        );
        try {
          response = await fallbackDio.get('/dashboard');
        } catch (_) {}
      }

      if (response != null && response.statusCode == 200 && response.data is Map) {
        final Map<String, dynamic> body = Map<String, dynamic>.from(response.data as Map);
        if (body['success'] == true && body['data'] is Map) {
          _parseDashboard(Map<String, dynamic>.from(body['data'] as Map));
        }
      }
      _isInitialized = true;
      _initCompleter?.complete();
    } catch (e) {
      debugPrint('⚠️ [FreewatchApiDatasource] Error initializing API: $e');
      _isInitialized = true;
      _initCompleter?.complete();
    }
  }

  void _parseDashboard(Map<String, dynamic> data) {
    // 1. Featured Hero
    if (data['featured'] is Map) {
      _featuredMovie = _mapToMovie(Map<String, dynamic>.from(data['featured'] as Map));
      if (_featuredMovie != null) {
        _catalog[_featuredMovie!.id] = _featuredMovie!;
      }
    }

    // 2. Latest Movies
    _latestMovies.clear();
    if (data['latest'] is List) {
      for (final item in data['latest'] as List) {
        if (item is Map) {
          final m = _mapToMovie(Map<String, dynamic>.from(item));
          if (m != null) {
            _latestMovies.add(m);
            _catalog[m.id] = m;
          }
        }
      }
    }

    // 3. Continue Watching
    _continueWatching.clear();
    if (data['continueWatching'] is List) {
      for (final item in data['continueWatching'] as List) {
        if (item is Map) {
          final m = _mapToMovie(Map<String, dynamic>.from(item));
          if (m != null) {
            _continueWatching.add(m);
            _catalog[m.id] = m;
          }
        }
      }
    }

    // 4. Categories
    _byCategory.clear();
    if (data['categories'] is Map) {
      final catMap = Map<String, dynamic>.from(data['categories'] as Map);
      catMap.forEach((catName, list) {
        if (list is List) {
          final List<Movie> catMovies = [];
          for (final item in list) {
            if (item is Map) {
              final m = _mapToMovie(Map<String, dynamic>.from(item));
              if (m != null) {
                catMovies.add(m);
                _catalog[m.id] = m;
              }
            }
          }
          if (catMovies.isNotEmpty) {
            _byCategory[catName.toLowerCase().trim()] = catMovies;
          }
        }
      });
    }

    // 5. Index by VJ
    _byVj.clear();
    for (final m in _catalog.values) {
      final v = (m.vjName ?? 'Luganda Dubbed').toLowerCase().trim();
      _byVj.putIfAbsent(v, () => []).add(m);
    }

    debugPrint('🚀 [FreewatchApiDatasource] Ingested ${_catalog.length} enriched movies via FreeWatch API');
  }

  Movie? _mapToMovie(Map<String, dynamic> map) {
    try {
      final id = map['id'] is int ? map['id'] as int : int.tryParse(map['id']?.toString() ?? '') ?? 0;
      if (id == 0) return null;

      final title = map['title']?.toString().trim() ?? '';
      if (title.isEmpty) return null;

      final poster = map['poster_path']?.toString() ?? map['poster']?.toString() ?? map['image']?.toString();
      final backdrop = map['backdrop_path']?.toString() ?? map['backdrop']?.toString() ?? poster;
      final stream = map['streamUrl']?.toString() ?? map['playingurl']?.toString();
      final vj = map['vj']?.toString() ?? map['vjName']?.toString();
      final cat = map['category']?.toString() ?? 'Action';
      final isSeries = map['isTv'] == true || map['is_series'] == true;

      return Movie(
        id: id,
        title: title,
        overview: map['overview']?.toString(),
        posterPath: poster,
        backdropPath: backdrop,
        voteAverage: double.tryParse(map['vote_average']?.toString() ?? map['rating']?.toString() ?? '8.5') ?? 8.5,
        releaseDate: map['year']?.toString() ?? '2025',
        genreNames: [cat],
        isTv: isSeries,
        videoUrl: (stream != null && stream.isNotEmpty) ? stream : null,
        vjName: (vj != null && vj.isNotEmpty) ? vj : 'Luganda Dubbed',
        seriesCode: map['series_code']?.toString(),
      );
    } catch (_) {
      return null;
    }
  }

  /// Get all movies cached in memory
  Future<List<Movie>> getCatalog({bool forceRefresh = false}) async {
    await initialize(forceRefresh: forceRefresh);
    return _catalog.values.toList();
  }

  /// Get movies for a specific category
  Future<List<Movie>> getCategoryMovies(String categoryName) async {
    await initialize();
    final clean = categoryName.toLowerCase().trim();
    if (_byCategory.containsKey(clean)) {
      return _byCategory[clean]!;
    }
    // Partial search
    for (final entry in _byCategory.entries) {
      if (entry.key.contains(clean) || clean.contains(entry.key)) {
        return entry.value;
      }
    }
    return _catalog.values.where((m) => m.genreNames.any((g) => g.toLowerCase().contains(clean))).toList();
  }

  /// Get movies for a specific VJ
  Future<List<Movie>> getMoviesByVj(String vjName) async {
    await initialize();
    final clean = vjName.toLowerCase().trim();
    for (final entry in _byVj.entries) {
      if (entry.key.contains(clean) || clean.contains(entry.key)) {
        return entry.value;
      }
    }
    return _catalog.values.where((m) => (m.vjName?.toLowerCase() ?? '').contains(clean)).toList();
  }

  /// Get series episodes directly from API
  Future<List<TvEpisodeData>> getSeriesEpisodes(dynamic idOrCode) async {
    try {
      final res = await _dio.get('/series', queryParameters: {'code': idOrCode.toString()});
      if (res.statusCode == 200 && res.data is Map) {
        final body = Map<String, dynamic>.from(res.data as Map);
        if (body['success'] == true && body['data'] is Map) {
          final sData = Map<String, dynamic>.from(body['data'] as Map);
          final rawEps = sData['episodes'];
          if (rawEps is List) {
            final List<TvEpisodeData> eps = [];
            for (var i = 0; i < rawEps.length; i++) {
              final ep = rawEps[i];
              if (ep is Map) {
                final epMap = Map<String, dynamic>.from(ep);
                final epNum = epMap['episodeNumber'] is int
                    ? epMap['episodeNumber'] as int
                    : int.tryParse(epMap['episodeNumber']?.toString() ?? '') ?? (i + 1);
                final epId = int.tryParse(epMap['id']?.toString() ?? '') ?? (i + 1);
                eps.add(
                  TvEpisodeData(
                    id: epId,
                    episodeNumber: epNum,
                    seasonNumber: 1,
                    name: epMap['title']?.toString() ?? 'Episode $epNum',
                    overview: sData['title']?.toString() ?? '',
                    runtime: 45,
                    stillPath: epMap['image']?.toString(),
                    voteAverage: 8.5,
                    videoUrl: epMap['streamUrl']?.toString() ?? epMap['playingurl']?.toString(),
                  ),
                );
              }
            }
            if (eps.isNotEmpty) return eps;
          }
        }
      }
    } catch (e) {
      debugPrint('⚠️ [FreewatchApiDatasource] Error fetching series episodes: $e');
    }
    return const [];
  }

  /// Live search directly on FreeWatch API
  Future<List<Movie>> searchMovies(String query) async {
    final cleanQ = query.trim();
    if (cleanQ.isEmpty) return [];

    try {
      final res = await _dio.get('/search', queryParameters: {'q': cleanQ});
      if (res.statusCode == 200 && res.data is Map) {
        final body = Map<String, dynamic>.from(res.data as Map);
        if (body['success'] == true && body['data'] is List) {
          final List<Movie> list = [];
          for (final item in body['data'] as List) {
            if (item is Map) {
              final m = _mapToMovie(Map<String, dynamic>.from(item));
              if (m != null) list.add(m);
            }
          }
          if (list.isNotEmpty) return list;
        }
      }
    } catch (_) {}

    // Fallback to local catalog search
    return _catalog.values
        .where((m) =>
            m.title.toLowerCase().contains(cleanQ.toLowerCase()) ||
            (m.vjName?.toLowerCase() ?? '').contains(cleanQ.toLowerCase()))
        .toList();
  }
}
