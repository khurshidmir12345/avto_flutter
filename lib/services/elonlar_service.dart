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

  Future<List<ElonModel>> getList({
    int? categoryId,
    String? marka,
    String? shahar,
    String? yoqilgiTuri,
    int? narxMin,
    int? narxMax,
    int? yilMin,
    int? yilMax,
    int page = 1,
    int perPage = 15,
  }) async {
    final query = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
    };
    if (categoryId != null) query['category_id'] = categoryId.toString();
    if (marka != null && marka.isNotEmpty) query['marka'] = marka;
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
      return list;
    }
    return [];
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

  /// Rasmlarni e'londan oldin yuklash. image_ids qaytaradi.
  Future<({bool success, String message, List<int> imageIds})> uploadImagesBeforeElon(
      List<String> filePaths) async {
    try {
      final token = await StorageService.getToken();
      if (token == null) return (success: false, message: 'Avval kirish kerak', imageIds: <int>[]);

      final request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConstants.imagesUploadUrl),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      for (var i = 0; i < filePaths.length; i++) {
        final path = filePaths[i];
        final file = File(path);
        final bytes = await file.readAsBytes();
        final name = path.split('/').last;
        final filename = (name.isNotEmpty && name.contains('.')) ? name : 'image_$i.jpg';
        request.files.add(http.MultipartFile.fromBytes(
          'images[]',
          bytes,
          filename: filename,
        ));
      }

      final streamed = await request.send().timeout(
        const Duration(seconds: 60),
        onTimeout: () => throw Exception('Vaqt tugadi'),
      );
      final response = await http.Response.fromStream(streamed);
      final body = response.body;

      if (response.statusCode == 201) {
        final data = jsonDecode(body);
        final images = data['images'] as List<dynamic>? ?? [];
        final ids = List<int>.from(images.map((e) => (e as Map<String, dynamic>)['id'] as int));
        return (success: true, message: data['message'] as String, imageIds: ids);
      }

      try {
        final data = jsonDecode(body);
        final msg = data['message'] as String? ?? data['errors']?.toString() ?? 'Xatolik';
        return (success: false, message: msg, imageIds: <int>[]);
      } catch (_) {
        return (success: false, message: 'Server javobi: ${response.statusCode}', imageIds: <int>[]);
      }
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

  /// E'longa qo'shimcha rasm yuklash (e'lon yaratilgandan keyin)
  Future<({bool success, String message})> uploadImagesToElon(int elonId, List<String> filePaths) async {
    try {
      final token = await StorageService.getToken();
      if (token == null) return (success: false, message: 'Avval kirish kerak');

      final request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConstants.elonlarImages(elonId)),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      for (final path in filePaths) {
        request.files.add(await http.MultipartFile.fromPath('images[]', path));
      }

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      final body = response.body;

      if (response.statusCode == 201) {
        final data = jsonDecode(body);
        return (success: true, message: data['message'] as String);
      }

      try {
        final data = jsonDecode(body);
        final msg = data['message'] as String? ?? data['errors']?.toString() ?? 'Xatolik';
        return (success: false, message: msg);
      } catch (_) {
        return (success: false, message: 'Server javobi: ${response.statusCode}');
      }
    } catch (e) {
      return (success: false, message: 'Serverga ulanib bo\'lmadi: $e');
    }
  }

  Future<List<ElonModel>> getMyList({int page = 1, int perPage = 15}) async {
    final headers = await _authHeaders();
    final uri = Uri.parse(ApiConstants.myElonlarUrl).replace(
      queryParameters: {'page': page.toString(), 'per_page': perPage.toString()},
    );
    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final list = (data['data'] as List? ?? []).map((e) => ElonModel.fromJson(e as Map<String, dynamic>)).toList();
      return list;
    }
    return [];
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
