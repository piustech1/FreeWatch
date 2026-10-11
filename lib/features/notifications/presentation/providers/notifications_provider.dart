import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../data/mock/mock_movies.dart';
import '../../data/models/notification_item.dart';

const String _prefKeyNotifications = 'freewatch_user_notifications_v1';

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, List<NotificationItem>>((ref) {
  return NotificationsNotifier();
});

final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationsProvider);
  return notifications.where((n) => !n.isRead).length;
});

class NotificationsNotifier extends StateNotifier<List<NotificationItem>> {
  NotificationsNotifier() : super([]) {
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedJson = prefs.getString(_prefKeyNotifications);
      if (savedJson != null && savedJson.isNotEmpty) {
        final List<dynamic> list = jsonDecode(savedJson) as List<dynamic>;
        final items = list
            .map((e) => NotificationItem.fromJson(e as Map<String, dynamic>))
            .toList();
        if (items.isNotEmpty) {
          state = items;
          return;
        }
      }
    } catch (_) {}

    // Initial seed notifications with rich posters from catalog
    final beekeeper = MockData.trendingMovies.firstWhere((m) => m.id == 1011985);
    final deadpool = MockData.trendingMovies.firstWhere((m) => m.id == 533535);

    state = [
      NotificationItem(
        id: 'seed_1011985',
        section: 'Today',
        message: 'New Release: The Beekeeper translated by VJ Kevin is now streaming in 1080p Full HD!',
        time: '2h ago',
        icon: Icons.movie_filter_rounded,
        iconColor: const Color(0xFFC084FC),
        linkedMovie: beekeeper,
        imageUrl: beekeeper.posterUrl,
        isRead: false,
      ),
      NotificationItem(
        id: 'seed_533535',
        section: 'This week',
        message: 'Trending: Deadpool & Wolverine translated by VJ Junior is now available in Luganda voiceover!',
        time: '1d ago',
        icon: Icons.local_fire_department_rounded,
        iconColor: const Color(0xFFEF4444),
        linkedMovie: deadpool,
        imageUrl: deadpool.posterUrl,
        isRead: false,
      ),
    ];
    _persistNotifications(state);
  }

  Future<void> _persistNotifications(List<NotificationItem> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(items.map((e) => e.toJson()).toList());
      await prefs.setString(_prefKeyNotifications, jsonStr);
    } catch (_) {}
  }

  void addNotification(NotificationItem item) {
    if (state.any((n) => n.id == item.id)) return;
    state = [item, ...state];
    _persistNotifications(state);
  }

  void markAsRead(String id) {
    state = [
      for (final n in state)
        if (n.id == id) n.copyWith(isRead: true) else n,
    ];
    _persistNotifications(state);
  }

  void markAllAsRead() {
    state = [
      for (final n in state) n.copyWith(isRead: true),
    ];
    _persistNotifications(state);
  }

  void toggleRead(String id) {
    state = [
      for (final n in state)
        if (n.id == id) n.copyWith(isRead: !n.isRead) else n,
    ];
    _persistNotifications(state);
  }

  void deleteNotification(String id) {
    state = state.where((n) => n.id != id).toList();
    _persistNotifications(state);
  }

  void clearAll() {
    state = [];
    _persistNotifications(state);
  }
}
