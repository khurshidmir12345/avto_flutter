import 'dart:io';
import 'package:dio/dio.dart';
import '../utils/constants.dart';
import 'storage_service.dart';

/// Presigned URL javob elementi
class PresignedUrlItem {
  final String imageKey;
  final String uploadUrl;

  PresignedUrlItem({required this.imageKey, required this.uploadUrl});

  factory PresignedUrlItem.fromJson(Map<String, dynamic> json) {
    return PresignedUrlItem(
      imageKey: json['image_key'] as String,
      uploadUrl: json['upload_url'] as String,
    );
  }
}

/// Tasdiqlangan rasm javobi
class ConfirmedImage {
  final int id;
  final String imageKey;
  final String? originalUrl;
  final String? thumbUrl;
  final int sortOrder;

  ConfirmedImage({
    required this.id,
    required this.imageKey,
    this.originalUrl,
    this.thumbUrl,
    required this.sortOrder,
  });

  factory ConfirmedImage.fromJson(Map<String, dynamic> json) {
    return ConfirmedImage(
      id: (json['id'] is int) ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      imageKey: json['image_key'] as String,
      originalUrl: json['original'] as String?,
      thumbUrl: json['thumb'] as String?,
      sortOrder: (json['sort_order'] as int?) ?? 0,
    );
  }
}

