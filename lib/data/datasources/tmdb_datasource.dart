import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../models/movie.dart';
import '../models/genre.dart';

/// Remote datasource — all TMDB API calls live here
class TmdbDatasource {
  final Dio _dio = ApiClient.instance;

  // ── Movies ────────────────────────────────────────────────────────────────

  Future<List<Movie>> getTrending({int page = 1}) async {
    final res = await _dio.get(
      ApiConstants.trendingMovies,
      queryParameters: {'page': page},
    );
    return Movie.fromJsonList(res.data as Map<String, dynamic>);
  }

  Future<List<Movie>> getPopular({int page = 1}) async {
    final res = await _dio.get(
      ApiConstants.popularMovies,
      queryParameters: {'page': page},
    );
    return Movie.fromJsonList(res.data as Map<String, dynamic>);
  }

  Future<List<Movie>> getTopRated({int page = 1}) async {
    final res = await _dio.get(
      ApiConstants.topRatedMovies,
      queryParameters: {'page': page},
    );
    return Movie.fromJsonList(res.data as Map<String, dynamic>);
  }

  Future<List<Movie>> getNowPlaying({int page = 1}) async {
    final res = await _dio.get(
      ApiConstants.nowPlayingMovies,
      queryParameters: {'page': page},
    );
    return Movie.fromJsonList(res.data as Map<String, dynamic>);
  }

  Future<List<Movie>> getUpcoming({int page = 1}) async {
    final res = await _dio.get(
      ApiConstants.upcomingMovies,
      queryParameters: {'page': page},
    );
    return Movie.fromJsonList(res.data as Map<String, dynamic>);
  }

  Future<List<Movie>> searchMovies(String query, {int page = 1}) async {
    final res = await _dio.get(
      ApiConstants.searchMovies,
      queryParameters: {'query': query, 'page': page},
    );
    return Movie.fromJsonList(res.data as Map<String, dynamic>);
  }

  // ── Genres ────────────────────────────────────────────────────────────────

  Future<List<Genre>> getGenres() async {
    final res = await _dio.get(ApiConstants.genres);
    return Genre.fromJsonList(res.data as Map<String, dynamic>);
  }
}
