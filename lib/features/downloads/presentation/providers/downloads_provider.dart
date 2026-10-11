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
            // Reset any item that was stuck in downloading state across app restarts to paused
            .map((e) {
              if (e.isDownloading) {
                return e.copyWith(
                  isDownloading: false,
                  isPaused: true,
                );
              }
              return e;
            })
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
      // Persist all items; if actively downloading, save as paused so app kill won't lose them
      final toSave = list.map((m) {
        if (m.isDownloading) {
          return m.copyWith(isDownloading: false, isPaused: true);
        }
        return m;
      }).toList();
      final encoded = jsonEncode(toSave.map((m) => m.toJson()).toList());
      await prefs.setString(_prefKeyDownloadedMovies, encoded);
    } catch (e) {
      debugPrint('Error persisting downloads: $e');
    }
  }

  bool isDownloaded(int movieId) {
    return state.any((m) =>
        m.id == movieId &&
        !m.isDownloading &&
        !m.isPaused &&
        m.downloadProgress >= 1.0 &&
        (m.localFilePath != null && File(m.localFilePath!).existsSync()));
  }

  bool isDownloading(int movieId) {
    return state.any((m) => m.id == movieId && m.isDownloading);
  }

  bool isPaused(int movieId) {
    return state.any((m) => m.id == movieId && (m.isPaused || m.isFailed));
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

    final rawUrl = movie.videoUrl != null && movie.videoUrl!.isNotEmpty
        ? movie.videoUrl!
        : 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4';
    final targetUrl = rawUrl.trim().replaceAll(' ', '%20');

    final existing = getDownloadedMovie(movie.id);

    final initialItem = existing?.copyWith(
          isDownloading: true,
          isPaused: false,
          isFailed: false,
          videoUrl: targetUrl,
        ) ??
        DownloadedMovie.fromMovie(
          movie,
          vjName: vjName ?? movie.vjName ?? 'VJ',
          videoUrl: targetUrl,
          isDownloading: true,
          isPaused: false,
          isFailed: false,
          downloadProgress: 0.05,
        );

    // Add or update downloading item in state
    state = [initialItem, ...state.where((m) => m.id != movie.id)];
    await _persistDownloads(state);

    _executeDownload(initialItem);
  }

  Future<void> resumeDownload(int movieId) async {
    final item = getDownloadedMovie(movieId);
    if (item == null || item.isDownloading) return;

    final activeItem = item.copyWith(
      isDownloading: true,
      isPaused: false,
      isFailed: false,
    );
    state = state.map((m) => m.id == movieId ? activeItem : m).toList();
    await _persistDownloads(state);

    _executeDownload(activeItem);
  }

  Future<void> pauseDownload(int movieId) async {
    final token = _cancelTokens[movieId];
    if (token != null && !token.isCancelled) {
      token.cancel('User paused download');
    }
    _cancelTokens.remove(movieId);

    state = state.map((m) {
      if (m.id == movieId) {
        return m.copyWith(isDownloading: false, isPaused: true);
      }
      return m;
    }).toList();
    await _persistDownloads(state);
  }

  Future<void> _executeDownload(DownloadedMovie item) async {
    final cancelToken = CancelToken();
    _cancelTokens[item.id] = cancelToken;

    try {
      final dir = await getApplicationDocumentsDirectory();
      final moviesDir = Directory('${dir.path}/movies');
      if (!await moviesDir.exists()) {
        await moviesDir.create(recursive: true);
      }

      final filePath = '${moviesDir.path}/${item.id}.mp4';
      final file = File(filePath);

      int existingBytes = 0;
      if (await file.exists()) {
        existingBytes = await file.length();
      }

      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(minutes: 60),
        ),
      );

      DateTime lastUiUpdate = DateTime.now();

      await dio.download(
        item.videoUrl,
        filePath,
        cancelToken: cancelToken,
        deleteOnError: false, // KEEP partial file for resuming!
        onReceiveProgress: (received, total) {
          if (total > 0) {
            final now = DateTime.now();
            final actualReceived = existingBytes + received;
            final actualTotal = existingBytes + total;
            final progress = (actualReceived / actualTotal).clamp(0.0, 1.0);

            if (now.difference(lastUiUpdate).inMilliseconds > 250 || received == total) {
              lastUiUpdate = now;
              state = state.map((m) {
                if (m.id == item.id) {
                  return m.copyWith(
                    downloadProgress: progress,
                    downloadedBytes: actualReceived,
                    totalBytes: actualTotal,
                    isDownloading: received < total,
                    isPaused: false,
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
      int sizeMb = item.fileSizeMb;
      if (await downloadedFile.exists()) {
        final bytes = await downloadedFile.length();
        if (bytes > 0) {
          sizeMb = (bytes / (1024 * 1024)).round();
          if (sizeMb < 1) sizeMb = 1;
        }
      }

      final completedItem = item.copyWith(
        localFilePath: filePath,
        isDownloading: false,
        isPaused: false,
        isFailed: false,
        downloadProgress: 1.0,
        fileSizeMb: sizeMb,
      );

      state = [
        completedItem,
        ...state.where((m) => m.id != item.id),
      ];
      await _persistDownloads(state);
    } catch (e) {
      debugPrint('Download interrupted for movie ${item.id}: $e');
      // DO NOT REMOVE FROM STATE! Mark as paused or interrupted with its saved progress
      state = state.map((m) {
        if (m.id == item.id) {
          return m.copyWith(
            isDownloading: false,
            isPaused: true,
            isFailed: cancelToken.isCancelled ? false : true,
            failureReason: cancelToken.isCancelled ? null : 'Network interrupted',
          );
        }
        return m;
      }).toList();
      await _persistDownloads(state);
    } finally {
      _cancelTokens.remove(item.id);
    }
  }

  Future<void> cancelDownload(int movieId) async {
    pauseDownload(movieId);
  }

  Future<void> removeDownload(int movieId) async {
    final token = _cancelTokens[movieId];
    if (token != null && !token.isCancelled) {
      token.cancel('User canceled download');
    }
    _cancelTokens.remove(movieId);

    final target = getDownloadedMovie(movieId);
    if (target?.localFilePath != null) {
      try {
        final f = File(target!.localFilePath!);
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
    for (final token in _cancelTokens.values) {
      if (!token.isCancelled) token.cancel();
    }
    _cancelTokens.clear();

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
