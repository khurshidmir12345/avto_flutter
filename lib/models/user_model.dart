class UserModel {
  final int id;
  final String name;
  final String phone;
  final String? phoneVerifiedAt;
  final String? createdAt;
  final String? updatedAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.phone,
    this.phoneVerifiedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      name: json['name'] as String,
      phone: json['phone'] as String,
      phoneVerifiedAt: json['phone_verified_at'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'phone_verified_at': phoneVerifiedAt,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
