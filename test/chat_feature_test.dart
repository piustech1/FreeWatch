import 'package:flutter_test/flutter_test.dart';
import 'package:freewatch/features/chat/domain/models/chat_message.dart';
import 'package:freewatch/features/chat/presentation/providers/chat_provider.dart';

void main() {
  group('ChatMessage Unit Tests', () {
    test('ChatMessage json serialization and deserialization works correctly', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      final msg = ChatMessage(
        id: 'msg_101',
        senderId: 'user_123',
        senderName: 'John Doe',
        senderRole: 'user',
        text: 'Can we get more action series translated by VJ Junior?',
        timestamp: now,
        replyToId: 'welcome_msg',
        replyToSender: 'Admin',
        replyToText: 'Welcome to FreeWatch Support!',
        isRead: false,
      );

      final json = msg.toJson();
      expect(json['id'], equals('msg_101'));
      expect(json['senderRole'], equals('user'));
      expect(json['replyToSender'], equals('Admin'));

      final restored = ChatMessage.fromJson(json);
      expect(restored.id, equals('msg_101'));
      expect(restored.isFromUser, isTrue);
      expect(restored.isFromAdmin, isFalse);
      expect(restored.replyToSender, equals('Admin'));
      expect(restored.replyToText, equals('Welcome to FreeWatch Support!'));
    });

    test('ChatMessage copyWith preserves and updates fields', () {
      const msg = ChatMessage(
        id: 'msg_1',
        senderId: 'admin',
        senderName: 'Admin',
        senderRole: 'admin',
        text: 'Hello!',
        timestamp: 123456,
      );

      expect(msg.isFromAdmin, isTrue);
      expect(msg.isFromUser, isFalse);

      final updated = msg.copyWith(text: 'Updated message', isRead: true);
      expect(updated.text, equals('Updated message'));
      expect(updated.isRead, isTrue);
      expect(updated.senderName, equals('Admin'));
    });

    test('ChatState default and copyWith work properly', () {
      const state = ChatState(isLoading: true);
      expect(state.isLoading, isTrue);
      expect(state.messages.isEmpty, isTrue);

      final updated = state.copyWith(
        isLoading: false,
        userId: 'user_999',
        messages: const [
          ChatMessage(
            id: '1',
            senderId: 'admin',
            senderName: 'Admin',
            senderRole: 'admin',
            text: 'Welcome',
            timestamp: 100,
          ),
        ],
      );

      expect(updated.isLoading, isFalse);
      expect(updated.userId, equals('user_999'));
      expect(updated.messages.length, equals(1));
    });
  });
}
