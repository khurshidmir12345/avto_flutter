class ConversationMessageModel {
  final int id;
  final int conversationId;
  final int senderId;
  final String? body;
  final String type;
  final String? mediaUrl;
  final String? mediaMime;
  final bool readAt;
  final String? createdAt;

  ConversationMessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    this.body,
    required this.type,
    this.mediaUrl,
    this.mediaMime,
    required this.readAt,
    this.createdAt,
  });

  factory ConversationMessageModel.fromJson(Map<String, dynamic> json) {
    return ConversationMessageModel(
      id: json['id'] as int,
      conversationId: json['conversation_id'] as int,
      senderId: json['sender_id'] as int,
      body: json['body'] as String?,
      type: json['type'] as String? ?? 'text',
      mediaUrl: json['media_url'] as String?,
      mediaMime: json['media_mime'] as String?,
      readAt: json['read_at'] == true,
      createdAt: json['created_at'] as String?,
    );
  }

  bool get isImage => type == 'image';
  bool get isVoice => type == 'voice';
  bool get isText => type == 'text';
}
