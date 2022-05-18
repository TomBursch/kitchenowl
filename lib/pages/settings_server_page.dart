import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/auth_cubit.dart';
import 'package:kitchenowl/cubits/settings_cubit.dart';
import 'package:kitchenowl/cubits/settings_server_cubit.dart';
import 'package:kitchenowl/enums/update_enum.dart';
import 'package:kitchenowl/models/tag.dart';
import 'package:kitchenowl/models/user.dart';
import 'package:kitchenowl/pages/settings/create_user_page.dart';
import 'package:kitchenowl/pages/settings_user_page.dart';
import 'package:kitchenowl/services/api/api_service.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/widgets/language_dialog.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.server),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints.expand(width: 600),
          child: RefreshIndicator(
            onRefresh: cubit.refresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
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
                        title: Text(AppLocalizations.of(context)!.mealPlanner),
                        leading: const Icon(Icons.calendar_today_rounded),
                        contentPadding:
                            const EdgeInsets.only(left: 20, right: 0),
                        trailing: Transform.scale(
                          scale: 0.9,
                          child: CupertinoSwitch(
                            value: state.serverSettings.featurePlanner ?? false,
                            activeColor:
                                Theme.of(context).colorScheme.secondary,
                            onChanged: BlocProvider.of<SettingsCubit>(context)
                                .setFeaturePlanner,
                          ),
                        ),
                      ),
                      ListTile(
                        title: Text(AppLocalizations.of(context)!.balances),
                        leading: const Icon(Icons.account_balance_rounded),
                        contentPadding:
                            const EdgeInsets.only(left: 20, right: 0),
                        trailing: Transform.scale(
                          scale: 0.9,
                          child: CupertinoSwitch(
                            value:
                                state.serverSettings.featureExpenses ?? false,
                            activeColor:
                                Theme.of(context).colorScheme.secondary,
                            onChanged: BlocProvider.of<SettingsCubit>(context)
                                .setFeatureExpenses,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                ListTile(
                  title: Text(AppLocalizations.of(context)!.language),
                  leading: const Icon(Icons.language_rounded),
                  contentPadding: const EdgeInsets.only(left: 20, right: 5),
                  trailing: ElevatedButton(
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
                        content: Text(AppLocalizations.of(context)!
                            .addLanguageConfirm(language)),
                      );
                      if (!confirm) return;
                      ApiService.getInstance().importLanguage(language);
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
                          cubit.addCategory(res);
                        }
                      },
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
                BlocBuilder<SettingsServerCubit, SettingsServerState>(
                  bloc: cubit,
                  buildWhen: (prev, curr) => prev.categories != curr.categories,
                  builder: (context, state) => ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemCount: state.categories.length,
                    itemBuilder: (context, i) => Dismissible(
                      key: ValueKey<String>(
                        state.categories.elementAt(i).name,
                      ),
                      confirmDismiss: (direction) async {
                        return (await askForConfirmation(
                          context: context,
                          title: Text(
                            AppLocalizations.of(context)!.categoryDelete,
                          ),
                          content: Text(
                            AppLocalizations.of(context)!
                                .categoryDeleteConfirmation(
                              state.categories.elementAt(i).name,
                            ),
                          ),
                        ));
                      },
                      onDismissed: (direction) {
                        cubit.deleteCategory(
                          state.categories.elementAt(i),
                        );
                      },
                      background: Container(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(left: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          color: Colors.red,
                        ),
                        child: const Icon(
                          Icons.delete,
                          color: Colors.white,
                        ),
                      ),
                      secondaryBackground: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          color: Colors.red,
                        ),
                        child: const Icon(
                          Icons.delete,
                          color: Colors.white,
                        ),
                      ),
                      child: Card(
                        child: ListTile(
                          title: Text(
                            state.categories.elementAt(i).name,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Text(
                  AppLocalizations.of(context)!.swipeToDeleteType(
                    AppLocalizations.of(context)!.categories,
                  ),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.caption,
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${AppLocalizations.of(context)!.tags}:',
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
                              title: AppLocalizations.of(context)!.addTag,
                              doneText: AppLocalizations.of(context)!.add,
                              hintText: AppLocalizations.of(context)!.name,
                            );
                          },
                        );
                        if (res != null && res.isNotEmpty) {
                          cubit.addTag(res);
                        }
                      },
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
                BlocBuilder<SettingsServerCubit, SettingsServerState>(
                  bloc: cubit,
                  buildWhen: (prev, curr) => prev.tags != curr.tags,
                  builder: (context, state) => ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: state.tags.length,
                    itemBuilder: (context, i) => Dismissible(
                      key: ValueKey<Tag>(state.tags.elementAt(i)),
                      confirmDismiss: (direction) async {
                        return (await askForConfirmation(
                          context: context,
                          title: Text(
                            AppLocalizations.of(context)!.tagDelete,
                          ),
                          content: Text(AppLocalizations.of(context)!
                              .tagDeleteConfirmation(
                            state.tags.elementAt(i).name,
                          )),
                        ));
                      },
                      onDismissed: (direction) {
                        cubit.deleteTag(state.tags.elementAt(i));
                      },
                      background: Container(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(left: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          color: Colors.red,
                        ),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      secondaryBackground: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          color: Colors.red,
                        ),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      child: Card(
                        child: ListTile(
                          title: Text(state.tags.elementAt(i).name),
                        ),
                      ),
                    ),
                  ),
                ),
                Text(
                  AppLocalizations.of(context)!
                      .swipeToDeleteType(AppLocalizations.of(context)!.tags),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.caption,
                ),
                BlocBuilder<SettingsCubit, SettingsState>(
                  buildWhen: (prev, curr) =>
                      prev.serverSettings.featureExpenses !=
                      curr.serverSettings.featureExpenses,
                  builder: (context, settingsState) =>
                      BlocBuilder<SettingsServerCubit, SettingsServerState>(
                    bloc: cubit,
                    buildWhen: (prev, curr) =>
                        prev.expenseCategories != curr.expenseCategories,
                    builder: (context, state) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: (settingsState.serverSettings.featureExpenses ??
                                  false) &&
                              state.expenseCategories.isNotEmpty
                          ? [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${AppLocalizations.of(context)!.expenseCategories}:',
                                      style:
                                          Theme.of(context).textTheme.headline6,
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
                                                AppLocalizations.of(context)!
                                                    .add,
                                            hintText:
                                                AppLocalizations.of(context)!
                                                    .name,
                                          );
                                        },
                                      );
                                      if (res != null && res.isNotEmpty) {
                                        cubit.addExpenseCategory(res);
                                      }
                                    },
                                    padding: EdgeInsets.zero,
                                  ),
                                ],
                              ),
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                padding: EdgeInsets.zero,
                                itemCount: state.expenseCategories.length,
                                itemBuilder: (context, i) => Dismissible(
                                  key: ValueKey<String>(
                                    state.expenseCategories.elementAt(i),
                                  ),
                                  confirmDismiss: (direction) async {
                                    return (await askForConfirmation(
                                      context: context,
                                      title: Text(
                                        AppLocalizations.of(context)!
                                            .categoryDelete,
                                      ),
                                      content: Text(
                                        AppLocalizations.of(context)!
                                            .categoryExpenseDeleteConfirmation(
                                          state.expenseCategories.elementAt(i),
                                        ),
                                      ),
                                    ));
                                  },
                                  onDismissed: (direction) {
                                    cubit.deleteExpenseCategory(
                                      state.expenseCategories.elementAt(i),
                                    );
                                  },
                                  background: Container(
                                    alignment: Alignment.centerLeft,
                                    padding: const EdgeInsets.only(left: 16),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(5),
                                      color: Colors.red,
                                    ),
                                    child: const Icon(
                                      Icons.delete,
                                      color: Colors.white,
                                    ),
                                  ),
                                  secondaryBackground: Container(
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 16),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(5),
                                      color: Colors.red,
                                    ),
                                    child: const Icon(
                                      Icons.delete,
                                      color: Colors.white,
                                    ),
                                  ),
                                  child: Card(
                                    child: ListTile(
                                      title: Text(
                                        state.expenseCategories.elementAt(i),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Text(
                                AppLocalizations.of(context)!.swipeToDeleteType(
                                  AppLocalizations.of(context)!.categories,
                                ),
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.caption,
                              ),
                            ]
                          : const [],
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${AppLocalizations.of(context)!.users}:',
                        style: Theme.of(context).textTheme.headline6,
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
                BlocBuilder<SettingsServerCubit, SettingsServerState>(
                  bloc: cubit,
                  buildWhen: (prev, curr) => prev.users != curr.users,
                  builder: (context, state) => ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: state.users.length,
                    itemBuilder: (context, i) => Dismissible(
                      key: ValueKey<User>(state.users[i]),
                      confirmDismiss: (direction) async {
                        if (state.users[i].owner) return false;

                        return (await askForConfirmation(
                          context: context,
                          title: Text(
                            AppLocalizations.of(context)!.userDelete,
                          ),
                          content: Text(AppLocalizations.of(context)!
                              .userDeleteConfirmation(state.users[i].name)),
                        ));
                      },
                      onDismissed: (direction) {
                        cubit.deleteUser(state.users[i]);
                      },
                      background: Container(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(left: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          color: Colors.red,
                        ),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      secondaryBackground: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          color: Colors.red,
                        ),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      child: Card(
                        child: ListTile(
                          title: Text(state.users[i].name),
                          subtitle: Text(state.users[i].username +
                              ((state.users[i].id ==
                                      (BlocProvider.of<AuthCubit>(context).state
                                              as Authenticated)
                                          .user
                                          .id)
                                  ? ' (${AppLocalizations.of(context)!.you})'
                                  : '')),
                          trailing: state.users[i].hasAdminRights()
                              ? const Icon(Icons.admin_panel_settings_rounded)
                              : null,
                          onTap: () async {
                            final res = await Navigator.of(context)
                                .push<UpdateEnum>(MaterialPageRoute(
                              builder: (context) => SettingsUserPage(
                                userId: state.users[i].id,
                              ),
                            ));
                            if (res == UpdateEnum.updated) {
                              cubit.refresh();
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                Text(
                  AppLocalizations.of(context)!.swipeToDeleteType(
                    AppLocalizations.of(context)!.users,
                  ),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.caption,
                ),
                SizedBox(height: MediaQuery.of(context).padding.bottom),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
