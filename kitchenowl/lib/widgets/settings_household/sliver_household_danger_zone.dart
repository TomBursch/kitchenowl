import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kitchenowl/cubits/household_add_update/household_update_cubit.dart';
import 'package:kitchenowl/helpers/share.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/import_settings.dart';

import 'import_settings_dialog.dart';

class SliverHouseholdDangerZone extends StatelessWidget {
  const SliverHouseholdDangerZone({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
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
                      final file = await FilePicker.platform.pickFiles(
                        allowMultiple: false,
                        allowedExtensions: ['json'],
                        dialogTitle: 'Please select a file to import:',
                        type: FileType.custom,
                        withData: true,
                      );
                      if (file != null && file.files.first.name.isNotEmpty) {
                        try {
                          dynamic content = jsonDecode(
                            String.fromCharCodes(file.files.first.bytes!),
                          );
                          if (content == null ||
                              content is! Map<String, dynamic>) return;

                          ImportSettings? settings =
                              await askForImportSettings(context: context);

                          if (settings == null) return;

                          showSnackbar(
                            context: context,
                            content: Text(
                              AppLocalizations.of(context)!.importStartedHint,
                            ),
                            width: null,
                          );

                          return BlocProvider.of<HouseholdUpdateCubit>(context)
                              .importHousehold(
                            content,
                            settings,
                          );
                        } catch (_) {}
                      }
                    },
                    child: Text(AppLocalizations.of(context)!.import),
                  ),
                ),
              ],
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
                    AppLocalizations.of(context)!.householdDeleteConfirmation(
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
    );
  }
}
