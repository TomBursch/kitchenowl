import 'package:flutter_test/flutter_test.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:world_countries/world_countries.dart';

void main() {
  testWidgets('provides Material localizations for German', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
          TypedLocaleDelegate(),
        ],
        supportedLocales:
            const [Locale('en')] + AppLocalizations.supportedLocales,
        home: Scaffold(
          appBar: AppBar(title: const Text('KitchenOwl')),
          body: const TextField(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
