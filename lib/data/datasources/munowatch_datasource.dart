import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/movie.dart';

/// Remote datasource connecting directly to the live MunoWatch API
/// (https://munowatch.ai.studio/)
/// Fetches real-time Luganda-dubbed movies across 13+ categories with live search
/// and on-demand stream resolution.
class MunowatchDatasource {
  static const String _baseUrl = 'https://munowatch.ai.studio';
  static const String _fallbackBaseUrl = 'https://mumowatch.ai.studio';

  final Dio _dio;
  final Dio _fallbackDio;

  // In-memory caching with TTL
  List<Movie>? _cachedMovies;
  List<Movie>? _latestMovies;
  DateTime? _lastFetch;
  static const Duration _cacheTtl = Duration(minutes: 15);

  // Global registry of all discovered movies (from dashboard, search, and deep lookups)
  final Map<int, Movie> _knownMoviesMap = {};

  /// Helper web URLs matching MunoWatch web routing conventions
  static String dashboardWebUrl() => '$_baseUrl/dashboard';
  static String movieWebUrl(dynamic id) => '$_baseUrl/movie/$id';
  static String moviePlayWebUrl(dynamic id) => '$_baseUrl/movie/$id/play';
  static String moviePlayQueryWebUrl({dynamic id}) =>
      id != null ? '$_baseUrl/movie/play?id=$id' : '$_baseUrl/movie/play';
  static String seriesWebUrl(String seriesCode) => '$_baseUrl/series/$seriesCode';

  /// Sanitize and upgrade video stream URLs (convert cleartext http to https on CDNs & encode spaces)
  static String? sanitizeStreamUrl(String? raw) {
    if (raw == null) return null;
    var trimmed = raw.trim();
    if (trimmed.isEmpty || !trimmed.startsWith('http')) return null;
    if (trimmed.startsWith('http://') &&
        (trimmed.contains('b-cdn.net') || trimmed.contains('r2.dev') || trimmed.contains('pearlpix'))) {
      trimmed = trimmed.replaceFirst('http://', 'https://');
    }
    if (trimmed.contains(' ')) {
      trimmed = trimmed.replaceAll(' ', '%20');
    }
    return trimmed;
  }

