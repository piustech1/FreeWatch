import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../data/models/downloaded_movie.dart';
import '../../../../data/models/movie.dart';

const String _prefKeyDownloadedMovies = 'freewatch_downloaded_movies_list_v1';

class DownloadsNotifier extends StateNotifier<List<DownloadedMovie>> {
  final Map<int, CancelToken> _cancelTokens = {};

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
            // Reset any item that was stuck in downloading state across app restarts
            .map((e) => e.isDownloading ? e.copyWith(isDownloading: false) : e)
            .toList();
        state = items;
        return;
      }
    } catch (e) {
      debugPrint('Error loading downloads: $e');
    }

    state = [];
  }

  Future<void> _persistDownloads(List<DownloadedMovie> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final toSave = list.where((m) => !m.isDownloading).toList();
      final encoded = jsonEncode(toSave.map((m) => m.toJson()).toList());
      await prefs.setString(_prefKeyDownloadedMovies, encoded);
    } catch (e) {
      debugPrint('Error persisting downloads: $e');
    }
  }

  bool isDownloaded(int movieId) {
    return state.any((m) => m.id == movieId && !m.isDownloading && (m.localFilePath != null && File(m.localFilePath!).existsSync()));
  }

  bool isDownloading(int movieId) {
    return state.any((m) => m.id == movieId && m.isDownloading);
  }

  DownloadedMovie? getDownloadedMovie(int movieId) {
    try {
      return state.firstWhere((m) => m.id == movieId);
    } catch (_) {
      return null;
    }
  }

  Future<void> addDownload(Movie movie, {String? vjName}) async {
    return startDownload(movie, vjName: vjName);
  }

  Future<void> startDownload(Movie movie, {String? vjName}) async {
    if (isDownloaded(movie.id) || isDownloading(movie.id)) return;

    final targetUrl = movie.videoUrl != null && movie.videoUrl!.isNotEmpty
        ? movie.videoUrl!
        : 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4';

    final initialItem = DownloadedMovie.fromMovie(
      movie,
      vjName: vjName ?? movie.vjName ?? 'VJ JUNIOR',
      videoUrl: targetUrl,
      isDownloading: true,
      downloadProgress: 0.05,
    );

    // Add or update downloading item in state
    state = [initialItem, ...state.where((m) => m.id != movie.id)];

    final cancelToken = CancelToken();
    _cancelTokens[movie.id] = cancelToken;

    try {
      final dir = await getApplicationDocumentsDirectory();
      final moviesDir = Directory('${dir.path}/movies');
      if (!await moviesDir.exists()) {
        await moviesDir.create(recursive: true);
      }

      final filePath = '${moviesDir.path}/${movie.id}.mp4';

      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(minutes: 60),
        ),
      );

      DateTime lastUiUpdate = DateTime.now();

      await dio.download(
        targetUrl,
        filePath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            final now = DateTime.now();
            // Throttle UI updates to once every 250ms to keep UI silky smooth
            if (now.difference(lastUiUpdate).inMilliseconds > 250 || received == total) {
              lastUiUpdate = now;
              final progress = (received / total).clamp(0.0, 1.0);
              state = state.map((m) {
                if (m.id == movie.id) {
                  return m.copyWith(
                    downloadProgress: progress,
                    isDownloading: received < total,
                  );
                }
                return m;
              }).toList();
            }
          }
        },
      );

      // Verify file and size
      final downloadedFile = File(filePath);
      int sizeMb = initialItem.fileSizeMb;
      if (await downloadedFile.exists()) {
        final bytes = await downloadedFile.length();
        if (bytes > 0) {
          sizeMb = (bytes / (1024 * 1024)).round();
          if (sizeMb < 1) sizeMb = 1;
        }
      }

      final completedItem = initialItem.copyWith(
        localFilePath: filePath,
        isDownloading: false,
        downloadProgress: 1.0,
        fileSizeMb: sizeMb,
      );

      final updated = [
        completedItem,
        ...state.where((m) => m.id != movie.id),
      ];
      state = updated;
      await _persistDownloads(updated);
    } catch (e) {
      debugPrint('Download error for movie ${movie.id}: $e');
      // If cancelled or failed, remove from active state
      state = state.where((m) => m.id != movie.id).toList();
      _cancelTokens.remove(movie.id);
    } finally {
      _cancelTokens.remove(movie.id);
    }
  }

  Future<void> cancelDownload(int movieId) async {
    final token = _cancelTokens[movieId];
    if (token != null && !token.isCancelled) {
      token.cancel('User canceled download');
    }
    _cancelTokens.remove(movieId);
    state = state.where((m) => m.id != movieId).toList();
  }

  Future<void> removeDownload(int movieId) async {
    cancelDownload(movieId);
    final target = state.firstWhere(
      (m) => m.id == movieId,
      orElse: () => DownloadedMovie(
        id: -1,
        title: '',
        voteAverage: 0,
        fileSizeMb: 0,
        downloadedAt: DateTime.now(),
      ),
    );

    if (target.localFilePath != null) {
      try {
        final f = File(target.localFilePath!);
        if (await f.exists()) {
          await f.delete();
        }
      } catch (e) {
        debugPrint('Error deleting local file: $e');
      }
    }

    final updated = state.where((m) => m.id != movieId).toList();
    state = updated;
    await _persistDownloads(updated);
  }

  Future<void> clearAllDownloads() async {
    for (final m in state) {
      if (m.localFilePath != null) {
        try {
          final f = File(m.localFilePath!);
          if (await f.exists()) {
            await f.delete();
          }
        } catch (_) {}
      }
    }
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
