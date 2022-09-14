import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/settings_cubit.dart';
import 'package:kitchenowl/cubits/settings_server_cubit.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/services/api/api_service.dart';
import 'package:kitchenowl/widgets/language_dialog.dart';

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
        Text(
          '${AppLocalizations.of(context)!.features}:',
          style: Theme.of(context).textTheme.headline6,
        ),
        const SizedBox(height: 8),
        BlocBuilder<SettingsCubit, SettingsState>(
          builder: (context, state) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(
                  AppLocalizations.of(context)!.mealPlanner,
                ),
                leading: const Icon(Icons.calendar_today_rounded),
                contentPadding: const EdgeInsets.only(left: 20, right: 0),
                trailing: KitchenOwlSwitch(
                  value: state.serverSettings.featurePlanner ?? false,
                  onChanged:
                      BlocProvider.of<SettingsCubit>(context).setFeaturePlanner,
                ),
              ),
              ListTile(
                title: Text(
                  AppLocalizations.of(context)!.balances,
                ),
                leading: const Icon(Icons.account_balance_rounded),
                contentPadding: const EdgeInsets.only(left: 20, right: 0),
                trailing: KitchenOwlSwitch(
                  value: state.serverSettings.featureExpenses ?? false,
                  onChanged: BlocProvider.of<SettingsCubit>(context)
                      .setFeatureExpenses,
                ),
              ),
            ],
          ),
        ),
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
                '${AppLocalizations.of(context)!.categories}:',
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
                      title: AppLocalizations.of(context)!.addCategory,
                      doneText: AppLocalizations.of(context)!.add,
                      hintText: AppLocalizations.of(context)!.name,
                    );
                  },
                );
                if (res != null && res.isNotEmpty) {
                  BlocProvider.of<SettingsServerCubit>(context)
                      .addCategory(res);
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
