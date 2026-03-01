import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';

/// Rasmlarni 20MB dan kichik qiladi — backend limitiga mos
const int _maxBytes = 20 * 1024 * 1024; // 20MB
const int _maxWidth = 1920;
const int _quality = 80;

Future<List<File>> compressImages(List<File> files) async {
  final result = <File>[];
  final tempDir = Directory.systemTemp;

  for (var i = 0; i < files.length; i++) {
    final file = files[i];
    var quality = _quality;
    var width = _maxWidth;

    while (quality >= 50) {
      final targetPath = '${tempDir.path}/avtovodiy_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
      final compressed = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        format: CompressFormat.jpeg,
        quality: quality,
        minWidth: width,
      );

      if (compressed == null) {
        result.add(file);
        break;
      }

      final compressedFile = File(compressed.path);
      final size = await compressedFile.length();
      if (size <= _maxBytes) {
        result.add(compressedFile);
        break;
      }

      quality -= 15;
      width = (width * 0.85).round();
      if (quality < 50 || width < 800) {
        result.add(compressedFile);
        break;
      }
    }
  }

  return result;
}
