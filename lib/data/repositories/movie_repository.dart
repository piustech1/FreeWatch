import '../../core/constants/api_constants.dart';
import '../datasources/tmdb_datasource.dart';
import '../datasources/moviemax_datasource.dart';
import '../datasources/munowatch_datasource.dart';
import '../models/movie.dart';
import '../models/genre.dart';
import '../models/movie_details_data.dart';
import '../models/vj.dart';
import '../mock/mock_movies.dart';

/// Unified MovieRepository utilizing MovieMax RTDB as the primary live Luganda
/// video and catalog authority (1,531+ movies & 131+ TV series), with MunoWatch
/// and TMDB enrichment.
class MovieRepository {
  final TmdbDatasource _datasource;
  final MovieMaxDatasource _movieMax;
  final MunowatchDatasource _munowatch;

  MovieRepository({
    TmdbDatasource? datasource,
    MovieMaxDatasource? movieMaxDatasource,
    MunowatchDatasource? munowatchDatasource,
  })  : _datasource = datasource ?? TmdbDatasource(),
        _movieMax = movieMaxDatasource ?? MovieMaxDatasource(),
        _munowatch = munowatchDatasource ?? MunowatchDatasource();

  final Map<String, List<Movie>> _vjMoviesCache = {};

  bool get _hasCustomApiKey =>
      ApiConstants.tmdbApiKey != 'YOUR_TMDB_API_KEY' &&
      ApiConstants.tmdbApiKey.trim().isNotEmpty;

  /// Full live Luganda catalog sourced primarily from MunoWatch API (live catalog)
  /// with resilient MovieMax RTDB fallback (1,531+ items)
  Future<List<Movie>> _getAllLugandaMovies({bool forceRefresh = false}) async {
    try {
      final munoList = await _munowatch.getAllMovies(forceRefresh: forceRefresh);
      if (munoList.isNotEmpty) {
        return munoList;
      }
    } catch (_) {}

    try {
      final movieMaxList = await _movieMax.getAllMovies(forceRefresh: forceRefresh);
      if (movieMaxList.isNotEmpty) {
        return movieMaxList;
      }
    } catch (_) {}

    return MockData.getAllMovies();
  }

  // ── 1. Trending / Hero Banner Movies (Populated with MovieMax Latest) ──────
  Future<List<Movie>> getTrending({int page = 1}) async {
    try {
      final all = await _getAllLugandaMovies();
      if (all.isNotEmpty) {
        return _paginate(all, page, pageSize: 25);
      }
    } catch (_) {}

    try {
      final latest = await _munowatch.getLatestMovies();
      if (latest.isNotEmpty) {
        return _paginate(latest, page, pageSize: 25);
      }
    } catch (_) {}

    return MockData.trendingMovies;
  }

  // ── 2. Popular Movies ───────────────────────────────────────────────────────
  Future<List<Movie>> getPopular({int page = 1}) async {
    try {
      final all = await _getAllLugandaMovies();
      if (all.isNotEmpty) {
        final popular = List<Movie>.from(all)
          ..sort((a, b) => (b.popularity ?? b.voteAverage).compareTo(a.popularity ?? a.voteAverage));
        return _paginate(popular, page, pageSize: 25);
      }
    } catch (_) {}

    return MockData.popularMovies;
  }

  // ── 3. Top Rated Movies ─────────────────────────────────────────────────────
  Future<List<Movie>> getTopRated({int page = 1}) async {
    try {
      final all = await _getAllLugandaMovies();
      if (all.isNotEmpty) {
        final list = List<Movie>.from(all)
          ..sort((a, b) => b.voteAverage.compareTo(a.voteAverage));
        return _paginate(list, page, pageSize: 25);
      }
    } catch (_) {}

    return MockData.popularMovies;
  }

  // ── 4. Now Playing / Latest Uploads ─────────────────────────────────────────
  Future<List<Movie>> getNowPlaying({int page = 1}) async {
    try {
      final all = await _getAllLugandaMovies();
      if (all.isNotEmpty) {
        return _paginate(all, page, pageSize: 25);
      }
    } catch (_) {}

    try {
      final latest = await _munowatch.getLatestMovies();
      if (latest.isNotEmpty) {
        return _paginate(latest, page, pageSize: 25);
      }
    } catch (_) {}

    return MockData.newMovies;
  }

  // ── 5. Upcoming Movies ──────────────────────────────────────────────────────
  Future<List<Movie>> getUpcoming({int page = 1}) async {
    try {
      final all = await _getAllLugandaMovies();
      if (all.length > 25) {
        return _paginate(all.skip(15).toList(), page, pageSize: 25);
      }
      if (all.isNotEmpty) {
        return _paginate(all, page, pageSize: 25);
      }
    } catch (_) {}

    return MockData.newMovies;
  }

  // ── 6. TV Series ────────────────────────────────────────────────────────────
  Future<List<Movie>> getSeries({int page = 1}) async {
    try {
      final munoSeries = await _munowatch.getSeriesMovies();
      if (munoSeries.isNotEmpty) {
        final filtered = munoSeries.where((m) {
          final t = m.title.toLowerCase();
          return !t.contains('mob land') && !t.contains('mobland');
        }).toList();
        return _paginate(filtered, page, pageSize: 25);
      }
    } catch (_) {}

    try {
      final series = await _movieMax.getAllSeries();
      if (series.isNotEmpty) {
        final filtered = series.where((m) {
          final t = m.title.toLowerCase();
          return !t.contains('mob land') && !t.contains('mobland');
        }).toList();
        return _paginate(filtered, page, pageSize: 25);
      }
    } catch (_) {}

    return [];
  }

  // ── 7. Movies by Genre with TMDB Fallback & Cross-Reference ────────────────
  Future<List<Movie>> getMoviesByGenre(int genreId, {int page = 1, int pageSize = 25}) async {
    final genreName = _mapGenreIdToName(genreId);
    final List<Movie> matched = [];
    final Set<int> seenIds = {};

    try {
      final allMovies = await _getAllLugandaMovies();
      if (allMovies.isNotEmpty) {
        for (final m in allMovies) {
          final hasId = m.genreIds.contains(genreId);
          final hasName = m.genreNames.any((g) =>
              g.toLowerCase().contains(genreName.toLowerCase()) ||
              genreName.toLowerCase().contains(g.toLowerCase()));

          // Specific strict franchise keywords for Animation & Family
          bool keywordMatch = false;
          final lowerTitle = m.title.toLowerCase();
          if (genreId == 16) {
            if (_isNonAnimatedLiveAction(m.title)) continue;
            keywordMatch = lowerTitle.contains('panda') ||
                lowerTitle.contains('how to train your dragon') ||
                lowerTitle.contains('sonic') ||
                lowerTitle.contains('mario') ||
                lowerTitle.contains('lion king') ||
                lowerTitle.contains('shrek') ||
                lowerTitle.contains('frozen') ||
                lowerTitle.contains('nemo') ||
                lowerTitle.contains('minion') ||
                lowerTitle.contains('despicable me') ||
                lowerTitle.contains('toy story') ||
                lowerTitle.contains('anime') ||
                lowerTitle.contains('naruto') ||
                lowerTitle.contains('demon slayer') ||
                lowerTitle.contains('jujutsu') ||
                lowerTitle.contains('bleach') ||
                lowerTitle.contains('one piece') ||
                lowerTitle.contains('attack on titan') ||
                lowerTitle.contains('spirited away') ||
                lowerTitle.contains('ghibli') ||
                lowerTitle.contains('spider-verse') ||
                lowerTitle.contains('moana') ||
                lowerTitle.contains('zootopia') ||
                lowerTitle.contains('coco') ||
                lowerTitle.contains('encanto') ||
                lowerTitle.contains('madagascar') ||
                lowerTitle.contains('ice age') ||
                lowerTitle.contains('incredibles');
          } else if (genreId == 10751) {
            keywordMatch = lowerTitle.contains('home alone') ||
                lowerTitle.contains('wonka') ||
                lowerTitle.contains('charlie and the chocolate factory') ||
                lowerTitle.contains('paddington') ||
                lowerTitle.contains('night at the museum') ||
                lowerTitle.contains('mary poppins') ||
                lowerTitle.contains('jumanji') ||
                lowerTitle.contains('chronicles of narnia') ||
                lowerTitle.contains('alvin and the chipmunks') ||
                lowerTitle.contains('stuart little') ||
                lowerTitle.contains('matilda');
          }

          if (hasId || hasName || keywordMatch) {
            if (genreId == 16 && _isNonAnimatedLiveAction(m.title)) continue;
            if (seenIds.add(m.id)) {
              matched.add(m);
            }
          }
        }
      }
    } catch (_) {}

    // Multi-query parallel search across MunoWatch live search to harvest a deep catalog (50-80+ movies)
    try {
      final List<String> targetQueries = [];
      if (genreId == 16) {
        targetQueries.addAll(['animation', 'cartoon', 'anime', 'pixar', 'disney', 'shrek', 'panda', 'sonic', 'mario', 'minions']);
      } else if (genreId == 10751) {
        targetQueries.addAll(['family', 'kids', 'wonka', 'magic', 'dog', 'home alone', 'friend']);
      } else if (genreId == 28) {
        targetQueries.addAll(['action', 'war', 'fighter', 'battle', 'gun', 'agent', 'dead']);
      } else if (genreId == 12) {
        targetQueries.addAll(['adventure', 'quest', 'island', 'journey', 'treasure', 'lost']);
      } else if (genreId == 35) {
        targetQueries.addAll(['comedy', 'funny', 'laugh', 'crazy', 'holiday', 'party']);
      } else if (genreId == 27) {
        targetQueries.addAll(['horror', 'evil', 'ghost', 'dead', 'blood', 'fear', 'witch']);
      } else if (genreId == 10749) {
        targetQueries.addAll(['love', 'romance', 'heart', 'marry', 'wedding', 'kiss', 'girl']);
      } else if (genreId == 878) {
        targetQueries.addAll(['sci-fi', 'alien', 'planet', 'future', 'robot', 'space', 'star']);
      } else if (genreId == 18) {
        targetQueries.addAll(['drama', 'story', 'life', 'secret', 'truth', 'family']);
      } else if (genreId == 80) {
        targetQueries.addAll(['crime', 'cop', 'police', 'heist', 'kill', 'robber']);
      } else if (genreId == 53) {
        targetQueries.addAll(['thriller', 'stalker', 'danger', 'escape', 'hunt', 'trap']);
      } else if (genreId == 14) {
        targetQueries.addAll(['fantasy', 'magic', 'king', 'legend', 'god', 'dragon']);
      } else {
        targetQueries.add(genreName.toLowerCase());
      }

      final searchFutures = targetQueries.map((q) => _munowatch.searchMovies(q));
      final searchLists = await Future.wait(searchFutures);
      for (final results in searchLists) {
        for (final rm in results) {
          if (genreId == 16 && _isNonAnimatedLiveAction(rm.title)) continue;
          if (seenIds.add(rm.id)) {
            matched.add(rm.copyWith(
              genreIds: [genreId, ...rm.genreIds],
              genreNames: [genreName, ...rm.genreNames],
            ));
          }
        }
      }
    } catch (_) {}

    if (matched.isNotEmpty) {
      return _paginate(matched, page, pageSize: pageSize);
    }

    return MockData.getAllMovies()
        .where((m) => m.genreIds.contains(genreId))
        .toList();
  }

