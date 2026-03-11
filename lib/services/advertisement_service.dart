import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import '../models/advertisement_model.dart';
import '../utils/constants.dart';
import 'storage_service.dart';

class AdvertisementService {
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

  /// Faol reklamalar (public)
  Future<List<AdvertisementModel>> getActiveAds() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.advertisementsUrl),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['data'] as List? ?? [])
            .map((e) => AdvertisementModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  /// Reklama narxi
  Future<({int dailyPrice, int maxDaily, int todayCount, int slotsRemaining})?> getPrice() async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse(ApiConstants.advertisementsPriceUrl),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return (
          dailyPrice: (data['daily_price'] as num).toInt(),
          maxDaily: (data['max_daily_ads'] as num).toInt(),
          todayCount: (data['today_approved_count'] as num).toInt(),
          slotsRemaining: (data['slots_remaining'] as num).toInt(),
        );
      }
    } catch (_) {}
    return null;
  }

  /// Mening reklamalarim
  Future<({List<AdvertisementModel> items, String? error})> getMyAds({int page = 1}) async {
    try {
      final headers = await _authHeaders();
      final uri = Uri.parse(ApiConstants.advertisementsMyUrl)
          .replace(queryParameters: {'page': '$page'});
      final response = await http.get(uri, headers: headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final items = (data['data'] as List? ?? [])
            .map((e) => AdvertisementModel.fromJson(e as Map<String, dynamic>))
            .toList();
        return (items: items, error: null);
      }
      return (items: <AdvertisementModel>[], error: 'Server xatosi');
    } catch (e) {
      return (items: <AdvertisementModel>[], error: 'Serverga ulanib bo\'lmadi');
    }
  }

  /// Rasm uchun presigned URL olish
  Future<({String? imageKey, String? uploadUrl, String? error})> getPresignedUrl(String contentType) async {
    try {
      final headers = await _authHeaders();
      final response = await http.post(
        Uri.parse(ApiConstants.advertisementsPresignedUrl),
        headers: headers,
        body: jsonEncode({'content_type': contentType}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return (
          imageKey: data['image_key'] as String?,
          uploadUrl: data['upload_url'] as String?,
          error: null,
        );
      }
      final data = jsonDecode(response.body);
      return (imageKey: null, uploadUrl: null, error: data['message'] as String? ?? 'Xatolik');
    } catch (e) {
      return (imageKey: null, uploadUrl: null, error: 'Serverga ulanib bo\'lmadi');
    }
  }

  /// Rasmni R2 ga yuklash
  Future<bool> uploadImageToR2(File file, String uploadUrl, String contentType) async {
    try {
      final dio = Dio();
      final bytes = await file.readAsBytes();
      await dio.put(
        uploadUrl,
        data: bytes,
        options: Options(
          headers: {'Content-Type': contentType},
          sendTimeout: const Duration(seconds: 60),
        ),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Reklama yaratish
  Future<({bool success, String message, AdvertisementModel? ad})> create({
    required String title,
    String? description,
    String? imageKey,
    String? link,
    required int days,
  }) async {
    try {
      final headers = await _authHeaders();
      final response = await http.post(
        Uri.parse(ApiConstants.advertisementsUrl),
        headers: headers,
        body: jsonEncode({
          'title': title,
          'description': description,
          'image_key': imageKey,
          'link': link,
          'days': days,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 201) {
        final ad = AdvertisementModel.fromJson(data['advertisement'] as Map<String, dynamic>);
        return (success: true, message: data['message'] as String, ad: ad);
      }

      return (success: false, message: data['message'] as String? ?? 'Xatolik', ad: null);
    } catch (e) {
      return (success: false, message: 'Serverga ulanib bo\'lmadi', ad: null);
    }
  }

  /// Reklamani qayta faollashtirish
  Future<({bool success, String message})> reactivate(int id) async {
    try {
      final headers = await _authHeaders();
      final response = await http.post(
        Uri.parse('${ApiConstants.advertisementsUrl}/$id/reactivate'),
        headers: headers,
      );
      final data = jsonDecode(response.body);
      return (
        success: response.statusCode == 200,
        message: data['message'] as String? ?? 'Xatolik',
      );
    } catch (e) {
      return (success: false, message: 'Serverga ulanib bo\'lmadi');
    }
  }

  /// Reklamani o'chirish
  Future<({bool success, String message})> delete(int id) async {
    try {
      final headers = await _authHeaders();
      final response = await http.delete(
        Uri.parse('${ApiConstants.advertisementsUrl}/$id'),
        headers: headers,
      );
      final data = jsonDecode(response.body);
      return (
        success: response.statusCode == 200,
        message: data['message'] as String? ?? 'Xatolik',
      );
    } catch (e) {
      return (success: false, message: 'Serverga ulanib bo\'lmadi');
    }
  }

  /// Ko'rishni qayd etish
  Future<void> trackView(int id) async {
    try {
      await http.post(
        Uri.parse('${ApiConstants.advertisementsUrl}/$id/view'),
        headers: _headers,
      );
    } catch (_) {}
  }
}
