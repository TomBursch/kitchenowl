import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:kitchenowl/cubits/recipe_cubit.dart';
import 'package:kitchenowl/helpers/recipe_item_markdown_extension.dart';
import 'package:kitchenowl/helpers/short_image_markdown_extension.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/recipe.dart';
import 'package:kitchenowl/widgets/kitchenowl_markdown_builder.dart';
import 'package:markdown/markdown.dart' as md;

class RecipeMarkdownBody extends StatelessWidget {
  final Recipe recipe;
  final MarkdownElementBuilder? recipeItemBuilder;

  const RecipeMarkdownBody({
    super.key,
    required this.recipe,
    this.recipeItemBuilder,
  });

  List<md.Node> _parseAndGroupMarkdown(md.ExtensionSet extensionSet) {
    final md.Document document = md.Document(
      extensionSet: extensionSet,
      encodeHtml: false,
    );

    // Parse the source Markdown data into nodes of an Abstract Syntax Tree.
    final List<String> lines = const LineSplitter().convert(recipe.description);
    final List<md.Node> astNodes = document.parseLines(lines);

    List<md.Node> result = [];
    for (final md.Node node in astNodes) {
      if (node is md.Element && node.tag == 'ol') {
        int index = 1;
        if (node.attributes['start'] != null) {
          index = int.parse(node.attributes['start']!);
        }
        node.children?.forEach((child) {
          result.add(child);
          if (child is md.Element) {
            child.attributes['indexText'] = (index++).toString();
          }
        });

        continue;
      }
      result.add(node);
    }

    return result;
  }

  (md.Node, String?) _extractAndRemoveImage(md.Node step) {
    if (step is md.Element && step.tag == 'li' && step.children != null) {
      md.Node? first = step.children?.firstOrNull;
      if (first != null && first is md.Element && first.tag == "p") {
        md.Node? possibleImg = first.children?.firstOrNull;
        if (possibleImg != null &&
            possibleImg is md.Element &&
            possibleImg.tag == "img") {
          first.children?.removeAt(0);
          return (step, possibleImg.attributes['src']);
        }
      }
    }
    return (step, null);
  }

  @override
  Widget build(BuildContext context) {
    md.ExtensionSet extensionSet = md.ExtensionSet(
      md.ExtensionSet.gitHubWeb.blockSyntaxes,
      md.ExtensionSet.gitHubWeb.inlineSyntaxes +
          [
            ShortImageMarkdownSyntax(),
            RecipeExplicitItemMarkdownSyntax(recipe),
          ],
    );

    List<md.Node> nodes = _parseAndGroupMarkdown(extensionSet);
    return Column(
      children: nodes.map((node) {
        String? stepImage;
        (node, stepImage) = _extractAndRemoveImage(node);
        final child = KitchenOwlMarkdownBuilder(
          nodes: [node],
          builders: <String, MarkdownElementBuilder>{
            'recipeItem': recipeItemBuilder ??
                RecipeCubitItemMarkdownBuilder(
                  cubit: BlocProvider.of<RecipeCubit>(context),
                ),
          },
          extensionSet: extensionSet,
          imageBuilder: (config) => Image(
            fit: BoxFit.cover,
            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) =>
                Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: child,
              ),
            ),
            image: getImageProvider(
              context,
              int.tryParse(config.uri.toString()) == 0
                  ? recipe.image ?? config.uri.toString()
                  : config.uri.toString(),
            ),
            loadingBuilder: (context, child, progress) => progress == null
                ? child
                : Center(
                    child: CircularProgressIndicator(
                      value: (progress.expectedTotalBytes != null)
                          ? (progress.cumulativeBytesLoaded /
                              progress.expectedTotalBytes!)
                          : null,
                    ),
                  ),
            errorBuilder: (context, url, error) => const Icon(Icons.error),
          ),
        );
        if (node is md.Element && node.tag == 'li')
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(right: 12),
                  width: 55,
                  alignment: Alignment.center,
                  child: Text(
                    "${node.attributes['indexText']}.",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                  ),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.primaryContainer,
                  ),
                ),
                Expanded(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Divider(),
                    if (stepImage != null)
                      Image(
                        fit: BoxFit.cover,
                        frameBuilder:
                            (context, child, frame, wasSynchronouslyLoaded) =>
                                Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: child,
                          ),
                        ),
                        image: getImageProvider(
                            context,
                            int.tryParse(stepImage) == 0
                                ? recipe.image ?? stepImage
                                : stepImage),
                        loadingBuilder: (context, child, progress) =>
                            progress == null
                                ? child
                                : Center(
                                    child: CircularProgressIndicator(
                                      value: (progress.expectedTotalBytes !=
                                              null)
                                          ? (progress.cumulativeBytesLoaded /
                                              progress.expectedTotalBytes!)
                                          : null,
                                    ),
                                  ),
                        errorBuilder: (context, url, error) =>
                            const Icon(Icons.error),
                      ),
                    child,
                  ],
                )),
              ],
            ),
          );
        return child;
      }).toList(),
    );
  }
}
