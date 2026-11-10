import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:intl/number_symbols_data.dart';
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

  static FiatCurrency? currencyOf(String? locale) {
    if (locale == null || locale.isEmpty) return null;
    return FiatCurrency.maybeFromAnyCode(
      NumberFormat.simpleCurrency(locale: locale).currencyName,
    );
  }

  static String? currencyNameOf(
    BuildContext context,
    FiatCurrency? currency,
  ) {
    if (currency == null) return null;
    return context.maybeLocale?.currencyTranslations[currency] ?? currency.name;
  }

  static Iterable<FiatCurrency> supportedCurrencies([BuildContext? context]) {
    final supportedCodes =
        numberFormatSymbols.values.map((s) => s.DEF_CURRENCY_CODE).toSet();
    return (context?.maybeLocale?.currencyTranslations.keys ??
            FiatCurrency.list)
        .where((c) => supportedCodes.contains(c.code));
  }

  static String? localeForCurrency(FiatCurrency currency) {
    for (final country
        in [currency].byCountryMap()[currency] ?? const <WorldCountry>[]) {
      for (final lang in country.languages) {
        final candidate = country.toLocale(language: lang).toString();
        if (numberFormatSymbols[candidate]?.DEF_CURRENCY_CODE ==
            currency.code) {
          return candidate;
        }
      }
    }
    return numberFormatSymbols.entries
        .firstWhereOrNull((e) => e.value.DEF_CURRENCY_CODE == currency.code)
        ?.key;
  }
}
