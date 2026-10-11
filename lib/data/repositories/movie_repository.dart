import '../../core/constants/api_constants.dart';
import '../datasources/tmdb_datasource.dart';
import '../datasources/munowatch_datasource.dart';
import '../models/movie.dart';
import '../models/genre.dart';
import '../models/movie_details_data.dart';
import '../models/vj.dart';
import '../mock/mock_movies.dart';

/// Unified MovieRepository depending exclusively on MunoWatch
/// (https://munowatch.ai.studio/) as the sole live Luganda video and catalog authority.
class MovieRepository {
  final TmdbDatasource _datasource;
  final MunowatchDatasource _munowatch;

  MovieRepository({
    TmdbDatasource? datasource,
    MunowatchDatasource? munowatchDatasource,
  })  : _datasource = datasource ?? TmdbDatasource(),
        _munowatch = munowatchDatasource ?? MunowatchDatasource();

  bool get _hasCustomApiKey =>
      ApiConstants.tmdbApiKey != 'YOUR_TMDB_API_KEY' &&
      ApiConstants.tmdbApiKey.trim().isNotEmpty;

  /// Full live Luganda catalog sourced solely from MunoWatch (13+ categories)
  Future<List<Movie>> _getAllLugandaMovies({bool forceRefresh = false}) async {
    try {
      final munoList = await _munowatch.getAllMovies(forceRefresh: forceRefresh);
      if (munoList.isNotEmpty) {
        return munoList;
      }
    } catch (_) {}

    return MockData.getAllMovies();
  }

  // ── 1. Trending / Hero Banner Movies (Populated with MunoWatch Latest) ─────
  Future<List<Movie>> getTrending({int page = 1}) async {
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
        return _paginate(all, page, pageSize: 25);
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
      if (all.isNotEmpty) {
        return _paginate(all, page, pageSize: 25);
      }
    } catch (_) {}

