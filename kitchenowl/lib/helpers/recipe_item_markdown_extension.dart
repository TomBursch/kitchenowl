import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:fraction/fraction.dart';
import 'package:kitchenowl/cubits/recipe_cubit.dart';
import 'package:kitchenowl/helpers/string_scaler.dart';
import 'package:kitchenowl/models/item.dart';
import 'package:kitchenowl/models/recipe.dart';
import 'package:kitchenowl/widgets/item_chip.dart';
import 'package:markdown/markdown.dart' as md;

class RecipeItemMarkdownBuilder extends MarkdownElementBuilder {
  final List<RecipeItem> items;
  final Fraction? itemScaledFactor;

  RecipeItemMarkdownBuilder({required this.items, this.itemScaledFactor});

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
    String? overridenDescription = element.attributes["description"];
    if (overridenDescription != null && itemScaledFactor != null) {
      overridenDescription =
          StringScaler.scale(overridenDescription, itemScaledFactor!);
    }
    return RichText(
      text: TextSpan(children: [
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: ItemChip(
            item: item,
            description: overridenDescription,
          ),
        ),
      ]),
    );
  }
}

class RecipeCubitItemMarkdownBuilder extends MarkdownElementBuilder {
  final RecipeCubit cubit;

  RecipeCubitItemMarkdownBuilder({required this.cubit});

  String cleanItemName(String name) {
    return name.toLowerCase().replaceAll(
        RegExp(r"""\n|\.|\(|\)|\\|\/|\?|\*|\+|,|!|%|$|#|@|^|;|:|"|=|~|{"""),
        "");
  }

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
                      (e) => cleanItemName(e.name) == element.textContent,
                    ) !=
                    current.dynamicRecipe.items.firstWhere(
                      (e) => cleanItemName(e.name) == element.textContent,
                    ) ||
                previous.selectedYields != current.selectedYields,
            builder: (context, state) {
              RecipeItem item = state.dynamicRecipe.items.firstWhere(
                (e) => cleanItemName(e.name) == element.textContent,
              );

              String? overridenDescription = element.attributes["description"];
              if (overridenDescription != null &&
                  state.recipe.yields != 0 &&
                  state.selectedYields != null &&
                  state.recipe.yields != state.selectedYields) {
                overridenDescription = StringScaler.scale(overridenDescription,
                    Fraction(state.selectedYields!, state.recipe.yields));
              }

              return ItemChip(
                item: item,
                description: overridenDescription,
              );
            },
          ),
        ),
      ]),
    );
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
      r"""@([^ \n\.\(\)\\\/\?\*\+,!%$#@^;:"=~{]+)({([^}]*)})?"""; // TODO: replace with \p{L} and unicode=true

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final name = match[1]!.replaceAll("_", " ").trim().toLowerCase();
    if (!recipe.items
        .map((e) => e.name.toLowerCase().replaceAll(
            RegExp(r"""\n|\.|\(|\)|\\|\/|\?|\*|\+|,|!|%|$|#|@|^|;|:|"|=|~|{"""),
            ""))
        .contains(name)) {
      parser.advanceBy(1);

      return false;
    }

    final node = md.Element.text('recipeItem', name);
    if (match.group(3) != null)
      node.attributes["description"] = match.group(3)!;
    parser.addNode(node);

    return true;
  }
}
