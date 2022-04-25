import 'dart:io';

import 'package:animations/animations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
    return Padding(
      padding: Theme.of(context).cardTheme.margin ??
          const EdgeInsets.symmetric(vertical: 4),
      child: OpenContainer<UpdateEnum>(
        closedColor: Theme.of(context).cardColor,
        openColor: Theme.of(context).scaffoldBackgroundColor,
        onClosed: _handleUpdate,
        closedBuilder: (context, toggle) => ListTile(
          title: Text(recipe.name),
          trailing: const Icon(Icons.arrow_right_rounded),
          selected: recipe.isPlanned,
          subtitle: description,
          onTap: (kIsWeb || !Platform.isIOS)
              ? toggle
              : () async {
                  final res = await Navigator.of(context)
                      .push<UpdateEnum>(MaterialPageRoute(
                    builder: (context) => RecipePage(
                      recipe: recipe,
                    ),
                  ));
                  _handleUpdate(res);
                },
        ),
        openBuilder: (
          BuildContext context,
          toggle,
        ) =>
            RecipePage(
          recipe: recipe,
        ),
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
