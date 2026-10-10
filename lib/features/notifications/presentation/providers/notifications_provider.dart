import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  // Empty initial list — zero fake mockup notifications
  NotificationsNotifier() : super([]);

  void addNotification(NotificationItem item) {
    // Avoid duplicate IDs
    if (state.any((n) => n.id == item.id)) return;
    state = [item, ...state];
  }

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

  void clearAll() {
    state = [];
  }
}
