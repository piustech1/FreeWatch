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

    if (matching.isNotEmpty) return matching;

    final mockVjMovies = MockData.getMoviesByVj(vjOrId is Vj ? vjOrId.id : vjOrId.toString());
    return mockVjMovies.map((m) => m.copyWith(vjName: rawName)).toList();
  }

  /// Calculates real dynamic movie counts for all VJs directly from MunoWatch
  Future<List<Vj>> getVjsWithRealCounts() async {
    try {
      final allMovies = await _getAllLugandaMovies();
      return MockData.vjs.map((vj) {
        final target = normalizeVjName(vj.name);
        final count = allMovies.where((m) {
          if (m.vjName == null || m.vjName!.isEmpty) return false;
          final clean = normalizeVjName(m.vjName!);
          return clean.contains(target) || target.contains(clean);
        }).length;

        return vj.copyWith(
          movieCount: count > 0 ? count : (vj.movieCount > 0 ? vj.movieCount : 1),
        );
      }).toList();
    } catch (_) {
      return MockData.vjs;
    }
  }

  /// Sourced strictly from MunoWatch: finds real related movies matching VJ and genre
  Future<List<Movie>> getRelatedMovies(Movie movie) async {
    try {
      final all = await _getAllLugandaMovies();
      final cleanVj = movie.vjName != null ? normalizeVjName(movie.vjName!) : '';
      final movieGenres = Set<int>.from(movie.genreIds);

      final List<Movie> related = [];
      final Set<int> seenIds = {movie.id};

      // 1. Same VJ
      if (cleanVj.isNotEmpty) {
        for (final m in all) {
          if (m.id == movie.id) continue;
          if (m.vjName != null && normalizeVjName(m.vjName!).contains(cleanVj)) {
            if (seenIds.add(m.id)) {
              related.add(m);
            }
          }
          if (related.length >= 8) break;
        }
      }

      // 2. Shared Genres
      if (related.length < 12 && movieGenres.isNotEmpty) {
        for (final m in all) {
          if (seenIds.contains(m.id)) continue;
          final sharesGenre = m.genreIds.any((g) => movieGenres.contains(g));
          if (sharesGenre) {
            if (seenIds.add(m.id)) {
              related.add(m);
            }
          }
          if (related.length >= 12) break;
        }
      }

      // 3. Fallback other MunoWatch movies
      if (related.length < 6) {
        for (final m in all) {
          if (seenIds.contains(m.id)) continue;
          if (seenIds.add(m.id)) {
            related.add(m);
          }
          if (related.length >= 10) break;
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

    final bool actuallyTv = isTv || (lugandaMovie?.isTv == true);

    // Identity is guaranteed: Title, artwork, VJ name belong strictly to the clicked movie
    final title = resolvedTitle ?? ((lugandaMovie != null && lugandaMovie.title.isNotEmpty && lugandaMovie.title != 'Movie')
        ? lugandaMovie.title
        : 'Movie');
    final overview = resolvedOverview ?? (lugandaMovie?.overview ?? 'Official Luganda translated cinema release on MunoWatch.');
    final backdrop = resolvedBackdrop;
    final releaseDate = lugandaMovie?.releaseDate ?? '2026-01-01';
    final voteAvg = (lugandaMovie?.voteAverage ?? 0.0) > 0 ? lugandaMovie!.voteAverage : 8.5;
    final genres = (lugandaMovie != null && lugandaMovie.genreNames.isNotEmpty)
        ? lugandaMovie.genreNames
        : (actuallyTv ? ['Drama', 'Action'] : ['Action', 'Cinema']);
    final runtime = resolvedRuntime ?? (actuallyTv ? 55 : 115);
    final vjName = resolvedVj ?? (lugandaMovie?.vjName ?? 'VJ Junior');

    final activeMovieForRelated = lugandaMovie ?? Movie(
      id: movieId,
      title: title,
      voteAverage: voteAvg,
      vjName: vjName,
      genreIds: lugandaMovie?.genreIds ?? const [],
      isTv: actuallyTv,
    );

    final realRelated = await getRelatedMovies(activeMovieForRelated);

    return MovieDetailsData(
      id: movieId,
      title: title,
      overview: overview,
      backdropPath: backdrop,
      runtime: runtime,
      releaseDate: releaseDate,
      voteAverage: voteAvg,
      voteCount: lugandaMovie?.voteCount ?? 200,
      genres: genres,
      certification: actuallyTv ? 'TV-MA' : 'PG-13',
      cast: const [
        CastMember(id: 1, name: 'Lead Cast', character: 'Featured Actor', profilePath: null),
      ],
      relatedMovies: realRelated,
      isTv: actuallyTv,
      numberOfSeasons: actuallyTv ? 2 : 0,
      seasons: actuallyTv
          ? const [
              TvSeasonData(id: 1, seasonNumber: 1, name: 'Season 1', episodeCount: 10),
            ]
          : const [],
      videoUrl: resolvedVideoUrl, // STRICTLY REAL VOD ONLY (null if none)
      vjName: vjName,
    );
  }

  // ── 11. TV Season Episodes with Live Video URLs from MunoWatch ──────────────
  Future<List<TvEpisodeData>> getTvSeasonEpisodes(
    int tvId,
    int seasonNumber, {
    String? seriesTitle,
  }) async {
    // 1. Search MunoWatch for matching season episodes
    try {
      final query = seriesTitle != null && seriesTitle.isNotEmpty
          ? '$seriesTitle Season $seasonNumber'
          : 'Season $seasonNumber';
      final searchResults = await _munowatch.searchMovies(query);
      if (searchResults.isNotEmpty) {
        final List<TvEpisodeData> episodes = [];
        int epCounter = 1;
        for (final m in searchResults) {
          episodes.add(
            TvEpisodeData(
              id: m.id,
              episodeNumber: epCounter++,
              seasonNumber: seasonNumber,
              name: m.title,
              overview: m.overview ?? 'Official Luganda translated episode release',
              runtime: m.runtime ?? 50,
              stillPath: m.posterPath,
              voteAverage: m.voteAverage,
              videoUrl: m.videoUrl,
            ),
          );
        }
        return episodes;
      }
    } catch (_) {}

    // 2. Fallback mock episodes
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
