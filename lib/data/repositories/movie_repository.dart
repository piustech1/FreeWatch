import '../../core/constants/api_constants.dart';
import '../datasources/tmdb_datasource.dart';
import '../datasources/moviemax_datasource.dart';
import '../datasources/munowatch_datasource.dart';
import '../models/movie.dart';
import '../models/genre.dart';
import '../models/movie_details_data.dart';
import '../models/vj.dart';
import '../mock/mock_movies.dart';

/// Unified MovieRepository with Hybrid Gap-Filling Architecture:
/// - Primary: Live MunoWatch API (13+ categories with live search) + MovieMax RTDB (1,531+ movies)
/// - Enrichment & Gap-Filler: TMDB official API (cast, certifications, logos, official 1280 backdrops)
/// - Offline Resilience: MockData guaranteed fallback
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

  bool get _hasCustomApiKey =>
      ApiConstants.tmdbApiKey != 'YOUR_TMDB_API_KEY' &&
      ApiConstants.tmdbApiKey.trim().isNotEmpty;

  /// Combined catalog merging live MunoWatch releases across all 13 categories
  /// with MovieMax RTDB records, deduplicating by normalized title.
  Future<List<Movie>> _getAllLugandaMovies({bool forceRefresh = false}) async {
    final List<Movie> results = [];
    final Set<String> seenTitles = {};

    // 1. Live MunoWatch movies (13 categories)
    try {
      final munoList = await _munowatch.getAllMovies(forceRefresh: forceRefresh);
      for (final m in munoList) {
        final norm = m.title.toLowerCase().trim();
        if (norm.isNotEmpty && !seenTitles.contains(norm)) {
          seenTitles.add(norm);
          results.add(m);
        }
      }
    } catch (_) {}

    // 2. MovieMax RTDB movies (1,531+ movies)
    try {
      final movieMaxList = await _movieMax.getAllMovies(forceRefresh: forceRefresh);
      for (final m in movieMaxList) {
        final norm = m.title.toLowerCase().trim();
        if (norm.isNotEmpty && !seenTitles.contains(norm)) {
          seenTitles.add(norm);
          results.add(m);
        }
      }
    } catch (_) {}

    return results;
  }

  // ── 1. Trending Movies ──────────────────────────────────────────────────────
  Future<List<Movie>> getTrending({int page = 1}) async {
    try {
      final all = await _getAllLugandaMovies();
      if (all.isNotEmpty) {
        // Return movies sorted by rating and popularity
        final list = List<Movie>.from(all)
          ..sort((a, b) => b.voteAverage.compareTo(a.voteAverage));
        return _paginate(list, page, pageSize: 25);
      }
    } catch (_) {}

    if (_hasCustomApiKey) {
      try {
        final list = await _datasource.getTrending(page: page);
        if (list.isNotEmpty) return list;
      } catch (_) {}
    }

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

    if (_hasCustomApiKey) {
      try {
        final list = await _datasource.getPopular(page: page);
        if (list.isNotEmpty) return list;
      } catch (_) {}
    }

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

    if (_hasCustomApiKey) {
      try {
        final list = await _datasource.getTopRated(page: page);
        if (list.isNotEmpty) return list;
      } catch (_) {}
    }

    return MockData.popularMovies;
  }

  // ── 4. Now Playing / Latest Uploads ─────────────────────────────────────────
  Future<List<Movie>> getNowPlaying({int page = 1}) async {
    try {
      final all = await _getAllLugandaMovies();
      if (all.isNotEmpty) {
        // Reverse order represents the latest additions
        final list = List<Movie>.from(all.reversed);
        return _paginate(list, page, pageSize: 25);
      }
    } catch (_) {}

    if (_hasCustomApiKey) {
      try {
        final list = await _datasource.getNowPlaying(page: page);
        if (list.isNotEmpty) return list;
      } catch (_) {}
    }

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

    if (_hasCustomApiKey) {
      try {
        final list = await _datasource.getUpcoming(page: page);
        if (list.isNotEmpty) return list;
      } catch (_) {}
    }

    return MockData.newMovies;
  }

  // ── 6. TV Series ────────────────────────────────────────────────────────────
  Future<List<Movie>> getSeries({int page = 1}) async {
    try {
      final rtdbSeries = await _movieMax.getAllSeries();
      if (rtdbSeries.isNotEmpty) {
        return _paginate(rtdbSeries, page, pageSize: 25);
      }
    } catch (_) {}

    if (_hasCustomApiKey) {
      try {
        final list = await _datasource.getDiscoverTv(page: page);
        if (list.isNotEmpty) return list;
      } catch (_) {}
    }

    return MockData.popularTv;
  }

  // ── 7. Movies by Genre with Gap-Filling ─────────────────────────────────────
  Future<List<Movie>> getMoviesByGenre(int genreId, {int page = 1}) async {
    final genreName = _mapGenreIdToName(genreId);

    try {
      final allMovies = await _getAllLugandaMovies();
      if (allMovies.isNotEmpty) {
        final matched = allMovies.where((m) {
          final hasId = m.genreIds.contains(genreId);
          final hasName = m.genreNames.any((g) =>
              g.toLowerCase().contains(genreName.toLowerCase()) ||
              genreName.toLowerCase().contains(g.toLowerCase()));
          return hasId || hasName;
        }).toList();

        if (matched.isNotEmpty) {
          return _paginate(matched, page, pageSize: 25);
        }
      }
    } catch (_) {}

    if (_hasCustomApiKey) {
      try {
        final list = await _datasource.getMoviesByGenre(genreId, page: page);
        if (list.isNotEmpty) return list;
      } catch (_) {}
    }

    return MockData.getAllMovies()
        .where((m) => m.genreIds.contains(genreId))
        .toList();
  }

  // ── 8. Search Movies across Live MunoWatch, MovieMax, and TMDB ─────────────
  Future<List<Movie>> searchMovies(String query, {int page = 1}) async {
    final cleanQuery = query.toLowerCase().trim();
    if (cleanQuery.isEmpty) return [];

    final List<Movie> combinedResults = [];
    final Set<String> seenTitles = {};

    // 1. Live MunoWatch API backend search
    try {
      final munoSearchResults = await _munowatch.searchMovies(cleanQuery);
      for (final m in munoSearchResults) {
        final norm = m.title.toLowerCase().trim();
        if (norm.isNotEmpty && !seenTitles.contains(norm)) {
          seenTitles.add(norm);
          combinedResults.add(m);
        }
      }
    } catch (_) {}

    // 2. Local pool matching across all Luganda movies and series
    try {
      final allMovies = await _getAllLugandaMovies();
      final allSeries = await _movieMax.getAllSeries();
      final pool = [...allMovies, ...allSeries];

      final qTokens = cleanQuery
          .replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), ' ')
          .toLowerCase()
          .split(RegExp(r'\s+'))
          .where((t) => t.isNotEmpty)
          .toList();

      final localMatches = pool.where((m) {
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
        final norm = m.title.toLowerCase().trim();
        if (norm.isNotEmpty && !seenTitles.contains(norm)) {
          seenTitles.add(norm);
          combinedResults.add(m);
        }
      }
    } catch (_) {}

    // 3. TMDB fallback search if pool has few results
    if (_hasCustomApiKey && combinedResults.length < 10) {
      try {
        final tmdbList = await _datasource.searchMovies(cleanQuery, page: page);
        for (final m in tmdbList) {
          final norm = m.title.toLowerCase().trim();
          if (norm.isNotEmpty && !seenTitles.contains(norm)) {
            seenTitles.add(norm);
            combinedResults.add(m);
          }
        }
      } catch (_) {}
    }

    if (combinedResults.isNotEmpty) {
      return _paginate(combinedResults, page, pageSize: 30);
    }

    return MockData.popularMovies
        .where((m) => m.title.toLowerCase().contains(cleanQuery))
        .toList();
  }

  // ── Helper: Normalize VJ names for resilient matching ──────────────────────
  static String normalizeVjName(String raw) {
    return raw
        .toLowerCase()
        .replaceAll('vj.', '')
        .replaceAll('vj', '')
        .replaceAll('.', '')
        .replaceAll(':', '')
        .replaceAll('_', '')
        .replaceAll('-', '')
        .trim();
  }

  // ── 9. Dedicated VJ Movie Filtering with Strict Real Match ─────────────────
  Future<List<Movie>> getMoviesByVj(dynamic vjOrId) async {
    Vj vj;
    if (vjOrId is Vj) {
      vj = vjOrId;
    } else {
      final idStr = vjOrId.toString();
      vj = MockData.vjs.firstWhere((v) => v.id == idStr, orElse: () => MockData.vjs.first);
    }

    final cleanVjTarget = normalizeVjName(vj.name);
    final List<Movie> matching = [];
    final Set<int> seenIds = {};

    try {
      final allMovies = await _getAllLugandaMovies();
      final allSeries = await _movieMax.getAllSeries();
      final pool = [...allMovies, ...allSeries];

      for (final m in pool) {
        if (m.vjName == null || m.vjName!.isEmpty) continue;
        final cleanMovieVj = normalizeVjName(m.vjName!);
        if (cleanMovieVj.contains(cleanVjTarget) || cleanVjTarget.contains(cleanMovieVj)) {
          if (seenIds.add(m.id)) {
            // Standardize display VJ name to canonical VJ name
            matching.add(m.copyWith(vjName: vj.name));
          }
        }
      }
    } catch (_) {}

    if (matching.isNotEmpty) return matching;

    // Fallback: curated mock movies for this VJ
    final mockVjMovies = MockData.getMoviesByVj(vj.id);
    return mockVjMovies.map((m) => m.copyWith(vjName: vj.name)).toList();
  }

  /// Calculates real dynamic movie counts for all VJs directly from merged records
  Future<List<Vj>> getVjsWithRealCounts() async {
    try {
      final allMovies = await _getAllLugandaMovies();
      final allSeries = await _movieMax.getAllSeries();
      final pool = [...allMovies, ...allSeries];

      return MockData.vjs.map((vj) {
        final target = normalizeVjName(vj.name);
        final count = pool.where((m) {
          if (m.vjName == null || m.vjName!.isEmpty) return false;
          final clean = normalizeVjName(m.vjName!);
          return clean.contains(target) || target.contains(clean);
        }).length;

        // If database has matching movies, use exact count; otherwise keep minimum 1
        return vj.copyWith(
          movieCount: count > 0 ? count : (vj.movieCount > 0 ? vj.movieCount : 1),
        );
      }).toList();
    } catch (_) {
      return MockData.vjs;
    }
  }

  /// Sourced strictly from real records: finds real streamable related movies
  Future<List<Movie>> getRelatedMovies(Movie movie) async {
    try {
      final all = await _getAllLugandaMovies();
      final allSeries = await _movieMax.getAllSeries();
      final pool = [...all, ...allSeries];

      final cleanVj = movie.vjName != null ? normalizeVjName(movie.vjName!) : '';
      final movieGenres = Set<int>.from(movie.genreIds);

      final List<Movie> related = [];
      final Set<int> seenIds = {movie.id};

      // 1. Same VJ
      if (cleanVj.isNotEmpty) {
        for (final m in pool) {
          if (m.id == movie.id) continue;
          if (m.vjName != null && normalizeVjName(m.vjName!).contains(cleanVj)) {
            if (seenIds.add(m.id)) {
              related.add(m);
            }
          }
          if (related.length >= 10) break;
        }
      }

      // 2. Shared Genres
      if (related.length < 15 && movieGenres.isNotEmpty) {
        for (final m in pool) {
          if (seenIds.contains(m.id)) continue;
          final sharesGenre = m.genreIds.any((g) => movieGenres.contains(g));
          if (sharesGenre) {
            if (seenIds.add(m.id)) {
              related.add(m);
            }
          }
          if (related.length >= 15) break;
        }
      }

      // 3. Same content type (movies or series)
      if (related.length < 10) {
        for (final m in pool) {
          if (seenIds.contains(m.id)) continue;
          if (m.isTv == movie.isTv) {
            if (seenIds.add(m.id)) {
              related.add(m);
            }
          }
          if (related.length >= 15) break;
        }
      }

      if (related.isNotEmpty) return related;
    } catch (_) {}

    return [];
  }

  /// Full un-truncated list for 'See All' category pages
  Future<List<Movie>> getAllMoviesByGenre(int genreId) async {
    try {
      final allMovies = await _getAllLugandaMovies();
      final filtered = allMovies.where((m) => m.genreIds.contains(genreId)).toList();
      if (filtered.isNotEmpty) return filtered;
    } catch (_) {}
    return getMoviesByGenre(genreId, page: 1);
  }

  /// Full un-truncated list of uploads for 'See All'
  Future<List<Movie>> getAllUploads() async {
    try {
      final allMovies = await _getAllLugandaMovies();
      if (allMovies.isNotEmpty) return allMovies;
    } catch (_) {}
    return getNowPlaying(page: 1);
  }

  /// Full un-truncated list of series for 'See All'
  Future<List<Movie>> getAllSeriesList() async {
    try {
      final rtdbSeries = await _movieMax.getAllSeries();
      if (rtdbSeries.isNotEmpty) return rtdbSeries;
    } catch (_) {}
    return getSeries(page: 1);
  }

  // ── 10. Movie Details with Gap-Filling & Metadata Enrichment ─────────────────
  Future<MovieDetailsData> getMovieDetails(int movieId, {bool isTv = false}) async {
    // 1. Check MunoWatch and MovieMax for streaming link and VJ info
    Movie? lugandaMovie;
    try {
      lugandaMovie = await _munowatch.findMovie(movieId);
      if (lugandaMovie != null) {
        // Resolve stream URL on-demand from MunoWatch if missing
        if (lugandaMovie.videoUrl == null || lugandaMovie.videoUrl!.isEmpty) {
          final streamDetails = await _munowatch.getStreamDetails(movieId);
          if (streamDetails != null) {
            final playingUrl = streamDetails['playingurl']?.toString();
            final desc = streamDetails['description']?.toString();
            final dur = streamDetails['duration']?.toString();
            int? parsedRuntime;
            if (dur != null && dur.contains('h')) {
              final parts = dur.split('h');
              final h = int.tryParse(parts[0].trim()) ?? 1;
              final m = int.tryParse(parts[1].replaceAll('m', '').trim()) ?? 0;
              parsedRuntime = h * 60 + m;
            }
            lugandaMovie = lugandaMovie.copyWith(
              videoUrl: playingUrl,
              overview: desc?.isNotEmpty == true ? desc : lugandaMovie.overview,
              runtime: parsedRuntime,
            );
          }
        }
      }
    } catch (_) {}

    if (lugandaMovie == null) {
      try {
        lugandaMovie = await _movieMax.findMovie(movieId);
      } catch (_) {}
    }

    final bool actuallyTv = isTv || (lugandaMovie?.isTv == true);

    // 2. Fetch TMDB rich metadata (cast, certification, backdrop, runtime)
    MovieDetailsData? tmdbDetails;
    if (_hasCustomApiKey) {
      try {
        tmdbDetails = actuallyTv
            ? await _datasource.getTvDetails(movieId)
            : await _datasource.getMovieDetails(movieId);
      } catch (_) {
        try {
          tmdbDetails = actuallyTv
              ? await _datasource.getMovieDetails(movieId)
              : await _datasource.getTvDetails(movieId);
        } catch (_) {}
      }
    }

    // 3. If TMDB metadata exists, enrich it with Luganda streaming link, VJ name, and related movies
    if (tmdbDetails != null) {
      final realRelated = await getRelatedMovies(
        lugandaMovie ??
            Movie(
              id: movieId,
              title: tmdbDetails.title,
              voteAverage: tmdbDetails.voteAverage,
              vjName: lugandaMovie?.vjName ?? tmdbDetails.vjName,
              genreIds: lugandaMovie?.genreIds ?? const [],
              isTv: actuallyTv,
            ),
      );

      return tmdbDetails.copyWith(
        videoUrl: lugandaMovie?.videoUrl ?? tmdbDetails.videoUrl,
        vjName: lugandaMovie?.vjName ?? tmdbDetails.vjName,
        backdropPath: tmdbDetails.backdropPath ?? lugandaMovie?.backdropPath,
        runtime: tmdbDetails.runtime > 0 ? tmdbDetails.runtime : (lugandaMovie?.runtime ?? 110),
        relatedMovies: realRelated.isNotEmpty ? realRelated : tmdbDetails.relatedMovies,
      );
    }

    // 4. Gap-filling fallback: Build complete details with MockData backing
    final mockFallback = MockData.getAllMovies().firstWhere(
      (m) => m.id == movieId,
      orElse: () => actuallyTv ? MockData.popularTv.first : MockData.trendingMovies.first,
    );

    final title = lugandaMovie?.title.isNotEmpty == true ? lugandaMovie!.title : mockFallback.title;
    final overview = lugandaMovie?.overview?.isNotEmpty == true ? lugandaMovie!.overview! : (mockFallback.overview ?? '');
    final backdrop = lugandaMovie?.backdropPath ?? mockFallback.backdropPath;
    final releaseDate = lugandaMovie?.releaseDate ?? mockFallback.releaseDate ?? '2025-01-01';
    final voteAvg = (lugandaMovie?.voteAverage ?? 0.0) > 0 ? lugandaMovie!.voteAverage : mockFallback.voteAverage;
    final genres = (lugandaMovie?.genreNames.isNotEmpty == true)
        ? lugandaMovie!.genreNames
        : (actuallyTv ? ['Drama', 'Action'] : ['Action', 'Thriller']);
    final runtime = lugandaMovie?.runtime ?? (actuallyTv ? 55 : 110);
    final videoUrl = lugandaMovie?.videoUrl ?? mockFallback.videoUrl;
    final vjName = lugandaMovie?.vjName ?? mockFallback.vjName ?? 'VJ Junior';

    final realFallbackRelated = await getRelatedMovies(
      lugandaMovie ?? mockFallback,
    );

    return MovieDetailsData(
      id: movieId,
      title: title,
      overview: overview,
      backdropPath: backdrop,
      runtime: runtime,
      releaseDate: releaseDate,
      voteAverage: voteAvg,
      voteCount: mockFallback.voteCount ?? 4500,
      genres: genres,
      certification: actuallyTv ? 'TV-MA' : 'PG-13',
      cast: const [
        CastMember(id: 1, name: 'Jason Momoa', character: 'Garrett', profilePath: '/6AUNvdc3RAq7fq9eT01O9450p9C.jpg'),
        CastMember(id: 2, name: 'Jack Black', character: 'Steve', profilePath: '/rtCx0fiYxJVG4Uj0qrPDMu49Vmm.jpg'),
        CastMember(id: 3, name: 'Emma Myers', character: 'Natalie', profilePath: '/4woSOUD0equAYzvwhWBHIJDCM88.jpg'),
        CastMember(id: 4, name: 'Danielle Brooks', character: 'Dawn', profilePath: '/kSpsYjG80eL4qQ3R3n9k6rLqC9p.jpg'),
      ],
      relatedMovies: realFallbackRelated.isNotEmpty
          ? realFallbackRelated
          : (actuallyTv
              ? MockData.popularTv.where((m) => m.id != movieId).toList()
              : MockData.trendingMovies.where((m) => m.id != movieId).toList()),
      isTv: actuallyTv,
      numberOfSeasons: actuallyTv ? 3 : 0,
      seasons: actuallyTv
          ? const [
              TvSeasonData(id: 1, seasonNumber: 1, name: 'Season 1', episodeCount: 8),
              TvSeasonData(id: 2, seasonNumber: 2, name: 'Season 2', episodeCount: 8),
              TvSeasonData(id: 3, seasonNumber: 3, name: 'Season 3', episodeCount: 6),
            ]
          : const [],
      videoUrl: videoUrl,
      vjName: vjName,
    );
  }

  // ── 11. TV Season Episodes with Live Video URLs ─────────────────────────────
  Future<List<TvEpisodeData>> getTvSeasonEpisodes(int tvId, int seasonNumber, {String? seriesTitle}) async {
    // 1. Try to fetch live episodes with direct Cloudflare video URLs from MovieMax
    try {
      final episodes = await _movieMax.getSeriesEpisodes(tvId, seasonNumber, seriesTitle: seriesTitle);
      if (episodes.isNotEmpty) return episodes;
    } catch (_) {}

    // 2. Try TMDB
    if (_hasCustomApiKey) {
      try {
        final episodes = await _datasource.getTvSeasonEpisodes(tvId, seasonNumber);
        if (episodes.isNotEmpty) return episodes;
      } catch (_) {}
    }

    // 3. Fallback mock episodes
    return List.generate(6, (i) {
      final epNum = i + 1;
      return TvEpisodeData(
        id: epNum,
        episodeNumber: epNum,
        seasonNumber: seasonNumber,
        name: 'Episode $epNum',
        overview: 'Official translated episode release',
        runtime: 48 + (i * 3) % 15,
        stillPath: null,
        voteAverage: 8.2,
      );
    });
  }

  // ── 12. Genres ──────────────────────────────────────────────────────────────
  Future<List<Genre>> getGenres() async {
    if (!_hasCustomApiKey) return MockData.genres;
    try {
      final list = await _datasource.getGenres();
      return list.isNotEmpty ? list : MockData.genres;
    } catch (_) {
      return MockData.genres;
    }
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
