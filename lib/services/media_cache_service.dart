import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'storage_service.dart';

/// Chat media (rasm, ovoz) uchun lokal cache — bir marta yuklab, keyin offline ishlatish.
class MediaCacheService {
  MediaCacheService._();
  static final MediaCacheService instance = MediaCacheService._();

  static const String _cacheDir = 'chat_media_cache';
  Directory? _cacheDirectory;

  Future<Directory> _getCacheDir() async {
    _cacheDirectory ??= Directory(
      '${(await getTemporaryDirectory()).path}/$_cacheDir',
    );
    if (!await _cacheDirectory!.exists()) {
      await _cacheDirectory!.create(recursive: true);
    }
    return _cacheDirectory!;
  }

  String _cacheKey(String url, {String? forceExtension}) {
    final bytes = utf8.encode(url);
    final hash = bytes.fold<int>(0, (a, b) => ((a << 5) - a) + b).abs();
    String ext;
    if (forceExtension != null) {
      ext = forceExtension;
    } else if (url.contains('.m4a') || url.contains('voice')) {
      ext = 'm4a';
    } else if (url.contains('.jpg') || url.contains('.jpeg')) {
      ext = 'jpg';
    } else if (url.contains('.png')) {
      ext = 'png';
    } else {
      ext = 'bin';
    }
    return '${hash}_$ext';
  }

  bool _needsAuth(String url) => url.contains('/api/chat/media/');

  Future<Map<String, String>> _authHeaders() async {
    final token = await StorageService.getToken();
    return {
      'Accept': '*/*',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// URL dan faylni cache ga yuklab, lokal path qaytaradi.
  /// Agar allaqachon cache da bo'lsa, yangi yuklash qilmaydi.
  /// [forceExtension] — ovoz uchun 'm4a', rasm uchun null (avtomatik).
  Future<String?> getCachedPath(String url, {String? forceExtension}) async {
    if (url.isEmpty) return null;

    final dir = await _getCacheDir();
    final key = _cacheKey(url, forceExtension: forceExtension);
    final file = File('${dir.path}/$key');

    if (await file.exists()) {
      return file.path;
    }

    try {
      final headers = _needsAuth(url) ? await _authHeaders() : <String, String>{};
      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        return file.path;
      }
    } catch (_) {}
    return null;
  }

  /// Cache ni tozalash (ixtiyoriy)
  Future<void> clearCache() async {
    try {
      final dir = await _getCacheDir();
      if (await dir.exists()) {
        await for (final entity in dir.list()) {
          await entity.delete();
        }
      }
    } catch (_) {}
  }
}
