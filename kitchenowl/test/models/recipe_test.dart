import 'package:flutter_test/flutter_test.dart';
import 'package:kitchenowl/models/item.dart';
import 'package:kitchenowl/models/recipe.dart';

const tomato = RecipeItem(name: "Tomato", description: "2");

void main() {
  test("withYields scales the items", () {
    const recipe = Recipe(name: "foo", items: [tomato], yields: 2);

    expect(recipe.withYields(4).items.single.description, "4");
  });

  test("withYields leaves a recipe without servings unscaled", () {
    // yields defaults to 0; scaling it used to throw
    // "FractionException: Denominator cannot be zero."
    const recipe = Recipe(name: "foo", items: [tomato]);

    expect(recipe.withYields(1), same(recipe));
  });

  test("withYields ignores missing or non-positive yields", () {
    const recipe = Recipe(name: "foo", items: [tomato], yields: 2);

    expect(recipe.withYields(null), same(recipe));
    expect(recipe.withYields(0), same(recipe));
    expect(recipe.withYields(2), same(recipe));
  });
}
