import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../data/models/movie.dart';

/// Provider for user's favorite / watchlist movies with user-scoped persistence
final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, List<Movie>>((ref) {
  return FavoritesNotifier();
});

class FavoritesNotifier extends StateNotifier<List<Movie>> {
  String? _currentUid;

  String get _storageKey => _currentUid != null
      ? 'freewatch_${_currentUid}_favorites'
      : 'freewatch_user_favorites';

  FavoritesNotifier() : super([]) {
    try {
      _currentUid = FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {}
    _loadFavorites();
  }

  /// Called whenever authentication state changes
  Future<void> syncWithUser(String? uid) async {
    if (_currentUid == uid && state.isNotEmpty) return;
    _currentUid = uid;
    await _loadFavorites();
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
        state = [];
      }
    } catch (_) {
      state = [];
    }

    // If logged in, also fetch from Firebase Realtime Database
    final uid = _currentUid;
    if (uid != null && uid.isNotEmpty) {
      try {
        final snapshot = await FirebaseDatabase.instance
            .ref('users/$uid/favorites')
            .get()
            .timeout(const Duration(seconds: 4));
        if (snapshot.exists && snapshot.value is List) {
          final list = (snapshot.value as List)
              .whereType<Map>()
              .map((e) => Movie.fromJson(Map<String, dynamic>.from(e)))
              .toList();
          if (list.isNotEmpty) {
            state = list;
            final prefs = await SharedPreferences.getInstance();
            final jsonList = state.map((m) => json.encode(m.toJson())).toList();
            await prefs.setStringList(_storageKey, jsonList);
          }
        }
      } catch (e) {
        debugPrint('RTDB load favorites notice: $e');
      }
    }
  }

  Future<void> _saveFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = state.map((m) => json.encode(m.toJson())).toList();
      await prefs.setStringList(_storageKey, jsonList);
    } catch (_) {}

    final uid = _currentUid;
    if (uid != null && uid.isNotEmpty) {
      try {
        final rawList = state.map((m) => m.toJson()).toList();
        await FirebaseDatabase.instance
            .ref('users/$uid/favorites')
            .set(rawList)
            .timeout(const Duration(seconds: 4));
      } catch (e) {
        debugPrint('RTDB save favorites notice: $e');
      }
    }
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
