import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/settings_cubit.dart';
import 'package:kitchenowl/cubits/settings_server_cubit.dart';
import 'package:kitchenowl/enums/update_enum.dart';
import 'package:kitchenowl/pages/expense_category_add_update_page.dart';
import 'package:kitchenowl/pages/settings/create_user_page.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/widgets/settings_server/sliver_server_category_settings.dart';
import 'package:kitchenowl/widgets/settings_server/sliver_server_expense_category_settings.dart';
import 'package:kitchenowl/widgets/settings_server/sliver_server_features_settings.dart';
import 'package:kitchenowl/widgets/settings_server/sliver_server_tags_settings.dart';
import 'package:kitchenowl/widgets/settings_server/sliver_server_user_settings.dart';

import '../widgets/settings_server/sliver_server_shoppinglists_settings.dart';

class SettingsServerPage extends StatefulWidget {
  const SettingsServerPage({Key? key}) : super(key: key);

  @override
  _SettingsServerPageState createState() => _SettingsServerPageState();
}

class _SettingsServerPageState extends State<SettingsServerPage> {
  late SettingsServerCubit cubit;

  @override
  void initState() {
    super.initState();
    cubit = SettingsServerCubit();
  }

  @override
  void dispose() {
    cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //TODO this still needs some major refactoring
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.server),
      ),
      body: BlocProvider.value(
        value: cubit,
        child: Align(
          alignment: Alignment.topCenter,
          child: Scrollbar(
            child: ConstrainedBox(
              constraints: const BoxConstraints.expand(width: 600),
              child: RefreshIndicator(
                onRefresh: cubit.refresh,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: CustomScrollView(
                    primary: true,
                    scrollBehavior: const MaterialScrollBehavior()
                        .copyWith(scrollbars: false),
                    slivers: [
                      const SliverServerFeaturesSettings(),
                      const SliverServerShoppingListsSettings(),
                      SliverList(
                        delegate: SliverChildListDelegate(
                          [
                            Text(
                              AppLocalizations.of(context)!
                                  .swipeToDeleteAndLongPressToReorder,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${AppLocalizations.of(context)!.categories}:',
                                    style:
                                        Theme.of(context).textTheme.titleLarge,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add),
                                  onPressed: () async {
                                    final res = await showDialog<String>(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return TextDialog(
                                          title: AppLocalizations.of(context)!
                                              .addCategory,
                                          doneText:
                                              AppLocalizations.of(context)!.add,
                                          hintText:
                                              AppLocalizations.of(context)!
                                                  .name,
                                          isInputValid: (s) => s.isNotEmpty,
                                        );
                                      },
                                    );
                                    if (res != null) {
                                      BlocProvider.of<SettingsServerCubit>(
                                        context,
                                      ).addCategory(res);
                                    }
                                  },
                                  padding: EdgeInsets.zero,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SliverServerCategorySettings(),
                      SliverList(
                        delegate: SliverChildListDelegate([
                          Text(
                            AppLocalizations.of(context)!
                                .swipeToDeleteAndLongPressToReorder,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${AppLocalizations.of(context)!.tags}:',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () async {
                                  final res = await showDialog<String>(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return TextDialog(
                                        title: AppLocalizations.of(context)!
                                            .addTag,
                                        doneText:
                                            AppLocalizations.of(context)!.add,
                                        hintText:
                                            AppLocalizations.of(context)!.name,
                                        isInputValid: (s) => s.isNotEmpty,
                                      );
                                    },
                                  );
                                  if (res != null) {
                                    cubit.addTag(res);
                                  }
                                },
                                padding: EdgeInsets.zero,
                              ),
                            ],
                          ),
                        ]),
                      ),
                      const SliverServerTagsSettings(),
                      SliverList(
                        delegate: SliverChildListDelegate([
                          Text(
                            AppLocalizations.of(context)!.swipeToDelete,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          BlocBuilder<SettingsCubit, SettingsState>(
                            buildWhen: (prev, curr) =>
                                prev.serverSettings.featureExpenses !=
                                curr.serverSettings.featureExpenses,
                            builder: (context, settingsState) =>
                                (settingsState.serverSettings.featureExpenses ??
                                        false)
                                    ? Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              '${AppLocalizations.of(context)!.expenseCategories}:',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleLarge,
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.add),
                                            onPressed: () async {
                                              final res =
                                                  await Navigator.of(context)
                                                      .push<UpdateEnum>(
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      const AddUpdateExpenseCategoryPage(),
                                                ),
                                              );
                                              if (res == UpdateEnum.updated ||
                                                  res == UpdateEnum.updated) {
                                                BlocProvider.of<
                                                    SettingsServerCubit>(
                                                  context,
                                                ).refresh();
                                              }
                                            },
                                            padding: EdgeInsets.zero,
                                          ),
                                        ],
                                      )
                                    : const SizedBox(),
                          ),
                        ]),
                      ),
                      BlocBuilder<SettingsCubit, SettingsState>(
                        buildWhen: (prev, curr) =>
                            prev.serverSettings.featureExpenses !=
                            curr.serverSettings.featureExpenses,
                        builder: (context, settingsState) =>
                            (settingsState.serverSettings.featureExpenses ??
                                    false)
                                ? const SliverServerExpenseCategorySettings()
                                : const SliverToBoxAdapter(child: SizedBox()),
                      ),
                      SliverList(
                        delegate: SliverChildListDelegate([
                          BlocBuilder<SettingsCubit, SettingsState>(
                            buildWhen: (prev, curr) =>
                                prev.serverSettings.featureExpenses !=
                                curr.serverSettings.featureExpenses,
                            builder: (context, settingsState) => (settingsState
                                        .serverSettings.featureExpenses ??
                                    false)
                                ? Text(
                                    AppLocalizations.of(context)!.swipeToDelete,
                                    textAlign: TextAlign.center,
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  )
                                : const SizedBox(),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${AppLocalizations.of(context)!.users}:',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () async {
                                  final res = await Navigator.of(context)
                                      .push<UpdateEnum>(MaterialPageRoute(
                                    builder: (context) => BlocProvider.value(
                                      value: cubit,
                                      child: const CreateUserPage(),
                                    ),
                                  ));
                                  if (res == UpdateEnum.updated) {
                                    cubit.refresh();
                                  }
                                },
                                padding: EdgeInsets.zero,
                              ),
                            ],
                          ),
                        ]),
                      ),
                      const SliverServerUserSettings(),
                      SliverList(
                        delegate: SliverChildListDelegate([
                          Text(
                            AppLocalizations.of(context)!.swipeToDelete,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          SizedBox(
                            height: MediaQuery.of(context).padding.bottom + 4,
                          ),
                        ]),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
