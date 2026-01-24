import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:kitchenowl/helpers/url_launcher.dart';

class KitchenOwlMarkdownBody extends StatelessWidget {
  final String data;
  final Map<String, MarkdownElementBuilder> builders;
  final MarkdownStyleSheet? styleSheet;
  final md.ExtensionSet? extensionSet;

  const KitchenOwlMarkdownBody({
    super.key,
    required this.data,
    this.builders = const <String, MarkdownElementBuilder>{},
    this.styleSheet,
    this.extensionSet,
  });

  @override
  Widget build(BuildContext context) {
    return MarkdownBody(
      data: data,
      shrinkWrap: true,
      styleSheet: MarkdownStyleSheet.fromTheme(
        Theme.of(context),
      )
          .copyWith(
            blockquoteDecoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color ??
                  Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(2.0),
            ),
          )
          .merge(styleSheet),
      imageBuilder: (uri, title, alt) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: CachedNetworkImage(
            imageUrl: uri.toString(),
            placeholder: (context, url) =>
                const Center(child: CircularProgressIndicator()),
            errorWidget: (context, url, error) => const Icon(Icons.error),
          ),
        ),
      ),
      onTapLink: (text, href, title) {
        if (href != null && isValidUrl(href)) {
          openUrl(context, href);
        }
      },
      builders: builders,
      extensionSet: extensionSet,
    );
  }
}
