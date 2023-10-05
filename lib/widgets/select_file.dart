import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kitchenowl/helpers/named_bytearray.dart';
import 'package:kitchenowl/kitchenowl.dart';

// ignore: long-method
Future<NamedByteArray?> selectFile({
  required BuildContext context,
  required String title,
  bool deleteOption = false,
}) async {
  final ImagePicker picker = ImagePicker();

  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    int? i = await showDialog<int>(
      context: context,
      builder: (context) => SelectDialog(
        title: title,
        cancelText: AppLocalizations.of(context)!.cancel,
        options: [
          SelectDialogOption(
            ImageSource.camera.index,
            AppLocalizations.of(context)!.camera,
            Icons.camera_alt_rounded,
          ),
          SelectDialogOption(
            ImageSource.gallery.index,
            AppLocalizations.of(context)!.gallery,
            Icons.photo_library_rounded,
          ),
          if (deleteOption)
            SelectDialogOption(
              -1,
              AppLocalizations.of(context)!.delete,
              Icons.delete,
            ),
        ],
      ),
    );
    if (i == null) return null;
    if (i == -1) return NamedByteArray.empty;
    XFile? result = await picker.pickImage(
      source: ImageSource.values[i],
      imageQuality: 90,
      maxHeight: 2048,
      maxWidth: 2048,
    );
    if (result != null) {
      return NamedByteArray(result.name, await result.readAsBytes());
    }
  } else {
    if (deleteOption) {
      int? i = await showDialog<int>(
        context: context,
        builder: (context) => SelectDialog(
          title: title,
          cancelText: AppLocalizations.of(context)!.cancel,
          options: [
            SelectDialogOption(
              0,
              AppLocalizations.of(context)!.gallery,
              Icons.folder_open_rounded,
            ),
            SelectDialogOption(
              -1,
              AppLocalizations.of(context)!.delete,
              Icons.delete,
            ),
          ],
        ),
      );
      if (i == null) return null;
      if (i == -1) return NamedByteArray.empty;
    }
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result != null && result.files.first.name.isNotEmpty) {
      return NamedByteArray(result.files.first.name, result.files.first.bytes!);
    }
  }

  return null;
}