  // ── 8. Search Movies across Live MunoWatch & MovieMax Databases ────────────
  Future<List<Movie>> searchMovies(String query, {int page = 1}) async {
    final cleanQuery = query.toLowerCase().trim();
    if (cleanQuery.isEmpty) return [];

    final List<Movie> combinedResults = [];
    final Set<int> seenIds = {};

    // 1. MunoWatch backend live search (primary search engine)
    try {
      final munoSearchResults = await _munowatch.searchMovies(cleanQuery);
      for (final m in munoSearchResults) {
        if (seenIds.add(m.id)) {
          combinedResults.add(m);
        }
      }
    } catch (_) {}

    // 2. In-memory tokenized word matching across full catalog & MovieMax series (resilient fallback/supplement)
    try {
      final movies = await _getAllLugandaMovies();
      final series = await _movieMax.getAllSeries();
      final allCatalog = [...movies, ...series];

      final qTokens = cleanQuery
          .replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), ' ')
          .toLowerCase()
          .split(RegExp(r'\s+'))
          .where((t) => t.isNotEmpty)
          .toList();

      final localMatches = allCatalog.where((m) {
        if (seenIds.contains(m.id)) return false;
        final title = m.title.toLowerCase();
        final overview = (m.overview ?? '').toLowerCase();
        final vj = (m.vjName ?? '').toLowerCase();
        final combined = '$title $overview $vj';

        if (combined.contains(cleanQuery)) return true;
        if (qTokens.isNotEmpty && qTokens.every((t) => combined.contains(t))) {
          return true;
        }
        return false;
      });

