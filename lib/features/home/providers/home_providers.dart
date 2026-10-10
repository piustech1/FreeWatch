import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/movie.dart';
import '../../../data/models/genre.dart';
import '../../../data/repositories/movie_repository.dart';

// ── Global Bottom Navigation Provider & Helper ─────────────────────────────

/// Active tab index on HomeScreen (0: Home, 1: Search, 2: Favorites, 3: Downloads, 4: Profile)
final bottomNavIndexProvider = StateProvider<int>((ref) => 0);

/// Navigates to a root bottom nav tab from any screen depth in a single atomic step
void navigateToBottomNavTab(BuildContext context, WidgetRef ref, int index) {
  ref.read(bottomNavIndexProvider.notifier).state = index;
  if (Navigator.of(context).canPop()) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}

// ── Repository provider ────────────────────────────────────────────────────

final movieRepositoryProvider = Provider<MovieRepository>(
  (ref) => MovieRepository(),
);

// ── Genre providers ────────────────────────────────────────────────────────

final genresProvider = FutureProvider<List<Genre>>((ref) async {
  return ref.watch(movieRepositoryProvider).getGenres();
});

/// Which genre chip is currently selected (null = All)
final selectedGenreProvider = StateProvider<int?>((ref) => null);

// ── Movie section providers ────────────────────────────────────────────────

final trendingMoviesProvider = FutureProvider<List<Movie>>((ref) async {
  return ref.watch(movieRepositoryProvider).getTrending();
});

final popularMoviesProvider = FutureProvider<List<Movie>>((ref) async {
  return ref.watch(movieRepositoryProvider).getPopular();
});

final topRatedMoviesProvider = FutureProvider<List<Movie>>((ref) async {
  return ref.watch(movieRepositoryProvider).getTopRated();
});

final nowPlayingMoviesProvider = FutureProvider<List<Movie>>((ref) async {
  return ref.watch(movieRepositoryProvider).getNowPlaying();
});

// ── Movie Logo provider ───────────────────────────────────────────────────

final movieLogoProvider = FutureProvider.family<String?, int>((ref, movieId) async {
  return ref.watch(movieRepositoryProvider).getMovieLogo(movieId);
});

// ── Specific named sections as requested by user ──────────────────────────

/// "Latest to Rewatch" section
final latestToRewatchProvider = FutureProvider<List<Movie>>((ref) async {
  return ref.watch(movieRepositoryProvider).getNowPlaying();
});

/// "Latest Uploads" section
final latestUploadsProvider = FutureProvider<List<Movie>>((ref) async {
  return ref.watch(movieRepositoryProvider).getPopular();
});

/// "Series" section
final seriesProvider = FutureProvider<List<Movie>>((ref) async {
  return ref.watch(movieRepositoryProvider).getSeries();
});

/// "Action" section (Genre ID 28)
final actionMoviesProvider = FutureProvider<List<Movie>>((ref) async {
  return ref.watch(movieRepositoryProvider).getMoviesByGenre(28);
});

/// "Sci-Fi" section (Genre ID 878)
final sciFiMoviesProvider = FutureProvider<List<Movie>>((ref) async {
  return ref.watch(movieRepositoryProvider).getMoviesByGenre(878);
});

/// "Romance" section (Genre ID 10749)
final romanceMoviesProvider = FutureProvider<List<Movie>>((ref) async {
  return ref.watch(movieRepositoryProvider).getMoviesByGenre(10749);
});

/// "Horror" section (Genre ID 27)
final horrorMoviesProvider = FutureProvider<List<Movie>>((ref) async {
  return ref.watch(movieRepositoryProvider).getMoviesByGenre(27);
});

/// "Drama" section (Genre ID 18)
final dramaMoviesProvider = FutureProvider<List<Movie>>((ref) async {
  return ref.watch(movieRepositoryProvider).getMoviesByGenre(18);
});

/// "Animation" section (Genre ID 16)
final animationMoviesProvider = FutureProvider<List<Movie>>((ref) async {
  return ref.watch(movieRepositoryProvider).getMoviesByGenre(16);
});

/// "Family" section (Genre ID 10751)
final familyMoviesProvider = FutureProvider<List<Movie>>((ref) async {
  return ref.watch(movieRepositoryProvider).getMoviesByGenre(10751);
});

/// Dedicated VJ movies provider (combining MovieMax live translated movies with MockData)
final vjMoviesProvider = FutureProvider.family<List<Movie>, String>((ref, vjId) async {
  return ref.watch(movieRepositoryProvider).getMoviesByVj(vjId);
});

