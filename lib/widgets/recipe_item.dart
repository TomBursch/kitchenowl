import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/recipe_list_cubit.dart';
import 'package:kitchenowl/enums/update_enum.dart';
import 'package:kitchenowl/models/recipe.dart';
import 'package:kitchenowl/models/tag.dart';
import 'package:kitchenowl/pages/recipe_page.dart';

class RecipeItemWidget extends StatelessWidget {
  final Recipe recipe;
  final List<Tag> tags;
  final void Function() onUpdated;

  const RecipeItemWidget({
    Key key,
    @required this.recipe,
    this.onUpdated,
    this.tags,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(recipe.name),
        trailing: const Icon(Icons.arrow_right_rounded),
        selected: recipe.isPlanned,
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
            onUpdated();
          }
        },
      ),
    );
  }
}
