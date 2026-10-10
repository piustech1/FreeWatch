import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/datasources/moviemax_datasource.dart';
import '../../features/notifications/data/models/notification_item.dart';
import '../../features/notifications/presentation/providers/notifications_provider.dart';
import 'notification_service.dart';

/// Monitors external MovieMax database for new movie uploads.
/// Throws rich device notifications with posters/backdrops and adds them to in-app tray.
class MovieNotificationTracker {
  static const String _prefKeyKnownIds = 'freewatch_known_movie_ids_v1';
  static const Duration _checkInterval = Duration(minutes: 30);

  final ProviderContainer _container;
  final MovieMaxDatasource _datasource;
  Timer? _periodicTimer;
  bool _isChecking = false;

  MovieNotificationTracker(this._container, {MovieMaxDatasource? datasource})
      : _datasource = datasource ?? MovieMaxDatasource();

  void startTracking() {
    // Initial check shortly after app boot
    Future.delayed(const Duration(seconds: 4), () {
      checkForNewMovies();
    });

    // Periodic background checking interval
    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(_checkInterval, (_) {
      checkForNewMovies();
    });
  }

  void stopTracking() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
  }

  Future<void> checkForNewMovies() async {
    if (_isChecking) return;
    _isChecking = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final storedIds = prefs.getStringList(_prefKeyKnownIds)?.toSet();

      final movies = await _datasource.getAllMovies(forceRefresh: true);
      if (movies.isEmpty) {
        _isChecking = false;
        return;
      }

      final currentIds = movies.map((m) => m.id.toString()).toSet();

      if (storedIds == null) {
        // First run: cache all existing movie IDs so we don't spam 1,500 notifications at once
        await prefs.setStringList(_prefKeyKnownIds, currentIds.toList());
        _isChecking = false;
        return;
      }

      // Detect newly uploaded movie IDs
      final newIds = currentIds.difference(storedIds);
      if (newIds.isNotEmpty) {
        final newMovies = movies.where((m) => newIds.contains(m.id.toString())).toList();

        // Dispatch notification for the new releases (up to 3 at a time)
        for (final movie in newMovies.take(3)) {
          final vj = movie.vjName?.isNotEmpty == true ? movie.vjName! : 'Luganda Dubbed';
          final title = movie.title;
          final body = 'New Release: $title translated by $vj is now streaming on FreeWatch!';
          final posterOrBackdrop = movie.backdropPath?.isNotEmpty == true
              ? (movie.backdropPath!.startsWith('http')
                  ? movie.backdropPath!
                  : 'https://image.tmdb.org/t/p/w780${movie.backdropPath}')
              : (movie.posterPath?.isNotEmpty == true
                  ? (movie.posterPath!.startsWith('http')
                      ? movie.posterPath!
                      : 'https://image.tmdb.org/t/p/w500${movie.posterPath}')
                  : null);

          // 1. Throw Rich OS-level Device Notification with Backdrop
          await NotificationService().showMovieNotification(
            id: movie.id.abs(),
            title: title,
            body: body,
            imageUrl: posterOrBackdrop,
            payload: movie.id.toString(),
          );

          // 2. Add to In-App Notifications Tray
          final notifItem = NotificationItem(
            id: 'movie_${movie.id}_${DateTime.now().millisecondsSinceEpoch}',
            section: 'Today',
            message: body,
            time: 'Just now',
            icon: Icons.movie_filter_rounded,
            iconColor: const Color(0xFF00E676),
            linkedMovie: movie,
          );
          _container.read(notificationsProvider.notifier).addNotification(notifItem);
        }

        // Update known IDs in local persistent storage
        final updatedIds = {...storedIds, ...newIds};
        await prefs.setStringList(_prefKeyKnownIds, updatedIds.toList());
      }
    } catch (e) {
      debugPrint('MovieNotificationTracker error: $e');
    } finally {
      _isChecking = false;
    }
  }
}
