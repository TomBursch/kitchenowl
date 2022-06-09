import 'package:flutter/material.dart';

ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showSnackbar({
  required BuildContext context,
  SnackBarAction? action,
  required Widget content,
  Duration? duration,
}) =>
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        action: action,
        content: DefaultTextStyle(
          style: Theme.of(context).textTheme.bodyText1!,
          textAlign: action == null ? TextAlign.center : null,
          child: content,
        ),
        duration: duration ?? const Duration(milliseconds: 1500),
        width: 180,
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.none,
        backgroundColor: Theme.of(context).cardColor,
      ),
    );
