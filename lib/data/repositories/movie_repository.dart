import '../../core/constants/api_constants.dart';
import '../datasources/tmdb_datasource.dart';
import '../models/movie.dart';
import '../models/genre.dart';
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
}
