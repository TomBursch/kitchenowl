# Generate messages from arb
# Run from project folder's root
echo Run from project root
flutter pub run intl_translation:generate_from_arb --output-dir=lib/l10n lib/l10n/grexLocalizationDelegate.dart lib/l10n/intl_*.arb