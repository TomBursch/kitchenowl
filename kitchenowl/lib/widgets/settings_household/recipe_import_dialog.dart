import 'package:flutter/material.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/recipe_import_preview.dart';

const String _actionSkip = 'skip';
const String _actionOverwrite = 'overwrite';
const String _actionCopy = 'copy';
const String _defaultDuplicateAction = _actionSkip;
const String _defaultImportAction = _actionCopy;

Future<Map<String, String>?> askForRecipeImportDecisions({
  required BuildContext context,
  required RecipeImportPreview preview,
}) async {
  if (!preview.hasDuplicates) {
    return {
      for (final recipe in preview.recipes) recipe.importId: _defaultImportAction,
    };
  }

  return showDialog<Map<String, String>>(
    context: context,
    builder: (context) => _RecipeImportDialog(preview: preview),
  );
}

class _RecipeImportDialog extends StatefulWidget {
  final RecipeImportPreview preview;

  const _RecipeImportDialog({
    required this.preview,
  });

  @override
  State<_RecipeImportDialog> createState() => _RecipeImportDialogState();
}

class _RecipeImportDialogState extends State<_RecipeImportDialog> {
  late final Map<String, String> decisions;
  late final Map<String, RecipeImportRecipe> recipesById;

  void _setAllDuplicateDecisions(String action) {
    setState(() {
      for (final duplicate in widget.preview.duplicates) {
        decisions[duplicate.importId] = action;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    decisions = {
      for (final recipe in widget.preview.recipes)
        recipe.importId: _defaultDuplicateAction,
    };
    recipesById = {
      for (final recipe in widget.preview.recipes) recipe.importId: recipe,
    };
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.recipeImportDuplicatesTitle),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppLocalizations.of(context)!.recipeImportDuplicatesBody,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!
                        .recipeImportApplyAllDuplicates,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                TextButton(
                  onPressed: () => _setAllDuplicateDecisions(_actionSkip),
                  child:
                      Text(AppLocalizations.of(context)!.recipeImportActionSkip),
                ),
                TextButton(
                  onPressed: () => _setAllDuplicateDecisions(_actionOverwrite),
                  child: Text(
                    AppLocalizations.of(context)!.recipeImportActionOverwrite,
                  ),
                ),
                TextButton(
                  onPressed: () => _setAllDuplicateDecisions(_actionCopy),
                  child:
                      Text(AppLocalizations.of(context)!.recipeImportActionCopy),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.preview.duplicates.length,
                itemBuilder: (context, index) {
                  final duplicate = widget.preview.duplicates[index];
                  final recipe = recipesById[duplicate.importId];
                  if (recipe == null) return const SizedBox.shrink();
                  return Padding(
                    key: ValueKey(duplicate.importId),
                    padding: EdgeInsets.only(
                      bottom: index == widget.preview.duplicates.length - 1 ? 0 : 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recipe.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: decisions[duplicate.importId] ?? _defaultDuplicateAction,
                          items: [
                            DropdownMenuItem(
                              value: _actionSkip,
                              child: Text(
                                AppLocalizations.of(context)!
                                    .recipeImportActionSkip,
                              ),
                            ),
                            DropdownMenuItem(
                              value: _actionOverwrite,
                              child: Text(
                                AppLocalizations.of(context)!
                                    .recipeImportActionOverwrite,
                              ),
                            ),
                            DropdownMenuItem(
                              value: _actionCopy,
                              child: Text(
                                AppLocalizations.of(context)!
                                    .recipeImportActionCopy,
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() {
                              decisions[duplicate.importId] = value;
                            });
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop({
            for (final d in widget.preview.duplicates)
              d.importId: decisions[d.importId] ?? _defaultDuplicateAction,
          }),
          child: Text(AppLocalizations.of(context)!.import),
        ),
      ],
    );
  }
}
