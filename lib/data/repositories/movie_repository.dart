import '../../core/constants/api_constants.dart';
import '../datasources/tmdb_datasource.dart';
import '../models/movie.dart';
import '../models/genre.dart';
import '../models/movie_details_data.dart';
import '../mock/mock_movies.dart';

/// Repository that abstracts data access from the features layer
class MovieRepository {
  final TmdbDatasource _datasource;

  MovieRepository({TmdbDatasource? datasource})
      : _datasource = datasource ?? TmdbDatasource();

  bool get _hasCustomApiKey =>
      ApiConstants.tmdbApiKey != 'YOUR_TMDB_API_KEY' &&
      ApiConstants.tmdbApiKey.trim().isNotEmpty;

  Future<List<Movie>> getTrending({int page = 1}) async {
    if (!_hasCustomApiKey) return MockData.trendingMovies;
    try {
      final list = await _datasource.getTrending(page: page);
      return list.isNotEmpty ? list : MockData.trendingMovies;
    } catch (_) {
      return MockData.trendingMovies;
    }
  }

  Future<List<Movie>> getPopular({int page = 1}) async {
    if (!_hasCustomApiKey) return MockData.popularMovies;
    try {
      final list = await _datasource.getPopular(page: page);
      return list.isNotEmpty ? list : MockData.popularMovies;
    } catch (_) {
      return MockData.popularMovies;
    }
  }

  Future<List<Movie>> getTopRated({int page = 1}) async {
    if (!_hasCustomApiKey) return MockData.popularMovies;
    try {
      final list = await _datasource.getTopRated(page: page);
      return list.isNotEmpty ? list : MockData.popularMovies;
    } catch (_) {
      return MockData.popularMovies;
    }
  }

  Future<List<Movie>> getNowPlaying({int page = 1}) async {
    if (!_hasCustomApiKey) return MockData.newMovies;
    try {
      final list = await _datasource.getNowPlaying(page: page);
      return list.isNotEmpty ? list : MockData.newMovies;
    } catch (_) {
      return MockData.newMovies;
    }
  }

  Future<List<Movie>> getUpcoming({int page = 1}) async {
    if (!_hasCustomApiKey) return MockData.newMovies;
    try {
      final list = await _datasource.getUpcoming(page: page);
      return list.isNotEmpty ? list : MockData.newMovies;
    } catch (_) {
      return MockData.newMovies;
    }
  }

  Future<List<Movie>> searchMovies(String query, {int page = 1}) async {
    if (!_hasCustomApiKey) {
      return MockData.popularMovies
          .where((m) => m.title.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
    try {
      return await _datasource.searchMovies(query, page: page);
    } catch (_) {
      return [];
    }
  }

  Future<List<Genre>> getGenres() async {
    if (!_hasCustomApiKey) return MockData.genres;
    try {
      final list = await _datasource.getGenres();
      return list.isNotEmpty ? list : MockData.genres;
    } catch (_) {
      return MockData.genres;
    }
  }

  Future<String?> getMovieLogo(int movieId) async {
    if (!_hasCustomApiKey) return null;
    try {
      return await _datasource.getMovieLogo(movieId);
    } catch (_) {
      return null;
    }
  }

  Future<MovieDetailsData> getMovieDetails(int movieId) async {
    if (_hasCustomApiKey) {
      try {
        return await _datasource.getMovieDetails(movieId);
      } catch (_) {
        try {
          return await _datasource.getTvDetails(movieId);
        } catch (_) {}
      }
    }
    // Fallback: construct MovieDetailsData from mock data
    final mockMovie = MockData.getAllMovies().firstWhere(
      (m) => m.id == movieId,
      orElse: () => MockData.trendingMovies.first,
    );

    return MovieDetailsData(
      id: mockMovie.id,
      title: mockMovie.title,
      overview: mockMovie.overview ?? '',
      runtime: 110,
      releaseDate: mockMovie.releaseDate ?? '2024-03-01',
      voteAverage: mockMovie.voteAverage,
      voteCount: mockMovie.voteCount ?? 4200,
      genres: ['Action', 'Adventure'],
      certification: 'PG-13',
      cast: const [
        CastMember(id: 1, name: 'Jason Momoa', character: 'Garrett', profilePath: '/6AUNvdc3RAq7fq9eT01O9450p9C.jpg'),
        CastMember(id: 2, name: 'Jack Black', character: 'Steve', profilePath: '/rtCx0fiYxJVG4Uj0qrPDMu49Vmm.jpg'),
        CastMember(id: 3, name: 'Emma Myers', character: 'Natalie', profilePath: '/4woSOUD0equAYzvwhWBHIJDCM88.jpg'),
        CastMember(id: 4, name: 'Danielle Brooks', character: 'Dawn', profilePath: '/kSpsYjG80eL4qQ3R3n9k6rLqC9p.jpg'),
      ],
      relatedMovies: MockData.trendingMovies.where((m) => m.id != movieId).toList(),
      isTv: mockMovie.isTv,
      numberOfSeasons: mockMovie.isTv ? 3 : 0,
      seasons: mockMovie.isTv
          ? const [
              TvSeasonData(id: 1, seasonNumber: 1, name: 'Season 1', episodeCount: 8),
              TvSeasonData(id: 2, seasonNumber: 2, name: 'Season 2', episodeCount: 8),
              TvSeasonData(id: 3, seasonNumber: 3, name: 'Season 3', episodeCount: 6),
            ]
          : const [],
    );
  }

  Future<List<TvEpisodeData>> getTvSeasonEpisodes(int tvId, int seasonNumber) async {
    if (_hasCustomApiKey) {
      try {
        final episodes = await _datasource.getTvSeasonEpisodes(tvId, seasonNumber);
        if (episodes.isNotEmpty) return episodes;
      } catch (_) {}
    }
    // Fallback episodes
    return List.generate(6, (i) {
      final epNum = i + 1;
      return TvEpisodeData(
        id: epNum,
        episodeNumber: epNum,
        seasonNumber: seasonNumber,
        name: 'Episode $epNum',
        overview: 'Official episode description',
        runtime: 48 + (i * 3) % 15,
        stillPath: null,
        voteAverage: 8.2,
      );
    });
  }

  Future<List<Movie>> getMoviesByGenre(int genreId, {int page = 1}) async {
    if (!_hasCustomApiKey) {
      return MockData.getAllMovies()
          .where((m) => m.genreIds.contains(genreId))
          .toList();
    }
    try {
      final list = await _datasource.getMoviesByGenre(genreId, page: page);
      return list.isNotEmpty
          ? list
          : MockData.getAllMovies()
              .where((m) => m.genreIds.contains(genreId))
              .toList();
    } catch (_) {
      return MockData.getAllMovies()
          .where((m) => m.genreIds.contains(genreId))
          .toList();
    }
  }

  Future<List<Movie>> getSeries({int page = 1}) async {
    if (!_hasCustomApiKey) return MockData.popularMovies;
    try {
      final list = await _datasource.getDiscoverTv(page: page);
      return list.isNotEmpty ? list : MockData.popularMovies;
    } catch (_) {
      return MockData.popularMovies;
    }
  }
}
