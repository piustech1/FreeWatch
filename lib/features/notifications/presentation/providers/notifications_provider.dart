import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/mock/mock_movies.dart';
import '../../data/models/notification_item.dart';

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, List<NotificationItem>>((ref) {
  return NotificationsNotifier();
});

final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationsProvider);
  return notifications.where((n) => !n.isRead).length;
});

class NotificationsNotifier extends StateNotifier<List<NotificationItem>> {
  NotificationsNotifier() : super(_initialNotifications);

  static List<NotificationItem> get _initialNotifications => [
        // ── Today ───────────────────────────────────────────────────────────
        NotificationItem(
          id: '1',
          section: 'Today',
          message: 'What if your next favorite movie is online right now?',
          time: '15m ago',
          icon: Icons.favorite_rounded,
          iconColor: const Color(0xFFFF2D55),
          linkedMovie: MockData.trendingMovies.isNotEmpty ? MockData.trendingMovies[0] : null,
          isRead: false,
        ),
        NotificationItem(
          id: '2',
          section: 'Today',
          message:
              'Choose who you want to watch! Certified Luganda VJ translations, 4K quality, new releases...',
          time: '2h ago',
          icon: Icons.grid_view_rounded,
          iconColor: const Color(0xFF34C759),
          linkedMovie: MockData.newMovies.length > 3 ? MockData.newMovies[3] : null,
          isRead: false,
        ),
        NotificationItem(
          id: '3',
          section: 'Today',
          message:
              '🎯 Target: Certified profiles! No need to compromise to make great streaming entertainment',
          time: '5h ago',
          icon: Icons.verified_rounded,
          iconColor: const Color(0xFF0A84FF),
          linkedMovie: MockData.trendingMovies.length > 2 ? MockData.trendingMovies[2] : null,
          isRead: true,
        ),

        // ── This week ───────────────────────────────────────────────────────
        NotificationItem(
          id: '4',
          section: 'This week',
          message: 'Meet top picks according to your mood and your interests',
          time: 'Yesterday',
          icon: Icons.grid_view_rounded,
          iconColor: const Color(0xFF34C759),
          linkedMovie: MockData.trendingMovies.length > 1 ? MockData.trendingMovies[1] : null,
          isRead: true,
        ),
        NotificationItem(
          id: '5',
          section: 'This week',
          message:
              'Find your next movie crush. Take a look at the latest hits FreeWatch fans crossed paths with!',
          time: '2 days ago',
          icon: Icons.favorite_rounded,
          iconColor: const Color(0xFFFF2D55),
          linkedMovie: MockData.newMovies.isNotEmpty ? MockData.newMovies[0] : null,
          isRead: true,
        ),
        const NotificationItem(
          id: '6',
          section: 'This week',
          message:
              'Explore the catalog and easily find the movies you love. Your next watch is right here',
          time: '3 days ago',
          icon: Icons.location_on_rounded,
          iconColor: Color(0xFF30D158),
          isRead: true,
        ),
        const NotificationItem(
          id: '7',
          section: 'This week',
          message:
              'Your future favorite series may have dropped at the same time as you 👀',
          time: '5 days ago',
          icon: Icons.favorite_rounded,
          iconColor: Color(0xFFFF2D55),
          isRead: true,
        ),
      ];

  void markAsRead(String id) {
    state = [
      for (final n in state)
        if (n.id == id) n.copyWith(isRead: true) else n,
    ];
  }

  void markAllAsRead() {
    state = [
      for (final n in state) n.copyWith(isRead: true),
    ];
  }

  void toggleRead(String id) {
    state = [
      for (final n in state)
        if (n.id == id) n.copyWith(isRead: !n.isRead) else n,
    ];
  }

  void deleteNotification(String id) {
    state = state.where((n) => n.id != id).toList();
  }
}
