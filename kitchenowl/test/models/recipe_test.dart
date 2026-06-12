import 'package:flutter_test/flutter_test.dart';
import 'package:kitchenowl/models/recipe.dart';

void main() {
  test("Recipe gallery images should be deduplicated", () {
    final recipe = Recipe(
      image: "preview.jpg",
      additionalImages: const [
        "preview.jpg",
        " step_1.jpg ",
        "step_1.jpg",
        "step_2.jpg",
        "",
      ],
    );

    expect(
      recipe.galleryImages,
      equals(["preview.jpg", "step_1.jpg", "step_2.jpg"]),
    );
  });
}