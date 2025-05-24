import 'dart:math' as math;
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:kitchenowl/cubits/recipe_cubit.dart';
import 'package:kitchenowl/item_icons.dart';
import 'package:kitchenowl/models/item.dart';
import 'package:kitchenowl/models/recipe.dart';
import 'package:markdown/markdown.dart' as md;

class RecipeItemMarkdownBuilder extends MarkdownElementBuilder {
  final List<RecipeItem> items;

  RecipeItemMarkdownBuilder({required this.items});

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    if ((parentStyle?.fontSize ?? 0) > 14) return null;

    RecipeItem item = items.firstWhere(
      (e) => e.name.toLowerCase() == element.textContent,
    );
    IconData? icon = ItemIcons.get(item);
    return RichText(
      text: TextSpan(children: [
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Chip(
            avatar: icon != null ? Icon(icon) : null,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: EdgeInsets.zero,
            labelPadding:
                icon != null ? const EdgeInsets.only(left: 1, right: 4) : null,
            label: Text(item.name +
                (item.description.isNotEmpty
                    ? " (${_limitString(item.description)})"
                    : "")),
          ),
        ),
      ]),
    );
  }

  String _limitString(String s) {
    return s.length > 15 ? "${s.substring(0, math.min(15, s.length))}..." : s;
  }
}

class RecipeCubitItemMarkdownBuilder extends MarkdownElementBuilder {
  final RecipeCubit cubit;

  RecipeCubitItemMarkdownBuilder({required this.cubit});

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    if ((parentStyle?.fontSize ?? 0) > 14) return null;

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

class RecipeExplicitItemMarkdownSyntax extends md.InlineSyntax {
  final Recipe recipe;

  RecipeExplicitItemMarkdownSyntax(this.recipe)
      : super(
          _pattern,
          caseSensitive: false,
        );

  static const String _pattern =
      r"""@([^ \n\.\(\)\\\/\?\*\+,!%$#@^;:"=~]+)"""; // TODO: replace with \p{L} and unicode=true

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

class RecipeImplicitItemMarkdownSyntax extends md.InlineSyntax {
  final Recipe recipe;

  RecipeImplicitItemMarkdownSyntax(this.recipe)
      : super(
          "\\b(" +
              recipe.items
                  // sort long to short names
                  .sorted((a, b) => b.name.length.compareTo(a.name.length))
                  .map((e) => e.name)
                  .fold("", (a, b) => a.isEmpty ? "$b" : "$a|$b") +
              ")\\b",
          caseSensitive: false,
        );

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final name = match[1]!.toLowerCase();
    if (!recipe.items.map((e) => e.name.toLowerCase()).contains(name)) {
      parser.advanceBy(1);

      return false;
    }

    parser.addNode(md.Element.text('recipeItem', name));

    return true;
  }
}
