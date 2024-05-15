import 'package:flutter/material.dart';
import 'package:kitchenowl/kitchenowl.dart';

Future<bool> askForConfirmation({
  required BuildContext context,
  Widget? content,
  Widget? title,
  String? confirmText,
  String? cancelText,
  bool showCancel = true,
  Color? confirmBackgroundColor = Colors.redAccent,
  Color? confirmForegroundColor = Colors.white,
  Color? cancelColor,
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
                  foregroundColor: WidgetStateProperty.all<Color>(
                    cancelColor ?? Theme.of(context).disabledColor,
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  cancelText ?? AppLocalizations.of(context)!.cancel,
                ),
              ),
            FilledButton(
              style: confirmBackgroundColor != null ||
                      confirmForegroundColor != null
                  ? ButtonStyle(
                      backgroundColor: confirmBackgroundColor != null
                          ? WidgetStateProperty.all<Color>(
                              confirmBackgroundColor,
                            )
                          : null,
                      foregroundColor: confirmForegroundColor != null
                          ? WidgetStateProperty.all<Color>(
                              confirmForegroundColor,
                            )
                          : null,
                    )
                  : null,
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(confirmText ?? AppLocalizations.of(context)!.delete),
            ),
          ],
        );
      },
    ) ??
    false;
