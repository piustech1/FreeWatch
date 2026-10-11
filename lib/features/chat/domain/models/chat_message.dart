class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String senderRole; // 'user' or 'admin'
  final String text;
  final int timestamp;
  final String? replyToId;
  final String? replyToSender;
  final String? replyToText;
  final bool isRead;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.text,
    required this.timestamp,
    this.replyToId,
    this.replyToSender,
    this.replyToText,
    this.isRead = false,
  });

  bool get isFromUser => senderRole == 'user';
  bool get isFromAdmin => senderRole == 'admin';

  ChatMessage copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? senderRole,
    String? text,
    int? timestamp,
    String? replyToId,
    String? replyToSender,
    String? replyToText,
    bool? isRead,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderRole: senderRole ?? this.senderRole,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      replyToId: replyToId ?? this.replyToId,
      replyToSender: replyToSender ?? this.replyToSender,
      replyToText: replyToText ?? this.replyToText,
      isRead: isRead ?? this.isRead,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'senderRole': senderRole,
      'text': text,
      'timestamp': timestamp,
      if (replyToId != null) 'replyToId': replyToId,
      if (replyToSender != null) 'replyToSender': replyToSender,
      if (replyToText != null) 'replyToText': replyToText,
      'isRead': isRead,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json, [String? fallbackId]) {
    final senderRole = (json['senderRole'] ?? (json['isFromUser'] == false ? 'admin' : 'user')).toString();
    return ChatMessage(
      id: (json['id'] ?? fallbackId ?? '').toString(),
      senderId: (json['senderId'] ?? '').toString(),
      senderName: (json['senderName'] ?? (senderRole == 'admin' ? 'Admin' : 'User')).toString(),
      senderRole: senderRole,
      text: (json['text'] ?? '').toString(),
      timestamp: json['timestamp'] is int
          ? json['timestamp'] as int
          : (json['timestamp'] is num
              ? (json['timestamp'] as num).toInt()
              : DateTime.now().millisecondsSinceEpoch),
      replyToId: json['replyToId']?.toString(),
      replyToSender: json['replyToSender']?.toString(),
      replyToText: json['replyToText']?.toString(),
      isRead: json['isRead'] == true || json['read'] == true,
    );
  }
}
