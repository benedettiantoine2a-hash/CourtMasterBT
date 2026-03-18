import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

class ShareService {
  final ScreenshotController _screenshotController = ScreenshotController();

  ScreenshotController get controller => _screenshotController;

  Future<void> shareMatchCard(Widget matchCard) async {
    try {
      final directory = await getTemporaryDirectory();
      final String fileName = 'match_result_${DateTime.now().millisecondsSinceEpoch}.png';
      final imagePath = await _screenshotController.captureFromWidget(
        matchCard,
        delay: const Duration(milliseconds: 100),
      );

      final File imageFile = File('${directory.path}/$fileName');
      await imageFile.writeAsBytes(imagePath);

      await Share.shareXFiles(
        [XFile(imageFile.path)],
        text: 'Regardez le résultat de notre match de Padel ! 🎾',
      );
    } catch (e) {
      debugPrint('Erreur lors du partage : $e');
    }
  }
}
