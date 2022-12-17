import 'package:flutter/material.dart';

// ignore: long-parameter-list
ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showSnackbar({
  required BuildContext context,
  SnackBarAction? action,
  required Widget content,
  Duration? duration,
  double? width = 180,
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
        width: width,
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        clipBehavior: Clip.none,
        backgroundColor: Theme.of(context).cardColor,
      ),
    );
