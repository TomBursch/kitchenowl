import 'package:flutter_test/flutter_test.dart';
import 'package:kitchenowl/cubits/recipe_cubit.dart';
import 'package:kitchenowl/models/item.dart';
import 'package:kitchenowl/models/recipe.dart';

import 'local_only_transaction_handler.dart';

const flour = RecipeItem(name: "Flour");
const salt = RecipeItem(name: "Salt");
const recipe = Recipe(
    id: 100,
    name: "foo",
    description: "The desc",
    items: [flour, salt],
    yields: 1);

RecipeCubit createSampleCubit() =>
    RecipeCubit.forTesting(LocalOnlyTransactionHandler(), null, recipe, 1);

void main() {
  test("Item selection works", () {
    final cubit = createSampleCubit();
    final allItems = recipe.mandatoryItems.map((e) => e.name).toSet();

    expect(cubit.state.selectedItems, allItems);

    cubit.itemSelected(flour);
    expect(cubit.state.selectedItems, {salt.name});

    cubit.itemSelected(flour);
    expect(cubit.state.selectedItems, allItems);

    cubit.itemSelected(flour);
    cubit.itemSelected(salt);
    expect(cubit.state.selectedItems, isEmpty);
  });

  test("Changing the yield works", () {
    final cubit = createSampleCubit();
    expect(cubit.state.selectedYields, 1);

    cubit.setSelectedYields(4);
    expect(cubit.state.selectedYields, 4);
  });
}
