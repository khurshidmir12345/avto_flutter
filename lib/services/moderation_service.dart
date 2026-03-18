import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import 'storage_service.dart';

class ModerationService {
  Future<Map<String, String>> _authHeaders() async {
    final token = await StorageService.getToken();
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<({bool success, String message})> reportContent({
    required String reportableType,
    required int reportableId,
    required String reason,
    String? description,
  }) async {
    try {
      final headers = await _authHeaders();
      final response = await http.post(
        Uri.parse(ApiConstants.reportsUrl),
        headers: headers,
        body: jsonEncode({
          'reportable_type': reportableType,
          'reportable_id': reportableId,
          'reason': reason,
          if (description != null && description.isNotEmpty)
            'description': description,
        }),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 201) {
        return (success: true, message: data['message'] as String);
      }

      return (
        success: false,
        message: data['message'] as String? ?? 'Xatolik yuz berdi',
      );
    } catch (e) {
      return (success: false, message: 'Serverga ulanib bo\'lmadi');
    }
  }

  Future<({bool success, String message})> blockUser(int userId) async {
    try {
      final headers = await _authHeaders();
      final response = await http.post(
        Uri.parse(ApiConstants.blockedUsersUrl),
        headers: headers,
        body: jsonEncode({'blocked_user_id': userId}),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 201) {
        return (success: true, message: data['message'] as String);
      }

      return (
        success: false,
        message: data['message'] as String? ?? 'Xatolik yuz berdi',
      );
    } catch (e) {
      return (success: false, message: 'Serverga ulanib bo\'lmadi');
    }
  }

  Future<({bool success, String message})> unblockUser(int userId) async {
    try {
      final headers = await _authHeaders();
      final response = await http.delete(
        Uri.parse(ApiConstants.unblockUserUrl(userId)),
        headers: headers,
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return (success: true, message: data['message'] as String);
      }

      return (
        success: false,
        message: data['message'] as String? ?? 'Xatolik yuz berdi',
      );
    } catch (e) {
      return (success: false, message: 'Serverga ulanib bo\'lmadi');
    }
  }

  Future<List<Map<String, dynamic>>> getBlockedUsers() async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse(ApiConstants.blockedUsersUrl),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final list = data['data'] as List;
        return list.cast<Map<String, dynamic>>();
      }
    } catch (_) {}
    return [];
  }
}
