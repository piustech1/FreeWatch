import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
            // Remove mock-up seed notifications completely
            .where((n) => !n.id.startsWith('seed_') &&
                !n.message.contains('The Beekeeper') &&
                !n.message.contains('Deadpool & Wolverine'))
            .toList();
        state = items;
        _persistNotifications(state);
        return;
      }
    } catch (_) {}

    // Only genuine dynamic notifications are kept - default to empty state
    state = [];
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
