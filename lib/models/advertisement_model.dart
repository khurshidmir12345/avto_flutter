class AdvertisementModel {
  final int id;
  final int userId;
  final String? userName;
  final String title;
  final String? description;
  final String? imageUrl;
  final String? imageKey;
  final String? link;
  final String status;
  final int days;
  final int dailyPrice;
  final int totalPrice;
  final int views;
  final String? startedAt;
  final String? expiresAt;
  final String? rejectionReason;
  final String? createdAt;
  final bool isActive;

  AdvertisementModel({
    required this.id,
    required this.userId,
    this.userName,
    required this.title,
    this.description,
    this.imageUrl,
    this.imageKey,
    this.link,
    required this.status,
    required this.days,
    required this.dailyPrice,
    required this.totalPrice,
    required this.views,
    this.startedAt,
    this.expiresAt,
    this.rejectionReason,
    this.createdAt,
    required this.isActive,
  });

  factory AdvertisementModel.fromJson(Map<String, dynamic> json) {
    return AdvertisementModel(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      userName: json['user_name'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      imageKey: json['image_key'] as String?,
      link: json['link'] as String?,
      status: json['status'] as String,
      days: (json['days'] as num?)?.toInt() ?? 1,
      dailyPrice: (json['daily_price'] as num?)?.toInt() ?? 0,
      totalPrice: (json['total_price'] as num?)?.toInt() ?? 0,
      views: (json['views'] as num?)?.toInt() ?? 0,
      startedAt: json['started_at'] as String?,
      expiresAt: json['expires_at'] as String?,
      rejectionReason: json['rejection_reason'] as String?,
      createdAt: json['created_at'] as String?,
      isActive: json['is_active'] as bool? ?? false,
    );
  }

  String get statusLabel => switch (status) {
    'pending' => 'Kutilmoqda',
    'approved' => 'Faol',
    'rejected' => 'Rad etilgan',
    'expired' => 'Muddati tugagan',
    'draft' => 'Qoralama',
    _ => status,
  };

  bool get canReactivate => status == 'expired' || status == 'rejected';
  bool get canDelete => status == 'pending' || status == 'draft';
}
