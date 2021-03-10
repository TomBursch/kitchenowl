import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/auth_cubit.dart';
import 'package:kitchenowl/cubits/settings_server_cubit.dart';
import 'package:kitchenowl/models/user.dart';
import 'package:kitchenowl/pages/settings/create_user_page.dart';
import 'package:kitchenowl/pages/settings_user_page.dart';
import 'package:kitchenowl/services/api/api_service.dart';
import 'package:kitchenowl/kitchenowl.dart';

class SettingsServerPage extends StatefulWidget {
  const SettingsServerPage({Key key}) : super(key: key);

  @override
  _SettingsServerPageState createState() => _SettingsServerPageState();
}

class _SettingsServerPageState extends State<SettingsServerPage> {
  SettingsServerCubit cubit;

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
        title: Text(AppLocalizations.of(context).server),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints.expand(width: 600),
          child: RefreshIndicator(
            onRefresh: cubit.refresh,
            child: ListView(
              padding: EdgeInsets.all(16),
              children: [
                Text(
                  AppLocalizations.of(context).server + ':',
                  style: Theme.of(context).textTheme.headline6,
                ),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                      title: Text(Uri.parse(ApiService.getInstance().baseUrl)
                          .authority)),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context).users + ':',
                        style: Theme.of(context).textTheme.headline6,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.add),
                      onPressed: () =>
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) => BlocProvider.value(
                                    value: cubit,
                                    child: CreateUserPage(),
                                  ))),
                      padding: EdgeInsets.zero,
                    )
                  ],
                ),
                BlocBuilder<SettingsServerCubit, SettingsServerState>(
                  cubit: cubit,
                  builder: (context, state) => ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: state.users.length,
                    itemBuilder: (context, i) => Dismissible(
                      key: ValueKey<User>(state.users[i]),
                      confirmDismiss: (direction) async {
                        if (state.users[i].owner) return false;
                        return (await showDialog<bool>(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: Text(
                                      AppLocalizations.of(context).userDelete,
                                    ),
                                    content: Text(AppLocalizations.of(context)
                                        .userDeleteConfirmation(
                                            state.users[i].name)),
                                    actions: <Widget>[
                                      TextButton(
                                        child: Text(AppLocalizations.of(context)
                                            .cancel),
                                        style: ButtonStyle(
                                          foregroundColor:
                                              MaterialStateProperty.all<Color>(
                                            Theme.of(context).disabledColor,
                                          ),
                                        ),
                                        onPressed: () =>
                                            Navigator.of(context).pop(false),
                                      ),
                                      TextButton(
                                        child: Text(AppLocalizations.of(context)
                                            .delete),
                                        style: ButtonStyle(
                                          foregroundColor:
                                              MaterialStateProperty.all<Color>(
                                            Colors.red,
                                          ),
                                        ),
                                        onPressed: () =>
                                            Navigator.of(context).pop(true),
                                      ),
                                    ],
                                  );
                                }) ??
                            false);
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
                        child: Icon(Icons.delete, color: Colors.white),
                      ),
                      secondaryBackground: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          color: Colors.red,
                        ),
                        child: Icon(Icons.delete, color: Colors.white),
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
                                  ? ' (${AppLocalizations.of(context).you})'
                                  : '')),
                          trailing: state.users[i].owner
                              ? Icon(Icons.admin_panel_settings_rounded)
                              : null,
                          onTap: () =>
                              Navigator.of(context).push(MaterialPageRoute(
                                  builder: (context) => SettingsUserPage(
                                        userId: state.users[i].id,
                                      ))),
                        ),
                      ),
                    ),
                  ),
                ),
                Text(
                  AppLocalizations.of(context).swipeToDeleteUser,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.caption,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
