import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localized_locales/flutter_localized_locales.dart';
import 'package:kitchenowl/kitchenowl.dart';

class LanguageBottomSheet extends StatefulWidget {
  final String title;
  final String doneText;
  final String? initialLanguage;
  final String? nullText;
  final Map<String, String>? supportedLanguages;

  const LanguageBottomSheet({
    super.key,
    this.title = "",
    this.doneText = "",
    this.initialLanguage,
    this.nullText,
    required this.supportedLanguages,
  });

  @override
  State<LanguageBottomSheet> createState() => _LanguageBottomSheetState();
}

class _LanguageBottomSheetState extends State<LanguageBottomSheet> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              AppLocalizations.of(context)!.languageSelect,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          const Divider(indent: 16, endIndent: 16),
          ListTile(
            selected: widget.initialLanguage == null,
            title: Text(widget.nullText ?? AppLocalizations.of(context)!.none),
            onTap: () => Navigator.of(context).pop(Nullable<String>.empty()),
            trailing: widget.initialLanguage == null
                ? const Icon(Icons.check_circle_rounded)
                : null,
          ),
          for (final e in (widget.supportedLanguages?.entries
                  .map((e) => MapEntry(
                      e.key, LocaleNames.of(context)!.nameOf(e.key) ?? e.value))
                  .sorted((a, b) {
                if (AppLocalizations.of(context)!.localeName == b.key ||
                    AppLocalizations.of(context)!.localeName == a.key)
                  return AppLocalizations.of(context)!.localeName == a.key
                      ? -1
                      : 1;

                if (widget.initialLanguage == b.key ||
                    widget.initialLanguage == a.key)
                  return widget.initialLanguage == a.key ? -1 : 1;

                return a.value.compareTo(b.value);
              }) ??
              const <MapEntry<String, String>>[]))
            ListTile(
              selected: widget.initialLanguage == e.key,
              title: Text(e.value),
              onTap: () => Navigator.of(context).pop(
                (widget.supportedLanguages?.containsKey(e.key) ?? false)
                    ? Nullable(e.key)
                    : null,
              ),
              trailing: widget.initialLanguage == e.key
                  ? const Icon(Icons.check_circle_rounded)
                  : null,
            ),
          SizedBox(height: MediaQuery.paddingOf(context).bottom),
        ],
      ),
    );
  }
}
