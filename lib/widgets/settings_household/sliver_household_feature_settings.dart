import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/settings_household_cubit.dart';
import 'package:kitchenowl/enums/views_enum.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/services/api/api_service.dart';
import 'package:kitchenowl/widgets/language_dialog.dart';
import 'package:reorderables/reorderables.dart';

import 'view_settings_list_tile.dart';

class SliverHouseholdFeatureSettings extends StatelessWidget {
  const SliverHouseholdFeatureSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildListDelegate([
        BlocBuilder<SettingsHouseholdCubit, SettingsHouseholdState>(
          builder: (context, state) => Row(
            children: [
              Expanded(
                child: Text(
                  '${AppLocalizations.of(context)!.features}:',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              if (state.viewOrdering != ViewsEnum.values)
                IconButton(
                  onPressed: BlocProvider.of<SettingsHouseholdCubit>(context)
                      .resetViewOrder,
                  icon: const Icon(Icons.restart_alt_rounded),
                  padding: EdgeInsets.zero,
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        BlocBuilder<SettingsHouseholdCubit, SettingsHouseholdState>(
          builder: (context, state) => ReorderableColumn(
            onReorder:
                BlocProvider.of<SettingsHouseholdCubit>(context).reorderView,
            children: state.viewOrdering
                .sublist(0, state.viewOrdering.length - 1)
                .map(
                  (view) => ViewSettingsListTile(
                    key: ValueKey(view),
                    view: view,
                    isActive: state.isViewActive(view),
                  ),
                )
                .toList(),
          ),
        ),
        const ViewSettingsListTile(
          view: ViewsEnum.profile,
          showHandleIfNotOptional: false,
        ),
        const Divider(),
        ListTile(
          title: Text(AppLocalizations.of(context)!.language),
          leading: const Icon(Icons.language_rounded),
          contentPadding: const EdgeInsets.only(left: 20, right: 5),
          trailing: LoadingElevatedButton(
            child: Text(AppLocalizations.of(context)!.add),
            onPressed: () async {
              final language = await showDialog<String>(
                context: context,
                builder: (BuildContext context) {
                  return LanguageDialog(
                    title: AppLocalizations.of(context)!.language,
                    doneText: AppLocalizations.of(context)!.add,
                    cancelText: AppLocalizations.of(context)!.cancel,
                  );
                },
              );
              if (language == null) return;
              final confirm = await askForConfirmation(
                context: context,
                confirmText: AppLocalizations.of(context)!.add,
                title: Text(
                  AppLocalizations.of(context)!.addLanguage,
                ),
                content: Text(
                  AppLocalizations.of(context)!.addLanguageConfirm(language),
                ),
              );
              if (!confirm) return;
              await ApiService.getInstance().importLanguage(
                BlocProvider.of<SettingsHouseholdCubit>(context).household,
                language,
              );
            },
          ),
        ),
      ]),
    );
  }
}
