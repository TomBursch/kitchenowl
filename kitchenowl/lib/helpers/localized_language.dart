import 'package:flutter/widgets.dart';
import 'package:world_countries/world_countries.dart';

sealed class LocalizedLanguage {
  static String? nameOf(
    BuildContext context,
    String? code, [
    Map<String, String>? supportedLanguages,
  ]) {
    if (code == null || code.isEmpty) return null;
    final parsed = const LocalizationDelegate().parseLocale(code);
    if (parsed == null) return supportedLanguages?[code];

    final typedLocale = context.maybeLocale;
    final targetLocale = typedLocale ??
        Localizations.maybeLocaleOf(context).maybeToTypedLocale();
    final langName = typedLocale?.languageTranslations[parsed.language] ??
        parsed.language.maybeCommonNameFor(targetLocale);
    if (langName == null) return supportedLanguages?[code];

    if (parsed.countryCode != null) {
      final country = WorldCountry.maybeFromAnyCode(parsed.countryCode);
      final countryName = (country != null
              ? (typedLocale?.countryTranslations[country] ??
                  country.maybeCommonNameFor(targetLocale))
              : null) ??
          parsed.countryCode!;
      return '$langName ($countryName)';
    }

    if (parsed.script != null) {
      final scriptLabel = supportedLanguages?[code] ?? parsed.script!.name;
      return '$langName ($scriptLabel)';
    }

    return langName;
  }
}
