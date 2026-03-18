import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/telegram_channel_model.dart';
import '../models/user_telegram_channel_model.dart';
import '../utils/constants.dart';
import 'storage_service.dart';

class TelegramChannelApiService {
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

  /// Global Telegram kanallar ro'yxati (public)
  Future<List<TelegramChannelModel>> getGlobalChannels() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.telegramChannelsUrl),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['data'] as List? ?? [])
            .map((e) => TelegramChannelModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  /// Foydalanuvchining shaxsiy kanallari
  Future<({List<UserTelegramChannelModel> channels, int maxChannels})>
      getUserChannels() async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse(ApiConstants.userChannelsUrl),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final channels = (data['data'] as List? ?? [])
            .map((e) =>
                UserTelegramChannelModel.fromJson(e as Map<String, dynamic>))
            .toList();
        final maxChannels = (data['max_channels'] as num?)?.toInt() ?? 5;
        return (channels: channels, maxChannels: maxChannels);
      }
    } catch (_) {}
    return (channels: <UserTelegramChannelModel>[], maxChannels: 5);
  }

  /// Yangi kanal qo'shish
  Future<({bool success, String message, UserTelegramChannelModel? channel})>
      createUserChannel({
    required String botToken,
    required String chatId,
    String? channelName,
    String? channelUsername,
    String? messageTemplate,
    String? footerText,
  }) async {
    try {
      final headers = await _authHeaders();
      final response = await http.post(
        Uri.parse(ApiConstants.userChannelsUrl),
        headers: headers,
        body: jsonEncode({
          'bot_token': botToken,
          'chat_id': chatId,
          if (channelName != null) 'channel_name': channelName,
          if (channelUsername != null) 'channel_username': channelUsername,
          if (messageTemplate != null) 'message_template': messageTemplate,
          if (footerText != null) 'footer_text': footerText,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        final channel = UserTelegramChannelModel.fromJson(
            data['channel'] as Map<String, dynamic>);
        return (
          success: true,
          message: data['message'] as String,
          channel: channel
        );
      }

      return (
        success: false,
        message: data['message'] as String? ?? 'Xatolik yuz berdi',
        channel: null
      );
    } catch (e) {
      return (
        success: false,
        message: 'Serverga ulanib bo\'lmadi',
        channel: null
      );
    }
  }

  /// Kanalni tahrirlash
  Future<({bool success, String message})> updateUserChannel({
    required int id,
    String? botToken,
    String? chatId,
    String? channelName,
    String? messageTemplate,
    String? footerText,
    bool? isActive,
  }) async {
    try {
      final headers = await _authHeaders();
      final body = <String, dynamic>{};
      if (botToken != null) body['bot_token'] = botToken;
      if (chatId != null) body['chat_id'] = chatId;
      if (channelName != null) body['channel_name'] = channelName;
      if (messageTemplate != null) body['message_template'] = messageTemplate;
      if (footerText != null) body['footer_text'] = footerText;
      if (isActive != null) body['is_active'] = isActive;

      final response = await http.put(
        Uri.parse(ApiConstants.userChannelUrl(id)),
        headers: headers,
        body: jsonEncode(body),
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

  /// Kanalni o'chirish
  Future<({bool success, String message})> deleteUserChannel(int id) async {
    try {
      final headers = await _authHeaders();
      final response = await http.delete(
        Uri.parse(ApiConstants.userChannelUrl(id)),
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

  /// Test xabar yuborish
  Future<({bool success, String message})> testUserChannel(int id) async {
    try {
      final headers = await _authHeaders();
      final response = await http.post(
        Uri.parse(ApiConstants.userChannelTestUrl(id)),
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
}
