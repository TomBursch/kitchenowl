import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:kitchenowl/cubits/recipe_cubit.dart';
import 'package:kitchenowl/helpers/recipe_item_markdown_extension.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/recipe.dart';
import 'package:markdown/markdown.dart' as md;

class RecipeMarkdownBody extends StatelessWidget {
  final Recipe recipe;
  final MarkdownElementBuilder? recipeItemBuilder;

  const RecipeMarkdownBody({
    super.key,
    required this.recipe,
    this.recipeItemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return KitchenOwlMarkdownBody(
      data: recipe.description,
      builders: <String, MarkdownElementBuilder>{
        'recipeItem': recipeItemBuilder ??
            RecipeCubitItemMarkdownBuilder(
              cubit: BlocProvider.of<RecipeCubit>(context),
            ),
      },
      extensionSet: md.ExtensionSet(
        md.ExtensionSet.gitHubWeb.blockSyntaxes,
        md.ExtensionSet.gitHubWeb.inlineSyntaxes +
            [
              RecipeItemMarkdownSyntax(recipe),
            ],
      ),
    );
  }
}
