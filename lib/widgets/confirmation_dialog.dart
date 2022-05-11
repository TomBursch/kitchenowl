import 'package:flutter/material.dart';
import 'package:kitchenowl/kitchenowl.dart';

// ignore: long-parameter-list
Future<bool> askForConfirmation({
  required BuildContext context,
  Widget? content,
  Widget? title,
  String? confirmText,
  String? cancelText,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: title,
          content: content,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          actions: <Widget>[
            TextButton(
              style: ButtonStyle(
                foregroundColor: MaterialStateProperty.all<Color>(
                  Theme.of(context).disabledColor,
                ),
              ),
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(cancelText ?? AppLocalizations.of(context)!.cancel),
            ),
            TextButton(
              style: ButtonStyle(
                foregroundColor: MaterialStateProperty.all<Color>(
                  Colors.red,
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
