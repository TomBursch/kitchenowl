import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:universal_html/html.dart' as html;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart' as SharePlus;

abstract class Share {
  static Future<void> shareJsonFile(
    BuildContext context,
    String content,
    String filename,
  ) async {
    if (kIsWeb) {
      final url = Uri.dataFromString(
        content,
        mimeType: 'text/plain',
        encoding: utf8,
      );
      final anchor = html.document.createElement('a') as html.AnchorElement
        ..href = url.toString()
        ..style.display = 'none'
        ..download = filename;
      html.document.body?.children.add(anchor);

      anchor.click();

      html.document.body?.children.remove(anchor);
      html.Url.revokeObjectUrl(url.toString());
    } else if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
      String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Please select an output file:',
        allowedExtensions: ['json'],
        type: FileType.custom,
        fileName: filename,
      );
      if (outputPath == null) return;

      try {
        await File(outputPath).writeAsString(content);
      } catch (_) {}
    } else {
      final box = context.findRenderObject() as RenderBox?;
      SharePlus.Share.shareXFiles(
        [
          SharePlus.XFile.fromData(
            Uint8List.fromList(content.codeUnits),
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
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
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
