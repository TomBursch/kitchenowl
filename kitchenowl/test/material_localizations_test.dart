import 'package:flutter_test/flutter_test.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('provides Material localizations for German', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: GlobalMaterialLocalizations.delegates +
            AppLocalizations.localizationsDelegates,
        supportedLocales: const [Locale('de')],
        home: Scaffold(appBar: AppBar(title: const Text('KitchenOwl'))),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
