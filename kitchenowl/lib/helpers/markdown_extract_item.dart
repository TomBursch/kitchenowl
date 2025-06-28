import 'package:collection/collection.dart';
import 'package:fraction/fraction.dart';
import 'package:kitchenowl/helpers/string_scaler.dart';
import 'package:kitchenowl/models/item.dart';
import 'package:kitchenowl/models/recipe.dart';
import 'package:markdown/markdown.dart' as md;

class ExtractItemVisitor extends md.NodeVisitor {
  final Recipe recipe;
  final Set<RecipeItem> items = {};
  final Fraction? itemScaledFactor;

  ExtractItemVisitor({
    required this.recipe,
    this.itemScaledFactor,
  });

  @override
  void visitElementAfter(md.Element element) {}

  @override
  bool visitElementBefore(md.Element element) {
    if (element.tag != 'recipeItem') return true;

    RecipeItem? item = recipe.items.firstWhereOrNull(
      (e) => e.name.toLowerCase() == element.textContent,
    );
    if (item != null && element.attributes["description"] != null) {
      String? overridenDescription = element.attributes["description"];
      if (overridenDescription != null && itemScaledFactor != null) {
        overridenDescription =
            StringScaler.scale(overridenDescription, itemScaledFactor!);
      }
      item = item.copyWith(description: overridenDescription);
    }
    if (item != null) items.add(item);
    return false;
  }

  @override
  void visitText(md.Text text) {}
}
