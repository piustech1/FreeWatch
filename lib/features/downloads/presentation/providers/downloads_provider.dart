import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../data/models/downloaded_movie.dart';
import '../../../../data/models/movie.dart';

const String _prefKeyDownloadedMovies = 'freewatch_downloaded_movies_list_v1';

class DownloadsNotifier extends StateNotifier<List<DownloadedMovie>> {
  DownloadsNotifier() : super([]) {
    _loadDownloads();
  }

  Future<void> _loadDownloads() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedJson = prefs.getString(_prefKeyDownloadedMovies);

      if (savedJson != null && savedJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(savedJson) as List<dynamic>;
        final items = decoded
            .map((e) => DownloadedMovie.fromJson(e as Map<String, dynamic>))
            .toList();
        state = items;
        return;
      }
    } catch (_) {}

    state = [];
  }

  Future<void> _persistDownloads(List<DownloadedMovie> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(list.map((m) => m.toJson()).toList());
      await prefs.setString(_prefKeyDownloadedMovies, encoded);
    } catch (_) {}
  }

  bool isDownloaded(int movieId) {
    return state.any((m) => m.id == movieId);
  }

  Future<void> addDownload(Movie movie, {String? vjName}) async {
    if (isDownloaded(movie.id)) return;
    final item = DownloadedMovie.fromMovie(
      movie,
      vjName: vjName ?? 'VJ JUNIOR',
    );
    final updated = [item, ...state];
    state = updated;
    await _persistDownloads(updated);
  }

  Future<void> removeDownload(int movieId) async {
    final updated = state.where((m) => m.id != movieId).toList();
    state = updated;
    await _persistDownloads(updated);
  }

  Future<void> clearAllDownloads() async {
    state = [];
    await _persistDownloads([]);
  }

  int get totalSizeMb {
    return state.fold<int>(0, (acc, item) => acc + item.fileSizeMb);
  }

  String get formattedTotalStorage {
    final total = totalSizeMb;
    if (total >= 1000) {
      return '${(total / 1024).toStringAsFixed(1)} GB';
    }
    return '$total MB';
  }
}

final downloadsProvider =
    StateNotifierProvider<DownloadsNotifier, List<DownloadedMovie>>((ref) {
  return DownloadsNotifier();
});
