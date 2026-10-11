import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../data/models/movie.dart';

class WatchHistoryNotifier extends StateNotifier<List<Movie>> {
  String? _currentUid;

  String get _storageKey => _currentUid != null
      ? 'freewatch_${_currentUid}_watch_history'
      : 'freewatch_user_watch_history';

  WatchHistoryNotifier() : super([]) {
    try {
      _currentUid = FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {}
    _loadHistory();
  }

  /// Called whenever authentication state changes
  Future<void> syncWithUser(String? uid) async {
    if (_currentUid == uid && state.isNotEmpty) return;
    _currentUid = uid;
    await _loadHistory();
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

    // If logged in, also fetch from Firebase Realtime Database
    final uid = _currentUid;
    if (uid != null && uid.isNotEmpty) {
      try {
        final snapshot = await FirebaseDatabase.instance
            .ref('users/$uid/watch_history')
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
        debugPrint('RTDB load watch history notice: $e');
      }
    }
  }

  Future<void> _saveHistory() async {
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
            .ref('users/$uid/watch_history')
            .set(rawList)
            .timeout(const Duration(seconds: 4));
      } catch (e) {
        debugPrint('RTDB save watch history notice: $e');
      }
    }
  }

  void addToHistory(Movie movie, {double? progress, int? positionSeconds}) {
    final updatedMovie = movie.copyWith(
      resumeProgress: progress ?? movie.resumeProgress ?? 0.0,
      resumePositionSeconds: positionSeconds ?? movie.resumePositionSeconds ?? 0,
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

  void clearAll() {
    state = [];
    _saveHistory();
  }
}

final watchHistoryProvider =
    StateNotifierProvider<WatchHistoryNotifier, List<Movie>>((ref) {
  return WatchHistoryNotifier();
});
