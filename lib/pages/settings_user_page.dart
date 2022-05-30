import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/settings_user_cubit.dart';
import 'package:kitchenowl/kitchenowl.dart';

class SettingsUserPage extends StatefulWidget {
  final int? userId;
  const SettingsUserPage({Key? key, this.userId}) : super(key: key);

  @override
  _SettingsUserPageState createState() => _SettingsUserPageState();
}

class _SettingsUserPageState extends State<SettingsUserPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  late SettingsUserCubit cubit;

  @override
  void initState() {
    super.initState();
    cubit = SettingsUserCubit(widget.userId);
  }

  @override
  void dispose() {
    cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop(cubit.state.updateState);

        return false;
      },
      child: BlocListener<SettingsUserCubit, SettingsUserState>(
        bloc: cubit,
        listener: (context, state) {
          if (state.user != null) {
            usernameController.text = state.user?.username ?? '';
            nameController.text = state.user?.name ?? '';
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text(AppLocalizations.of(context)!.user),
            leading: BackButton(
              onPressed: () =>
                  Navigator.of(context).pop(cubit.state.updateState),
            ),
          ),
          body: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints.expand(width: 600),
              child: AutofillGroup(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Icon(
                      Icons.account_circle_rounded,
                      size: 90,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    TextField(
                      controller: usernameController,
                      autofocus: true,
                      enabled: false,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.username,
                      ),
                    ),
                    TextField(
                      controller: nameController,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.name,
                      ),
                    ),
                    if (cubit.userId != null)
                      BlocBuilder<SettingsUserCubit, SettingsUserState>(
                        bloc: cubit,
                        builder: (context, state) {
                          return ListTile(
                            title: Text(AppLocalizations.of(context)!.admin),
                            leading:
                                const Icon(Icons.admin_panel_settings_rounded),
                            contentPadding:
                                const EdgeInsets.only(left: 0, right: 0),
                            trailing: Transform.scale(
                              scale: 0.9,
                              child: CupertinoSwitch(
                                value: state.setAdmin,
                                activeColor:
                                    Theme.of(context).colorScheme.secondary,
                                onChanged: cubit.setAdmin,
                              ),
                            ),
                          );
                        },
                      ),
                    Padding(
                      padding: const EdgeInsets.only(top: 16, bottom: 8),
                      child: LoadingElevatedButton(
                        onPressed: () => cubit.updateUser(
                          context: context,
                          name: nameController.text,
                        ),
                        child: Text(AppLocalizations.of(context)!.save),
                      ),
                    ),
                    TextField(
                      controller: passwordController,
                      autofillHints: const [AutofillHints.newPassword],
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.password,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 16, bottom: 8),
                      child: LoadingElevatedButton(
                        onPressed: () => cubit.updateUser(
                          context: context,
                          password: passwordController.text,
                        ),
                        child: Text(AppLocalizations.of(context)!.passwordSave),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
