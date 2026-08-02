import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchenowl/helpers/recipe_item_markdown_extension.dart';
import 'package:kitchenowl/models/item.dart';
import 'package:kitchenowl/models/recipe.dart';
import 'package:kitchenowl/widgets/item_chip.dart';
import 'package:kitchenowl/widgets/kitchenowl_markdown_builder.dart';
import 'package:markdown/markdown.dart' as md;

void main() {
  test('parses Unicode recipe item names', () {
    const recipe = Recipe(
      items: [
        RecipeItem(name: 'Crème fraîche'),
        RecipeItem(name: '豆腐'),
      ],
    );
    final document = md.Document(
      inlineSyntaxes: [RecipeExplicitItemMarkdownSyntax(recipe)],
    );

    final nodes = document.parseLines([
      '@crème_fraîche{200 g} and @豆腐',
    ]);
    final paragraph = nodes.single as md.Element;
    final recipeItems = paragraph.children!
        .whereType<md.Element>()
        .where((element) => element.tag == 'recipeItem')
        .toList();

    expect(recipeItems.map((element) => element.textContent), [
      'crème fraîche',
      '豆腐',
    ]);
    expect(recipeItems.first.attributes['description'], '200 g');
    expect(recipeItems.first.attributes['trailingSpace'], 'true');
  });

  testWidgets('lays out highlighted ingredients without overlap',
      (tester) async {
    const recipe = Recipe(
      items: [
        RecipeItem(name: 'Zwiebel'),
        RecipeItem(name: 'Knoblauchzehe'),
        RecipeItem(name: 'Ingwer'),
      ],
    );
    final extensionSet = md.ExtensionSet(
      md.ExtensionSet.gitHubWeb.blockSyntaxes,
      md.ExtensionSet.gitHubWeb.inlineSyntaxes +
          [RecipeExplicitItemMarkdownSyntax(recipe)],
    );
    final document = md.Document(extensionSet: extensionSet);
    final nodes = document.parseLines([
      'Die @Zwiebel{1 Stück}, die @Knoblauchzehe{1 Stück} und den '
          '@Ingwer{1 cm Stück} fein würfeln.',
    ]);

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.8)),
          child: Scaffold(
            body: SizedBox(
              width: 320,
              child: KitchenOwlMarkdownBuilder(
                nodes: nodes,
                extensionSet: extensionSet,
                builders: {
                  'recipeItem': RecipeItemMarkdownBuilder(items: recipe.items),
                },
              ),
            ),
          ),
        ),
      ),
    );

    final chips = find.byType(ItemChip);
    expect(chips, findsNWidgets(3));
    for (var first = 0; first < 3; first++) {
      for (var second = first + 1; second < 3; second++) {
        expect(
          tester.getRect(chips.at(first)).overlaps(
                tester.getRect(chips.at(second)),
              ),
          isFalse,
        );
      }
    }
    final continuation = find.textContaining('fein würfeln.');
    expect(continuation, findsOneWidget);
    expect(tester.getTopLeft(continuation).dx, 0);
    expect(tester.takeException(), isNull);
  });
}
