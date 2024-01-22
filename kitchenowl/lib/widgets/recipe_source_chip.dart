import 'package:flutter/material.dart';
import 'package:kitchenowl/helpers/url_launcher.dart';

class RecipeSourceChip extends StatelessWidget {
  final String source;

  const RecipeSourceChip({super.key, required this.source});

  @override
  Widget build(BuildContext context) {
    if (isValidUrl(source)) {
      return ActionChip(
        avatar: Icon(
          Icons.link,
          color: Theme.of(context).colorScheme.onPrimary,
        ),
        label: Text(
          Uri.tryParse(source)?.host ?? source,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 3,
        onPressed: () => openUrl(context, source),
      );
    }

    return Chip(
      avatar: Icon(
        Icons.book_rounded,
        color: Theme.of(context).colorScheme.onPrimary,
      ),
      label: Text(
        source,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onPrimary,
        ),
      ),
      backgroundColor: Theme.of(context).colorScheme.primary,
      elevation: 3,
    );
  }
}
