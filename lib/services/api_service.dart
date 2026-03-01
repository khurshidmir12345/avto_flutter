import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../utils/constants.dart';
import 'storage_service.dart';

class ApiService {
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

  // POST /api/auth/register
  Future<({bool success, String message})> register(
      String name, String phone, String password, String passwordConfirmation) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.registerUrl),
        headers: _headers,
        body: jsonEncode({
          'name': name,
          'phone': phone,
          'password': password,
          'password_confirmation': passwordConfirmation,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return (success: true, message: data['message'] as String);
      }

      final errors = data['errors'] as Map<String, dynamic>?;
      final errorMsg = errors?.values.first is List
          ? (errors!.values.first as List).first as String
          : data['message'] as String;
      return (success: false, message: errorMsg);
    } catch (e) {
      return (success: false, message: 'Serverga ulanib bo\'lmadi');
    }
  }

  // POST /api/auth/login — parol bilan
  Future<({bool success, String message, UserModel? user, String? token})> login(
      String phone, String password) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.loginUrl),
        headers: _headers,
        body: jsonEncode({'phone': phone, 'password': password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final user = UserModel.fromJson(data['user']);
        final token = data['token'] as String;
        await StorageService.saveToken(token);
        return (success: true, message: data['message'] as String, user: user, token: token);
      }

      return (success: false, message: data['message'] as String, user: null, token: null);
    } catch (e) {
      return (success: false, message: 'Serverga ulanib bo\'lmadi', user: null, token: null);
    }
  }

  // POST /api/auth/verify-otp
  Future<({bool success, String message, UserModel? user, String? token})> verifyOtp(
      String phone, String code) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.verifyOtpUrl),
        headers: _headers,
        body: jsonEncode({'phone': phone, 'code': code}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final user = UserModel.fromJson(data['user']);
        final token = data['token'] as String;
        await StorageService.saveToken(token);
        return (success: true, message: data['message'] as String, user: user, token: token);
      }

      return (success: false, message: data['message'] as String, user: null, token: null);
    } catch (e) {
      return (success: false, message: 'Serverga ulanib bo\'lmadi', user: null, token: null);
    }
  }

  // GET /api/auth/user
  Future<UserModel?> getCurrentUser() async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse(ApiConstants.userUrl),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return UserModel.fromJson(data['user']);
      }
    } catch (_) {}

    return null;
  }

  // POST /api/auth/logout
  Future<bool> logout() async {
    try {
      final headers = await _authHeaders();
      final response = await http.post(
        Uri.parse(ApiConstants.logoutUrl),
        headers: headers,
      );

      if (response.statusCode == 200) {
        await StorageService.clearAll();
        return true;
      }
    } catch (_) {}

    return false;
  }
}
