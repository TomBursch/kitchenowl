import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:kitchenowl/helpers/url_launcher.dart';
import 'package:markdown/markdown.dart' as md;

class KitchenOwlMarkdownBuilder extends StatefulWidget {
  /// Creates a widget that parses and displays Markdown.
  ///
  /// The [nodes] argument must not be null.
  const KitchenOwlMarkdownBuilder({
    super.key,
    required this.nodes,
    this.selectable = false,
    this.styleSheet,
    this.styleSheetTheme = MarkdownStyleSheetBaseTheme.material,
    this.syntaxHighlighter,
    this.onSelectionChanged,
    this.onTapLink,
    this.onTapText,
    this.imageDirectory,
    this.blockSyntaxes,
    this.inlineSyntaxes,
    this.extensionSet,
    this.imageBuilder,
    this.checkboxBuilder,
    this.bulletBuilder,
    this.builders = const <String, MarkdownElementBuilder>{},
    this.paddingBuilders = const <String, MarkdownPaddingBuilder>{},
    this.fitContent = false,
    this.listItemCrossAxisAlignment =
        MarkdownListItemCrossAxisAlignment.baseline,
    this.softLineBreak = false,
  });

  /// The Markdown to display.
  final List<md.Node> nodes;

  /// If true, the text is selectable.
  ///
  /// Defaults to false.
  final bool selectable;

  /// The styles to use when displaying the Markdown.
  ///
  /// If null, the styles are inferred from the current [Theme].
  final MarkdownStyleSheet? styleSheet;

  /// Setting to specify base theme for MarkdownStyleSheet
  ///
  /// Default to [MarkdownStyleSheetBaseTheme.material]
  final MarkdownStyleSheetBaseTheme? styleSheetTheme;

  /// The syntax highlighter used to color text in `pre` elements.
  ///
  /// If null, the [MarkdownStyleSheet.code] style is used for `pre` elements.
  final SyntaxHighlighter? syntaxHighlighter;

  /// Called when the user taps a link.
  final MarkdownTapLinkCallback? onTapLink;

  /// Called when the user changes selection when [selectable] is set to true.
  final MarkdownOnSelectionChangedCallback? onSelectionChanged;

  /// Default tap handler used when [selectable] is set to true
  final VoidCallback? onTapText;

  /// The base directory holding images referenced by Img tags with local or network file paths.
  final String? imageDirectory;

  /// Collection of custom block syntax types to be used parsing the Markdown data.
  final List<md.BlockSyntax>? blockSyntaxes;

  /// Collection of custom inline syntax types to be used parsing the Markdown data.
  final List<md.InlineSyntax>? inlineSyntaxes;

  /// Markdown syntax extension set
  ///
  /// Defaults to [md.ExtensionSet.gitHubFlavored]
  final md.ExtensionSet? extensionSet;

  /// Call when build an image widget.
  final MarkdownImageBuilder? imageBuilder;

  /// Call when build a checkbox widget.
  final MarkdownCheckboxBuilder? checkboxBuilder;

  /// Called when building a bullet
  final MarkdownBulletBuilder? bulletBuilder;

  /// Render certain tags, usually used with [extensionSet]
  ///
  /// For example, we will add support for `sub` tag:
  ///
  /// ```dart
  /// builders: {
  ///   'sub': SubscriptBuilder(),
  /// }
  /// ```
  ///
  /// The `SubscriptBuilder` is a subclass of [MarkdownElementBuilder].
  final Map<String, MarkdownElementBuilder> builders;

  /// Add padding for different tags (use only for block elements and img)
  ///
  /// For example, we will add padding for `img` tag:
  ///
  /// ```dart
  /// paddingBuilders: {
  ///   'img': ImgPaddingBuilder(),
  /// }
  /// ```
  ///
  /// The `ImgPaddingBuilder` is a subclass of [MarkdownPaddingBuilder].
  final Map<String, MarkdownPaddingBuilder> paddingBuilders;

