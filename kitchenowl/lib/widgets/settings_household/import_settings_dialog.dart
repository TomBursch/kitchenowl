import 'package:flutter/material.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/import_settings.dart';

Future<ImportSettings?> askForImportSettings({
  required BuildContext context,
}) async =>
    await showDialog<ImportSettings>(
      context: context,
      builder: (BuildContext context) {
        return const _ImportSettingsDialog();
      },
    );

class _ImportSettingsDialog extends StatefulWidget {
  const _ImportSettingsDialog();

  @override
  State<_ImportSettingsDialog> createState() => _ImportSettingsDialogState();
}

class _ImportSettingsDialogState extends State<_ImportSettingsDialog> {
  ImportSettings settings = const ImportSettings();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.import),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CheckboxListTile(
            title: Text(AppLocalizations.of(context)!.items),
            value: settings.items,
            onChanged: (value) {
              setState(() {
                settings = settings.copyWith(items: value);
              });
            },
          ),
          CheckboxListTile(
            title: Text(AppLocalizations.of(context)!.recipes),
            value: settings.recipes,
            onChanged: (value) {
              setState(() {
                settings = settings.copyWith(recipes: value);
              });
            },
          ),
          CheckboxListTile(
            title: Text(AppLocalizations.of(context)!.recipesOverwrite),
            subtitle: Text(
              AppLocalizations.of(context)!.recipesOverwriteDescription,
            ),
            value: settings.recipesOverwrite,
            onChanged: settings.recipes
                ? (value) {
                    setState(() {
                      settings = settings.copyWith(recipesOverwrite: value);
                    });
                  }
                : null,
          ),
          CheckboxListTile(
            title: Text(AppLocalizations.of(context)!.expense),
            value: settings.expenses,
            onChanged: (value) {
              setState(() {
                settings = settings.copyWith(expenses: value);
              });
            },
          ),
          CheckboxListTile(
            title: Text(AppLocalizations.of(context)!.shoppingLists),
            value: settings.shoppinglists,
            onChanged: (value) {
              setState(() {
                settings = settings.copyWith(shoppinglists: value);
              });
            },
          ),
        ],
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      actions: <Widget>[
        TextButton(
          style: ButtonStyle(
            foregroundColor: WidgetStateProperty.all<Color>(
              Theme.of(context).disabledColor,
            ),
          ),
          onPressed: () => Navigator.of(context).pop(null),
          child: Text(
            AppLocalizations.of(context)!.cancel,
          ),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(settings),
          child: Text(AppLocalizations.of(context)!.import),
        ),
      ],
    );
  }
}
