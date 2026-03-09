class UserModel {
  final int id;
  final String name;
  final String phone;
  final int balance;
  final String? avatarIcon;
  final String? avatarUrl;
  final String? phoneVerifiedAt;
  final String? createdAt;
  final String? updatedAt;
  final int? telegramUserId;
  final String? telegramUsername;
  final String? telegramFirstName;
  final String? telegramLastName;

  const UserModel({
    required this.id,
    required this.name,
    required this.phone,
    this.balance = 0,
    this.avatarIcon,
    this.avatarUrl,
    this.phoneVerifiedAt,
    this.createdAt,
    this.updatedAt,
    this.telegramUserId,
    this.telegramUsername,
    this.telegramFirstName,
    this.telegramLastName,
  });

  bool get hasTelegramLinked => telegramUserId != null;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      name: json['name'] as String,
      phone: json['phone'] as String,
      balance: (json['balance'] as num?)?.toInt() ?? 0,
      avatarIcon: json['avatar_icon'] as String?,
      avatarUrl: (json['avatar_url'] ?? json['avat_url']) as String?,
      phoneVerifiedAt: json['phone_verified_at'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      telegramUserId: (json['telegram_user_id'] as num?)?.toInt(),
      telegramUsername: json['telegram_username'] as String?,
      telegramFirstName: json['telegram_first_name'] as String?,
      telegramLastName: json['telegram_last_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'balance': balance,
      'avatar_icon': avatarIcon,
      'avatar_url': avatarUrl,
      'phone_verified_at': phoneVerifiedAt,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'telegram_user_id': telegramUserId,
      'telegram_username': telegramUsername,
      'telegram_first_name': telegramFirstName,
      'telegram_last_name': telegramLastName,
    };
  }
}