/// Rasm yuklash servisi — presigned URL orqali R2 ga yuklash
class ImageUploadService {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    sendTimeout: const Duration(seconds: 60),
  ));

  Future<Map<String, String>> _authHeaders() async {
    final token = await StorageService.getToken();
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Presigned URL lar olish
  /// [contentTypes] — har bir rasm uchun MIME (image/jpeg, image/png)
  Future<({bool success, String message, List<PresignedUrlItem> urls})> getPresignedUrls(
    List<String> contentTypes, {
    int? carId,
  }) async {
    try {
      final headers = await _authHeaders();
      final response = await _dio.post(
        ApiConstants.imagesPresignedUrl,
        options: Options(headers: headers),
        data: {
          if (carId != null) 'car_id': carId,
          'content_types': contentTypes,
        },
      );

      if (response.statusCode == 200) {
        final urls = (response.data['urls'] as List<dynamic>?)
                ?.map((e) => PresignedUrlItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [];
        return (success: true, message: response.data['message'] as String? ?? 'Tayyor', urls: urls);
      }

      final msg = _extractMessage(response.data);
      return (success: false, message: msg, urls: <PresignedUrlItem>[]);
    } on DioException catch (e) {
      return (success: false, message: _dioErrorMessage(e), urls: <PresignedUrlItem>[]);
    } catch (e) {
      return (success: false, message: 'Xatolik: $e', urls: <PresignedUrlItem>[]);
    }
  }

  /// Bitta rasmni R2 ga yuklash (progress bilan)
  Future<({bool success, String message})> uploadImage(
    File file,
    String uploadUrl,
    String contentType, {
    void Function(int sent, int total)? onProgress,
  }) async {
    try {
      final bytes = await file.readAsBytes();
      await _dio.put(
        uploadUrl,
        data: bytes,
        options: Options(
          headers: {'Content-Type': contentType},
          sendTimeout: const Duration(seconds: 60),
        ),
        onSendProgress: (sent, total) {
          onProgress?.call(sent, total);
        },
      );
      return (success: true, message: 'Yuklandi');
    } on DioException catch (e) {
      return (success: false, message: _dioErrorMessage(e));
    } catch (e) {
      return (success: false, message: 'Yuklash xatoligi: $e');
    }
  }

  /// Yuklangan rasmlarni backendda tasdiqlash (save)
  Future<({bool success, String message, List<ConfirmedImage> images})> confirmImages(
    List<String> imageKeys, {
    int? carId,
  }) async {
    try {
      final headers = await _authHeaders();
      final response = await _dio.post(
        ApiConstants.imagesSaveUrl,
        options: Options(headers: headers),
        data: {
          if (carId != null) 'car_id': carId,
          'image_keys': imageKeys,
        },
      );

      if (response.statusCode == 201) {
        final images = (response.data['images'] as List<dynamic>?)
                ?.map((e) => ConfirmedImage.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [];
        return (
          success: true,
          message: response.data['message'] as String? ?? 'Saqlandi',
          images: images,
        );
      }

      final msg = _extractMessage(response.data);
      return (success: false, message: msg, images: <ConfirmedImage>[]);
    } on DioException catch (e) {
      return (success: false, message: _dioErrorMessage(e), images: <ConfirmedImage>[]);
    } catch (e) {
      return (success: false, message: 'Xatolik: $e', images: <ConfirmedImage>[]);
    }
  }

  /// E'londan oldin rasmlarni navbat bilan yuklash (presigned → R2 → confirm)
  /// [onImageProgress] — (index, sent, total) callback
  /// [onImageStatus] — (index, status) callback: 'pending'|'uploading'|'success'|'error'
  /// Qisman muvaffaqiyat: agar biror rasm xato bo'lsa, yuklanganlar confirm qilinadi
  Future<({bool success, String message, List<int> imageIds})> uploadImagesBeforeElon(
    List<File> files, {
    void Function(int index, int sent, int total)? onImageProgress,
    void Function(int index, String status)? onImageStatus,
  }) async {
    if (files.isEmpty) return (success: false, message: 'Rasmlar yo\'q', imageIds: <int>[]);

    try {
      final token = await StorageService.getToken();
      if (token == null) return (success: false, message: 'Avval kirish kerak', imageIds: <int>[]);

      final contentTypes = files.map((f) {
        final ext = f.path.split('.').last.toLowerCase();
        return switch (ext) {
          'png' => 'image/png',
          'webp' => 'image/webp',
          'gif' => 'image/gif',
          'bmp' => 'image/bmp',
          'heic' => 'image/heic',
          'heif' => 'image/heif',
          'tiff' || 'tif' => 'image/tiff',
          _ => 'image/jpeg',
        };
      }).toList();

      // 1. Presigned URL lar olish
      final presigned = await getPresignedUrls(contentTypes);
      if (!presigned.success || presigned.urls.length != files.length) {
        return (success: false, message: presigned.message, imageIds: <int>[]);
      }

      // 2. Navbat bilan R2 ga yuklash
      final uploadedKeys = <String>[];
      String? lastError;

      for (var i = 0; i < files.length; i++) {
        onImageStatus?.call(i, 'uploading');
        final result = await uploadImage(
          files[i],
          presigned.urls[i].uploadUrl,
          contentTypes[i],
          onProgress: (sent, total) => onImageProgress?.call(i, sent, total),
        );
        if (!result.success) {
          onImageStatus?.call(i, 'error');
          lastError = result.message;
          break;
        }
        uploadedKeys.add(presigned.urls[i].imageKey);
        onImageStatus?.call(i, 'success');
      }

      // 3. Yuklangan rasmlarni tasdiqlash (qisman bo'lsa ham)
      if (uploadedKeys.isEmpty) {
        return (success: false, message: lastError ?? 'Yuklash xatoligi', imageIds: <int>[]);
      }

      final confirm = await confirmImages(uploadedKeys);
      if (!confirm.success) {
        return (success: false, message: confirm.message, imageIds: <int>[]);
      }

      final ids = confirm.images.map((img) => img.id).toList();
      final allSuccess = uploadedKeys.length == files.length;
      return (
        success: allSuccess,
        message: allSuccess ? confirm.message : (lastError ?? 'Ba\'zi rasmlar yuklanmadi'),
        imageIds: ids,
      );
    } catch (e) {
      return (success: false, message: 'Xatolik: $e', imageIds: <int>[]);
    }
  }

  String _extractMessage(dynamic data) {
    if (data is! Map) return 'Xatolik';
    final msg = data['message'] as String?;
    if (msg != null && msg.isNotEmpty) return msg;
    final errors = data['errors'];
    if (errors is Map && errors.isNotEmpty) {
      final first = errors.values.first;
      if (first is List && first.isNotEmpty) return first.first.toString();
    }
    return 'Xatolik';
  }

  String _dioErrorMessage(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return 'Serverga ulanib bo\'lmadi';
    }
    if (e.response?.data is Map) {
      final msg = _extractMessage(e.response!.data);
      if (msg.isNotEmpty) return msg;
    }
    return e.message ?? 'Serverga ulanib bo\'lmadi';
  }
}
