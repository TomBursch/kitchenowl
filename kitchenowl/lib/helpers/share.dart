import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:kitchenowl/kitchenowl.dart';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:share_plus/share_plus.dart' as SharePlus;

abstract class Share {
  static Future<void> shareJsonFile(
    BuildContext context,
    String content,
    String filename,
  ) async {
    final bytes = Uint8List.fromList(utf8.encode(content));
    if (kIsWeb ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows) {
      await FilePicker.saveFile(
        dialogTitle: 'Please select an output file:',
        allowedExtensions: ['json'],
        type: FileType.custom,
        fileName: filename,
        bytes: bytes,
      );
    } else {
      final box = context.findRenderObject() as RenderBox?;
      SharePlus.Share.shareXFiles(
        [
          SharePlus.XFile.fromData(
            bytes,
            name: filename,
            mimeType: 'application/json',
          ),
        ],
        sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
      );
    }
  }

  static Future<void> shareUri(BuildContext context, Uri uri) async {
    final box = context.findRenderObject() as RenderBox?;
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS)) {
      SharePlus.Share.shareUri(
        uri,
        sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
      );
    } else {
      Clipboard.setData(
        ClipboardData(
          text: uri.toString(),
        ),
      );
      showSnackbar(
        context: context,
        content: Text(
          AppLocalizations.of(context)!.copied,
        ),
      );
    }
  }
}
