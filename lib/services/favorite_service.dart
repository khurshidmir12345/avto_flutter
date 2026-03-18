import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/elon_model.dart';
import '../utils/constants.dart';
import 'storage_service.dart';

class FavoriteService {
  Future<Map<String, String>> _authHeaders() async {
    final token = await StorageService.getToken();
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<ElonModel>> getFavorites({int page = 1}) async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('${ApiConstants.favoritesUrl}?page=$page'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['data'] as List? ?? [])
            .map((e) => ElonModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  Future<({bool success, bool isFavorited, String message})> toggle(int elonId) async {
    try {
      final headers = await _authHeaders();
      final response = await http.post(
        Uri.parse(ApiConstants.favoritesToggleUrl),
        headers: headers,
        body: jsonEncode({'elon_id': elonId}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return (
          success: true,
          isFavorited: data['is_favorited'] as bool? ?? false,
          message: data['message'] as String? ?? '',
        );
      }
      return (
        success: false,
        isFavorited: false,
        message: data['message'] as String? ?? 'Xatolik',
      );
    } catch (_) {
      return (success: false, isFavorited: false, message: 'Serverga ulanib bo\'lmadi');
    }
  }

  Future<bool> checkFavorite(int elonId) async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse(ApiConstants.favoritesCheckUrl(elonId)),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['is_favorited'] as bool? ?? false;
      }
    } catch (_) {}
    return false;
  }
}
