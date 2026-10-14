import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/chat_message.dart';
import '../../../profile/presentation/providers/user_profile_provider.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/support_chat_notification_service.dart';

const String _prefKeyGuestChatUid = 'freewatch_guest_chat_uid';

class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;
  final String userId;

  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
    this.userId = '',
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? error,
    String? userId,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      userId: userId ?? this.userId,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  final Ref _ref;
  StreamSubscription<DatabaseEvent>? _firebaseSub;
  String _activeUid = '';

  ChatNotifier(this._ref) : super(const ChatState(isLoading: true)) {
    _initializeChat();
  }

  static const String _defaultWelcomeText =
      'Hello! 👋 Welcome to FreeWatch Support. How can we help you today? '
      'Feel free to ask about any movies, series, translation requests, or app features!';

  ChatMessage _createWelcomeMessage() {
    return ChatMessage(
      id: 'welcome_msg',
      senderId: 'admin',
      senderName: 'Admin',
      senderRole: 'admin',
      text: _defaultWelcomeText,
      timestamp: DateTime.now().millisecondsSinceEpoch - 60000,
      isRead: true,
    );
  }

  Future<void> _initializeChat() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Determine active UID (Firebase Auth or Persistent Guest UID)
      String? uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null || uid.isEmpty) {
        uid = prefs.getString(_prefKeyGuestChatUid);
        if (uid == null || uid.isEmpty) {
          uid = 'guest_${DateTime.now().millisecondsSinceEpoch}';
          await prefs.setString(_prefKeyGuestChatUid, uid);
        }
      }
      _activeUid = uid;
      state = state.copyWith(userId: _activeUid);

      // Subscribe to targeted FCM topic and start support chat listener
      NotificationService().subscribeToUserTopic(_activeUid);
      SupportChatNotificationService().startListening(_activeUid);

      // 1. Load locally cached messages
      final cacheKey = 'freewatch_chat_messages_$_activeUid';
      final cachedJsonList = prefs.getStringList(cacheKey);
      List<ChatMessage> localMessages = [];
      if (cachedJsonList != null && cachedJsonList.isNotEmpty) {
        try {
          localMessages = cachedJsonList
              .map((str) => ChatMessage.fromJson(jsonDecode(str) as Map<String, dynamic>))
              .toList();
        } catch (_) {}
      }

      if (localMessages.isEmpty) {
        localMessages = [_createWelcomeMessage()];
      }

      state = state.copyWith(
        messages: localMessages,
        isLoading: false,
      );

      // 2. Attach real-time Firebase Realtime Database listener
      _listenToFirebase();
    } catch (e) {
      if (state.messages.isEmpty) {
        state = state.copyWith(
          messages: [_createWelcomeMessage()],
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    }
  }

  void _listenToFirebase() {
    _firebaseSub?.cancel();
    if (_activeUid.isEmpty) return;

    try {
      final messagesRef = FirebaseDatabase.instance.ref('support_chats/$_activeUid/messages');
      _firebaseSub = messagesRef.onValue.listen((event) {
        final data = event.snapshot.value;
        if (data == null) {
          // If no messages on Firebase yet, keep welcome message
          if (state.messages.isEmpty) {
            final welcome = _createWelcomeMessage();
            state = state.copyWith(messages: [welcome]);
            _saveToCache([welcome]);
          }
          return;
        }

        final List<ChatMessage> fetched = [];
        if (data is Map) {
          data.forEach((key, val) {
            if (val is Map) {
              try {
                fetched.add(ChatMessage.fromJson(
                  Map<String, dynamic>.from(val),
                  key.toString(),
                ));
              } catch (_) {}
            }
          });
        } else if (data is List) {
          for (int i = 0; i < data.length; i++) {
            final val = data[i];
            if (val is Map) {
              try {
                fetched.add(ChatMessage.fromJson(
                  Map<String, dynamic>.from(val),
                  'msg_$i',
                ));
              } catch (_) {}
            }
          }
        }

        // Sort chronologically
        fetched.sort((a, b) => a.timestamp.compareTo(b.timestamp));

        // Ensure welcome message exists as first message if not already present
        if (fetched.isEmpty || !fetched.any((m) => m.id == 'welcome_msg' || m.senderRole == 'admin')) {
          fetched.insert(0, _createWelcomeMessage());
        }

        state = state.copyWith(messages: fetched);
        _saveToCache(fetched);
      }, onError: (err) {
        debugPrint('[ChatNotifier] Firebase listener error: $err');
      });
    } catch (e) {
      debugPrint('[ChatNotifier] Firebase init failed: $e');
    }
  }

  Future<void> sendMessage({
    required String text,
    ChatMessage? replyTo,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _activeUid.isEmpty) return;

    final profile = _ref.read(userProfileProvider);
    final userName = profile.name.isNotEmpty ? profile.name : 'FreeWatch User';

    String newMsgId = '';
    try {
      final pushRef = FirebaseDatabase.instance.ref('support_chats/$_activeUid/messages').push();
      newMsgId = pushRef.key ?? 'msg_${DateTime.now().millisecondsSinceEpoch}';
    } catch (_) {
      newMsgId = 'msg_${DateTime.now().millisecondsSinceEpoch}';
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final message = ChatMessage(
      id: newMsgId,
      senderId: _activeUid,
      senderName: userName,
      senderRole: 'user',
      text: trimmed,
      timestamp: now,
      replyToId: replyTo?.id,
      replyToSender: replyTo?.senderName,
      replyToText: replyTo?.text,
      isRead: false,
    );

    // Optimistically append to state
    final updated = List<ChatMessage>.from(state.messages)..add(message);
    state = state.copyWith(messages: updated);
    _saveToCache(updated);

    // Synchronize to Firebase Realtime Database
    try {
      final msgRef = FirebaseDatabase.instance.ref('support_chats/$_activeUid/messages/$newMsgId');
      await msgRef.set(message.toJson()).timeout(const Duration(seconds: 5));

      // Update thread metadata for Admin Panel
      final metaRef = FirebaseDatabase.instance.ref('support_chats/$_activeUid/metadata');
      await metaRef.update({
        'userId': _activeUid,
        'userName': userName,
        'lastMessage': trimmed,
        'lastTimestamp': now,
        'unreadCountAdmin': ServerValue.increment(1),
        'unreadCountUser': 0,
        'updatedAt': ServerValue.timestamp,
      }).timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('[ChatNotifier] Firebase sync error: $e');
    }
  }

  Future<void> _saveToCache(List<ChatMessage> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = 'freewatch_chat_messages_$_activeUid';
      final stringList = list.map((m) => jsonEncode(m.toJson())).toList();
      await prefs.setStringList(cacheKey, stringList);
    } catch (_) {}
  }

  @override
  void dispose() {
    _firebaseSub?.cancel();
    super.dispose();
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier(ref);
});
