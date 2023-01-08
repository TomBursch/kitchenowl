import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/settings_cubit.dart';
import 'package:kitchenowl/cubits/settings_server_cubit.dart';
import 'package:kitchenowl/enums/views_enum.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/services/api/api_service.dart';
import 'package:kitchenowl/widgets/language_dialog.dart';
import 'package:kitchenowl/widgets/settings_server/view_settings_list_tile.dart';
import 'package:reorderables/reorderables.dart';

class SliverServerFeaturesSettings extends StatelessWidget {
  const SliverServerFeaturesSettings({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildListDelegate([
        const SizedBox(height: 16),
        Text(
          '${AppLocalizations.of(context)!.server}:',
          style: Theme.of(context).textTheme.headline6,
        ),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            title: Text(
              Uri.parse(ApiService.getInstance().baseUrl).authority,
            ),
          ),
        ),
        const SizedBox(height: 8),
        BlocBuilder<SettingsCubit, SettingsState>(
          builder: (context, state) => Row(
            children: [
              Expanded(
                child: Text(
                  '${AppLocalizations.of(context)!.features}:',
                  style: Theme.of(context).textTheme.headline6,
                ),
              ),
              if (state.serverSettings.viewOrdering != ViewsEnum.values)
                IconButton(
                  onPressed:
                      BlocProvider.of<SettingsCubit>(context).resetViewOrder,
                  icon: const Icon(Icons.restart_alt_rounded),
                  padding: EdgeInsets.zero,
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        BlocBuilder<SettingsCubit, SettingsState>(
          builder: (context, state) => ReorderableColumn(
            onReorder: BlocProvider.of<SettingsCubit>(context).reorderView,
            children: state.serverSettings.viewOrdering!
                .sublist(0, state.serverSettings.viewOrdering!.length - 1)
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
              await ApiService.getInstance().importLanguage(language);
            },
          ),
        ),
        Row(
          children: [
            Expanded(
              child: Text(
                '${AppLocalizations.of(context)!.shoppingLists}:',
                style: Theme.of(context).textTheme.headline6,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () async {
                final res = await showDialog<String>(
                  context: context,
                  builder: (BuildContext context) {
                    return TextDialog(
                      title: AppLocalizations.of(context)!.addShoppingList,
                      doneText: AppLocalizations.of(context)!.add,
                      hintText: AppLocalizations.of(context)!.name,
                      isInputValid: (s) => s.isNotEmpty,
                    );
                  },
                );
                if (res != null) {
                  BlocProvider.of<SettingsServerCubit>(context)
                      .addShoppingList(res);
                }
              },
              padding: EdgeInsets.zero,
            ),
          ],
        ),
      ]),
    );
  }
}
