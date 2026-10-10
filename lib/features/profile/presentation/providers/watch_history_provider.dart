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

  void addToHistory(Movie movie, {double? progress, int? positionSeconds}) {
    final updatedMovie = movie.copyWith(
      resumeProgress: progress ?? movie.resumeProgress ?? 0.15,
      resumePositionSeconds: positionSeconds ?? movie.resumePositionSeconds ?? 120,
    );
    state = [
      updatedMovie,
      ...state.where((m) => m.id != movie.id),
    ];
    _saveHistory();
  }

  void updateProgress(int movieId, double progress, int positionSeconds) {
    state = state.map((m) {
      if (m.id == movieId) {
        return m.copyWith(
          resumeProgress: progress,
          resumePositionSeconds: positionSeconds,
        );
      }
      return m;
    }).toList();
    _saveHistory();
  }
}

final watchHistoryProvider =
    StateNotifierProvider<WatchHistoryNotifier, List<Movie>>((ref) {
  return WatchHistoryNotifier();
});
