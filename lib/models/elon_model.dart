import 'elon_image_model.dart';

class ElonModel {
  final int id;
  final int? userId;
  final String? ownerName;
  final String? ownerPhone;
  final String? ownerAvatarUrl;
  final String marka;
  final String? model;
  final int yil;
  final int probeg;
  final String narx;
  final String valyuta;
  final String? rang;
  final String? yoqilgiTuri;
  final String? uzatishQutisi;
  final String? kraskaHolati;
  final String shahar;
  final String telefon;
  final String? tavsif;
  final bool? bankKredit;
  final bool? general;
  final String? holati;
  final int? categoryId;
  final String? categoryName;
  final List<ElonImageModel> images;

  const ElonModel({
    required this.id,
    this.userId,
    this.ownerName,
    this.ownerPhone,
    this.ownerAvatarUrl,
    required this.marka,
    this.model,
    required this.yil,
    required this.probeg,
    required this.narx,
    required this.valyuta,
    this.rang,
    this.yoqilgiTuri,
    this.uzatishQutisi,
    this.kraskaHolati,
    required this.shahar,
    required this.telefon,
    this.tavsif,
    this.bankKredit,
    this.general,
    this.holati,
    this.categoryId,
    this.categoryName,
    this.images = const [],
  });

  factory ElonModel.fromJson(Map<String, dynamic> json) {
    final imagesList = json['images'] as List<dynamic>? ?? [];
    final user = json['user'] as Map<String, dynamic>?;
    final category = json['category'] as Map<String, dynamic>?;
    return ElonModel(
      id: json['id'] as int,
      userId: user?['id'] as int? ?? json['user_id'] as int?,
      ownerName: user?['name'] as String?,
      ownerPhone: user?['phone'] as String?,
      ownerAvatarUrl: user?['avatar_url'] as String?,
      marka: json['marka'] as String,
      model: json['model'] as String?,
      yil: json['yil'] as int,
      probeg: json['probeg'] as int,
      narx: json['narx']?.toString() ?? '0',
      valyuta: json['valyuta'] as String? ?? 'USD',
      rang: json['rang'] as String?,
      yoqilgiTuri: json['yoqilgi_turi'] as String?,
      uzatishQutisi: json['uzatish_qutisi'] as String?,
      kraskaHolati: json['kraska_holati'] as String?,
      shahar: json['shahar'] as String,
      telefon: json['telefon'] as String,
      tavsif: json['tavsif'] as String?,
      bankKredit: json['bank_kredit'] as bool?,
      general: json['general'] as bool?,
      holati: json['holati'] as String?,
      categoryId: category?['id'] as int? ?? json['category_id'] as int?,
      categoryName: category?['name'] as String?,
      images: imagesList.map((e) => ElonImageModel.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  String get narxFormatted {
    final n = double.tryParse(narx) ?? 0;
    final s = n.toInt().toString();
    final sb = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) sb.write(' ');
      sb.write(s[i]);
    }
    return '${sb.toString()} $valyuta';
  }
}
