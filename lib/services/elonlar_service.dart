import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/elon_model.dart';
import '../utils/constants.dart';
import 'storage_service.dart';

class ElonlarService {
  Map<String, String> get _headers => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

  Future<Map<String, String>> _authHeaders() async {
    final token = await StorageService.getToken();
    return {
      ..._headers,
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<({List<ElonModel> items, String? error})> getList({
    int? categoryId,
    String? marka,
    String? model,
    String? search,
    String? shahar,
    String? yoqilgiTuri,
    int? narxMin,
    int? narxMax,
    int? yilMin,
    int? yilMax,
    int page = 1,
    int perPage = 15,
  }) async {
    try {
      final query = <String, String>{
        'page': page.toString(),
        'per_page': perPage.toString(),
      };
      if (categoryId != null) query['category_id'] = categoryId.toString();
      if (marka != null && marka.isNotEmpty) query['marka'] = marka;
      if (model != null && model.isNotEmpty) query['model'] = model;
      if (search != null && search.isNotEmpty) query['search'] = search;
      if (shahar != null && shahar.isNotEmpty) query['shahar'] = shahar;
      if (yoqilgiTuri != null && yoqilgiTuri.isNotEmpty) query['yoqilgi_turi'] = yoqilgiTuri;
      if (narxMin != null) query['narx_min'] = narxMin.toString();
      if (narxMax != null) query['narx_max'] = narxMax.toString();
      if (yilMin != null) query['yil_min'] = yilMin.toString();
      if (yilMax != null) query['yil_max'] = yilMax.toString();

      final uri = Uri.parse(ApiConstants.elonlarUrl).replace(queryParameters: query);
      final response = await http.get(uri, headers: _headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rawList = data['data'] as List? ?? [];
        final list = rawList.map((e) => ElonModel.fromJson(e as Map<String, dynamic>)).toList();
        return (items: list, error: null);
      }
      return (items: <ElonModel>[], error: 'Server xatosi: ${response.statusCode}');
    } on SocketException {
      return (items: <ElonModel>[], error: 'Serverga ulanib bo\'lmadi. Internet aloqasini tekshiring.');
    } catch (e) {
      return (items: <ElonModel>[], error: 'Kutilmagan xatolik: $e');
    }
  }

  Future<ElonModel?> getById(int id) async {
    final response = await http.get(
      Uri.parse(ApiConstants.elonlarDetail(id)),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return ElonModel.fromJson(data['elon'] as Map<String, dynamic>);
    }
    return null;
  }

  Future<({bool success, String message, ElonModel? elon})> create(Map<String, dynamic> body) async {
    try {
      final headers = await _authHeaders();
      final response = await http.post(
        Uri.parse(ApiConstants.elonlarUrl),
        headers: headers,
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return (success: true, message: data['message'] as String, elon: ElonModel.fromJson(data['elon']));
      }

      final errors = data['errors'] as Map<String, dynamic>?;
      final msg = errors?.values.first is List
          ? (errors!.values.first as List).first as String
          : data['message'] as String;
      return (success: false, message: msg, elon: null);
    } catch (e) {
      return (success: false, message: 'Serverga ulanib bo\'lmadi', elon: null);
    }
  }

  /// Rasmlarni e'londan oldin yuklash (presigned URL flow). image_ids qaytaradi.
  Future<({bool success, String message, List<int> imageIds})> uploadImagesBeforeElon(
      List<String> filePaths) async {
    try {
      final token = await StorageService.getToken();
      if (token == null) return (success: false, message: 'Avval kirish kerak', imageIds: <int>[]);

      // 1. Content type larni aniqlash
      final contentTypes = <String>[];
      for (final path in filePaths) {
        final ext = path.split('.').last.toLowerCase();
        contentTypes.add(ext == 'png' ? 'image/png' : 'image/jpeg');
      }

      // 2. Presigned URL lar olish
      final headers = await _authHeaders();
      final presignedRes = await http.post(
        Uri.parse(ApiConstants.imagesPresignedUrl),
        headers: headers,
        body: jsonEncode({'content_types': contentTypes}),
      );

      if (presignedRes.statusCode != 200) {
        final data = jsonDecode(presignedRes.body);
        final msg = data['message'] as String? ?? data['errors']?.toString() ?? 'Xatolik';
        return (success: false, message: msg, imageIds: <int>[]);
      }

      final presignedData = jsonDecode(presignedRes.body);
      final urls = presignedData['urls'] as List<dynamic>? ?? [];
      if (urls.length != filePaths.length) {
        return (success: false, message: 'Presigned URL lar soni mos kelmadi', imageIds: <int>[]);
      }

      // 3. Har bir rasmni R2 ga yuklash
      for (var i = 0; i < filePaths.length; i++) {
        final file = File(filePaths[i]);
        final bytes = await file.readAsBytes();
        final uploadUrl = (urls[i] as Map<String, dynamic>)['upload_url'] as String;
        final contentType = contentTypes[i];
        final putRes = await http.put(
          Uri.parse(uploadUrl),
          headers: {'Content-Type': contentType},
          body: bytes,
        ).timeout(const Duration(seconds: 30));
        if (putRes.statusCode != 200 && putRes.statusCode != 204) {
          return (success: false, message: 'Rasm yuklashda xatolik', imageIds: <int>[]);
        }
      }

      // 4. image_key larni saqlash
      final imageKeys = urls.map((u) => (u as Map<String, dynamic>)['image_key'] as String).toList();
      final saveRes = await http.post(
        Uri.parse(ApiConstants.imagesSaveUrl),
        headers: headers,
        body: jsonEncode({'image_keys': imageKeys}),
      );

      if (saveRes.statusCode != 201) {
        final data = jsonDecode(saveRes.body);
        final msg = data['message'] as String? ?? data['errors']?.toString() ?? 'Xatolik';
        return (success: false, message: msg, imageIds: <int>[]);
      }

      final saveData = jsonDecode(saveRes.body);
      final images = saveData['images'] as List<dynamic>? ?? [];
      final ids = images.map((e) {
        final id = (e as Map<String, dynamic>)['id'];
        return id is int ? id : int.tryParse(id?.toString() ?? '0') ?? 0;
      }).toList();
      return (success: true, message: saveData['message'] as String, imageIds: ids);
    } catch (e) {
      return (success: false, message: 'Serverga ulanib bo\'lmadi: $e', imageIds: <int>[]);
    }
  }

  /// Yuklanmagan rasmni o'chirish (e'lon yaratilishidan oldin)
  Future<bool> deleteUnlinkedImage(int imageId) async {
    try {
      final headers = await _authHeaders();
      final response = await http.delete(
        Uri.parse(ApiConstants.imageDeleteUrl(imageId)),
        headers: headers,
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// E'longa qo'shimcha rasm yuklash (e'lon yaratilgandan keyin, presigned URL flow)
  Future<({bool success, String message})> uploadImagesToElon(int elonId, List<String> filePaths) async {
    try {
      final token = await StorageService.getToken();
      if (token == null) return (success: false, message: 'Avval kirish kerak');

      final contentTypes = filePaths.map((p) => p.split('.').last.toLowerCase() == 'png' ? 'image/png' : 'image/jpeg').toList();
      final headers = await _authHeaders();

      final presignedRes = await http.post(
        Uri.parse(ApiConstants.imagesPresignedUrl),
        headers: headers,
        body: jsonEncode({'car_id': elonId, 'content_types': contentTypes}),
      );
      if (presignedRes.statusCode != 200) {
        final data = jsonDecode(presignedRes.body);
        return (success: false, message: data['message'] as String? ?? 'Xatolik');
      }

      final urls = (jsonDecode(presignedRes.body)['urls'] as List<dynamic>?) ?? [];
      if (urls.length != filePaths.length) return (success: false, message: 'Presigned URL lar mos kelmadi');

      for (var i = 0; i < filePaths.length; i++) {
        final bytes = await File(filePaths[i]).readAsBytes();
        final putRes = await http.put(
          Uri.parse((urls[i] as Map<String, dynamic>)['upload_url'] as String),
          headers: {'Content-Type': contentTypes[i]},
          body: bytes,
        ).timeout(const Duration(seconds: 30));
        if (putRes.statusCode != 200 && putRes.statusCode != 204) return (success: false, message: 'Rasm yuklashda xatolik');
      }

      final imageKeys = urls.map((u) => (u as Map<String, dynamic>)['image_key'] as String).toList();
      final saveRes = await http.post(
        Uri.parse(ApiConstants.imagesSaveUrl),
        headers: headers,
        body: jsonEncode({'car_id': elonId, 'image_keys': imageKeys}),
      );
      if (saveRes.statusCode != 201) {
        final data = jsonDecode(saveRes.body);
        return (success: false, message: data['message'] as String? ?? 'Xatolik');
      }
      return (success: true, message: jsonDecode(saveRes.body)['message'] as String);
    } catch (e) {
      return (success: false, message: 'Serverga ulanib bo\'lmadi: $e');
    }
  }

  Future<({List<ElonModel> items, String? error})> getMyList({int page = 1, int perPage = 15}) async {
    try {
      final headers = await _authHeaders();
      final uri = Uri.parse(ApiConstants.myElonlarUrl).replace(
        queryParameters: {'page': page.toString(), 'per_page': perPage.toString()},
      );
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = (data['data'] as List? ?? []).map((e) => ElonModel.fromJson(e as Map<String, dynamic>)).toList();
        return (items: list, error: null);
      }
      return (items: <ElonModel>[], error: 'Server xatosi: ${response.statusCode}');
    } on SocketException {
      return (items: <ElonModel>[], error: 'Serverga ulanib bo\'lmadi');
    } catch (e) {
      return (items: <ElonModel>[], error: 'Xatolik: $e');
    }
  }

  /// PUT /api/elonlar/{id} — E'lon yangilash
  Future<({bool success, String message, ElonModel? elon})> update(
    int id,
    Map<String, dynamic> body,
  ) async {
    try {
      final headers = await _authHeaders();
      final response = await http.put(
        Uri.parse(ApiConstants.elonlarDetail(id)),
        headers: headers,
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return (success: true, message: data['message'] as String, elon: ElonModel.fromJson(data['elon']));
      }

      final errors = data['errors'] as Map<String, dynamic>?;
      final msg = errors?.values.first is List
          ? (errors!.values.first as List).first as String
          : (data['message'] as String? ?? 'Xatolik');
      return (success: false, message: msg, elon: null);
    } catch (e) {
      return (success: false, message: 'Serverga ulanib bo\'lmadi', elon: null);
    }
  }

  /// DELETE /api/elonlar/{id} — E'lon o'chirish
  Future<({bool success, String message})> delete(int id) async {
    try {
      final headers = await _authHeaders();
      final response = await http.delete(
        Uri.parse(ApiConstants.elonlarDetail(id)),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return (success: true, message: data['message'] as String);
      }

      final msg = data['message'] as String? ?? 'Xatolik';
      return (success: false, message: msg);
    } catch (e) {
      return (success: false, message: 'Serverga ulanib bo\'lmadi');
    }
  }

  /// PUT /api/elonlar/{id}/images/reorder — Rasm tartibini o'zgartirish
  Future<({bool success, String message})> reorderElonImages(int elonId, List<int> imageIds) async {
    try {
      final headers = await _authHeaders();
      final response = await http.put(
        Uri.parse(ApiConstants.elonlarImagesReorder(elonId)),
        headers: headers,
        body: jsonEncode({'image_ids': imageIds}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return (success: true, message: data['message'] as String);
      }
      return (success: false, message: data['message'] as String? ?? 'Xatolik');
    } catch (e) {
      return (success: false, message: 'Serverga ulanib bo\'lmadi');
    }
  }

  /// DELETE /api/elonlar/{id}/images/{imageId} — E'londan rasm o'chirish
  Future<({bool success, String message})> deleteElonImage(int elonId, int imageId) async {
    try {
      final headers = await _authHeaders();
      final response = await http.delete(
        Uri.parse(ApiConstants.elonlarImageDelete(elonId, imageId)),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return (success: true, message: data['message'] as String);
      }

      final msg = data['message'] as String? ?? 'Xatolik';
      return (success: false, message: msg);
    } catch (e) {
      return (success: false, message: 'Serverga ulanib bo\'lmadi');
    }
  }
}
