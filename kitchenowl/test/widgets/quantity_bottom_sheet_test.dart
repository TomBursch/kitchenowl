import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/item.dart';
import 'package:kitchenowl/widgets/shopping_list/quantity_bottom_sheet.dart';

const _units = ['g', 'kg', 'ml', 'l'];

/// Opens the sheet and returns a getter for the popped description.
Future<String? Function()> _open(
  WidgetTester tester, {
  String? initialDescription,
}) async {
  String? result;
  await tester.pumpWidget(MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Builder(
      builder: (context) => TextButton(
        onPressed: () async => result = await showModalBottomSheet<String>(
          context: context,
          isScrollControlled: true,
          builder: (context) => QuantityBottomSheet(
            item: const Item(name: "Paprika"),
            units: _units,
            initialDescription: initialDescription,
          ),
        ),
        child: const Text("open"),
      ),
    ),
  ));
  await tester.tap(find.text("open"));
  await tester.pumpAndSettle();

  return () => result;
}

Future<void> _tapAdd(WidgetTester tester) async {
  await tester.tap(find.byType(FilledButton));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets("Typed quantity without unit", (tester) async {
    final result = await _open(tester);
    await tester.enterText(find.byType(TextField).first, "3");
    await _tapAdd(tester);
    expect(result(), "3");
  });

  testWidgets("Unit, decimal comma and note", (tester) async {
    final result = await _open(tester);
    await tester.enterText(find.byType(TextField).first, "0,5");
    await tester.tap(find.text("kg"));
    await tester.enterText(find.byType(TextField).last, "organic");
    await _tapAdd(tester);
    expect(result(), "0.5 kg, organic");
  });

  testWidgets("Plus and minus follow the unit", (tester) async {
    final result = await _open(tester);
    await tester.tap(find.text("g"));
    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.tap(find.byIcon(Icons.remove_rounded));
    await tester.pump();
    await _tapAdd(tester);
    expect(result(), "200 g");
  });

  testWidgets("Initial description is split", (tester) async {
    final result = await _open(tester, initialDescription: "500 G, red");
    expect(find.text("500"), findsOneWidget);
    expect(find.text("red"), findsOneWidget);
    await _tapAdd(tester);
    expect(result(), "500 g, red");
  });

  testWidgets("Unknown unit from the search is kept", (tester) async {
    final result = await _open(tester, initialDescription: "2 jars");
    expect(find.text("jars"), findsOneWidget);
    await _tapAdd(tester);
    expect(result(), "2 jars");
  });

  testWidgets("Quantity keeps one decimal separator", (tester) async {
    final result = await _open(tester);
    await tester.enterText(find.byType(TextField).first, "1,5");
    await tester.enterText(find.byType(TextField).first, "1,5,");
    await tester.enterText(find.byType(TextField).first, "1,5a");
    await _tapAdd(tester);
    expect(result(), "1.5");
  });

  testWidgets("Quantity with several decimals", (tester) async {
    final result = await _open(tester);
    for (final text in ["1", "1.", "1.2", "1.25"]) {
      await tester.enterText(find.byType(TextField).first, text);
    }
    await tester.tap(find.text("kg"));
    await _tapAdd(tester);
    expect(result(), "1.25 kg");
  });

  testWidgets("Add without quantity", (tester) async {
    final result = await _open(tester, initialDescription: "2");
    await tester.tap(find.byType(TextButton).last);
    await tester.pumpAndSettle();
    expect(result(), "");
  });
}
