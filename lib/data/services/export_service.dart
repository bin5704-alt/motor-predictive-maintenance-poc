import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:ui' as ui;

class ExportService {
  static Future<void> shareText(String text, {String? subject}) async {
    await SharePlus.instance.share(ShareParams(text: text, subject: subject));
  }

  static Future<void> shareImageFromWidget(
    GlobalKey key,
    String fileName,
  ) async {
    try {
      final boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 2.0); // High res
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) return;
      final pngBytes = byteData.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/$fileName.png').create();
      await file.writeAsBytes(pngBytes);

      final xFile = XFile(file.path);
      await SharePlus.instance.share(
        ShareParams(files: [xFile], text: 'Shared from Motor Monitor App'),
      );
    } catch (e) {
      debugPrint('Error sharing image: $e');
    }
  }
}
