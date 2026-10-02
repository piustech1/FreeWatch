import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../data/models/movie.dart';
import '../../../../data/mock/mock_movies.dart';

/// Provider for user's favorite / watchlist movies
final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, List<Movie>>((ref) {
  return FavoritesNotifier();
});

class FavoritesNotifier extends StateNotifier<List<Movie>> {
  static const _storageKey = 'freewatch_user_favorites';

  FavoritesNotifier() : super([]) {
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList(_storageKey);
      if (jsonList != null && jsonList.isNotEmpty) {
        state = jsonList
            .map((item) => Movie.fromJson(json.decode(item) as Map<String, dynamic>))
            .toList();
      } else {
        // Seed with a couple of high-rated favorites initially
        state = [
          MockData.trendingMovies[1], // Dune 2
          MockData.trendingMovies[2], // Deadpool & Wolverine
        ];
        _saveFavorites();
      }
    } catch (_) {
      state = [
        MockData.trendingMovies[1],
        MockData.trendingMovies[2],
      ];
    }
  }

  Future<void> _saveFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = state.map((m) => json.encode(m.toJson())).toList();
      await prefs.setStringList(_storageKey, jsonList);
    } catch (_) {}
  }

  bool isFavorite(int movieId) {
    return state.any((m) => m.id == movieId);
  }

  void toggleFavorite(Movie movie) {
    if (isFavorite(movie.id)) {
      state = state.where((m) => m.id != movie.id).toList();
    } else {
      state = [movie, ...state];
    }
    _saveFavorites();
  }

  void removeFavorite(int movieId) {
    state = state.where((m) => m.id != movieId).toList();
    _saveFavorites();
  }

  void clearAll() {
    state = [];
    _saveFavorites();
  }
}
