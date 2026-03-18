class TelegramChannelModel {
  final int id;
  final String name;
  final String? username;
  final String? description;
  final String link;
  final String? avatarUrl;
  final int memberCount;

  const TelegramChannelModel({
    required this.id,
    required this.name,
    this.username,
    this.description,
    required this.link,
    this.avatarUrl,
    this.memberCount = 0,
  });

  factory TelegramChannelModel.fromJson(Map<String, dynamic> json) {
    return TelegramChannelModel(
      id: json['id'] as int,
      name: json['name'] as String,
      username: json['username'] as String?,
      description: json['description'] as String?,
      link: json['link'] as String,
      avatarUrl: json['avatar_url'] as String?,
      memberCount: (json['member_count'] as num?)?.toInt() ?? 0,
    );
  }
}
