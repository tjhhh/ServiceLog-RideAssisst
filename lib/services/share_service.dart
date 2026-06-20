import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../models/motorcycle.dart';
import '../models/service_record.dart';
import '../widgets/history/history_export_template.dart';

class ShareService {
  static const int _maxFileSizeBytes = 1 * 1024 * 1024; // 1 MB

  /// Render the export template for a single [record] and share it as JPG.
  static Future<void> shareServiceRecord({
    required BuildContext context,
    required ServiceRecord record,
    required Motorcycle? motorcycle,
    required Color themeColor,
  }) async {
    // Show loading
    _showLoading(context);

    try {
      final controller = ScreenshotController();

      // 1. Render widget off-screen to PNG bytes.
      //    - BoxConstraints: give bounded 800px width (prevents Infinity crash)
      //    - DefaultAssetBundle: allows Image.asset to resolve logo_ra.png
      //    - Directionality: required by Material widgets in off-screen context
      final pngBytes = await controller.captureFromLongWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: DefaultAssetBundle(
            bundle: rootBundle,
            child: HistoryExportTemplate(
              record: record,
              motorcycle: motorcycle,
              themeColor: themeColor,
            ),
          ),
        ),
        pixelRatio: 2.0,
        delay: const Duration(milliseconds: 150),
        constraints: const BoxConstraints(
          minWidth: 800,
          maxWidth: 800,
        ),
      );

      // 2. Compress PNG → JPG iteratively until < 1 MB
      final jpgBytes = await _compressToUnder1MB(pngBytes);

      // 3. Save to temp dir
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${tempDir.path}/rideassist_service_$timestamp.jpg');
      await file.writeAsBytes(jpgBytes);

      // 4. Close loading & share
      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/jpeg')],
        subject: 'Service Record - RideAssist',
        text:
            '📋 Service Record dari RideAssist\n'
            '🔧 ${record.serviceType} Maintenance\n'
            '📅 ${record.date.day}/${record.date.month}/${record.date.year}',
      );
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuat export: $e'),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    }
  }

  /// Iteratively compress [pngBytes] as JPEG, reducing quality by 10 each pass
  /// until the result is under [_maxFileSizeBytes] (1 MB).
  static Future<Uint8List> _compressToUnder1MB(Uint8List pngBytes) async {
    int quality = 88;
    Uint8List result = pngBytes;

    while (result.length > _maxFileSizeBytes && quality > 10) {
      final compressed = await FlutterImageCompress.compressWithList(
        pngBytes,
        quality: quality,
        format: CompressFormat.jpeg,
        minWidth: 800,
        minHeight: 1,
        keepExif: false,
      );
      if (compressed != null) result = compressed;
      quality -= 10;
    }

    // Final safety: if still too large, hard compress to quality 20
    if (result.length > _maxFileSizeBytes) {
      final last = await FlutterImageCompress.compressWithList(
        pngBytes,
        quality: 20,
        format: CompressFormat.jpeg,
        minWidth: 600,
        minHeight: 1,
        keepExif: false,
      );
      if (last != null) result = last;
    }

    return result;
  }

  static void _showLoading(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => const Center(
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(20)),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Menyiapkan gambar...',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }
}
