import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:kitchenowl/cubits/recipe_cubit.dart';
import 'package:kitchenowl/item_icons.dart';
import 'package:kitchenowl/models/item.dart';
import 'package:kitchenowl/models/recipe.dart';
import 'package:markdown/markdown.dart' as md;

class RecipeItemMarkdownBuilder extends MarkdownElementBuilder {
  final RecipeCubit cubit;

  RecipeItemMarkdownBuilder({required this.cubit});

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    return RichText(
      text: TextSpan(children: [
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: BlocBuilder<RecipeCubit, RecipeState>(
            bloc: cubit,
            buildWhen: (previous, current) =>
                previous.dynamicRecipe.items.firstWhere(
                  (e) => e.name.toLowerCase() == element.textContent,
                ) !=
                current.dynamicRecipe.items.firstWhere(
                  (e) => e.name.toLowerCase() == element.textContent,
                ),
            builder: (context, state) {
              RecipeItem item = state.dynamicRecipe.items.firstWhere(
                (e) => e.name.toLowerCase() == element.textContent,
              );
              IconData? icon = ItemIcons.get(item);

              return Chip(
                avatar: icon != null ? Icon(icon) : null,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: EdgeInsets.zero,
                labelPadding: icon != null
                    ? const EdgeInsets.only(left: 1, right: 4)
                    : null,
                label: Text(item.name +
                    (item.description.isNotEmpty
                        ? " (${_limitString(item.description)})"
                        : "")),
              );
            },
          ),
        ),
      ]),
    );
  }

  String _limitString(String s) {
    return s.length > 15 ? "${s.substring(0, math.min(15, s.length))}..." : s;
  }
}

class RecipeItemMarkdownSyntax extends md.InlineSyntax {
  final Recipe recipe;

  RecipeItemMarkdownSyntax(this.recipe)
      : super(
          _pattern,
          caseSensitive: false,
        );

  static const String _pattern = r'@([^ \n,-\.\(\)]+)';

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final name = match[1]!.replaceAll("_", " ").trim().toLowerCase();
    if (!recipe.items.map((e) => e.name.toLowerCase()).contains(name)) {
      parser.advanceBy(1);

      return false;
    }

    parser.addNode(md.Element.text('recipeItem', name));

    return true;
  }
}
