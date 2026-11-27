import 'package:flutter_test/flutter_test.dart';
import 'package:kitchenowl/cubits/settings_cubit.dart';

void main() {
  test("Default units are shown in order", () {
    const state = SettingsState();
    expect(state.visibleShoppingListUnits, kShoppingListUnitsDefault);
  });

  test("Custom units come after the built-in ones", () {
    const state = SettingsState(
      shoppingListUnits: ['box', 'g', 'kg'],
      shoppingListCustomUnits: ['box'],
    );
    expect(state.visibleShoppingListUnits, ['kg', 'g', 'box']);
  });

  test("A custom unit with a built-in name is listed once", () {
    const state = SettingsState(shoppingListCustomUnits: ['kg']);
    expect(state.allShoppingListUnits.where((e) => e == 'kg').length, 1);
  });
}
