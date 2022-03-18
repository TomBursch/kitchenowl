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
    return Card(
      child: ListTile(
        title: Text(recipe.name),
        trailing: const Icon(Icons.arrow_right_rounded),
        selected: recipe.isPlanned,
        subtitle: description,
        onTap: () async {
          final res = await Navigator.of(context).push<UpdateEnum>(
            MaterialPageRoute(
              builder: (context) => RecipePage(
                recipe: recipe,
              ),
            ),
          );
          if (onUpdated != null &&
              (res == UpdateEnum.updated || res == UpdateEnum.deleted)) {
            onUpdated!();
          }
        },
      ),
    );
  }
}
