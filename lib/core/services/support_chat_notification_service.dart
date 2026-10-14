import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';

/// Real-time service watching user support chat threads.
/// When an Admin replies to the user, this fires an instant OS notification
/// and app notification item, routing the user directly to /developer-chat upon click.
class SupportChatNotificationService {
  static final SupportChatNotificationService _instance =
      SupportChatNotificationService._internal();
  factory SupportChatNotificationService() => _instance;
  SupportChatNotificationService._internal();

  /// Static state tracking whether user currently has DeveloperChatScreen open
  static bool isChatScreenVisible = false;

  StreamSubscription<DatabaseEvent>? _messagesSubscription;
  String? _activeUid;
  final int _initTimestamp = DateTime.now().millisecondsSinceEpoch - 2000;
  final Set<String> _notifiedMessageIds = {};

  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null || uid.isEmpty) {
        uid = prefs.getString('freewatch_guest_chat_uid');
      }

      if (uid != null && uid.isNotEmpty) {
        startListening(uid);
      }

      // Also observe Firebase Auth changes to re-bind when user logs in or out
      FirebaseAuth.instance.authStateChanges().listen((user) {
        if (user != null) {
          startListening(user.uid);
        }
      });
    } catch (e) {
      debugPrint('[SupportChatNotificationService] Init notice: $e');
    }
  }

  void startListening(String uid) {
    if (_activeUid == uid && _messagesSubscription != null) return;
    _activeUid = uid;
    _messagesSubscription?.cancel();

    try {
      // Also subscribe to FCM topic for this specific user
      NotificationService().subscribeToUserTopic(uid);

      final messagesRef = FirebaseDatabase.instance.ref('support_chats/$uid/messages');
      _messagesSubscription = messagesRef.onChildAdded.listen((event) {
        final val = event.snapshot.value;
        if (val is! Map) return;

        final messageMap = Map<String, dynamic>.from(val);
        final msgId = event.snapshot.key ?? messageMap['id']?.toString() ?? '';
        final senderRole = messageMap['senderRole']?.toString();
        final timestamp = (messageMap['timestamp'] as num?)?.toInt() ?? 0;
        final text = messageMap['text']?.toString() ?? '';

        // Only alert on new admin messages received after service start
        if (senderRole == 'admin' &&
            timestamp > _initTimestamp &&
            !_notifiedMessageIds.contains(msgId)) {
          _notifiedMessageIds.add(msgId);

          // If user is not currently inside DeveloperChatScreen, display device notification
          if (!isChatScreenVisible) {
            _dispatchNotification(
              id: msgId,
              text: text.isNotEmpty ? text : 'New reply from FreeWatch Support',
            );
          }
        }
      }, onError: (err) {
        debugPrint('[SupportChatNotificationService] Listener error: $err');
      });
    } catch (e) {
      debugPrint('[SupportChatNotificationService] startListening error: $e');
    }
  }

  Future<void> _dispatchNotification({
    required String id,
    required String text,
  }) async {
    try {
      await persistToAppNotificationCenter(
        id: 'admin_chat_$id',
        title: 'FreeWatch Live Support',
        message: text,
        link: '/developer-chat',
      );

      await NotificationService().showSupportChatNotification(
        id: id.hashCode,
        title: '💬 FreeWatch Live Support',
        body: text,
        payload: '/developer-chat',
      );
    } catch (e) {
      debugPrint('[SupportChatNotificationService] Dispatch error: $e');
    }
  }

  void dispose() {
    _messagesSubscription?.cancel();
    _messagesSubscription = null;
  }
}
