import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../models/movie.dart';
import '../models/genre.dart';
import '../models/movie_details_data.dart';

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
    try {
      final res = await _dio.get(
        ApiConstants.searchMulti,
        queryParameters: {'query': query, 'page': page},
      );
      final results = res.data['results'] as List<dynamic>? ?? [];
      final moviesAndShows = results
          .where((e) => e['media_type'] != 'person')
          .map((e) => Movie.fromJson(e as Map<String, dynamic>))
          .toList();
      if (moviesAndShows.isNotEmpty) return moviesAndShows;
    } catch (_) {}

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

  // ── Movie & TV Logos ─────────────────────────────────────────────────────

  Future<String?> getMovieLogo(int id) async {
    // 1. Try movie logo
    try {
      final res = await _dio.get('/movie/$id/images');
      final data = res.data as Map<String, dynamic>;
      final logos = data['logos'] as List<dynamic>?;
      if (logos != null && logos.isNotEmpty) {
        final enLogos = logos.where((l) => l['iso_639_1'] == 'en').toList();
        final target = enLogos.isNotEmpty ? enLogos.first : logos.first;
        final filePath = target['file_path'] as String?;
        if (filePath != null) {
          return '${ApiConstants.logoW500}$filePath';
        }
      }
    } catch (_) {}

    // 2. Try TV series logo fallback
    try {
      final res = await _dio.get('/tv/$id/images');
      final data = res.data as Map<String, dynamic>;
      final logos = data['logos'] as List<dynamic>?;
      if (logos != null && logos.isNotEmpty) {
        final enLogos = logos.where((l) => l['iso_639_1'] == 'en').toList();
        final target = enLogos.isNotEmpty ? enLogos.first : logos.first;
        final filePath = target['file_path'] as String?;
        if (filePath != null) {
          return '${ApiConstants.logoW500}$filePath';
        }
      }
    } catch (_) {}

    return null;
  }

  // ── Movie & TV Details with Credits & Similar ──────────────────────────────
  Future<MovieDetailsData> getMovieDetails(int movieId) async {
    try {
      final res = await _dio.get(
        '/movie/$movieId',
        queryParameters: {
          'append_to_response': 'credits,release_dates,similar',
        },
      );
      return MovieDetailsData.fromJson(res.data as Map<String, dynamic>);
    } catch (_) {
      // Fallback: If not found in movie endpoint (e.g. 404), fetch as TV show!
      return await getTvDetails(movieId);
    }
  }

  Future<MovieDetailsData> getTvDetails(int tvId) async {
    final res = await _dio.get(
      '/tv/$tvId',
      queryParameters: {
        'append_to_response': 'credits,similar,images',
      },
    );
    return MovieDetailsData.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<TvEpisodeData>> getTvSeasonEpisodes(int tvId, int seasonNumber) async {
    final res = await _dio.get('/tv/$tvId/season/$seasonNumber');
    final data = res.data as Map<String, dynamic>;
    final episodes = data['episodes'] as List<dynamic>? ?? [];
    return episodes
        .map((e) => TvEpisodeData.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Discover by Genre ─────────────────────────────────────────────────────

  Future<List<Movie>> getMoviesByGenre(int genreId, {int page = 1}) async {
    final res = await _dio.get(
      ApiConstants.discoverMovie,
      queryParameters: {
        'with_genres': genreId,
        'page': page,
        'sort_by': 'popularity.desc',
      },
    );
    return Movie.fromJsonList(res.data as Map<String, dynamic>);
  }

  // ── TV Series ─────────────────────────────────────────────────────────────

  Future<List<Movie>> getPopularTv({int page = 1}) async {
    final res = await _dio.get(
      ApiConstants.popularTv,
      queryParameters: {'page': page},
    );
    return Movie.fromJsonList(res.data as Map<String, dynamic>);
  }

  Future<List<Movie>> getTrendingTv({int page = 1}) async {
    final res = await _dio.get(
      ApiConstants.trendingTv,
      queryParameters: {'page': page},
    );
    return Movie.fromJsonList(res.data as Map<String, dynamic>);
  }

  Future<List<Movie>> getDiscoverTv({int page = 1}) async {
    try {
      final popular = await getPopularTv(page: page);
      if (popular.isNotEmpty) return popular;
    } catch (_) {}

    final res = await _dio.get(
      ApiConstants.discoverTv,
      queryParameters: {
        'page': page,
        'sort_by': 'popularity.desc',
      },
    );
    return Movie.fromJsonList(res.data as Map<String, dynamic>);
  }
}
