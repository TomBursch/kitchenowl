import 'package:markdown/markdown.dart' as md;

class ShortImageMarkdownSyntax extends md.InlineSyntax {
  ShortImageMarkdownSyntax()
      : super(
          _pattern,
          caseSensitive: false,
        );

  static const String _pattern = r"""!\[(.+)\]""";

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final element = md.Element.withTag('img');
    element.attributes['src'] = match[1]!.trim();

    parser.addNode(element);

    return true;
  }
}