    return MockData.newMovies;
  }

  // ── 6. TV Series ────────────────────────────────────────────────────────────
  Future<List<Movie>> getSeries({int page = 1}) async {
    try {
      final series = await _munowatch.getSeriesMovies();
      if (series.isNotEmpty) {
        return _paginate(series, page, pageSize: 25);
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
        targetQueries.addAll(['animation', 'cartoon', 'dragon', 'panda', 'sonic', 'lion', 'shrek', 'anime']);
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

  // ── 8. Search Movies across Live MunoWatch 10,000+ Database ─────────────────
  Future<List<Movie>> searchMovies(String query, {int page = 1}) async {
    final cleanQuery = query.toLowerCase().trim();
    if (cleanQuery.isEmpty) return [];

    final List<Movie> combinedResults = [];
    final Set<int> seenIds = {};

    // 1. Live MunoWatch backend search across 10,000+ movies
    try {
      final munoSearchResults = await _munowatch.searchMovies(cleanQuery);
      for (final m in munoSearchResults) {
        if (seenIds.add(m.id)) {
          combinedResults.add(m);
        }
      }
    } catch (_) {}

    // 2. Tokenized word matching across loaded MunoWatch catalog
    try {
      final allMovies = await _getAllLugandaMovies();
      final qTokens = cleanQuery
          .replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), ' ')
          .toLowerCase()
          .split(RegExp(r'\s+'))
          .where((t) => t.isNotEmpty)
          .toList();

      final localMatches = allMovies.where((m) {
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

  // ── 9. Normalized VJ Name Helper ───────────────────────────────────────────
  static String normalizeVjName(String raw) {
    var s = raw.toLowerCase().trim();
    s = s.replaceAll(RegExp(r'^vj[\s\.\-_]*'), '');
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    return s;
  }

  /// Returns all movies translated by a specific VJ directly from MunoWatch
  Future<List<Movie>> getMoviesByVj(dynamic vjOrId) async {
    final String rawName = vjOrId is Vj ? vjOrId.name : vjOrId.toString();
    final cleanVjTarget = normalizeVjName(rawName);
    final List<Movie> matching = [];
    final Set<int> seenIds = {};

    try {
      final allMovies = await _getAllLugandaMovies();
      for (final m in allMovies) {
        if (m.vjName == null || m.vjName!.isEmpty) continue;
        final cleanMovieVj = normalizeVjName(m.vjName!);
        if (cleanMovieVj.contains(cleanVjTarget) || cleanVjTarget.contains(cleanMovieVj)) {
          if (seenIds.add(m.id)) {
            matching.add(m.copyWith(vjName: rawName));
          }
        }
      }
    } catch (_) {}

    // Check translatedMovieIds if Vj object was passed
    if (vjOrId is Vj && vjOrId.translatedMovieIds.isNotEmpty) {
      try {
        final allMovies = await _getAllLugandaMovies();
        for (final m in allMovies) {
          if (vjOrId.translatedMovieIds.contains(m.id)) {
            if (seenIds.add(m.id)) {
              matching.add(m.copyWith(vjName: rawName));
            }
          }
        }
      } catch (_) {}
    }

    // Search live MunoWatch API using multiple query variations (e.g. "VJ Isma", "Isma")
    if (matching.length < 20) {
      final searchQueries = [
        rawName,
        cleanVjTarget,
        if (cleanVjTarget.contains(' ')) cleanVjTarget.split(' ').first,
      ];
      for (final q in searchQueries) {
        if (q.trim().isEmpty) continue;
        try {
          final searchResults = await _munowatch.searchMovies(q.trim());
          for (final m in searchResults) {
            if (seenIds.add(m.id)) {
              matching.add(m.copyWith(vjName: rawName));
            }
          }
          if (matching.length >= 25) break;
        } catch (_) {}
      }
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
    s = s.replaceAll(RegExp(r'\b(season|s)\s*\d+.*', caseSensitive: false), '');
    s = s.replaceAll(RegExp(r'\b(episode|eps|ep|e)\s*\d+.*', caseSensitive: false), '');
    s = s.replaceAll(RegExp(r'\bvj\s+[a-zA-Z]+', caseSensitive: false), '');
    s = s.replaceAll(RegExp(r'[:\-–—\s]+$'), '').trim();
    return s.isNotEmpty ? s : raw.trim();
  }

  /// Search TMDB by clean title to retrieve missing metadata
  Future<Map<String, dynamic>?> _findTmdbMetadata(String title, {bool isTv = false}) async {
    final clean = _cleanTitleForTmdb(title);
    if (clean.isEmpty) return null;
    try {
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
      final latest = await _munowatch.getLatestMovies();
      if (latest.isNotEmpty) return latest;
    } catch (_) {}
    return getNowPlaying(page: 1);
  }

  /// Full un-truncated list of series for 'See All'
  Future<List<Movie>> getAllSeriesList() async {
    try {
      final series = await _munowatch.getSeriesMovies();
      if (series.isNotEmpty) return series;
    } catch (_) {}
    return getSeries(page: 1);
  }

  // ── 10. Movie Details with Strict VOD & Preserved Identity ──────────────────
  Future<MovieDetailsData> getMovieDetails(
    int movieId, {
    Movie? initialMovie,
    bool isTv = false,
  }) async {
    // 1. Identify movie from initialMovie or MunoWatch deep registry
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
    }
    if (lugandaMovie == null || lugandaMovie.title.trim().isEmpty) {
      try {
        lugandaMovie = MockData.trendingMovies
            .followedBy(MockData.newMovies)
            .followedBy(MockData.popularMovies)
            .firstWhere((m) => m.id == movieId);
      } catch (_) {}
    }

    // 2. Resolve VOD stream URL and full metadata strictly from MunoWatch / MumoWatch
    String? resolvedVideoUrl = lugandaMovie?.videoUrl;
    int? resolvedRuntime = lugandaMovie?.runtime;
    String? resolvedOverview = lugandaMovie?.overview;
    String? resolvedTitle = (lugandaMovie != null && lugandaMovie.title.isNotEmpty && lugandaMovie.title != 'Movie')
        ? lugandaMovie.title
        : null;
    String? resolvedBackdrop = lugandaMovie?.backdropPath ?? lugandaMovie?.posterPath;
    String? resolvedVj = lugandaMovie?.vjName;

    try {
      final streamDetails = await _munowatch.getStreamDetails(movieId);
      if (streamDetails != null) {
        final playingUrl = streamDetails['playingurl']?.toString();
        // Strict VOD verification: only accept genuine http url
        if (playingUrl != null && playingUrl.trim().startsWith('http')) {
          resolvedVideoUrl = playingUrl.trim();
        } else {
          // If MunoWatch returns no playingurl, strictly null (NO fake VOD)
          resolvedVideoUrl = null;
        }

        final rawTitle = (streamDetails['title'] ?? streamDetails['video_title'])?.toString().trim();
        if (rawTitle != null && rawTitle.isNotEmpty) {
          resolvedTitle = rawTitle;
        }

        final rawImg = (streamDetails['image'] ?? streamDetails['thumbnail'])?.toString().trim();
        if (rawImg != null && rawImg.startsWith('http')) {
          resolvedBackdrop = rawImg;
        }

        final rawVj = (streamDetails['vj'] ?? streamDetails['vjname'])?.toString().trim();
        if (rawVj != null && rawVj.isNotEmpty) {
          resolvedVj = rawVj.toUpperCase().startsWith('VJ ')
              ? rawVj
              : 'VJ $rawVj';
        }

        final desc = streamDetails['description']?.toString();
        if (desc != null && desc.isNotEmpty) {
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
    // Strictly respect MunoWatch classification: single movies remain single movies
    bool actuallyTv = (lugandaMovie != null) ? lugandaMovie.isTv : isTv;

    if (_hasCustomApiKey) {
      try {
        final tmdbMeta = await _findTmdbMetadata(currentTitle, isTv: actuallyTv);
        if (tmdbMeta != null) {
          tmdbId = tmdbMeta['id'] as int?;
          if (tmdbMeta['backdrop_path'] != null && (resolvedBackdrop == null || resolvedBackdrop.isEmpty)) {
            resolvedBackdrop = tmdbMeta['backdrop_path'].toString();
          }
          if (tmdbMeta['overview'] != null && (resolvedOverview == null || resolvedOverview.isEmpty)) {
            resolvedOverview = tmdbMeta['overview'].toString();
          }
          if (tmdbMeta['genre_ids'] is List && (tmdbMeta['genre_ids'] as List).isNotEmpty) {
            tmdbGenreIds = List<int>.from(tmdbMeta['genre_ids'] as List);
          }
          // Only adopt is_tv if lugandaMovie is null (never turn single movie into TV show)
          if (lugandaMovie == null && tmdbMeta['is_tv'] == true) {
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
                resolvedSeasons = tvDetails.seasons;
                resolvedNumberOfSeasons = tvDetails.numberOfSeasons > 0
                    ? tvDetails.numberOfSeasons
                    : tvDetails.seasons.length;
              }
              if (tvDetails.backdropPath != null && resolvedBackdrop == null) {
                resolvedBackdrop = tvDetails.backdropPath;
              }
            } else {
              final movieDetails = await _datasource.getMovieDetails(tmdbId);
              if (movieDetails.cast.isNotEmpty) {
                resolvedCast = movieDetails.cast;
              }
              if (movieDetails.backdropPath != null && resolvedBackdrop == null) {
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
    );
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

  // ── 11. TV Season Episodes with Live Video URLs from MunoWatch ──────────────
  Future<List<TvEpisodeData>> getTvSeasonEpisodes(
    int tvId,
    int seasonNumber, {
    String? seriesTitle,
    String? seriesCode,
  }) async {
    List<TvEpisodeData> officialEpisodes = [];

    // 1. Fetch official TMDB season episodes with real backdrops (solely to enrich stills/names)
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

    int? startEpId;
    final cleanTitle = seriesTitle != null ? _cleanTitleForTmdb(seriesTitle) : '';

    // If season > 1, search MunoWatch to find that specific season's starting episode ID
    if (seasonNumber > 1 && cleanTitle.isNotEmpty) {
      try {
        final queries = [
          '$cleanTitle Season $seasonNumber',
          '$cleanTitle S0$seasonNumber',
          '$cleanTitle S$seasonNumber',
          cleanTitle,
        ];
        for (final q in queries) {
          final searchResults = await _munowatch.searchMovies(q);
          for (final m in searchResults) {
            final tLower = m.title.toLowerCase();
            final matchesSeason = tLower.contains('season $seasonNumber') ||
                tLower.contains('s0$seasonNumber') ||
                tLower.contains('s$seasonNumber');
            if (matchesSeason) {
              startEpId = m.id;
              break;
            }
          }
          if (startEpId != null) break;
        }
      } catch (_) {}
    }

    // For season 1 (or fallback), use the series movie tvId
    startEpId ??= (tvId > 0 ? tvId : null);

    // 2. Probe sequential video IDs from MunoWatch /api/stream starting at startEpId
    if (startEpId != null && startEpId > 0) {
      try {
        final candidateIds = List.generate(12, (i) => startEpId! + i);
        final streamDetailsList = await Future.wait(
          candidateIds.map((id) => _munowatch.getStreamDetails(id)),
        );

        final List<TvEpisodeData> probedEpisodes = [];
        int consecutiveMismatches = 0;

        for (int i = 0; i < candidateIds.length; i++) {
          final detail = streamDetailsList[i];
          if (detail == null) {
            consecutiveMismatches++;
            if (consecutiveMismatches >= 2) break;
            continue;
          }

          final rawPlayingUrl = (detail['playingurl'] ?? detail['playingUrl'])?.toString().trim();
          if (rawPlayingUrl == null || !rawPlayingUrl.startsWith('http')) {
            consecutiveMismatches++;
            if (consecutiveMismatches >= 2) break;
            continue;
          }

          final epTitle = detail['title']?.toString() ?? 'Episode ${i + 1}';
          final epLower = epTitle.toLowerCase();
          final cleanLower = cleanTitle.toLowerCase();

          // Verify episode belongs to this series
          final belongsToSeries = i == 0 ||
              (cleanLower.isNotEmpty && epLower.contains(cleanLower)) ||
              epLower.contains('season $seasonNumber') ||
              epLower.contains('episode') ||
              epLower.contains('ep');

          if (!belongsToSeries && i > 0) {
            consecutiveMismatches++;
            if (consecutiveMismatches >= 2) break;
            continue;
          }

          consecutiveMismatches = 0;

          // Parse episode number
          int epNum = 0;
          if (detail['episode'] != null) {
            epNum = int.tryParse(detail['episode'].toString()) ?? 0;
          }
          if (epNum == 0) {
            final match = RegExp(r'(?:episode|eps|ep|\b)\s*0*(\d+)', caseSensitive: false).firstMatch(epTitle);
            if (match != null) {
              epNum = int.tryParse(match.group(1) ?? '') ?? 0;
            }
          }
          if (epNum == 0) {
            epNum = i + 1;
          }

          final currentEpId = candidateIds[i];

          // Match with TMDB episode for enriched backdrop/overview
          final tmdbEp = officialEpisodes.firstWhere(
            (o) => o.episodeNumber == epNum,
            orElse: () => TvEpisodeData(
              id: currentEpId,
              episodeNumber: epNum,
              seasonNumber: seasonNumber,
              name: epTitle,
              overview: detail['description']?.toString() ?? 'Official Luganda translated episode release',
              runtime: 45,
              stillPath: detail['image']?.toString(),
              voteAverage: 8.5,
            ),
          );

          probedEpisodes.add(TvEpisodeData(
            id: currentEpId,
            episodeNumber: epNum,
            seasonNumber: seasonNumber,
            name: (tmdbEp.name.isNotEmpty && tmdbEp.name != 'Episode $epNum')
                ? tmdbEp.name
                : epTitle,
            overview: tmdbEp.overview.isNotEmpty ? tmdbEp.overview : (detail['description']?.toString() ?? ''),
            runtime: tmdbEp.runtime > 0 ? tmdbEp.runtime : 45,
            stillPath: tmdbEp.stillPath ?? detail['image']?.toString(),
            voteAverage: tmdbEp.voteAverage > 0 ? tmdbEp.voteAverage : 8.5,
            videoUrl: rawPlayingUrl,
          ));
        }

        if (probedEpisodes.isNotEmpty) {
          probedEpisodes.sort((a, b) => a.episodeNumber.compareTo(b.episodeNumber));
          return probedEpisodes;
        }
      } catch (_) {}
    }

    // 3. Fallback: Search MunoWatch for matching season episodes and resolve their stream URLs
    final Map<int, String> streamUrlMap = {};
    final Map<int, int> streamIdMap = {};
    try {
      final queries = [
        if (cleanTitle.isNotEmpty) '$cleanTitle Season $seasonNumber',
        if (cleanTitle.isNotEmpty) cleanTitle,
        'Season $seasonNumber',
      ];

      for (final query in queries) {
        final searchResults = await _munowatch.searchMovies(query);
        for (final m in searchResults) {
          final titleLower = m.title.toLowerCase();
          final match = RegExp(r'(?:episode|eps|ep|e)\s*0*(\d+)', caseSensitive: false).firstMatch(titleLower);
          if (match != null) {
            final epNum = int.tryParse(match.group(1) ?? '');
            if (epNum != null && !streamUrlMap.containsKey(epNum)) {
              streamIdMap[epNum] = m.id;
              final streamData = await _munowatch.getStreamDetails(m.id);
              final playingUrl = (streamData?['playingurl'] ?? streamData?['playingUrl'])?.toString().trim();
              if (playingUrl != null && playingUrl.startsWith('http')) {
                streamUrlMap[epNum] = playingUrl;
              }
            }
          }
        }
        if (streamUrlMap.isNotEmpty) break;
      }
    } catch (_) {}

    // 4. Merge TMDB official episodes with MunoWatch streams
    if (officialEpisodes.isNotEmpty) {
      return officialEpisodes.map((ep) {
        final stream = streamUrlMap[ep.episodeNumber];
        final mappedId = streamIdMap[ep.episodeNumber] ?? ep.id;
        return TvEpisodeData(
          id: mappedId,
          episodeNumber: ep.episodeNumber,
          seasonNumber: seasonNumber,
          name: ep.name,
          overview: ep.overview,
          runtime: ep.runtime,
          stillPath: ep.stillPath,
          voteAverage: ep.voteAverage,
          videoUrl: stream ?? ep.videoUrl,
        );
      }).toList();
    }

    // Fallback: Build from MunoWatch search results
    if (streamUrlMap.isNotEmpty) {
      final List<TvEpisodeData> eps = [];
      final sortedEpNums = streamUrlMap.keys.toList()..sort();
      for (final epNum in sortedEpNums) {
        eps.add(
          TvEpisodeData(
            id: streamIdMap[epNum] ?? epNum,
            episodeNumber: epNum,
            seasonNumber: seasonNumber,
            name: 'Episode $epNum',
            overview: 'Official Luganda translated episode release',
            runtime: 48,
            stillPath: null,
            voteAverage: 8.4,
            videoUrl: streamUrlMap[epNum],
          ),
        );
      }
      return eps;
    }

    return [];
  }

  /// On-demand stream URL resolution for playback and downloads
  Future<String?> resolveStreamUrl(int movieId, {String? title}) async {
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
  Future<String?> getMovieLogo(int movieId) async {
    if (!_hasCustomApiKey) return null;
    try {
      return await _datasource.getMovieLogo(movieId);
    } catch (_) {
      return null;
    }
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
