/// TMDB API constants
/// Replace [tmdbApiKey] with your actual TMDB v3 API key from:
/// https://www.themoviedb.org/settings/api
class ApiConstants {
  ApiConstants._();

  // ── TMDB ──────────────────────────────────────────────────────────────────
  static const String tmdbApiKey = 'YOUR_TMDB_API_KEY'; // 🔑 Replace this
  static const String tmdbBaseUrl = 'https://api.themoviedb.org/3';
  static const String tmdbImageBaseUrl = 'https://image.tmdb.org/t/p';

  // Image sizes
  static const String posterW200 = '$tmdbImageBaseUrl/w200';
  static const String posterW342 = '$tmdbImageBaseUrl/w342';
  static const String posterW500 = '$tmdbImageBaseUrl/w500';
  static const String backdropW780 = '$tmdbImageBaseUrl/w780';
  static const String backdropOriginal = '$tmdbImageBaseUrl/original';

  // Endpoints
  static const String trendingMovies = '/trending/movie/week';
  static const String popularMovies = '/movie/popular';
  static const String topRatedMovies = '/movie/top_rated';
  static const String nowPlayingMovies = '/movie/now_playing';
  static const String upcomingMovies = '/movie/upcoming';
  static const String movieDetails = '/movie/{id}';
  static const String movieCredits = '/movie/{id}/credits';
  static const String similarMovies = '/movie/{id}/similar';
  static const String searchMovies = '/search/movie';
  static const String genres = '/genre/movie/list';
}
