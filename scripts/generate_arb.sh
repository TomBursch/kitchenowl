# Generate arb for localization
# Run from project folder's root
echo Run from project root
flutter pub run intl_translation:extract_to_arb --output-dir=lib/l10n lib/l10n/grexLocalizationDelegate.dart