import 'package:flutter/material.dart';
import 'package:kitchenowl/kitchenowl.dart';

class LanguageDialog extends StatefulWidget {
  final String title;
  final String doneText;
  final String? initialLanguage;
  final Map<String, String>? supportedLanguages;

  const LanguageDialog({
    Key? key,
    this.title = "",
    this.doneText = "",
    this.initialLanguage,
    required this.supportedLanguages,
  }) : super(key: key);

  @override
  State<LanguageDialog> createState() => _LanguageDialogState();
}

class _LanguageDialogState extends State<LanguageDialog> {
  String? language;

  @override
  void initState() {
    super.initState();
    language = widget.initialLanguage;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: Text(widget.title),
      content: DropdownButton<String?>(
        value: language,
        isExpanded: true,
        hint: Text(AppLocalizations.of(context)!.languageSelect),
        items: [
          DropdownMenuItem(
            value: null,
            child: Text(AppLocalizations.of(context)!.none),
          ),
          for (final e in (widget.supportedLanguages?.entries ??
              const <MapEntry<String, String>>[]))
            DropdownMenuItem(
              value: e.key,
              child: Text(e.value),
            ),
        ],
        onChanged: (String? value) {
          setState(() {
            language = value;
          });
        },
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(
            (widget.supportedLanguages?.containsKey(language) ?? false)
                ? language
                : null,
          ),
          child: Text(widget.doneText),
        ),
      ],
    );
  }
}
