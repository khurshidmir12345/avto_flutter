import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../services/storage_service.dart';

/// Rasm yuklash — API proxy URL bo'lsa (auth kerak) Bearer token bilan yuklaydi.
class AuthNetworkImage extends StatelessWidget {
  const AuthNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.errorWidget,
  });

  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? errorWidget;

  bool get _needsAuth => url.contains('/api/chat/media/');

  @override
  Widget build(BuildContext context) {
    if (_needsAuth) {
      return FutureBuilder<Map<String, String>>(
        future: _headers(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return SizedBox(
              width: width ?? 200,
              height: height ?? 200,
              child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }
          return CachedNetworkImage(
            imageUrl: url,
            httpHeaders: snapshot.data,
            width: width,
            height: height,
            fit: fit,
            placeholder: (_, __) => SizedBox(
              width: width ?? 200,
              height: height ?? 200,
              child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            errorWidget: (_, __, ___) => errorWidget ?? PhosphorIcon(PhosphorIconsRegular.imageBroken, size: 48),
          );
        },
      );
    }

    return CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: fit,
      placeholder: (_, __) => SizedBox(
        width: width ?? 200,
        height: height ?? 200,
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      errorWidget: (_, __, ___) => errorWidget ?? PhosphorIcon(PhosphorIconsRegular.imageBroken, size: 48),
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
