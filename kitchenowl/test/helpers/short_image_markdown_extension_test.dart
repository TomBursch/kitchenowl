import 'package:flutter_test/flutter_test.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:kitchenowl/helpers/short_image_markdown_extension.dart';

md.Document _buildDocument() {
  return md.Document(
    extensionSet: md.ExtensionSet.gitHubWeb,
    encodeHtml: false,
    inlineSyntaxes: [ShortImageMarkdownSyntax()],
  );
}

List<md.Element> _parseImageNodes(List<String> lines) {
  final nodes = _buildDocument().parseLines(lines);
  return nodes
      .whereType<md.Element>()
      .expand((node) => node.children ?? const <md.Node>[])
      .whereType<md.Element>()
      .where((node) => node.tag == 'img')
      .toList();
}

void main() {
  test('Short image syntax should not override standard markdown images', () {
    final imageNodes = _parseImageNodes(['![step image](step_1.jpg)']);

    expect(imageNodes, hasLength(1));
    expect(imageNodes.first.attributes['src'], equals('step_1.jpg'));
    expect(imageNodes.first.attributes['alt'], equals('step image'));
  });

  test('Numeric short image syntax should produce numeric src', () {
    final imageNodes = _parseImageNodes(['![0]']);

    expect(imageNodes, hasLength(1));
    expect(imageNodes.first.attributes['src'], equals('0'));
  });
}