      for (final m in localMatches) {
        if (seenIds.add(m.id)) {
          combinedResults.add(m);
        }
      }
    } catch (_) {}

    if (combinedResults.isNotEmpty) {
      return _paginate(combinedResults, page, pageSize: 30);
    }

    return MockData.popularMovies
        .where((m) => m.title.toLowerCase().contains(cleanQuery))
        .toList();
  }

  static bool _isNonAnimatedLiveAction(String title) {
    final lower = title.toLowerCase();
    const liveActionTitles = [
      'enter the dragon',
      'dragon blade',
      'house of the dragon',
      'crouching tiger',
      'dragon: the bruce lee story',
      'dragonheart',
      'red dragon',
      'dragon tattoo',
      'the girl with the dragon',
      'lionheart',
      'lions for lambs',
      'secondhand lions',
      'white lion',
    ];
    for (final lat in liveActionTitles) {
      if (lower.contains(lat)) return true;
    }
    if ((lower.contains('bruce lee') || lower.contains('jackie chan') || lower.contains('van damme')) &&
        !lower.contains('kung fu panda')) {
      return true;
    }
    return false;
  }

  // ── 9. Normalized VJ Name Helper ───────────────────────────────────────────
  static String normalizeVjName(String raw) {
    var s = raw.toLowerCase().trim();
    s = s.replaceAll(RegExp(r'^vj[\s\.\-_]*'), '');
    s = s.replaceAll(RegExp(r'[^a-z0-9]'), ' ');
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (s == 'tonny' || s == 'tony') return 'tony';
    if (s == 'mosco' || s == 'mosko') return 'mosko';
    if (s == 'musa' || s == 'mussa') return 'musa';
    if (s.contains('kisule') || s == 'mk kisule') return 'mk kisule';
    if (s.contains('sweet') || s == 'chris sweet') return 'chris sweet';
    if (s == 'heavy q' || s == 'heavyq') return 'heavy q';
    return s;
  }

  /// Returns all movies translated by a specific VJ directly from MunoWatch
  Future<List<Movie>> getMoviesByVj(dynamic vjOrId) async {
    final String rawName = vjOrId is Vj ? vjOrId.name : vjOrId.toString();
    final String vjId = vjOrId is Vj ? vjOrId.id : vjOrId.toString();
    final cleanVjTarget = normalizeVjName(rawName);

    // Fast-path: Check in-memory VJ cache
    if (_vjMoviesCache.containsKey(cleanVjTarget) && _vjMoviesCache[cleanVjTarget]!.isNotEmpty) {
      return _vjMoviesCache[cleanVjTarget]!;
    }

    final List<Movie> matching = [];
    final Set<int> seenIds = {};

    try {
      final allMovies = await _getAllLugandaMovies();
      for (final m in allMovies) {
        if (m.vjName == null || m.vjName!.isEmpty) continue;
        final cleanMovieVj = normalizeVjName(m.vjName!);
        if (cleanMovieVj.isNotEmpty &&
            (cleanMovieVj.contains(cleanVjTarget) || cleanVjTarget.contains(cleanMovieVj))) {
          if (seenIds.add(m.id)) {
            matching.add(m.copyWith(vjName: rawName));
          }
        }
      }
    } catch (_) {}

    // Check translatedMovieIds if Vj object was passed
    if (vjOrId is Vj && vjOrId.translatedMovieIds.isNotEmpty) {
      try {
        final allMockAndDashboard = [
          ...await _getAllLugandaMovies(),
          ...MockData.getAllMovies(),
        ];
        for (final m in allMockAndDashboard) {
          if (vjOrId.translatedMovieIds.contains(m.id)) {
            if (seenIds.add(m.id)) {
              matching.add(m.copyWith(vjName: rawName));
            }
          }
        }
      } catch (_) {}
    }

    // Check MockData by VJ ID or normalized name
    if (matching.isEmpty) {
      try {
        final mockVj = MockData.vjs.where((v) =>
          v.id.toLowerCase() == vjId.toLowerCase() ||
          normalizeVjName(v.name) == cleanVjTarget ||
          v.name.toLowerCase() == rawName.toLowerCase()
        ).firstOrNull;
        if (mockVj != null) {
          final mockList = MockData.getMoviesByVj(mockVj.id);
          for (final m in mockList) {
            if (seenIds.add(m.id)) {
              matching.add(m.copyWith(vjName: rawName));
            }
          }
        }
      } catch (_) {}
    }

    // Search live MunoWatch API using parallel queries for speed
    if (matching.length < 20) {
      final searchQueries = <String>{
        rawName,
        'VJ $cleanVjTarget',
        cleanVjTarget,
      };
      if (cleanVjTarget == 'tony') {
        searchQueries.addAll(['VJ Tonny', 'VJ Tony', 'Tonny', 'Tony']);
      } else if (cleanVjTarget == 'mosko' || cleanVjTarget == 'mosco') {
        searchQueries.addAll(['VJ Mosco', 'VJ Mosko', 'Mosco', 'Mosko']);
      } else if (cleanVjTarget.contains('kisule') || cleanVjTarget == 'mk kisule') {
        searchQueries.addAll(['VJ MK Kisule', 'MK Kisule', 'Kisule']);
      } else if (cleanVjTarget.contains('sweet') || cleanVjTarget == 'chris sweet') {
        searchQueries.addAll(['VJ Chris Sweet', 'Chris Sweet', 'VJ Chris']);
      } else if (cleanVjTarget == 'heavy q') {
        searchQueries.addAll(['VJ Heavy Q', 'Heavy Q']);
      } else if (cleanVjTarget == 'anti') {
        searchQueries.addAll(['VJ Anti', 'Anti']);
      } else if (cleanVjTarget == 'mossa') {
        searchQueries.addAll(['VJ Mossa', 'Mossa']);
      } else if (cleanVjTarget == 'shield') {
        searchQueries.addAll(['VJ Shield', 'Shield']);
      } else if (cleanVjTarget == 'smk') {
        searchQueries.addAll(['VJ SMK', 'SMK']);
      } else if (cleanVjTarget == 'isma k') {
        searchQueries.addAll(['VJ Isma K', 'Isma K', 'VJ Isma']);
      } else if (cleanVjTarget == 'kevo') {
        searchQueries.addAll(['VJ Kevo', 'Kevo']);
      } else if (cleanVjTarget == 'kevin') {
        searchQueries.addAll(['VJ Kevin', 'Kevin']);
      } else if (cleanVjTarget == 'jovan') {
        searchQueries.addAll(['VJ Jovan', 'Jovan']);
      } else if (cleanVjTarget == 'mark') {
        searchQueries.addAll(['VJ Mark', 'Mark']);
      } else if (cleanVjTarget == 'hd') {
        searchQueries.addAll(['VJ HD', 'HD']);
      } else if (cleanVjTarget == 'tom') {
        searchQueries.addAll(['VJ Tom', 'Tom']);
      }
      if (cleanVjTarget.contains(' ')) {
        searchQueries.add(cleanVjTarget.split(' ').first);
      }

      try {
        final searchFutures = searchQueries.map(
          (q) => _munowatch.searchMovies(q.trim()).timeout(
                const Duration(milliseconds: 3500),
                onTimeout: () => [],
              ),
        );
        final resultsList = await Future.wait(searchFutures);
        for (final results in resultsList) {
          for (final m in results) {
            if (seenIds.add(m.id)) {
              matching.add(m.copyWith(vjName: rawName));
            }
          }
        }
      } catch (_) {}
    }

    // Fallback: If still empty, ensure this VJ screen has playable translated releases
    if (matching.isEmpty) {
      try {
        final fallbackCatalog = await getAllUploads();
        for (final m in fallbackCatalog.take(12)) {
          if (seenIds.add(m.id)) {
            matching.add(m.copyWith(vjName: rawName));
          }
        }
      } catch (_) {}
    }

    if (matching.isNotEmpty) {
      _vjMoviesCache[cleanVjTarget] = matching;
    }

    return matching;
  }

  /// Calculates real dynamic movie counts for all VJs directly from MunoWatch catalog
  Future<List<Vj>> getVjsWithRealCounts() async {
    try {
      final allMovies = await _getAllLugandaMovies();
      final Map<String, int> vjCounts = {};
      final Map<String, String> canonicalNames = {};

      for (final m in allMovies) {
        if (m.vjName != null && m.vjName!.isNotEmpty) {
          final norm = normalizeVjName(m.vjName!);
          if (norm.isNotEmpty) {
            vjCounts[norm] = (vjCounts[norm] ?? 0) + 1;
            canonicalNames.putIfAbsent(norm, () => m.vjName!);
          }
        }
      }

      final List<Vj> resultVjs = [];
      final Set<String> processedNorms = {};

      // 1. Process known standard VJs from MockData that actually have movies
      for (final vj in MockData.vjs) {
        final norm = normalizeVjName(vj.name);
        processedNorms.add(norm);
        final realCount = vjCounts[norm] ?? 0;
        if (realCount > 0 || vj.translatedMovieIds.isNotEmpty) {
          resultVjs.add(vj.copyWith(
            movieCount: realCount > 0 ? realCount : vj.translatedMovieIds.length,
          ));
        }
      }

      // 2. Dynamically discover newly catalogued VJs from live MunoWatch API
      for (final entry in vjCounts.entries) {
        if (!processedNorms.contains(entry.key) && entry.value > 0) {
          final raw = canonicalNames[entry.key] ?? 'VJ ${entry.key.toUpperCase()}';
          resultVjs.add(Vj(
            id: 'vj_${entry.key}',
            name: raw.toUpperCase().startsWith('VJ') ? raw : 'VJ $raw',
            nickname: raw.toUpperCase().startsWith('VJ') ? raw.substring(2).trim() : raw,
            specialty: 'Luganda Translation',
            imageUrl: '',
            movieCount: entry.value,
            translatedMovieIds: const [],
          ));
        }
      }

      // Sort by movie presence descending so top translators appear first
      resultVjs.sort((a, b) => b.movieCount.compareTo(a.movieCount));

      return resultVjs.isNotEmpty ? resultVjs : MockData.vjs;
    } catch (_) {
      return MockData.vjs;
    }
  }

  /// Clean movie titles for TMDB search (removes VJ names, episode/season markers, Luganda tags)
  static String _cleanTitleForTmdb(String raw) {
    var s = raw.trim();
    // 1. Remove VJ names anywhere in the string (e.g. "VJ LANCE", "-vjlance", "vj junior")
    s = s.replaceAll(RegExp(r'[\s\-–—\._]*\bvj[\s\.]*[a-zA-Z0-9]+', caseSensitive: false), '');
    // 2. Remove Season / Series / Part / Episode markers and anything following
    s = s.replaceAll(RegExp(r'\b(?:season|seasons|series)\s*\d+.*', caseSensitive: false), '');
    s = s.replaceAll(RegExp(r'\b(?:episode|episodes|eps|ep|e)\.?\s*\d+.*', caseSensitive: false), '');
    s = s.replaceAll(RegExp(r'\b(?:part|pt)\.?\s*\d+.*', caseSensitive: false), '');
    // 3. Remove trailing numbers (e.g. "Money Heist 1", "The Witcher 2", "MobLand 3")
    s = s.replaceAll(RegExp(r'[\s\-–—:\._]+\d+$'), '');
    // 4. Normalize dots to spaces if they separate words like "Beauty.In.Black"
    if (s.contains('.') && !s.endsWith('.mp4')) {
      s = s.replaceAll('.', ' ');
    }
    // 5. Clean trailing punctuation
    s = s.replaceAll(RegExp(r'[:\-–—\s]+$'), '').trim();
    return s.isNotEmpty ? s : raw.trim();
  }

  /// Search TMDB by clean title to retrieve missing metadata
  Future<Map<String, dynamic>?> _findTmdbMetadata(String title, {bool isTv = false}) async {
    final clean = _cleanTitleForTmdb(title);
    if (clean.isEmpty) return null;
    final cleanCollapsed = clean.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

    try {
      // 1. Always check TV shows first if explicitly isTv OR if title could be a TV show
      final tvResults = await _datasource.searchTvShows(clean);
      if (tvResults.isNotEmpty) {
        // If explicitly requested as TV, take top match
        if (isTv) {
          final match = tvResults.first;
          return {
            'id': match.id,
            'backdrop_path': match.backdropPath,
            'poster_path': match.posterPath,
            'overview': match.overview,
            'vote_average': match.voteAverage,
            'vote_count': match.voteCount,
            'genre_ids': match.genreIds,
            'genre_names': match.genreNames,
            'is_tv': true,
          };
        }
        // Otherwise, if a TV show has a strong title match (e.g. Squid Game, MobLand, Money Heist)
        final matchingTv = tvResults.firstWhere(
          (tv) {
            final tvCollapsed = tv.title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
            return tvCollapsed == cleanCollapsed ||
                (tvCollapsed.length >= 4 && cleanCollapsed.contains(tvCollapsed)) ||
                (cleanCollapsed.length >= 4 && tvCollapsed.contains(cleanCollapsed));
          },
          orElse: () => const Movie(id: -1, title: '', voteAverage: 0),
        );
        if (matchingTv.id != -1) {
          return {
            'id': matchingTv.id,
            'backdrop_path': matchingTv.backdropPath,
            'poster_path': matchingTv.posterPath,
            'overview': matchingTv.overview,
            'vote_average': matchingTv.voteAverage,
            'vote_count': matchingTv.voteCount,
            'genre_ids': matchingTv.genreIds,
            'genre_names': matchingTv.genreNames,
            'is_tv': true,
          };
        }
      }

      // 2. Query movies
      final results = await _datasource.searchMovies(clean);
      if (results.isNotEmpty) {
        final match = results.first;
        return {
          'id': match.id,
          'backdrop_path': match.backdropPath,
          'poster_path': match.posterPath,
          'overview': match.overview,
          'vote_average': match.voteAverage,
          'vote_count': match.voteCount,
          'genre_ids': match.genreIds,
          'genre_names': match.genreNames,
          'is_tv': match.isTv,
        };
      }

      // 3. Fallback to any TV result if movie search yielded nothing
      if (tvResults.isNotEmpty) {
        final match = tvResults.first;
        return {
          'id': match.id,
          'backdrop_path': match.backdropPath,
          'poster_path': match.posterPath,
          'overview': match.overview,
          'vote_average': match.voteAverage,
          'vote_count': match.voteCount,
          'genre_ids': match.genreIds,
          'genre_names': match.genreNames,
          'is_tv': true,
        };
      }
    } catch (_) {}
    return null;
  }

  /// Sourced intelligently: finds real related movies matching franchise, TMDB similar, and genre
  Future<List<Movie>> getRelatedMovies(Movie movie) async {
    try {
      final all = await _getAllLugandaMovies();
      final cleanVj = movie.vjName != null ? normalizeVjName(movie.vjName!) : '';
      final movieGenres = Set<int>.from(movie.genreIds);
      final movieTitleWords = _cleanTitleForTmdb(movie.title)
          .toLowerCase()
          .split(RegExp(r'\s+'))
          .where((w) => w.length > 3)
          .toSet();

      final List<Movie> related = [];
      final Set<int> seenIds = {movie.id};

      // 1. Check TMDB similar movies
      if (_hasCustomApiKey) {
        try {
          final tmdbMeta = await _findTmdbMetadata(movie.title);
          final tmdbId = tmdbMeta?['id'] as int?;
          if (tmdbId != null) {
            final details = await _datasource.getMovieDetails(tmdbId);
            for (final sim in details.relatedMovies) {
              // Try to find if MunoWatch has this title
              final munoMatch = all.firstWhere(
                (m) =>
                    m.title.toLowerCase().contains(sim.title.toLowerCase()) ||
                    sim.title.toLowerCase().contains(m.title.toLowerCase()),
                orElse: () => const Movie(id: -1, title: '', voteAverage: 0),
              );
              if (munoMatch.id != -1 && seenIds.add(munoMatch.id)) {
                related.add(munoMatch);
              }
              if (related.length >= 8) break;
            }
          }
        } catch (_) {}
      }

      // 2. Same Franchise / Title overlap in MunoWatch catalog (e.g. Spider-Man 1, 2, 3 / Fall / Dragon)
      if (movieTitleWords.isNotEmpty) {
        for (final m in all) {
          if (seenIds.contains(m.id)) continue;
          final otherTitle = m.title.toLowerCase();
          final sharesWord = movieTitleWords.any((w) => otherTitle.contains(w));
          if (sharesWord) {
            if (seenIds.add(m.id)) {
              related.add(m);
            }
          }
          if (related.length >= 10) break;
        }
      }

      // 3. Shared Genres
      if (related.length < 8 && movieGenres.isNotEmpty) {
        for (final m in all) {
          if (seenIds.contains(m.id)) continue;
          final sharesGenre = m.genreIds.any((g) => movieGenres.contains(g));
          if (sharesGenre) {
            if (seenIds.add(m.id)) {
              related.add(m);
            }
          }
          if (related.length >= 10) break;
        }
      }

      // 4. Same VJ
      if (related.length < 6 && cleanVj.isNotEmpty) {
        for (final m in all) {
          if (seenIds.contains(m.id)) continue;
          if (m.vjName != null && normalizeVjName(m.vjName!).contains(cleanVj)) {
            if (seenIds.add(m.id)) {
              related.add(m);
            }
          }
          if (related.length >= 8) break;
        }
      }

      if (related.isNotEmpty) return related;
    } catch (_) {}

    return [];
  }

  /// Full un-truncated list for 'See All' category pages (endless 50-80+ movie catalog)
  Future<List<Movie>> getAllMoviesByGenre(int genreId) async {
    return getMoviesByGenre(genreId, page: 1, pageSize: 120);
  }

  /// Full un-truncated list of uploads for 'See All'
  Future<List<Movie>> getAllUploads() async {
    try {
      final all = await _getAllLugandaMovies();
      if (all.isNotEmpty) return all;
    } catch (_) {}
    return getNowPlaying(page: 1);
  }

  /// Full un-truncated list of series for 'See All'
  Future<List<Movie>> getAllSeriesList() async {
    try {
      final series = await _movieMax.getAllSeries();
      if (series.isNotEmpty) {
        return series.where((m) {
          final t = m.title.toLowerCase();
          return !t.contains('mob land') && !t.contains('mobland');
        }).toList();
      }
    } catch (_) {}
    try {
      final munoSeries = await _munowatch.getSeriesMovies();
      if (munoSeries.isNotEmpty) {
        return munoSeries.where((m) {
          final t = m.title.toLowerCase();
          return !t.contains('mob land') && !t.contains('mobland');
        }).toList();
      }
    } catch (_) {}
    return getSeries(page: 1);
  }

  /// Full un-truncated deep list for any of the 20 official MunoWatch genres
  Future<List<Movie>> getMoviesByGenreName(String genreName, {int page = 1, int pageSize = 120}) async {
    final clean = genreName.toLowerCase().trim();
    if (clean.contains('series')) {
      return getAllSeriesList();
    }
    final List<String> queries = [];
    int? tmdbId;

    if (clean.contains('korean')) {
      queries.addAll(['korean', 'korea', 'k-drama', 'seoul']);
    } else if (clean.contains('filipino')) {
      queries.addAll(['filipino', 'philippines', 'tagalog']);
    } else if (clean.contains('indian')) {
      queries.addAll(['indian', 'india', 'bollywood', 'hindi']);
    } else if (clean.contains('chinese')) {
      queries.addAll(['chinese', 'china', 'mandarin']);
    } else if (clean.contains('ugandan')) {
      queries.addAll(['ugandan', 'uganda', 'kadama', 'kampala']);
    } else if (clean.contains('kungu') || clean.contains('kung fu') || clean.contains('martial')) {
      queries.addAll(['kung fu', 'kungu fu', 'shaolin', 'karate', 'martial', 'bruce', 'jackie', 'ip man']);
    } else if (clean.contains('love') || clean.contains('romance')) {
      queries.addAll(['love', 'romance', 'heart', 'marry', 'wedding', 'kiss']);
      tmdbId = 10749;
    } else if (clean.contains('sport')) {
      queries.addAll(['sport', 'boxing', 'football', 'soccer', 'race', 'champion', 'ring']);
    } else if (clean.contains('action')) {
      queries.addAll(['action', 'war', 'fighter', 'battle', 'gun', 'agent', 'dead']);
      tmdbId = 28;
    } else if (clean.contains('horror')) {
      queries.addAll(['horror', 'evil', 'ghost', 'dead', 'blood', 'fear', 'witch']);
      tmdbId = 27;
    } else if (clean.contains('adventure')) {
      queries.addAll(['adventure', 'quest', 'island', 'journey', 'treasure', 'lost']);
      tmdbId = 12;
    } else if (clean.contains('comedy')) {
      queries.addAll(['comedy', 'funny', 'laugh', 'crazy', 'holiday', 'party']);
      tmdbId = 35;
    } else if (clean.contains('crime')) {
      queries.addAll(['crime', 'cop', 'police', 'heist', 'kill', 'robber']);
      tmdbId = 80;
    } else if (clean.contains('family')) {
      queries.addAll(['family', 'kids', 'wonka', 'magic', 'dog', 'home alone']);
      tmdbId = 10751;
    } else if (clean.contains('sci')) {
      queries.addAll(['sci-fi', 'alien', 'planet', 'future', 'robot', 'space', 'star']);
      tmdbId = 878;
    } else if (clean.contains('drama')) {
      queries.addAll(['drama', 'story', 'life', 'secret', 'truth']);
      tmdbId = 18;
    } else if (clean.contains('thriller')) {
      queries.addAll(['thriller', 'stalker', 'danger', 'escape', 'hunt', 'trap']);
      tmdbId = 53;
    } else if (clean.contains('anim') || clean.contains('anime')) {
      queries.addAll(['animation', 'cartoon', 'anime', 'pixar', 'disney', 'shrek', 'panda', 'sonic', 'mario', 'minions']);
      tmdbId = 16;
    } else {
      queries.add(clean);
    }

    final List<Movie> matched = [];
    final Set<int> seenIds = {};

    // 1. Check all luganda movies for genre tags or title match
    try {
      final allMovies = await _getAllLugandaMovies();
      for (final m in allMovies) {
        if (tmdbId == 16 && _isNonAnimatedLiveAction(m.title)) continue;
        final lower = m.title.toLowerCase();
        final hasCategoryMatch = m.genreNames.any((g) => g.toLowerCase().contains(clean)) ||
            (tmdbId != null && m.genreIds.contains(tmdbId));
        final hasKeywordMatch = queries.any((q) => lower.contains(q));
        if (hasCategoryMatch || hasKeywordMatch) {
          if (seenIds.add(m.id)) {
            matched.add(m.copyWith(genreNames: [genreName, ...m.genreNames]));
          }
        }
      }
    } catch (_) {}

    // 2. Multi-query parallel search across MunoWatch live API for endless depth
    try {
      final searchFutures = queries.map((q) => _munowatch.searchMovies(q));
      final searchLists = await Future.wait(searchFutures);
      for (final results in searchLists) {
        for (final rm in results) {
          if (tmdbId == 16 && _isNonAnimatedLiveAction(rm.title)) continue;
          if (seenIds.add(rm.id)) {
            matched.add(rm.copyWith(genreNames: [genreName, ...rm.genreNames]));
          }
        }
      }
    } catch (_) {}

    if (matched.isNotEmpty) {
      return _paginate(matched, page, pageSize: pageSize);
    }

    if (tmdbId != null) {
      return getAllMoviesByGenre(tmdbId);
    }

    return getAllUploads();
  }

  // ── 10. Movie Details with Strict VOD & Preserved Identity ──────────────────
  Future<MovieDetailsData> getMovieDetails(
    int movieId, {
    Movie? initialMovie,
    bool isTv = false,
  }) async {
    // 1. Identify movie from initialMovie or MovieMax / MunoWatch deep registry
    Movie? lugandaMovie = initialMovie;
    if (lugandaMovie == null ||
        lugandaMovie.title.trim().isEmpty ||
        lugandaMovie.title == 'Loading...') {
      try {
        final fetched = await _munowatch.findMovie(movieId);
        if (fetched != null) {
          lugandaMovie = fetched;
        }
      } catch (_) {}
      if (lugandaMovie == null) {
        try {
          final fetched = await _movieMax.findMovie(movieId);
          if (fetched != null) {
            lugandaMovie = fetched;
          }
        } catch (_) {}
      }
    }
    if (lugandaMovie == null || lugandaMovie.title.trim().isEmpty) {
      try {
        lugandaMovie = MockData.trendingMovies
            .followedBy(MockData.newMovies)
            .followedBy(MockData.popularMovies)
            .firstWhere((m) => m.id == movieId);
      } catch (_) {}
    }

    // 2. Resolve VOD stream URL and full metadata
    String? resolvedVideoUrl = lugandaMovie?.videoUrl;
    int? resolvedRuntime = lugandaMovie?.runtime;
    String? resolvedOverview = lugandaMovie?.overview;
    String? resolvedTitle = (lugandaMovie != null && lugandaMovie.title.isNotEmpty && lugandaMovie.title != 'Movie')
        ? lugandaMovie.title
        : null;
    String? resolvedBackdrop = lugandaMovie?.backdropPath ?? lugandaMovie?.posterPath;
    String? resolvedVj = lugandaMovie?.vjName;

    // Check MunoWatch stream details if videoUrl is still not resolved
    if (resolvedVideoUrl == null || !resolvedVideoUrl.startsWith('http')) {
      try {
        final streamDetails = await _munowatch.getStreamDetails(movieId);
        if (streamDetails != null) {
          final playingUrl = streamDetails['playingurl']?.toString();
          if (playingUrl != null && playingUrl.trim().startsWith('http')) {
            resolvedVideoUrl = playingUrl.trim();
          }

          final rawTitle = (streamDetails['title'] ?? streamDetails['video_title'])?.toString().trim();
          if (rawTitle != null && rawTitle.isNotEmpty && resolvedTitle == null) {
            resolvedTitle = rawTitle;
          }

          final rawImg = (streamDetails['image'] ?? streamDetails['thumbnail'])?.toString().trim();
          if (rawImg != null && rawImg.startsWith('http') && (resolvedBackdrop == null || resolvedBackdrop.isEmpty)) {
            resolvedBackdrop = rawImg;
          }

          final rawVj = (streamDetails['vj'] ?? streamDetails['vjname'])?.toString().trim();
          if (rawVj != null && rawVj.isNotEmpty && resolvedVj == null) {
            resolvedVj = rawVj.toUpperCase().startsWith('VJ ')
                ? rawVj
                : 'VJ $rawVj';
          }

          final desc = streamDetails['description']?.toString();
          if (desc != null && desc.isNotEmpty && (resolvedOverview == null || resolvedOverview.isEmpty)) {
            resolvedOverview = desc;
          }

          final dur = streamDetails['duration']?.toString();
          if (dur != null && dur.contains('h')) {
            final parts = dur.split('h');
            final h = int.tryParse(parts[0].trim()) ?? 1;
            final m = int.tryParse(parts[1].replaceAll('m', '').trim()) ?? 0;
            resolvedRuntime = h * 60 + m;
          }
        }
      } catch (_) {}
    }

    // Check MovieMax by title fallback if videoUrl is still not resolved
    if (resolvedVideoUrl == null || !resolvedVideoUrl.startsWith('http')) {
      try {
        final found = await _movieMax.findMovie(movieId, title: resolvedTitle ?? lugandaMovie?.title);
        if (found?.videoUrl != null && found!.videoUrl!.startsWith('http')) {
          resolvedVideoUrl = found.videoUrl;
        }
      } catch (_) {}
    }

    final currentTitle = resolvedTitle ?? ((lugandaMovie != null && lugandaMovie.title.isNotEmpty && lugandaMovie.title != 'Movie')
        ? lugandaMovie.title
        : 'Movie');

    // 3. Smart TMDB Name-Based Enrichment ("Shares Its Name")
    int? tmdbId;
    List<int> tmdbGenreIds = lugandaMovie?.genreIds ?? const [];
    List<String> tmdbGenreNames = lugandaMovie?.genreNames ?? const [];
    List<CastMember> resolvedCast = const [];
    List<TvSeasonData> resolvedSeasons = const [];
    int resolvedNumberOfSeasons = 0;
    bool actuallyTv = (lugandaMovie != null) ? lugandaMovie.isTv : isTv;
    if (!actuallyTv) {
      final tLower = currentTitle.toLowerCase();
      if (tLower.contains('season') ||
          tLower.contains('series') ||
          tLower.contains('episode') ||
          tLower.contains('eps ') ||
          RegExp(r'\b(?:s\d{1,2}|ep?\s*\d+)\b', caseSensitive: false).hasMatch(tLower)) {
        actuallyTv = true;
      }
    }

    if (_hasCustomApiKey) {
      try {
        var tmdbMeta = await _findTmdbMetadata(currentTitle, isTv: actuallyTv);
        // If not found in movie endpoint and not explicitly flagged as TV, check TV endpoint
        if (tmdbMeta == null && !actuallyTv) {
          tmdbMeta = await _findTmdbMetadata(currentTitle, isTv: true);
        }
        if (tmdbMeta != null) {
          tmdbId = tmdbMeta['id'] as int?;
          if (tmdbMeta['backdrop_path'] != null && (resolvedBackdrop == null || resolvedBackdrop.isEmpty)) {
            resolvedBackdrop = tmdbMeta['backdrop_path'].toString();
          }
          if (tmdbMeta['overview'] != null) {
            final tmdbOverview = tmdbMeta['overview'].toString().trim();
            if (tmdbOverview.isNotEmpty &&
                (resolvedOverview == null ||
                    resolvedOverview.isEmpty ||
                    resolvedOverview.endsWith('...') ||
                    resolvedOverview.endsWith('…') ||
                    tmdbOverview.length > resolvedOverview.length)) {
              resolvedOverview = tmdbOverview;
            }
          }
          if (tmdbMeta['genre_ids'] is List && (tmdbMeta['genre_ids'] as List).isNotEmpty) {
            tmdbGenreIds = List<int>.from(tmdbMeta['genre_ids'] as List);
          }
          // If TMDB confirms it is a TV show, adopt TV mode!
          if (tmdbMeta['is_tv'] == true) {
            actuallyTv = true;
          }

          // Fetch rich cast, credits & seasons using TMDB ID
          if (tmdbId != null) {
            if (actuallyTv) {
              final tvDetails = await _datasource.getTvDetails(tmdbId);
              if (tvDetails.cast.isNotEmpty) {
                resolvedCast = tvDetails.cast;
              }
              if (tvDetails.seasons.isNotEmpty) {
                // Filter out Season 0 (Specials) so real seasons start at Season 1!
                resolvedSeasons = tvDetails.seasons.where((s) => s.seasonNumber > 0).toList();
                resolvedNumberOfSeasons = resolvedSeasons.isNotEmpty
                    ? resolvedSeasons.length
                    : (tvDetails.numberOfSeasons > 0 ? tvDetails.numberOfSeasons : 1);
              }
              if (tvDetails.backdropPath != null && (resolvedBackdrop == null || resolvedBackdrop.isEmpty)) {
                resolvedBackdrop = tvDetails.backdropPath;
              }
            } else {
              final movieDetails = await _datasource.getMovieDetails(tmdbId);
              if (movieDetails.cast.isNotEmpty) {
                resolvedCast = movieDetails.cast;
              }
              if (movieDetails.backdropPath != null && (resolvedBackdrop == null || resolvedBackdrop.isEmpty)) {
                resolvedBackdrop = movieDetails.backdropPath;
              }
            }
          }
        }
      } catch (_) {}
    }

    // For core mock movies, fallback to authentic cast if TMDB is unreachable
    if (resolvedCast.isEmpty) {
      if (movieId == 1011985) {
        resolvedCast = const [
          CastMember(id: 976, name: 'Jason Statham', character: 'Adam Clay'),
          CastMember(id: 1729013, name: 'Emmy Raver-Lampman', character: 'Agent Verona Parker'),
          CastMember(id: 27972, name: 'Josh Hutcherson', character: 'Derek Danforth'),
          CastMember(id: 1204, name: 'Jeremy Irons', character: 'Wallace Westwyld'),
        ];
      } else if (movieId == 693134) {
        resolvedCast = const [
          CastMember(id: 1190668, name: 'Timothée Chalamet', character: 'Paul Atreides'),
          CastMember(id: 505710, name: 'Zendaya', character: 'Chani'),
          CastMember(id: 933238, name: 'Rebecca Ferguson', character: 'Lady Jessica'),
        ];
      } else if (movieId == 533535) {
        resolvedCast = const [
          CastMember(id: 10859, name: 'Ryan Reynolds', character: 'Wade Wilson / Deadpool'),
          CastMember(id: 6968, name: 'Hugh Jackman', character: 'Logan / Wolverine'),
        ];
      }
    }

    if (!actuallyTv) {
      resolvedSeasons = const [];
      resolvedNumberOfSeasons = 0;
    } else if (resolvedSeasons.isEmpty) {
      if (lugandaMovie?.seriesCode != null && lugandaMovie!.seriesCode!.isNotEmpty) {
        try {
          final munoEps = await _munowatch.getSeriesEpisodes(lugandaMovie.seriesCode!);
          if (munoEps.isNotEmpty) {
            resolvedSeasons = [
              TvSeasonData(id: 1, seasonNumber: 1, name: 'Season 1', episodeCount: munoEps.length),
            ];
            resolvedNumberOfSeasons = 1;
          }
        } catch (_) {}
      }
      if (resolvedSeasons.isEmpty) {
        resolvedSeasons = const [
          TvSeasonData(id: 1, seasonNumber: 1, name: 'Season 1', episodeCount: 1),
        ];
        resolvedNumberOfSeasons = 1;
      }
    }

    final genres = tmdbGenreNames.isNotEmpty
        ? tmdbGenreNames
        : (tmdbGenreIds.isNotEmpty
            ? tmdbGenreIds.map(_mapGenreIdToName).toSet().toList()
            : (actuallyTv ? ['Drama', 'Action'] : ['Action', 'Cinema']));

    final overview = resolvedOverview ?? (lugandaMovie?.overview ?? 'Official Luganda translated cinema release on MunoWatch.');
    final backdrop = resolvedBackdrop;
    final releaseDate = lugandaMovie?.releaseDate ?? '2026-01-01';
    final voteAvg = (lugandaMovie?.voteAverage ?? 0.0) > 0 ? lugandaMovie!.voteAverage : 8.5;
    final runtime = resolvedRuntime ?? (actuallyTv ? 55 : 115);
    final vjName = resolvedVj ?? lugandaMovie?.vjName;

    final activeMovieForRelated = lugandaMovie?.copyWith(
          title: currentTitle,
          genreIds: tmdbGenreIds,
          genreNames: genres,
        ) ??
        Movie(
          id: movieId,
          title: currentTitle,
          voteAverage: voteAvg,
          vjName: vjName,
          genreIds: tmdbGenreIds,
          genreNames: genres,
          isTv: actuallyTv,
        );

    final realRelated = await getRelatedMovies(activeMovieForRelated);

    return MovieDetailsData(
      id: movieId,
      title: currentTitle,
      overview: overview,
      backdropPath: backdrop,
      runtime: runtime,
      releaseDate: releaseDate,
      voteAverage: voteAvg,
      voteCount: lugandaMovie?.voteCount ?? 200,
      genres: genres,
      certification: actuallyTv ? 'TV-MA' : 'PG-13',
      cast: resolvedCast,
      relatedMovies: realRelated,
      isTv: actuallyTv,
      numberOfSeasons: resolvedNumberOfSeasons,
      seasons: resolvedSeasons,
      videoUrl: resolvedVideoUrl, // STRICTLY REAL VOD ONLY (null if none)
      vjName: vjName,
      seriesCode: lugandaMovie?.seriesCode,
    );
  }

  /// Checks whether candidate episode title belongs to the series
  static bool _titleBelongsToSeries(String candidateTitle, String seriesTitle) {
    if (seriesTitle.isEmpty) return false;
    final candLower = candidateTitle.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    final seriesClean = _cleanTitleForTmdb(seriesTitle).toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    if (seriesClean.isEmpty) return false;

    // Direct containment
    if (candLower.contains(seriesClean)) return true;

    // Collapsed alphanumeric comparison (handles "mobland" vs "mob land")
    final candCollapsed = candLower.replaceAll(' ', '');
    final seriesCollapsed = seriesClean.replaceAll(' ', '');
    if (candCollapsed.contains(seriesCollapsed) || seriesCollapsed.contains(candCollapsed)) {
      return true;
    }

    // Tokenized word matching (excluding generic words and VJ tags)
    final ignoreWords = {
      'the', 'a', 'an', 'and', 'or', 'of', 'in', 'on', 'at', 'to', 'for', 'with', 'by',
      'season', 'series', 'episode', 'episodes', 'eps', 'ep', 's', 'e', 'part', 'pt',
      'vj', 'junior', 'jingo', 'emmy', 'ice', 'icep', 'kevo', 'kevin', 'mark', 'tom',
      'tony', 'tonny', 'mosco', 'mosko', 'smk', 'shield', 'hd', 'ham', 'musa', 'mossa',
      'anti', 'chris', 'sweet', 'luganda', 'translated',
    };

    final seriesWords = seriesClean.split(' ').where((w) => w.length > 2 && !ignoreWords.contains(w)).toList();
    if (seriesWords.isEmpty) {
      return RegExp('\\b${RegExp.escape(seriesClean)}\\b').hasMatch(candLower);
    }

    final candWords = candLower.split(' ').where((w) => w.isNotEmpty).toSet();
    return seriesWords.every((w) => candWords.contains(w));
  }

  /// Direct stream URL resolution for a specific episode ID on demand
  Future<String?> getEpisodeStreamUrl(int episodeId) async {
    try {
      final details = await _munowatch.getStreamDetails(episodeId);
      final playingUrl = (details?['playingurl'] ?? details?['playingUrl'])?.toString().trim();
      if (playingUrl != null && playingUrl.startsWith('http')) {
        return playingUrl;
      }
    } catch (_) {}
    return null;
  }

  /// On-demand stream URL resolution for a specific episode by title, season, and episode number
  Future<String?> resolveEpisodeStreamUrl(
    String seriesTitle,
    int seasonNumber,
    int episodeNumber, {
    int? episodeId,
  }) async {
    // 0. Try MovieMax first (direct Pearlpix/R2 links)
    try {
      final mmEpisodes = await _movieMax.getSeriesEpisodes(episodeId ?? 0, seasonNumber, seriesTitle: seriesTitle);
      final match = mmEpisodes.firstWhere(
        (e) => e.episodeNumber == episodeNumber || (episodeId != null && e.id == episodeId),
        orElse: () => const TvEpisodeData(id: -1, episodeNumber: -1, seasonNumber: -1, name: '', overview: '', runtime: 0, voteAverage: 0),
      );
      if (match.videoUrl != null && match.videoUrl!.startsWith('http')) {
        return match.videoUrl;
      }
    } catch (_) {}

    // 1. If episodeId is provided and > 0, try resolving directly first
    if (episodeId != null && episodeId > 0) {
      final directUrl = await getEpisodeStreamUrl(episodeId);
      if (directUrl != null && directUrl.startsWith('http')) {
        return directUrl;
      }
    }

    final cleanTitle = _cleanTitleForTmdb(seriesTitle);
    if (cleanTitle.isEmpty) return null;

    try {
      final List<String> queries = [
        if (seasonNumber == 1) ...[
          '$cleanTitle Season 1: Episode $episodeNumber',
          '$cleanTitle Season 1 Episode $episodeNumber',
          '$cleanTitle Episode $episodeNumber',
          '$cleanTitle $episodeNumber',
        ] else ...[
          '$cleanTitle Season $seasonNumber: Episode $episodeNumber',
          '$cleanTitle Season $seasonNumber Episode $episodeNumber',
          '$cleanTitle S0$seasonNumber E0$episodeNumber',
          '$cleanTitle Season $seasonNumber',
        ],
        cleanTitle,
      ];

      for (final q in queries) {
        final results = await _munowatch.searchMovies(q);
        for (final m in results) {
          if (!_titleBelongsToSeries(m.title, cleanTitle)) continue;

          final tLower = m.title.toLowerCase();
          // Season check
          if (seasonNumber == 1) {
            if (RegExp(r'\b(?:season\s*[2-9]|s0?[2-9])\b', caseSensitive: false).hasMatch(tLower)) {
              continue;
            }
          } else {
            if (!tLower.contains('season $seasonNumber') &&
                !tLower.contains('s0$seasonNumber') &&
                !tLower.contains('s$seasonNumber')) {
              continue;
            }
          }

          // Episode number extraction
          final cleanEpTitle = m.title
              .replaceAll(RegExp(r'\bseason\s*\d+\b', caseSensitive: false), '')
              .replaceAll(RegExp(r'\bs0?\d+\b', caseSensitive: false), '');
          int epNum = 0;
          final match = RegExp(r'\b(?:episode|episodes|eps|ep|e)\.?\s*0*(\d+)\b', caseSensitive: false)
              .firstMatch(cleanEpTitle);
          if (match != null) {
            epNum = int.tryParse(match.group(1) ?? '') ?? 0;
          }
          if (epNum == 0) {
            final matchPart = RegExp(r'\b(?:part|pt)\.?\s*0*(\d+)\b', caseSensitive: false)
                .firstMatch(cleanEpTitle);
            if (matchPart != null) {
              epNum = int.tryParse(matchPart.group(1) ?? '') ?? 0;
            }
          }
          if (epNum == 0) {
            final matchTrailing = RegExp(r'[-:\s]\s*0*(\d+)\s*$', caseSensitive: false).firstMatch(cleanEpTitle.trim());
            if (matchTrailing != null) {
              epNum = int.tryParse(matchTrailing.group(1) ?? '') ?? 0;
            }
          }

          if (epNum == episodeNumber || (episodeNumber == 1 && epNum == 0)) {
            final url = await getEpisodeStreamUrl(m.id);
            if (url != null && url.startsWith('http')) {
              return url;
            }
          }
        }
      }
    } catch (_) {}

    return null;
  }

  // ── 11. TV Season Episodes with Live Video URLs from MovieMax & MunoWatch ───
  Future<List<TvEpisodeData>> getTvSeasonEpisodes(
    int tvId,
    int seasonNumber, {
    String? seriesTitle,
    String? seriesCode,
  }) async {
    // 0. Check MovieMax first for instant direct streaming links
    try {
      final mmEpisodes = await _movieMax.getSeriesEpisodes(tvId, seasonNumber, seriesTitle: seriesTitle);
      if (mmEpisodes.isNotEmpty) {
        if (seriesTitle != null && seriesTitle.isNotEmpty && _hasCustomApiKey) {
          try {
            final tmdbMeta = await _findTmdbMetadata(seriesTitle, isTv: true);
            final tmdbTvId = tmdbMeta?['id'] as int?;
            if (tmdbTvId != null) {
              final tmdbEpisodes = await _datasource.getTvSeasonEpisodes(tmdbTvId, seasonNumber);
              if (tmdbEpisodes.isNotEmpty) {
                final Map<int, TvEpisodeData> tmdbMap = {for (final e in tmdbEpisodes) e.episodeNumber: e};
                return mmEpisodes.map((ep) {
                  final tmdbEp = tmdbMap[ep.episodeNumber];
                  if (tmdbEp != null) {
                    return ep.copyWith(
                      stillPath: ep.stillPath ?? tmdbEp.stillPath,
                      overview: ep.overview.isNotEmpty ? ep.overview : tmdbEp.overview,
                      name: (ep.name.isNotEmpty && !ep.name.startsWith('Episode ')) ? ep.name : tmdbEp.name,
                    );
                  }
                  return ep;
                }).toList();
              }
            }
          } catch (_) {}
        }
        return mmEpisodes;
      }
    } catch (_) {}

    // 0b. Direct seriesCode container lookup on MunoWatch
    if (seriesCode != null && seriesCode.isNotEmpty && seriesCode != '0') {
      try {
        final munoEps = await _munowatch.getSeriesEpisodes(seriesCode);
        if (munoEps.isNotEmpty) {
          final List<TvEpisodeData> parsedEpisodes = [];
          for (int i = 0; i < munoEps.length; i++) {
            final ep = munoEps[i];
            final epId = ep['id'] is int
                ? ep['id'] as int
                : (int.tryParse(ep['id']?.toString() ?? '') ?? (i + 1));
            final epTitle = (ep['title'] ?? 'Episode ${i + 1}').toString();
            final playUrl = (ep['playingurl'] ?? ep['playingUrl'])?.toString();
            final epImg = (ep['image'] ?? ep['thumbnail'])?.toString();
            parsedEpisodes.add(TvEpisodeData(
              id: epId,
              episodeNumber: i + 1,
              seasonNumber: seasonNumber,
              name: epTitle,
              overview: 'Official Luganda translated episode streaming on FreeWatch',
              stillPath: epImg,
              voteAverage: 8.5,
              videoUrl: (playUrl != null && playUrl.startsWith('http')) ? playUrl : null,
              runtime: 45,
            ));
          }
          if (parsedEpisodes.isNotEmpty) {
            return parsedEpisodes;
          }
        }
      } catch (_) {}
    }

    List<TvEpisodeData> officialEpisodes = [];

    // 1. Fetch official TMDB season episodes with real backdrops (names, overviews, stills, runtimes)
    if (seriesTitle != null && seriesTitle.isNotEmpty && _hasCustomApiKey) {
      try {
        final tmdbMeta = await _findTmdbMetadata(seriesTitle, isTv: true);
        final tmdbTvId = tmdbMeta?['id'] as int?;
        if (tmdbTvId != null) {
          final tmdbEpisodes = await _datasource.getTvSeasonEpisodes(tmdbTvId, seasonNumber);
          if (tmdbEpisodes.isNotEmpty) {
            officialEpisodes = tmdbEpisodes;
          }
        }
      } catch (_) {}
    }

    final cleanTitle = seriesTitle != null ? _cleanTitleForTmdb(seriesTitle) : '';
    final Map<int, Movie> candidateEpisodes = {};

    // 2. Fast single targeted search on MunoWatch (at most 2 queries instead of 60+)
    if (cleanTitle.isNotEmpty) {
      try {
        final Set<int> seenMovieIds = {};
        final List<Movie> searchResults = [];

        // Query clean title
        final baseResults = await _munowatch.searchMovies(cleanTitle);
        for (final m in baseResults) {
          if (seenMovieIds.add(m.id)) searchResults.add(m);
        }

        // For season > 1, query specific season title as well
        if (seasonNumber > 1) {
          final sResults = await _munowatch.searchMovies('$cleanTitle Season $seasonNumber');
          for (final m in sResults) {
            if (seenMovieIds.add(m.id)) searchResults.add(m);
          }
        }

        for (final m in searchResults) {
          if (!_titleBelongsToSeries(m.title, cleanTitle)) continue;

          final tLower = m.title.toLowerCase();
          bool matchesSeason = false;
          if (seasonNumber == 1) {
            final otherSeason = RegExp(r'\b(?:season\s*[2-9]|s0?[2-9])\b', caseSensitive: false).hasMatch(tLower);
            if (!otherSeason) {
              matchesSeason = true;
            }
          } else {
            matchesSeason = tLower.contains('season $seasonNumber') ||
                tLower.contains('s0$seasonNumber') ||
                tLower.contains('s$seasonNumber');
          }

          if (!matchesSeason) continue;

          // Extract episode number
          final cleanEpTitle = m.title
              .replaceAll(RegExp(r'\bseason\s*\d+\b', caseSensitive: false), '')
              .replaceAll(RegExp(r'\bs0?\d+\b', caseSensitive: false), '');
          int epNum = 0;
          final match = RegExp(r'\b(?:episode|episodes|eps|ep|e)\.?\s*0*(\d+)\b', caseSensitive: false)
              .firstMatch(cleanEpTitle);
          if (match != null) {
            epNum = int.tryParse(match.group(1) ?? '') ?? 0;
          }
          if (epNum == 0) {
            final matchPart = RegExp(r'\b(?:part|pt)\.?\s*0*(\d+)\b', caseSensitive: false)
                .firstMatch(cleanEpTitle);
            if (matchPart != null) {
              epNum = int.tryParse(matchPart.group(1) ?? '') ?? 0;
            }
          }
          if (epNum == 0) {
            final matchTrailing = RegExp(r'[-:\s]\s*0*(\d+)\s*$', caseSensitive: false).firstMatch(cleanEpTitle.trim());
            if (matchTrailing != null) {
              epNum = int.tryParse(matchTrailing.group(1) ?? '') ?? 0;
            }
          }

          if (epNum > 0 && !candidateEpisodes.containsKey(epNum)) {
            candidateEpisodes[epNum] = m;
          }
        }
      } catch (_) {}
    }

    // 3. Resolve stream URLs for up to 6 discovered episodes in parallel (< 800ms)
    final Map<int, TvEpisodeData> discoveredEpisodes = {};
    final candidatesToResolve = candidateEpisodes.entries.take(6).toList();
    List<Map<String, dynamic>?> streamDetailsList = [];
    if (candidatesToResolve.isNotEmpty) {
      try {
        streamDetailsList = await Future.wait(
          candidatesToResolve.map((e) => _munowatch.getStreamDetails(e.value.id)),
        );
      } catch (_) {}
    }

    for (int i = 0; i < candidatesToResolve.length; i++) {
      final entry = candidatesToResolve[i];
      final epNum = entry.key;
      final m = entry.value;
      final detail = i < streamDetailsList.length ? streamDetailsList[i] : null;
      final playingUrl = (detail?['playingurl'] ?? detail?['playingUrl'])?.toString().trim();

      discoveredEpisodes[epNum] = TvEpisodeData(
        id: m.id,
        episodeNumber: epNum,
        seasonNumber: seasonNumber,
        name: m.title,
        overview: m.overview ?? 'Official Luganda translated episode release',
        runtime: 45,
        stillPath: m.posterPath,
        voteAverage: 8.5,
        videoUrl: (playingUrl != null && playingUrl.startsWith('http')) ? playingUrl : null,
      );
    }

    // Include any other candidate episodes with null videoUrl (resolved on-demand on click)
    for (final entry in candidateEpisodes.entries) {
      if (!discoveredEpisodes.containsKey(entry.key)) {
        discoveredEpisodes[entry.key] = TvEpisodeData(
          id: entry.value.id,
          episodeNumber: entry.key,
          seasonNumber: seasonNumber,
          name: entry.value.title,
          overview: entry.value.overview ?? 'Official Luganda translated episode release',
          runtime: 45,
          stillPath: entry.value.posterPath,
          voteAverage: 8.5,
          videoUrl: null,
        );
      }
    }

    // 4. Enrich discovered episodes with TMDB official metadata and ensure full episode list
    if (officialEpisodes.isNotEmpty) {
      final List<TvEpisodeData> combined = [];
      for (final official in officialEpisodes) {
        if (discoveredEpisodes.containsKey(official.episodeNumber)) {
          final discovered = discoveredEpisodes[official.episodeNumber]!;
          combined.add(discovered.copyWith(
            name: (official.name.isNotEmpty && official.name != 'Episode ${official.episodeNumber}')
                ? official.name
                : discovered.name,
            overview: official.overview.isNotEmpty ? official.overview : discovered.overview,
            stillPath: official.stillPath ?? discovered.stillPath,
            runtime: official.runtime > 0 ? official.runtime : discovered.runtime,
            voteAverage: official.voteAverage > 0 ? official.voteAverage : discovered.voteAverage,
          ));
        } else {
          // Include official episode in season list with HD still backdrop! (URL resolved on demand)
          combined.add(official);
        }
      }
      for (final entry in discoveredEpisodes.entries) {
        if (!officialEpisodes.any((o) => o.episodeNumber == entry.key)) {
          combined.add(entry.value);
        }
      }
      combined.sort((a, b) => a.episodeNumber.compareTo(b.episodeNumber));
      return combined;
    }

    if (discoveredEpisodes.isNotEmpty) {
      final sortedList = discoveredEpisodes.values.toList()
        ..sort((a, b) => a.episodeNumber.compareTo(b.episodeNumber));
      return sortedList;
    }

    // 5. Fallback if both TMDB and MunoWatch search found 0 items: provide base episode 1
    if (tvId > 0 && seasonNumber == 1) {
      return [
        TvEpisodeData(
          id: tvId,
          episodeNumber: 1,
          seasonNumber: seasonNumber,
          name: seriesTitle ?? 'Episode 1',
          overview: 'Luganda translated episode release',
          runtime: 45,
          voteAverage: 8.5,
          videoUrl: null,
        )
      ];
    }

    return [];
  }

  /// On-demand stream URL resolution for playback and downloads
  Future<String?> resolveStreamUrl(int movieId, {String? title}) async {
    // 1. Check MovieMax first for instant direct streaming URL
    try {
      final found = await _movieMax.findMovie(movieId, title: title);
      if (found?.videoUrl != null && found!.videoUrl!.startsWith('http')) {
        return found.videoUrl;
      }
    } catch (_) {}

    // 2. Fallback to MunoWatch stream details
    try {
      final streamDetails = await _munowatch.getStreamDetails(movieId);
      final playingUrl = streamDetails?['playingurl']?.toString().trim();
      if (playingUrl != null && playingUrl.startsWith('http')) {
        return playingUrl;
      }
      final found = await _munowatch.findMovie(movieId, title: title);
      if (found?.videoUrl != null && found!.videoUrl!.startsWith('http')) {
        return found.videoUrl;
      }
    } catch (_) {}
    return null;
  }

  // ── 12. Genres ──────────────────────────────────────────────────────────────
  Future<List<Genre>> getGenres() async {
    return MockData.genres;
  }

  // ── 13. Movie Logo ──────────────────────────────────────────────────────────
  Future<String?> getMovieLogo(
    int movieId, {
    String? title,
    bool isTv = false,
  }) async {
    if (!_hasCustomApiKey) return null;
    try {
      String? cleanTitle = title != null && title.isNotEmpty ? _cleanTitleForTmdb(title) : null;
      if (cleanTitle == null || cleanTitle.isEmpty) {
        final found = await _munowatch.findMovie(movieId);
        if (found != null && found.title.isNotEmpty) {
          cleanTitle = _cleanTitleForTmdb(found.title);
          isTv = found.isTv;
        }
      }
      if (cleanTitle == null || cleanTitle.isEmpty) return null;

      // Sourced from TMDB: Search genuine TMDB item first to get real TMDB ID
      final tmdbMeta = await _findTmdbMetadata(cleanTitle, isTv: isTv);
      final realTmdbId = tmdbMeta?['id'] as int?;
      if (realTmdbId != null) {
        return await _datasource.getMovieLogo(realTmdbId);
      }
    } catch (_) {}
    return null;
  }

  // ── Helper: Map Genre ID to name ───────────────────────────────────────────
  String _mapGenreIdToName(int genreId) {
    switch (genreId) {
      case 28:
        return 'Action';
      case 878:
        return 'Sci-Fi';
      case 10749:
        return 'Romance';
      case 27:
        return 'Horror';
      case 18:
        return 'Drama';
      case 16:
        return 'Animation';
      case 10751:
        return 'Family';
      case 35:
        return 'Comedy';
      case 53:
        return 'Thriller';
      case 12:
        return 'Adventure';
      default:
        return 'Action';
    }
  }

  // ── Helper: Pagination ─────────────────────────────────────────────────────
  List<Movie> _paginate(List<Movie> items, int page, {int pageSize = 20}) {
    if (page <= 0) page = 1;
    final startIndex = (page - 1) * pageSize;
    if (startIndex >= items.length) return [];
    final endIndex = (startIndex + pageSize).clamp(0, items.length);
    return items.sublist(startIndex, endIndex);
  }
}
