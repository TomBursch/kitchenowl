import 'package:flutter/material.dart';
import 'package:kitchenowl/kitchenowl.dart';

// ignore: long-parameter-list
Future<bool> askForConfirmation({
  required BuildContext context,
  Widget? content,
  Widget? title,
  String? confirmText,
  String? cancelText,
  bool showCancel = true,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: title,
          content: content,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          actions: <Widget>[
            if (showCancel)
              TextButton(
                style: ButtonStyle(
                  foregroundColor: MaterialStateProperty.all<Color>(
                    Theme.of(context).disabledColor,
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  cancelText ?? AppLocalizations.of(context)!.cancel,
                ),
              ),
            TextButton(
              style: ButtonStyle(
                foregroundColor: MaterialStateProperty.all<Color>(
                  Colors.redAccent,
                ),
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(confirmText ?? AppLocalizations.of(context)!.delete),
            ),
          ],
        );
      },
    ) ??
    false;
