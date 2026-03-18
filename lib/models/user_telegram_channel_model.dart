class UserTelegramChannelModel {
  final int id;
  final String chatId;
  final String? channelName;
  final String? channelUsername;
  final String? messageTemplate;
  final String? footerText;
  final bool isActive;
  final String? lastErrorAt;
  final String? lastErrorMessage;
  final String? createdAt;

  const UserTelegramChannelModel({
    required this.id,
    required this.chatId,
    this.channelName,
    this.channelUsername,
    this.messageTemplate,
    this.footerText,
    this.isActive = true,
    this.lastErrorAt,
    this.lastErrorMessage,
    this.createdAt,
  });

  bool get hasError => lastErrorAt != null && lastErrorMessage != null;

  factory UserTelegramChannelModel.fromJson(Map<String, dynamic> json) {
    return UserTelegramChannelModel(
      id: json['id'] as int,
      chatId: json['chat_id'] as String,
      channelName: json['channel_name'] as String?,
      channelUsername: json['channel_username'] as String?,
      messageTemplate: json['message_template'] as String?,
      footerText: json['footer_text'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      lastErrorAt: json['last_error_at'] as String?,
      lastErrorMessage: json['last_error_message'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }

  static const defaultTemplate = '''♻️ {hashtag} Сотилади ♻️

🚗 Модел: {marka} {model}
📆 Йил: {yil} йил
📏 Пробег: {probeg}
💰 Нархи: {narx}
📞 Тел: +{telefon}
📍 Манзил: {shahar}

{footer}

👉 Кўриш: {link}''';

  static const placeholders = [
    '{marka}',
    '{model}',
    '{yil}',
    '{probeg}',
    '{narx}',
    '{valyuta}',
    '{telefon}',
    '{shahar}',
    '{rang}',
    '{yoqilgi}',
    '{uzatish}',
    '{link}',
    '{hashtag}',
    '{footer}',
  ];

  static const placeholderDescriptions = {
    '{marka}': 'Avtomobil markasi',
    '{model}': 'Avtomobil modeli',
    '{yil}': 'Ishlab chiqarilgan yili',
    '{probeg}': 'Yurgan masofasi',
    '{narx}': 'Narxi (formatlangan)',
    '{valyuta}': 'Valyuta (USD/UZS)',
    '{telefon}': 'Telefon raqam',
    '{shahar}': 'Shahar/manzil',
    '{rang}': 'Rangi',
    '{yoqilgi}': "Yoqilg'i turi",
    '{uzatish}': 'Uzatish qutisi',
    '{link}': "E'lon havolasi",
    '{hashtag}': 'Avtomatik hashtag',
    '{footer}': "Siz kiritgan taglavha (footer)",
  };
}
