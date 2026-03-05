import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/conversation_model.dart';
import '../models/conversation_message_model.dart';
import '../utils/constants.dart';
import 'storage_service.dart';

class ChatService {
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

  Future<List<ConversationModel>> getConversations() async {
    final headers = await _authHeaders();
    final response = await http.get(
      Uri.parse(ApiConstants.chatConversationsUrl),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final list = data['data'] as List? ?? data;
      return (list as List).map((e) => ConversationModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<({bool success, ConversationModel? conversation})> createConversation(int userId) async {
    final headers = await _authHeaders();
    final response = await http.post(
      Uri.parse(ApiConstants.chatConversationsUrl),
      headers: headers,
      body: jsonEncode({'user_id': userId}),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      final conv = data['conversation'] as Map<String, dynamic>?;
      return (success: true, conversation: conv != null ? ConversationModel.fromJson(conv) : null);
    }
    return (success: false, conversation: null);
  }

  Future<List<ConversationMessageModel>> getMessages(int conversationId, {int page = 1}) async {
    final headers = await _authHeaders();
    final uri = Uri.parse(ApiConstants.chatConversationMessages(conversationId))
        .replace(queryParameters: {'page': page.toString(), 'per_page': '30'});
    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final list = data['data'] as List? ?? [];
      return list.map((e) => ConversationMessageModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<({bool success, ConversationMessageModel? message})> sendText(
    int conversationId,
    String message,
  ) async {
    final headers = await _authHeaders();
    final response = await http.post(
      Uri.parse(ApiConstants.chatConversationMessages(conversationId)),
      headers: headers,
      body: jsonEncode({'body': message}),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      final msg = data['data'] as Map<String, dynamic>?;
      return (success: true, message: msg != null ? ConversationMessageModel.fromJson(msg) : null);
    }
    return (success: false, message: null);
  }

  Future<({bool success, ConversationMessageModel? message})> sendImage(
    int conversationId,
    String filePath,
  ) async {
    final token = await StorageService.getToken();
    if (token == null) return (success: false, message: null);

    final request = http.MultipartRequest(
      'POST',
      Uri.parse(ApiConstants.chatConversationMessages(conversationId)),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';
    request.files.add(await http.MultipartFile.fromPath('image', filePath));

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      final msg = data['data'] as Map<String, dynamic>?;
      return (success: true, message: msg != null ? ConversationMessageModel.fromJson(msg) : null);
    }
    return (success: false, message: null);
  }

  Future<({bool success, ConversationMessageModel? message})> sendVoice(
    int conversationId,
    String filePath,
  ) async {
    final token = await StorageService.getToken();
    if (token == null) return (success: false, message: null);

    final request = http.MultipartRequest(
      'POST',
      Uri.parse(ApiConstants.chatConversationMessages(conversationId)),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';
    request.files.add(await http.MultipartFile.fromPath('voice', filePath));

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      final msg = data['data'] as Map<String, dynamic>?;
      return (success: true, message: msg != null ? ConversationMessageModel.fromJson(msg) : null);
    }
    return (success: false, message: null);
  }

  Future<List<ChatUserModel>> searchUsers(String query) async {
    final headers = await _authHeaders();
    final uri = Uri.parse(ApiConstants.chatUsersUrl).replace(queryParameters: {'q': query});
    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final list = data['data'] as List? ?? [];
      return list.map((e) => ChatUserModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }
}
