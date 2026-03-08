import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../services/storage_service.dart';

/// Rasmni to'liq ekranda ko'rsatish — X tugmasi va tap orqali yopish.
class FullScreenImageViewer extends StatelessWidget {
  const FullScreenImageViewer({
    super.key,
    required this.urls,
    this.initialIndex = 0,
  });

  final List<String> urls;
  final int initialIndex;

  static Future<void> show(
    BuildContext context, {
    required List<String> urls,
    int initialIndex = 0,
  }) {
    if (urls.isEmpty) return Future.value();
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullScreenImageViewer(
          urls: urls,
          initialIndex: initialIndex.clamp(0, urls.length - 1),
        ),
      ),
    );
  }

  bool _needsAuth(String url) => url.contains('/api/chat/media/');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: urls.length == 1
                ? _buildSingleImage(context, urls.first)
                : PageView.builder(
                    controller: PageController(initialPage: initialIndex),
                    itemCount: urls.length,
                    itemBuilder: (_, i) => _buildSingleImage(context, urls[i]),
                  ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 32),
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Yopish',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleImage(BuildContext context, String url) {
    if (_needsAuth(url)) {
      return FutureBuilder<Map<String, String>>(
        future: _headers(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }
          return InteractiveViewer(
            minScale: 0.5,
            maxScale: 4,
            child: Center(
              child: CachedNetworkImage(
                imageUrl: url,
                httpHeaders: snapshot.data,
                fit: BoxFit.contain,
                placeholder: (_, __) => const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
                errorWidget: (_, __, ___) => const Center(
                  child: Icon(Icons.broken_image, color: Colors.white, size: 64),
                ),
              ),
            ),
          );
        },
      );
    }

    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 4,
      child: Center(
        child: CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.contain,
          placeholder: (_, __) => const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
          errorWidget: (_, __, ___) => const Center(
            child: Icon(Icons.broken_image, color: Colors.white, size: 64),
          ),
        ),
      ),
    );
  }

  Future<Map<String, String>> _headers() async {
    final token = await StorageService.getToken();
    return {
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
}
