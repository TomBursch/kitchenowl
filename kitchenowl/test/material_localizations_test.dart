import 'package:flutter_localized_locales/flutter_localized_locales.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('provides Material localizations for German', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
          LocaleNamesLocalizationsDelegate(),
        ],
        supportedLocales:
            const [Locale('en')] + AppLocalizations.supportedLocales,
        home: Scaffold(
          appBar: AppBar(title: const Text('KitchenOwl')),
          body: const TextField(),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