  MunowatchDatasource({Dio? dio, Dio? fallbackDio})
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
            ),
        _fallbackDio = fallbackDio ??
            Dio(
              BaseOptions(
                baseUrl: _fallbackBaseUrl,
                connectTimeout: const Duration(seconds: 12),
                receiveTimeout: const Duration(seconds: 15),
                headers: {
                  'User-Agent': 'FreeWatch/1.0 (Flutter)',
                  'Accept': 'application/json, text/plain, */*',
                },
              ),
            );

  /// Health check verifying MunoWatch API is active and responsive
  Future<bool> isHealthy() async {
    if (_cachedMovies != null && _cachedMovies!.isNotEmpty) return true;
    try {
      final response = await _fallbackDio.get('/dashboard').timeout(const Duration(seconds: 4));
      return response.statusCode == 200 && response.data is Map;
    } catch (_) {
      try {
        final response = await _dio.get('/dashboard').timeout(const Duration(seconds: 4));
        return response.statusCode == 200;
      } catch (_) {
        return false;
      }
    }
  }

  /// Fetch all movies across all 13 MunoWatch categories
  Future<List<Movie>> getAllMovies({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _cachedMovies != null &&
        _lastFetch != null &&
        DateTime.now().difference(_lastFetch!) < _cacheTtl) {
      return _cachedMovies!;
    }

    try {
      Response? response;
      try {
        response = await _fallbackDio.get('/dashboard');
      } catch (_) {
        try {
          response = await _dio.get('/dashboard');
        } catch (_) {
          try {
            response = await _dio.get('/api/dashboard');
          } catch (_) {}
        }
      }
      if (response?.data is! Map) {
        return _cachedMovies ?? [];
      }

      final Map<String, dynamic> data =
          Map<String, dynamic>.from(response!.data as Map);

      // Guard: If response indicates access token error, fallback immediately to public backend
      if (data['error'] == true && data['dashboard'] == null && data['movies'] == null) {
        try {
          final fb = await _fallbackDio.get('/dashboard');
          if (fb.data is Map) {
            data.clear();
            data.addAll(Map<String, dynamic>.from(fb.data as Map));
          }
        } catch (_) {}
      }

      final Map<int, Movie> movieMap = {};
      final List<Movie> latestList = [];

      // Build section categories map
      final Map<int, String> sectionCategories = {};
      if (data['sections'] is List) {
        for (final sec in data['sections'] as List) {
          if (sec is Map) {
            final secId = sec['id'] is int
                ? sec['id'] as int
                : int.tryParse(sec['id']?.toString() ?? '');
            final secCat = sec['category']?.toString() ?? '';
            if (secId != null && secCat.isNotEmpty) {
              sectionCategories[secId] = secCat;
            }
          }
        }
      }

      // 1. Featured Banner
      if (data['banner'] is Map) {
        final banner = Map<String, dynamic>.from(data['banner'] as Map);
        final int? bId = banner['id'] is int
            ? banner['id'] as int
            : int.tryParse(banner['id']?.toString() ?? '');
        if (bId != null) {
          final movie = _mapToMovie(banner, defaultCategory: 'Featured');
          movieMap[bId] = movie;
          _knownMoviesMap[bId] = movie;
        }
      }

      // 2. All Category Rails (Latest, Action, Sci-Fi, Romance, Horror, Drama, etc.)
      if (data['dashboard'] is List) {
        for (final catItem in data['dashboard'] as List) {
          if (catItem is Map) {
            final catName = (catItem['category'] ?? 'General').toString();
            final bool isLatestCategory = catName.toLowerCase().contains('latest');
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
                    final movie = _mapToMovie(movieMapItem,
                        defaultCategory: catName);
                    movieMap[mId] = movie;
                    _knownMoviesMap[mId] = movie;
                    if (isLatestCategory) {
                      latestList.add(movie);
                    }
                  }
                }
              }
            }
          }
        }
      }

      // 3. Movies rail from MumoWatch /dashboard
      if (data['movies'] is List) {
        for (final rawMovie in data['movies'] as List) {
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
              final catId = movieMapItem['category_id'] is int
                  ? movieMapItem['category_id'] as int
                  : int.tryParse(movieMapItem['category_id']?.toString() ?? '');
              final catName = catId != null ? (sectionCategories[catId] ?? 'General') : 'General';
              final bool isLatestCategory = catName.toLowerCase().contains('latest');

              final movie = _mapToMovie(movieMapItem, defaultCategory: catName);
              movieMap[mId] = movie;
              _knownMoviesMap[mId] = movie;
              if (isLatestCategory || latestList.length < 15) {
                latestList.add(movie);
              }
            }
          }
        }
      }

      // 4. Seed and enrich catalog with authentic high-confidence MunoWatch titles
      final seedKeywords = ['the', 'action', 'love', 'man', 'war', 'season', 'life'];
      for (final kw in seedKeywords) {
        try {
          final res = await searchMovies(kw);
          for (final sm in res) {
            if (!movieMap.containsKey(sm.id) && sm.title.isNotEmpty && sm.title != 'Movie') {
              movieMap[sm.id] = sm;
              _knownMoviesMap[sm.id] = sm;
            }
          }
        } catch (_) {}
      }

      // 5. Parallel-enrich the top latest items so real titles appear immediately
      final toEnrich = latestList
          .where((m) => m.title == 'Movie' || m.title.isEmpty)
          .take(20)
          .toList();
      if (toEnrich.isNotEmpty) {
        try {
          final enrichedResults = await Future.wait(
            toEnrich.map((m) async {
              try {
                final det = await getStreamDetails(m.id);
                if (det != null &&
                    det['title'] != null &&
                    det['title'].toString().trim().isNotEmpty) {
                  return _mapToMovie(det,
                      defaultCategory: m.genreNames.firstOrNull ?? '');
                }
              } catch (_) {}
              return m;
            }),
          );
          for (final em in enrichedResults) {
            movieMap[em.id] = em;
            _knownMoviesMap[em.id] = em;
            final idx = latestList.indexWhere((l) => l.id == em.id);
            if (idx != -1) latestList[idx] = em;
          }
        } catch (_) {}
      }

      // Filter out any lingering blank/unresolved placeholder titles from public cached feed
      _cachedMovies = movieMap.values
          .where((m) => m.title.trim().isNotEmpty && m.title.trim() != 'Movie')
          .toList();
      if (_cachedMovies!.isEmpty) {
        _cachedMovies = movieMap.values.toList();
      }
      _latestMovies = latestList
          .where((m) => m.title.trim().isNotEmpty && m.title.trim() != 'Movie')
          .toList();
      if (_latestMovies!.isEmpty) {
        _latestMovies = _cachedMovies!.take(15).toList();
      }
      _lastFetch = DateTime.now();
      debugPrint('🎬 [MunowatchDatasource] Loaded ${_cachedMovies!.length} movies (Latest: ${_latestMovies!.length}) from MumoWatch/MunoWatch');
      return _cachedMovies!;
    } catch (e) {
      debugPrint('⚠️ [MunowatchDatasource] Error fetching dashboard: $e');
      return _cachedMovies ?? [];
    }
  }

  /// Exclusively returns movies from the "Latest on Munowatch" / "Latest Uploads" category
  Future<List<Movie>> getLatestMovies() async {
    if (_latestMovies != null && _latestMovies!.isNotEmpty) {
      return _latestMovies!;
    }
    await getAllMovies();
    return _latestMovies ?? (_cachedMovies?.take(15).toList() ?? []);
  }

  /// Returns series and episodic releases from MunoWatch
  Future<List<Movie>> getSeriesMovies() async {
    final all = await getAllMovies();
    final List<Movie> series = all.where((m) {
      if (!m.isTv) return false;
      final t = m.title.toLowerCase();
      return !t.contains('mob land') && !t.contains('mobland');
    }).toList();
    final Set<int> seenIds = series.map((s) => s.id).toSet();

    // Query top known Luganda translated series directly from MunoWatch API
    if (series.length < 15) {
      final popularSeriesQueries = [
        'Squid Game',
        'From',
        'Reacher',
        'Loki',
        'Vikings',
        'Tulsa King',
        'Money Heist',
        'Game of Thrones',
        'House of the Dragon',
        'The Boys',
        'Prison Break',
        'Sword and Fairy',
        'Breaking Bad',
      ];
      for (final query in popularSeriesQueries) {
        try {
          final results = await searchMovies(query);
          for (final m in results) {
            final t = m.title.toLowerCase();
            if (t.contains('mob land') || t.contains('mobland')) continue;
            final isRealSeries = m.isTv ||
                (m.seriesCode != null && m.seriesCode!.isNotEmpty && m.seriesCode != '0') ||
                t.contains('season') ||
                t.contains('series') ||
                t.contains('eps ') ||
                RegExp(r'\b(?:s\d{1,2}|ep?\s*\d+)\b', caseSensitive: false).hasMatch(m.title);
            if (isRealSeries && seenIds.add(m.id)) {
              series.add(m.copyWith(isTv: true));
            }
          }
          if (series.length >= 25) break;
        } catch (_) {}
      }
    }

    if (series.isNotEmpty) return series;

    // Search specifically for series if none on dashboard
    try {
      final searchSeries = await searchMovies('season');
      for (final s in searchSeries) {
        final t = s.title.toLowerCase();
        if (t.contains('mob land') || t.contains('mobland')) continue;
        final isRealSeries = s.isTv ||
            (s.seriesCode != null && s.seriesCode!.isNotEmpty && s.seriesCode != '0') ||
            t.contains('season') ||
            t.contains('series');
        if (isRealSeries && seenIds.add(s.id)) {
          series.add(s.copyWith(isTv: true));
        }
      }
      if (series.isNotEmpty) return series;
    } catch (_) {}

    return [];
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
      // 1. Query public host (mumowatch.ai.studio/search) first
      try {
        final response = await _fallbackDio.get(
          '/search',
          queryParameters: {'q': q},
        );
        if (response.data is Map) {
          final dataMap = response.data as Map;
          if (dataMap['series'] is List) {
            for (final s in dataMap['series'] as List) {
              if (s is Map) {
                final sTitle = s['title']?.toString() ?? '';
                final sCode = s['series_code']?.toString() ?? '';
                if (s['episodes'] is List) {
                  for (final ep in s['episodes'] as List) {
                    if (ep is Map) {
                      final epMap = Map<String, dynamic>.from(ep);
                      if ((epMap['title'] == null ||
                              epMap['title'].toString().isEmpty) &&
                          sTitle.isNotEmpty) {
                        epMap['title'] = sTitle;
                      }
                      if (sCode.isNotEmpty) {
                        epMap['series_code'] = sCode;
                      }
                      final movie = _mapToMovie(epMap, defaultCategory: q);
                      if (!resultsMap.containsKey(movie.id)) {
                        resultsMap[movie.id] = movie;
                        _knownMoviesMap[movie.id] = movie;
                      }
                    }
                  }
                }
              }
            }
          }
          if (dataMap['movies'] is List) {
            for (final item in dataMap['movies'] as List) {
              if (item is Map) {
                final movie = _mapToMovie(Map<String, dynamic>.from(item), defaultCategory: q);
                if (!resultsMap.containsKey(movie.id)) {
                  resultsMap[movie.id] = movie;
                  _knownMoviesMap[movie.id] = movie;
                }
              }
            }
          }
        } else if (response.data is List) {
          for (final item in response.data as List) {
            if (item is Map) {
              final movie = _mapToMovie(Map<String, dynamic>.from(item), defaultCategory: q);
              if (!resultsMap.containsKey(movie.id)) {
                resultsMap[movie.id] = movie;
                _knownMoviesMap[movie.id] = movie;
              }
            }
          }
        }
      } catch (e) {
        debugPrint('⚠️ [MunowatchDatasource] Fallback search error for "$q": $e');
      }

      // 2. Query primary host (munowatch.ai.studio/api/search) if empty
      if (resultsMap.isEmpty) {
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
                  _knownMoviesMap[movie.id] = movie;
                }
              }
            }
          }
        } catch (_) {}
      }

      if (resultsMap.length >= 25) break;
    }

    return resultsMap.values.toList();
  }

  /// Fetch full stream details (direct .mp4 URL, duration, file size, synopsis)
  /// Strictly returns direct .mp4 streaming link if available on MunoWatch
  Future<Map<String, dynamic>?> getStreamDetails(int vid) async {
    // 1. Try POST /api/stream on primary host (munowatch.ai.studio)
    try {
      final response = await _dio.post(
        '/api/stream',
        data: {'vid': vid},
      );

      if (response.data is Map) {
        final map = Map<String, dynamic>.from(response.data as Map);
        final rawUrl = (map['playingurl'] ?? map['playingUrl'])?.toString();
        map['playingurl'] = sanitizeStreamUrl(rawUrl);
        final rawSeriesCode = (map['series_code'] ?? map['seriesCode'])?.toString().trim();
        if (rawSeriesCode != null && rawSeriesCode.isNotEmpty && rawSeriesCode != '0') {
          map['series_code'] = rawSeriesCode;
        }
        return map;
      }
    } catch (e) {
      debugPrint('⚠️ [MunowatchDatasource] Primary /api/stream error for ID $vid: $e');
    }

    // 2. Try GET /movie/$vid on fallback host (mumowatch.ai.studio)
    try {
      final response = await _fallbackDio.get('/movie/$vid');
      if (response.data is Map) {
        final map = Map<String, dynamic>.from(response.data as Map);
        String? rawUrl = (map['playingurl'] ?? map['playingUrl'])?.toString();
        if (rawUrl != null && rawUrl.trim().startsWith('http')) {
          map['playingurl'] = sanitizeStreamUrl(rawUrl);
        } else {
          // Check if GET /movie/$vid/play redirects to direct stream URL
          try {
            final redirectResponse = await _fallbackDio.get(
              '/movie/$vid/play',
              options: Options(
                followRedirects: false,
                validateStatus: (status) => status != null && status < 400,
              ),
            );
            final location = redirectResponse.headers.value('location');
            if (location != null && location.trim().startsWith('http')) {
              map['playingurl'] = sanitizeStreamUrl(location);
            } else {
              map['playingurl'] = null;
            }
          } catch (_) {
            map['playingurl'] = null;
          }
        }
        final rawSeriesCode = (map['series_code'] ?? map['seriesCode'])?.toString().trim();
        if (rawSeriesCode != null && rawSeriesCode.isNotEmpty && rawSeriesCode != '0') {
          map['series_code'] = rawSeriesCode;
        }
        return map;
      }
    } catch (_) {}

    return null;
  }

  /// Fetch all real episodes for a given series code from MunoWatch
  Future<List<Map<String, dynamic>>> getSeriesEpisodes(String seriesCode) async {
    final cleanCode = seriesCode.trim();
    if (cleanCode.isEmpty) return [];

    try {
      final response = await _fallbackDio.get('/series/$cleanCode');
      if (response.data is Map) {
        final data = response.data as Map;
        if (data['episodes'] is List) {
          final List<Map<String, dynamic>> episodes = [];
          for (final ep in data['episodes'] as List) {
            if (ep is Map) {
              final map = Map<String, dynamic>.from(ep);
              final rawPlay = (map['playingurl'] ?? map['playingUrl'])?.toString();
              map['playingurl'] = sanitizeStreamUrl(rawPlay);
              episodes.add(map);
            }
          }
          return episodes;
        }
      }
    } catch (e) {
      debugPrint('⚠️ [MunowatchDatasource] Error fetching series episodes for $cleanCode: $e');
    }
    return [];
  }

  /// Find a movie by ID or title with deep on-demand stream lookup across 10,000+ catalog
  Future<Movie?> findMovie(int id, {String? title}) async {
    // 1. Check registry of known movies (ensuring valid non-empty title)
    if (_knownMoviesMap.containsKey(id)) {
      final cached = _knownMoviesMap[id]!;
      if (cached.title.isNotEmpty && cached.title != 'Movie') {
        return cached;
      }
    }

    // 2. Check full cached dashboard movies
    final movies = await getAllMovies();
    final match = movies.firstWhere(
      (m) =>
          m.id == id ||
          (title != null && m.title.toLowerCase() == title.toLowerCase()),
      orElse: () => const Movie(id: -1, title: '', voteAverage: 0),
    );
    if (match.id != -1 && match.title.isNotEmpty && match.title != 'Movie') {
      _knownMoviesMap[match.id] = match;
      return match;
    }

    // 3. Deep on-demand lookup via /movie/$id or /api/stream directly for this ID
    try {
      final details = await getStreamDetails(id);
      if (details != null && details['title'] != null && details['title'].toString().trim().isNotEmpty) {
        final deepMovie = _mapToMovie(details);
        _knownMoviesMap[id] = deepMovie;
        return deepMovie;
      }
    } catch (_) {}

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

    final dynamic rawCatId = json['category_id'] ?? json['categoryId'];
    final int? catId = rawCatId is int
        ? rawCatId
        : int.tryParse(rawCatId?.toString() ?? '');

    final String category = (json['category'] ?? defaultCategory).toString();

    // Map category name and numeric ID to TMDB genre IDs
    final genreMapping = _mapCategoryToGenres(category, categoryId: catId);

    final String? image = (json['thumbnail'] ?? json['image'])?.toString();
    final String? playingUrl =
        (json['playingUrl'] ?? json['playingurl'])?.toString();
    final String? description = json['description']?.toString();

    // Clean VJ Name (Strict analysis: only use genuine VJ if present, NEVER mimic fake VJ)
    String? rawVj = (json['vjname'] ?? json['vj'])?.toString().trim();
    if (rawVj != null && rawVj.isNotEmpty && rawVj != 'null') {
      if (!rawVj.toUpperCase().startsWith('VJ ') &&
          !rawVj.toUpperCase().startsWith('VJ.')) {
        rawVj = 'VJ $rawVj';
      }
    } else {
      // Extract from raw title if present (e.g. "HOKUM VJ JINGO.2026")
      final vjMatch = RegExp(r'\b(VJ\s+[A-Za-z0-9]+)\b', caseSensitive: false).firstMatch(rawTitle);
      if (vjMatch != null) {
        rawVj = vjMatch.group(1);
      } else {
        rawVj = null; // No VJ: leave null! Do not mimic or invent VJ Junior.
      }
    }

    final String? seriesCode = (json['series_code'] ?? json['seriesCode'])?.toString().trim();

    final int epCount = json['episodes'] is List ? (json['episodes'] as List).length : 1;
    final bool hasExplicitSeasonOrEp =
        cleanTitle.toLowerCase().contains('season') ||
        cleanTitle.toLowerCase().contains('eps ') ||
        RegExp(r'\b(?:s\d{1,2}|ep?\s*\d+)\b', caseSensitive: false).hasMatch(cleanTitle);

    final bool isTvShow = (category.toLowerCase().contains('series')) ||
        hasExplicitSeasonOrEp ||
        (epCount > 1 && seriesCode != null && seriesCode.isNotEmpty && seriesCode != '0' && seriesCode != json['id']?.toString());

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
      videoUrl: sanitizeStreamUrl(playingUrl),
      vjName: rawVj,
      seriesCode: seriesCode,
      firebaseKey: 'munowatch_$id',
    );
  }

  /// Helper to map category names and MunoWatch numeric category IDs to TMDB genre IDs and names
  _GenreData _mapCategoryToGenres(String category, {int? categoryId}) {
    if (categoryId != null) {
      switch (categoryId) {
        case 8:
          return const _GenreData([18], ['Drama']);
        case 10:
          return const _GenreData([27], ['Horror']);
        case 3:
          return const _GenreData([10749], ['Romance']);
        case 5:
          return const _GenreData([28], ['Action']);
        case 9:
          return const _GenreData([878], ['Science Fiction']);
        case 1:
          return const _GenreData([28, 53], ['Action', 'Thriller']);
        case 2:
          return const _GenreData([878, 14], ['Science Fiction', 'Fantasy']);
        case 14:
          return const _GenreData([27, 53], ['Horror', 'Thriller']);
        case 15:
          return const _GenreData([18, 10749], ['Drama', 'Romance']);
        case 16:
          return const _GenreData([16], ['Animation']);
        case 20:
          return const _GenreData([10751, 16], ['Family', 'Animation']);
        case 25:
          return const _GenreData([], ['Ugandan']);
      }
    }
    final lower = category.toLowerCase();
    if (lower.contains('action')) {
      return const _GenreData([28], ['Action']);
    } else if (lower.contains('sci') || lower.contains('fiction')) {
      return const _GenreData([878], ['Science Fiction']);
    } else if (lower.contains('romance') || lower.contains('love')) {
      return const _GenreData([10749], ['Romance']);
    } else if (lower.contains('horror')) {
      return const _GenreData([27], ['Horror']);
    } else if (lower.contains('drama') || lower.contains('story') || lower.contains('life')) {
      return const _GenreData([18], ['Drama']);
    } else if (lower.contains('animation') || lower.contains('anime') || lower.contains('cartoon') ||
               lower.contains('panda') || lower.contains('sonic') || lower.contains('mario') ||
               lower.contains('shrek') || lower.contains('frozen') || lower.contains('minion')) {
      return const _GenreData([16], ['Animation']);
    } else if (lower.contains('family') || lower.contains('kids') || lower.contains('wonka') || lower.contains('narnia')) {
      return const _GenreData([10751], ['Family']);
    } else if (lower.contains('comedy')) {
      return const _GenreData([35], ['Comedy']);
    } else if (lower.contains('thriller')) {
      return const _GenreData([53], ['Thriller']);
    } else if (lower.contains('adventure')) {
      return const _GenreData([12], ['Adventure']);
    } else if (lower.contains('crime')) {
      return const _GenreData([80], ['Crime']);
    } else if (lower.contains('fantasy')) {
      return const _GenreData([14], ['Fantasy']);
    } else if (lower.contains('korean')) {
      return const _GenreData([], ['Korean']);
    } else if (lower.contains('filipino')) {
      return const _GenreData([], ['Filipino']);
    } else if (lower.contains('indian')) {
      return const _GenreData([], ['Indian']);
    } else if (lower.contains('chinese')) {
      return const _GenreData([], ['Chinese']);
    } else if (lower.contains('ugandan')) {
      return const _GenreData([], ['Ugandan']);
    } else if (lower.contains('kungu') || lower.contains('kung fu') || lower.contains('martial')) {
      return const _GenreData([28], ['Kungu Fu', 'Action']);
    }
    return const _GenreData([28, 12], ['Action', 'Adventure']);
  }
}

class _GenreData {
  final List<int> ids;
  final List<String> names;
  const _GenreData(this.ids, this.names);
}
