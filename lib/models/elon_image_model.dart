import '../utils/constants.dart';

class ElonImageModel {
  final int id;
  final int? moshinaElonId;
  final String path;
  final String url;
  final int sortOrder;

  const ElonImageModel({
    required this.id,
    this.moshinaElonId,
    required this.path,
    required this.url,
    this.sortOrder = 0,
  });

  factory ElonImageModel.fromJson(Map<String, dynamic> json) {
    // Yangi format: original, thumb
    final original = json['original'] as String?;
    final thumb = json['thumb'] as String?;
    var url = original ?? thumb ?? json['url'] as String? ?? json['full_url'] as String? ?? '';
    if (url.isNotEmpty && !url.startsWith('http')) {
      final prefix = ApiConstants.imagePathPrefix;
      final path = url.startsWith('/') ? url : '/$url';
      url = '${ApiConstants.imageBaseUrl}$prefix$path';
    }
    final idRaw = json['id'];
    final id = idRaw is int ? idRaw : int.tryParse(idRaw?.toString() ?? '0') ?? 0;
    return ElonImageModel(
      id: id,
      moshinaElonId: json['moshina_elon_id'] as int?,
      path: json['path'] as String? ?? '',
      url: url,
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }
}
