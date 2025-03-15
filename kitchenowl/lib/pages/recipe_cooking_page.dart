import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:kitchenowl/helpers/recipe_item_markdown_extension.dart';
import 'package:kitchenowl/helpers/url_launcher.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/recipe.dart';
import 'package:kitchenowl/widgets/kitchenowl_markdown_builder.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:wakelock_plus/wakelock_plus.dart';

class RecipeCookingPage extends StatefulWidget {
  final Recipe recipe;

  RecipeCookingPage({
    super.key,
    required this.recipe,
  });

  @override
  State<StatefulWidget> createState() => _RecipeCookingPageState();
}

class _RecipeCookingPageState extends State<RecipeCookingPage> {
  int step = 0;
  double textScaleFactor = 1;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
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
          result.last.add(child);
          result.add([]);
        });

        continue;
      }
      result.last.add(node);
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    md.ExtensionSet extensionSet = md.ExtensionSet(
      md.ExtensionSet.gitHubWeb.blockSyntaxes,
      md.ExtensionSet.gitHubWeb.inlineSyntaxes +
          [
            RecipeItemMarkdownSyntax(widget.recipe),
          ],
    );

    List<List<md.Node>> nodes = _parseAndGroupMarkdown(extensionSet);

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
                    onPressed: () => setState(() {
                      textScaleFactor += 0.1;
                    }),
                    icon: Icon(Icons.text_increase_rounded),
                  ),
                  IconButton(
                    onPressed: () => setState(() {
                      textScaleFactor -= 0.1;
                    }),
                    icon: Icon(Icons.text_decrease_rounded),
                  ),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ConstrainedBox(
                    constraints: BoxConstraints.tightFor(width: 1600),
                    child: IndexedStack(
                      children: nodes.fold(
                        [],
                        (List<Widget> acc, List<md.Node> w) => acc
                          ..add(
                            KitchenOwlMarkdownBuilder(
                              nodes: w,
                              imageBuilder: (uri, title, alt) =>
                                  CachedNetworkImage(
                                imageUrl: uri.toString(),
                                placeholder: (context, url) =>
                                    const CircularProgressIndicator(),
                                errorWidget: (context, url, error) =>
                                    const Icon(Icons.error),
                              ),
                              builders: <String, MarkdownElementBuilder>{
                                'recipeItem': RecipeItemMarkdownBuilder(
                                    items: widget.recipe.items)
                              },
                              styleSheet: MarkdownStyleSheet.fromTheme(
                                Theme.of(context),
                              ).copyWith(
                                blockquoteDecoration: BoxDecoration(
                                  color: Theme.of(context).cardTheme.color ??
                                      Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(2.0),
                                ),
                                textScaleFactor: textScaleFactor,
                              ),
                              onTapLink: (text, href, title) {
                                if (href != null && isValidUrl(href)) {
                                  openUrl(context, href);
                                }
                              },
                              extensionSet: extensionSet,
                            ),
                          ),
                      ),
                      index: step,
                    ),
                  ),
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
