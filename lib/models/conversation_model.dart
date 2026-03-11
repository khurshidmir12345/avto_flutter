class ConversationModel {
  final int id;
  final ChatUserModel otherUser;
  final MessagePreviewModel? lastMessage;
  final String? lastMessageAt;
  final int unreadCount;

  ConversationModel({
    required this.id,
    required this.otherUser,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'] as int,
      otherUser: json['other_user'] != null
          ? ChatUserModel.fromJson(json['other_user'] as Map<String, dynamic>)
          : ChatUserModel(id: 0, name: 'Noma\'lum', phone: ''),
      lastMessage: json['last_message'] != null
          ? MessagePreviewModel.fromJson(json['last_message'] as Map<String, dynamic>)
          : null,
      lastMessageAt: json['last_message_at'] as String?,
      unreadCount: json['unread_count'] as int? ?? 0,
    );
  }
}

class ChatUserModel {
  final int id;
  final String name;
  final String phone;
  final String? avatarUrl;

  ChatUserModel({
    required this.id,
    required this.name,
    required this.phone,
    this.avatarUrl,
  });

  factory ChatUserModel.fromJson(Map<String, dynamic> json) {
    return ChatUserModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
    );
  }
}

class MessagePreviewModel {
  final int id;
  final String? body;
  final String type;
  final int senderId;
  final String? createdAt;

  MessagePreviewModel({
    required this.id,
    this.body,
    required this.type,
    required this.senderId,
    this.createdAt,
  });

  factory MessagePreviewModel.fromJson(Map<String, dynamic> json) {
    return MessagePreviewModel(
      id: json['id'] as int,
      body: json['body'] as String?,
      type: json['type'] as String? ?? 'text',
      senderId: (json['sender_id'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] as String?,
    );
  }

  String get previewText {
    switch (type) {
      case 'image':
        return '📷 Rasm';
      case 'voice':
        return '🎤 Ovozli xabar';
      default:
        return body ?? '';
    }
  }
}
