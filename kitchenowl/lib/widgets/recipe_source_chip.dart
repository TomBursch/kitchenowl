import 'package:flutter/material.dart';
import 'package:kitchenowl/helpers/url_launcher.dart';
import 'package:kitchenowl/kitchenowl.dart';

class RecipeSourceChip extends StatelessWidget {
  final String source;

  const RecipeSourceChip({super.key, required this.source});

  @override
  Widget build(BuildContext context) {
    if (isValidUrl(source)) {
      final host = (Uri.tryParse(source)?.host ?? source);
      return ActionChip(
        avatar: Icon(
          Icons.link,
          color: Theme.of(context).colorScheme.onPrimary,
        ),
        label: Text(
          host.isEmpty ? AppLocalizations.of(context)!.recipeSource : host,
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
