import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/balance_history_model.dart';
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
  Future<({bool success, String message, int statusCode})> register(
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

      if (response.statusCode == 201 || response.statusCode == 200) {
        return (success: true, message: data['message'] as String, statusCode: response.statusCode);
      }

      final errors = data['errors'] as Map<String, dynamic>?;
      final errorMsg = errors?.values.first is List
          ? (errors!.values.first as List).first as String
          : data['message'] as String;
      return (success: false, message: errorMsg, statusCode: response.statusCode);
    } catch (e) {
      return (success: false, message: 'Serverga ulanib bo\'lmadi', statusCode: 0);
    }
  }

  // POST /api/auth/login — parol bilan
  Future<({bool success, String message, UserModel? user, String? token, int statusCode})> login(
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
        return (success: true, message: data['message'] as String, user: user, token: token, statusCode: 200);
      }

      return (success: false, message: data['message'] as String, user: null, token: null, statusCode: response.statusCode);
    } catch (e) {
      return (success: false, message: 'Serverga ulanib bo\'lmadi', user: null, token: null, statusCode: 0);
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
        final appConfig = data['app_config'] as Map<String, dynamic>?;
        if (appConfig != null) {
          final topupEnabled = appConfig['balance_topup_enabled'] as bool? ?? true;
          await StorageService.saveBalanceTopupEnabled(topupEnabled);
        }

        return UserModel.fromJson(userJson);
      }
    } catch (_) {}

    return null;
  }

  // PUT /api/auth/profile
  Future<({bool success, String message, UserModel? user})> updateProfile(String name) async {
    try {
      final headers = await _authHeaders();
      final response = await http.put(
        Uri.parse(ApiConstants.updateProfileUrl),
        headers: headers,
        body: jsonEncode({'name': name}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final user = UserModel.fromJson(data['user']);
        return (success: true, message: data['message'] as String, user: user);
      }

      final errors = data['errors'] as Map<String, dynamic>?;
      final errorMsg = errors?.values.first is List
          ? (errors!.values.first as List).first as String
          : data['message'] as String;
      return (success: false, message: errorMsg, user: null);
    } catch (e) {
      return (success: false, message: 'Serverga ulanib bo\'lmadi', user: null);
    }
  }

  // PUT /api/auth/password
  Future<({bool success, String message})> changePassword(
      String currentPassword, String password, String passwordConfirmation) async {
    try {
      final headers = await _authHeaders();
      final response = await http.put(
        Uri.parse(ApiConstants.changePasswordUrl),
        headers: headers,
        body: jsonEncode({
          'current_password': currentPassword,
          'password': password,
          'password_confirmation': passwordConfirmation,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
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

  // POST /api/auth/avatar
  Future<({bool success, String message, UserModel? user})> uploadAvatar(String filePath) async {
    try {
      final token = await StorageService.getToken();
      if (token == null) {
        return (success: false, message: 'Avval kirish kerak', user: null);
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConstants.avatarUploadUrl),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';
      request.files.add(await http.MultipartFile.fromPath('avatar', filePath));

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
        return (success: true, message: data['message'] as String, user: user);
      }

      final errors = data['errors'] as Map<String, dynamic>?;
      final errorMsg = errors?.values.first is List
          ? (errors!.values.first as List).first as String
          : (data['message'] as String? ?? 'Xatolik yuz berdi');
      return (success: false, message: errorMsg, user: null);
    } on SocketException {
      return (success: false, message: 'Serverga ulanib bo\'lmadi', user: null);
    } catch (_) {
      return (success: false, message: 'Rasm yuklashda xatolik', user: null);
    }
  }

  // GET /api/auth/balance-history
  Future<({List<BalanceHistoryModel> items, int total, int lastPage})?> getBalanceHistory({
    int page = 1,
    int perPage = 15,
  }) async {
    try {
      final headers = await _authHeaders();
      final uri = Uri.parse(ApiConstants.balanceHistoryUrl)
          .replace(queryParameters: {'page': '$page', 'per_page': '$perPage'});
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final list = (data['data'] as List)
            .map((e) => BalanceHistoryModel.fromJson(e as Map<String, dynamic>))
            .toList();
        final meta = data['meta'] as Map<String, dynamic>;
        return (
          items: list,
          total: meta['total'] as int,
          lastPage: meta['last_page'] as int,
        );
      }
    } catch (_) {}
    return null;
  }

  // GET /api/auth/elon-create-price
  Future<int?> getElonCreatePrice() async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse(ApiConstants.elonCreatePriceUrl),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return (data['amount'] as num?)?.toInt();
      }
    } catch (_) {}
    return null;
  }

  /// Eng yangi balance history yozuvining created_at — yangi xabar badge uchun
  Future<String?> getLatestBalanceHistoryCreatedAt() async {
    final result = await getBalanceHistory(page: 1, perPage: 1);
    return result?.items.isNotEmpty == true ? result!.items.first.createdAt : null;
  }

  // GET /api/telegram/link-info
  Future<({String? botUsername, String? botLink, String? message})?> getTelegramLinkInfo() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.telegramLinkInfoUrl),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return (
          botUsername: data['bot_username'] as String?,
          botLink: data['bot_link'] as String?,
          message: data['instructions'] as String?,
        );
      }
    } catch (_) {}
    return null;
  }

  // POST /api/telegram/link
  Future<({bool success, String message, UserModel? user})> linkTelegram(String token) async {
    try {
      final headers = await _authHeaders();
      final response = await http.post(
        Uri.parse(ApiConstants.telegramLinkUrl),
        headers: headers,
        body: jsonEncode({'token': token}),
      );
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) {
        final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
        return (success: true, message: data['message'] as String, user: user);
      }
      if (response.statusCode == 401) {
        return (success: false, message: 'Avval ilovaga kiring', user: null);
      }
      return (
        success: false,
        message: data['message'] as String? ?? 'Xatolik yuz berdi',
        user: null,
      );
    } catch (e) {
      return (success: false, message: 'Serverga ulanib bo\'lmadi', user: null);
    }
  }

  // DELETE /api/auth/telegram/unlink
  Future<({bool success, String message, UserModel? user})> unlinkTelegram() async {
    try {
      final headers = await _authHeaders();
      final response = await http.delete(
        Uri.parse(ApiConstants.telegramUnlinkUrl),
        headers: headers,
      );
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) {
        final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
        return (success: true, message: data['message'] as String, user: user);
      }
      return (
        success: false,
        message: data['message'] as String? ?? 'Xatolik yuz berdi',
        user: null,
      );
    } catch (e) {
      return (success: false, message: 'Serverga ulanib bo\'lmadi', user: null);
    }
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
        await StorageService.clearAuthData();
        return true;
      }
    } catch (_) {}

    return false;
  }

  // GET /api/support/bot-info
  Future<String?> getSupportBotLink() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.supportBotInfoUrl),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['bot_link'] as String?;
      }
    } catch (_) {}
    return null;
  }
}
