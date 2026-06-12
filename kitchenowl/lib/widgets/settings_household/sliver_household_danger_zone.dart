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

class _RecipeImportProgressTracker {
  static final ValueNotifier<_RecipeImportProgress?> value =
      ValueNotifier<_RecipeImportProgress?>(null);

  static void start(int detected) {
    value.value = _RecipeImportProgress(
      detected: detected,
      imported: 0,
      failed: 0,
      skipped: 0,
      complete: false,
    );
  }

  static void update(RecipeImportResult current, int fallbackDetected) {
    value.value = _RecipeImportProgress(
      detected: current.detected > 0 ? current.detected : fallbackDetected,
      imported: current.imported,
      failed: current.failed,
      skipped: current.skipped,
      complete: current.complete,
    );
  }

  static void clear() {
    value.value = null;
  }
}

class SliverHouseholdDangerZone extends StatefulWidget {
  const SliverHouseholdDangerZone({super.key});

  @override
  State<SliverHouseholdDangerZone> createState() =>
      _SliverHouseholdDangerZoneState();
}

class _SliverHouseholdDangerZoneState
    extends State<SliverHouseholdDangerZone> {
  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ValueListenableBuilder<_RecipeImportProgress?>(
            valueListenable: _RecipeImportProgressTracker.value,
            builder: (context, progress, child) {
              if (progress == null) return const SizedBox.shrink();

              return Container(
                width: double.infinity,
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
                      progress.complete
                          ? AppLocalizations.of(context)!
                              .recipeImportProgressDoneTitle
                          : AppLocalizations.of(context)!
                              .recipeImportProgressTitle,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      [
                        AppLocalizations.of(context)!.recipeImportProgressDetected(
                          progress.detected,
                        ),
                        AppLocalizations.of(context)!.recipeImportProgressImported(
                          progress.imported,
                        ),
                        AppLocalizations.of(context)!.recipeImportProgressFailed(
                          progress.failed,
                        ),
                        AppLocalizations.of(context)!.recipeImportProgressSkipped(
                          progress.skipped,
                        ),
                      ].join('  |  '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: progress.complete
                          ? 1
                          : (progress.detected > 0
                              ? ((progress.imported +
                                          progress.failed +
                                          progress.skipped) /
                                      progress.detected)
                                  .clamp(0.0, 1.0)
                              : null),
                    ),
                    if (progress.complete) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            _RecipeImportProgressTracker.clear();
                          },
                          child: Text(AppLocalizations.of(context)!.done),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
          Container(
            width: double.infinity,
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
                const SizedBox(height: 8),
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

                    final householdUpdateCubit =
                        BlocProvider.of<HouseholdUpdateCubit>(context);

                    final decisions = await askForRecipeImportDecisions(
                      context: context,
                      preview: preview,
                    );
                    if (decisions == null) return;

                    _RecipeImportProgressTracker.start(preview.recipes.length);

                    final result = await householdUpdateCubit.commitRecipeImport(
                      preview.token,
                      decisions,
                    );

                    if (result != null) {
                      RecipeImportResult current = result;
                      int failedStatusPolls = 0;
                      const int maxFailedStatusPolls = 100;
                      _RecipeImportProgressTracker.update(
                        current,
                        preview.recipes.length,
                      );
                      while (!current.complete) {
                        await Future<void>.delayed(
                          const Duration(milliseconds: 500),
                        );
                        final status =
                            await householdUpdateCubit.getRecipeImportStatus(
                          preview.token,
                        );
                        if (status == null) {
                          failedStatusPolls += 1;
                          if (failedStatusPolls >= maxFailedStatusPolls) {
                            if (mounted) {
                              showSnackbar(
                                context: context,
                                content: Text(
                                  AppLocalizations.of(context)!
                                      .recipeImportStatusFetchFailed,
                                ),
                                width: null,
                              );
                            }
                            break;
                          }
                          continue;
                        }
                        failedStatusPolls = 0;
                        current = status;
                        _RecipeImportProgressTracker.update(
                          current,
                          preview.recipes.length,
                        );
                      }
                    } else {
                      _RecipeImportProgressTracker.clear();
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
