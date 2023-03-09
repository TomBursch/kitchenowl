import 'dart:io';

import 'package:animations/animations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kitchenowl/enums/update_enum.dart';
import 'package:kitchenowl/models/recipe.dart';
import 'package:kitchenowl/pages/recipe_page.dart';

class RecipeItemWidget extends StatelessWidget {
  final Recipe recipe;
  final void Function()? onUpdated;
  final Widget? description;

  const RecipeItemWidget({
    Key? key,
    required this.recipe,
    this.onUpdated,
    this.description,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return OpenContainer<UpdateEnum>(
      useRootNavigator: true,
      closedColor: ElevationOverlay.applySurfaceTint(
        Theme.of(context).colorScheme.surface,
        Theme.of(context).colorScheme.surfaceTint,
        1,
      ).withAlpha(0),
      closedElevation: 0,
      closedShape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(14),
        ),
      ),
      openColor: Theme.of(context).scaffoldBackgroundColor,
      onClosed: _handleUpdate,
      closedBuilder: (context, toggle) => Card(
        child: ListTile(
          title: Text(recipe.name),
          trailing: const Icon(Icons.arrow_right_rounded),
          selected: recipe.isPlanned,
          subtitle: description,
          onTap: (kIsWeb || Platform.isIOS)
              ? () async {
                  context.go(
                    "/recipes/${recipe.id}",
                    extra: recipe,
                  );
                  // _handleUpdate(res);
                }
              : toggle,
        ),
      ),
      openBuilder: (
        BuildContext context,
        toggle,
      ) =>
          RecipePage(
        recipe: recipe,
      ),
    );
  }

  void _handleUpdate(UpdateEnum? res) {
    if (onUpdated != null &&
        (res == UpdateEnum.updated || res == UpdateEnum.deleted)) {
      onUpdated!();
    }
  }
}
