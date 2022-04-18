import 'package:flutter/material.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/services/api/api_service.dart';

class LanguageDialog extends StatefulWidget {
  final String title;
  final String doneText;
  final String cancelText;

  const LanguageDialog({
    Key? key,
    this.title = "",
    this.doneText = "",
    this.cancelText = "",
  }) : super(key: key);

  @override
  State<LanguageDialog> createState() => _LanguageDialogState();
}

class _LanguageDialogState extends State<LanguageDialog> {
  String? language;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: Text(widget.title),
      content: FutureBuilder<Map<String, String>?>(
        initialData: const {},
        future: ApiService.getInstance().getSupportedLanguages(),
        builder: (context, snapshot) {
          return DropdownButton<String?>(
            value: language,
            isExpanded: true,
            hint: Text(AppLocalizations.of(context)!.languageSelect),
            items: [
              for (final e in (snapshot.data?.entries ??
                  const <MapEntry<String, String>>[]))
                DropdownMenuItem(
                  child: Text(e.value),
                  value: e.key,
                ),
            ],
            onChanged: (String? value) {
              setState(() {
                language = value;
              });
            },
          );
        },
      ),
      actions: [
        TextButton(
          child: Text(widget.doneText),
          onPressed: language != null
              ? () => Navigator.of(context).pop(language)
              : null,
        ),
        // TextButton(
        //   child: Text(widget.cancelText),
        //   onPressed: () => Navigator.of(context).pop(),
        // ),
      ],
    );
  }
}
