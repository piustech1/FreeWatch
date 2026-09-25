import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/movie.dart';
import '../../../data/models/genre.dart';
import '../../../data/repositories/movie_repository.dart';

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
