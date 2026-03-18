import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import 'storage_service.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._();
  factory AnalyticsService() => _instance;
  AnalyticsService._();

  String? _deviceId;
  String? _platform;

  Future<void> _ensureInitialized() async {
    _deviceId ??= await StorageService.getOrCreateDeviceId();
    _platform ??= Platform.isIOS ? 'ios' : 'android';
  }

  Future<void> trackPageView(String page) async {
    try {
      await _ensureInitialized();
      await http.post(
        Uri.parse(ApiConstants.pageViewsUrl),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'page': page,
          'device_id': _deviceId,
          'platform': _platform,
        }),
      );
    } catch (_) {}
  }
}
