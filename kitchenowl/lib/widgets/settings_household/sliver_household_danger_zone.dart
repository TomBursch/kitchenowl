import 'dart:convert';
import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kitchenowl/cubits/household_add_update/household_update_cubit.dart';
import 'package:kitchenowl/helpers/named_bytearray.dart';
import 'package:kitchenowl/helpers/share.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/recipe_import_result.dart';

import 'import_settings_dialog.dart';
import 'recipe_import_dialog.dart';

class _RecipeImportProgress {
  final int detected;
  final int imported;
  final int failed;
  final int skipped;
  final bool complete;

  const _RecipeImportProgress({
    required this.detected,
    required this.imported,
    required this.failed,
    required this.skipped,
    required this.complete,
  });
}

class SliverHouseholdDangerZone extends StatefulWidget {
  const SliverHouseholdDangerZone({super.key});

  @override
  State<SliverHouseholdDangerZone> createState() =>
      _SliverHouseholdDangerZoneState();
}

class _SliverHouseholdDangerZoneState
    extends State<SliverHouseholdDangerZone> {
  _RecipeImportProgress? _progress;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Column(
        children: [
          if (_progress != null) ...[
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.orangeAccent,
                  width: 2,
                ),
              ),
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(top: 16, bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _progress!.complete
                        ? AppLocalizations.of(context)!
                            .recipeImportProgressDoneTitle
                        : AppLocalizations.of(context)!
                            .recipeImportProgressTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)!
                        .recipeImportProgressDetected(_progress!.detected),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppLocalizations.of(context)!
                        .recipeImportProgressImported(_progress!.imported),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppLocalizations.of(context)!
                        .recipeImportProgressFailed(_progress!.failed),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppLocalizations.of(context)!
                        .recipeImportProgressSkipped(_progress!.skipped),
                  ),
                  if (_progress!.complete) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            _progress = null;
                          });
                        },
                        child: Text(AppLocalizations.of(context)!.done),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.redAccent,
                width: 2,
              ),
            ),
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${AppLocalizations.of(context)!.dangerZone}:',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Builder(
                        builder: (context) => LoadingElevatedButton(
                          onPressed: () async {
                            final export =
                                await BlocProvider.of<HouseholdUpdateCubit>(
                              context,
                            ).getExportHousehold();
                            if (export == null) return;
                            Share.shareJsonFile(context, export,
                                '${BlocProvider.of<HouseholdUpdateCubit>(context).household.name}_export.json');
                          },
                          child: Text(AppLocalizations.of(context)!.export),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: LoadingElevatedButton(
                        onPressed: () async {
                          final file = await FilePicker.pickFiles(
                            allowMultiple: false,
                            allowedExtensions: ['json'],
                            dialogTitle: 'Please select a file to import:',
                            type: FileType.custom,
                            withData: true,
                          );
                          if (file == null || file.files.first.bytes == null) {
                            return;
                          }

                          try {
                            final decoded = jsonDecode(
                              String.fromCharCodes(file.files.first.bytes!),
                            );
                            if (decoded is! Map<String, dynamic>) {
                              showSnackbar(
                                context: context,
                                content: const Text(
                                  'Selected file is not a valid household export.',
                                ),
                                width: null,
                              );
                              return;
                            }

                            final settings =
                                await askForImportSettings(context: context);
                            if (settings == null) return;

                            if (!settings.items &&
                                !settings.recipes &&
                                !settings.expenses &&
                                !settings.shoppinglists) {
                              showSnackbar(
                                context: context,
                                content: const Text(
                                  'Select at least one section to import.',
                                ),
                                width: null,
                              );
                              return;
                            }

                            showSnackbar(
                              context: context,
                              content: Text(
                                AppLocalizations.of(context)!.importStartedHint,
                              ),
                              width: null,
                            );

                            await BlocProvider.of<HouseholdUpdateCubit>(
                              context,
                            ).importHousehold(
                              decoded,
                              settings,
                            );
                          } on FormatException {
                            showSnackbar(
                              context: context,
                              content: const Text(
                                'Selected file is not valid JSON.',
                              ),
                              width: null,
                            );
                          } catch (_) {
                            showSnackbar(
                              context: context,
                              content: const Text('Import failed.'),
                              width: null,
                            );
                          }
                        },
                        child: Text(AppLocalizations.of(context)!.import),
                      ),
                    ),
                  ],
                ),
                const Divider(),
                LoadingElevatedButton(
                  onPressed: () async {
                    final file = await FilePicker.pickFiles(
                      allowMultiple: false,
                      allowedExtensions: ['json', 'zip'],
                      dialogTitle: AppLocalizations.of(context)!
                          .recipeImportChooseFile,
                      type: FileType.custom,
                      withData: true,
                    );
                    if (file == null || file.files.first.bytes == null) return;

                    final preview =
                        await BlocProvider.of<HouseholdUpdateCubit>(context)
                            .previewRecipeImport(
                      NamedByteArray(
                        file.files.first.name,
                        file.files.first.bytes!,
                      ),
                    );

                    if (preview == null) {
                      showSnackbar(
                        context: context,
                        content: Text(
                          AppLocalizations.of(context)!
                              .recipeImportPreviewFailed,
                        ),
                        width: null,
                      );
                      return;
                    }

                    if (preview.recipes.isEmpty) {
                      showSnackbar(
                        context: context,
                        content: Text(
                          AppLocalizations.of(context)!
                              .recipeImportNoRecipes,
                        ),
                        width: null,
                      );
                      return;
                    }

                    final decisions = await askForRecipeImportDecisions(
                      context: context,
                      preview: preview,
                    );
                    if (decisions == null) return;

                    setState(() {
                      _progress = _RecipeImportProgress(
                        detected: preview.recipes.length,
                        imported: 0,
                        failed: 0,
                        skipped: 0,
                        complete: false,
                      );
                    });

                    showSnackbar(
                      context: context,
                      content: Text(
                        AppLocalizations.of(context)!.importStartedHint,
                      ),
                      width: null,
                    );

                    final result =
                        await BlocProvider.of<HouseholdUpdateCubit>(context)
                            .commitRecipeImport(preview.token, decisions);

                    if (!mounted) return;

                    if (result != null) {
                      RecipeImportResult current = result;
                      setState(() {
                        _progress = _RecipeImportProgress(
                          detected: current.detected > 0
                              ? current.detected
                              : preview.recipes.length,
                          imported: current.imported,
                          failed: current.failed,
                          skipped: current.skipped,
                          complete: current.complete,
                        );
                      });
                      while (!current.complete && mounted) {
                        await Future<void>.delayed(
                          const Duration(milliseconds: 500),
                        );
                        final status =
                            await BlocProvider.of<HouseholdUpdateCubit>(context)
                                .getRecipeImportStatus(preview.token);
                        if (!mounted || status == null) break;
                        current = status;
                        setState(() {
                          _progress = _RecipeImportProgress(
                            detected: current.detected > 0
                                ? current.detected
                                : preview.recipes.length,
                            imported: current.imported,
                            failed: current.failed,
                            skipped: current.skipped,
                            complete: current.complete,
                          );
                        });
                      }
                      if (mounted && _progress != null) {
                        showSnackbar(
                          context: context,
                          content: Text(
                            AppLocalizations.of(context)!
                                .recipeImportResultSummary(
                              _progress!.imported,
                              _progress!.failed,
                              _progress!.skipped,
                            ),
                          ),
                          width: null,
                        );
                      }
                    } else {
                      setState(() {
                        _progress = null;
                      });
                    }
                  },
                  child: Text(AppLocalizations.of(context)!.recipeImportTitle),
                ),
                const Divider(),
                LoadingElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all<Color>(
                      Colors.redAccent,
                    ),
                    foregroundColor: WidgetStateProperty.all<Color>(
                      Colors.white,
                    ),
                  ),
                  onPressed: () async {
                    final confirm = await askForConfirmation(
                      context: context,
                      title: Text(
                        AppLocalizations.of(context)!.householdDelete,
                      ),
                      content: Text(
                        AppLocalizations.of(context)!
                            .householdDeleteConfirmation(
                          BlocProvider.of<HouseholdUpdateCubit>(context)
                              .household
                              .name,
                        ),
                      ),
                    );
                    if (confirm) {
                      if (await BlocProvider.of<HouseholdUpdateCubit>(context)
                          .deleteHousehold()) {
                        context.go('/household');
                      }
                    }
                  },
                  child: Text(AppLocalizations.of(context)!.householdDelete),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
