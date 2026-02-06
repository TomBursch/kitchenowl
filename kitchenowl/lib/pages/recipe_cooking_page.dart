import 'dart:convert';

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:fraction/fraction.dart';
import 'package:kitchenowl/helpers/markdown_extract_item.dart';
import 'package:kitchenowl/helpers/recipe_item_markdown_extension.dart';
import 'package:kitchenowl/helpers/short_image_markdown_extension.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/item.dart';
import 'package:kitchenowl/models/recipe.dart';
import 'package:kitchenowl/services/storage/storage.dart';
import 'package:kitchenowl/widgets/kitchenowl_markdown_builder.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:sliver_tools/sliver_tools.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class RecipeCookingPage extends StatefulWidget {
  final Recipe recipe;
  final double? initialTextScaleFactor;
  final Fraction? recipeScaleFactor;

  RecipeCookingPage({
    super.key,
    required this.recipe,
    this.initialTextScaleFactor,
    this.recipeScaleFactor,
  });

  @override
  State<StatefulWidget> createState() => _RecipeCookingPageState();
}

class _RecipeCookingPageState extends State<RecipeCookingPage> {
  int step = 0;
  late double textScaleFactor;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    textScaleFactor = widget.initialTextScaleFactor ?? 1;
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    super.dispose();
  }

  List<List<md.Node>> _parseAndGroupMarkdown(md.ExtensionSet extensionSet) {
    final md.Document document = md.Document(
      extensionSet: extensionSet,
      encodeHtml: false,
    );

    // Parse the source Markdown data into nodes of an Abstract Syntax Tree.
    final List<String> lines =
        const LineSplitter().convert(widget.recipe.description);
    final List<md.Node> astNodes = document.parseLines(lines);

    List<List<md.Node>> result = [[]];
    for (final md.Node node in astNodes) {
      if (node is md.Element && node.tag == 'ol') {
        node.children?.forEach((child) {
          if (result.last.isNotEmpty) result.add([]);
          result.last.add(child);
        });

        continue;
      }
      result.last.add(node);
    }

    return result;
  }

  List<Set<RecipeItem>> _extractItems(List<List<md.Node>> steps) {
    return steps.map((step) {
      final visitor = ExtractItemVisitor(
          recipe: widget.recipe, itemScaledFactor: widget.recipeScaleFactor);
      step.forEach((e) => e.accept(visitor));
      return visitor.items;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    md.ExtensionSet extensionSet = md.ExtensionSet(
      md.ExtensionSet.gitHubWeb.blockSyntaxes,
      md.ExtensionSet.gitHubWeb.inlineSyntaxes +
          [
            ShortImageMarkdownSyntax(),
            RecipeExplicitItemMarkdownSyntax(widget.recipe),
          ],
    );

    List<List<md.Node>> nodes = _parseAndGroupMarkdown(extensionSet);
    List<Set<RecipeItem>> stepItems = _extractItems(nodes);

    return Scaffold(
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: Column(
            children: [
              AppBar(
                title: TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  tween: Tween<double>(
                    begin: 1 / (nodes.length),
                    end: (step + 1) / (nodes.length),
                  ),
                  builder: (context, value, _) => LinearProgressIndicator(
                    value: value,
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                actions: [
                  IconButton(
                    onPressed: (textScaleFactor < 4)
                        ? () => setState(() {
                              textScaleFactor += 0.1;
                              PreferenceStorage.getInstance().writeDouble(
                                  key: "recipeCookingPageTextScaleFactor",
                                  value: textScaleFactor);
                            })
                        : null,
                    icon: Icon(Icons.text_increase_rounded),
                  ),
                  IconButton(
                    onPressed: (textScaleFactor > 0.8)
                        ? () => setState(() {
                              textScaleFactor -= 0.1;
                              PreferenceStorage.getInstance().writeDouble(
                                  key: "recipeCookingPageTextScaleFactor",
                                  value: textScaleFactor);
                            })
                        : null,
                    icon: Icon(Icons.text_decrease_rounded),
                  ),
                ],
              ),
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverCrossAxisConstrained(
                      maxCrossAxisExtent: 1600,
                      child: SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverToBoxAdapter(
                          child: AnimatedSize(
                            duration: const Duration(milliseconds: 100),
                            child: PageTransitionSwitcher(
                              transitionBuilder: (
                                Widget child,
                                Animation<double> animation,
                                Animation<double> secondaryAnimation,
                              ) {
                                return SharedAxisTransition(
                                  animation: animation,
                                  secondaryAnimation: secondaryAnimation,
                                  transitionType:
                                      SharedAxisTransitionType.horizontal,
                                  child: child,
                                );
                              },
                              child: KitchenOwlMarkdownBuilder(
                                key: ValueKey(step),
                                nodes: nodes[step],
                                builders: <String, MarkdownElementBuilder>{
                                  'recipeItem': RecipeItemMarkdownBuilder(
                                    items: widget.recipe.items,
                                    itemScaledFactor: widget.recipeScaleFactor,
                                  )
                                },
                                textScaler: TextScaler.linear(textScaleFactor),
                                extensionSet: extensionSet,
                                imageBuilder: (uri, title, alt) => Image(
                                  fit: BoxFit.cover,
                                  frameBuilder: (context, child, frame,
                                          wasSynchronouslyLoaded) =>
                                      Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: child,
                                    ),
                                  ),
                                  image: getImageProvider(
                                    context,
                                    int.tryParse(uri.toString()) == 0
                                        ? widget.recipe.image ?? uri.toString()
                                        : uri.toString(),
                                  ),
                                  loadingBuilder: (context, child, progress) =>
                                      progress == null
                                          ? child
                                          : Center(
                                              child: CircularProgressIndicator(
                                                value: (progress
                                                            .expectedTotalBytes !=
                                                        null)
                                                    ? (progress
                                                            .cumulativeBytesLoaded /
                                                        progress
                                                            .expectedTotalBytes!)
                                                    : null,
                                              ),
                                            ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SliverCrossAxisConstrained(
                      maxCrossAxisExtent: 1600,
                      child: SliverToBoxAdapter(
                        child: Divider(
                          indent: 16,
                          endIndent: 16,
                          height: 32,
                        ),
                      ),
                    ),
                    SliverCrossAxisConstrained(
                      maxCrossAxisExtent: 1600,
                      child: SliverItemGridList<RecipeItem>(
                        items: widget.recipe.items
                            .map((originalItem) => stepItems[step]
                                    .any((e) => e.id == originalItem.id)
                                ? stepItems[step]
                                    .firstWhere((e) => e.id == originalItem.id)
                                : originalItem)
                            .toList(),
                        onPressed: Nullable.empty(),
                        onLongPressed: Nullable.empty(),
                        selected: (item) => stepItems[step].contains(item),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Row(
                  children: [
                    if (step > 0)
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            if (step == 0)
                              Navigator.of(context).pop();
                            else
                              setState(() {
                                step--;
                              });
                          },
                          child: Text(AppLocalizations.of(context)!.back),
                        ),
                      ),
                    if (step == 0) const Spacer(),
                    Expanded(
                      child: Text(
                        "${step + 1} / ${nodes.length}",
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (step < nodes.length - 1)
                            setState(() {
                              step++;
                            });
                          else
                            Navigator.of(context).pop();
                        },
                        child: Text(
                          step < nodes.length - 1
                              ? AppLocalizations.of(context)!.next
                              : AppLocalizations.of(context)!.done,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
