import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../data/models/movie.dart';

class WatchHistoryNotifier extends StateNotifier<List<Movie>> {
  static const _storageKey = 'freewatch_user_watch_history';

  WatchHistoryNotifier() : super([]) {
    _loadHistory();
  }

  Future<void> _loadHistory() async {
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
  }

  Future<void> _saveHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = state.map((m) => json.encode(m.toJson())).toList();
      await prefs.setStringList(_storageKey, jsonList);
    } catch (_) {}
  }

  void addToHistory(Movie movie) {
    state = [
      movie,
      ...state.where((m) => m.id != movie.id),
    ];
    _saveHistory();
  }
}

final watchHistoryProvider =
    StateNotifierProvider<WatchHistoryNotifier, List<Movie>>((ref) {
  return WatchHistoryNotifier();
});