  /// Whether to allow the widget to fit the child content.
  final bool fitContent;

  /// Controls the cross axis alignment for the bullet and list item content
  /// in lists.
  ///
  /// Defaults to [MarkdownListItemCrossAxisAlignment.baseline], which
  /// does not allow for intrinsic height measurements.
  final MarkdownListItemCrossAxisAlignment listItemCrossAxisAlignment;

  /// The soft line break is used to identify the spaces at the end of aline of
  /// text and the leading spaces in the immediately following the line of text.
  ///
  /// Default these spaces are removed in accordance with the Markdown
  /// specification on soft line breaks when lines of text are joined.
  final bool softLineBreak;

  @override
  State<KitchenOwlMarkdownBuilder> createState() =>
      _KitchenOwlMarkdownBuilderState();
}

class _KitchenOwlMarkdownBuilderState extends State<KitchenOwlMarkdownBuilder>
    implements MarkdownBuilderDelegate {
  List<Widget>? _children;
  final List<GestureRecognizer> _recognizers = <GestureRecognizer>[];

  @override
  void didChangeDependencies() {
    _buildMarkdown();
    super.didChangeDependencies();
  }

  @override
  void didUpdateWidget(KitchenOwlMarkdownBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.nodes != oldWidget.nodes ||
        widget.styleSheet != oldWidget.styleSheet) {
      _buildMarkdown();
    }
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _buildMarkdown() {
    _disposeRecognizers();

    // Configure a Markdown widget builder to traverse the AST nodes and
    // create a widget tree based on the elements.
    final MarkdownBuilder builder = MarkdownBuilder(
      delegate: this,
      selectable: widget.selectable,
      styleSheet: widget.styleSheet ??
          MarkdownStyleSheet.fromTheme(
            Theme.of(context),
          ).copyWith(
            blockquoteDecoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color ??
                  Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(2.0),
            ),
          ),
      imageDirectory: widget.imageDirectory,
      imageBuilder: widget.imageBuilder ??
          (uri, title, alt) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: CachedNetworkImage(
                    imageUrl: uri.toString(),
                    placeholder: (context, url) =>
                        const Center(child: CircularProgressIndicator()),
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.error),
                  ),
                ),
              ),
      checkboxBuilder: widget.checkboxBuilder,
      bulletBuilder: widget.bulletBuilder,
      builders: widget.builders,
      paddingBuilders: widget.paddingBuilders,
      fitContent: widget.fitContent,
      listItemCrossAxisAlignment: widget.listItemCrossAxisAlignment,
      onSelectionChanged: widget.onSelectionChanged,
      onTapText: widget.onTapText,
      softLineBreak: widget.softLineBreak,
    );

    _children = builder.build(widget.nodes);
  }

  void _disposeRecognizers() {
    if (_recognizers.isEmpty) {
      return;
    }
    final List<GestureRecognizer> localRecognizers =
        List<GestureRecognizer>.from(_recognizers);
    _recognizers.clear();
    for (final GestureRecognizer recognizer in localRecognizers) {
      recognizer.dispose();
    }
  }

  @override
  GestureRecognizer createLink(String text, String? href, String title) {
    final TapGestureRecognizer recognizer = TapGestureRecognizer()
      ..onTap = () {
        if (widget.onTapLink != null) {
          widget.onTapLink!(text, href, title);
        } else {
          if (href != null && isValidUrl(href)) {
            openUrl(context, href);
          }
        }
      };
    _recognizers.add(recognizer);
    return recognizer;
  }

  @override
  TextSpan formatText(MarkdownStyleSheet styleSheet, String code) {
    code = code.replaceAll(RegExp(r'\n$'), '');
    if (widget.syntaxHighlighter != null) {
      return widget.syntaxHighlighter!.format(code);
    }
    return TextSpan(style: styleSheet.code, text: code);
  }

  @override
  Widget build(BuildContext context) => Column(
        children: _children ?? [],
        mainAxisSize: MainAxisSize.min,
      );
}
