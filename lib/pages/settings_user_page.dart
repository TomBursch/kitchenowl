import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:kitchenowl/cubits/auth_cubit.dart';
import 'package:kitchenowl/cubits/settings_user_cubit.dart';
import 'package:kitchenowl/enums/token_type_enum.dart';
import 'package:kitchenowl/enums/update_enum.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/token.dart';
import 'package:kitchenowl/models/user.dart';
import 'package:kitchenowl/pages/settings_user_password_page.dart';
import 'package:kitchenowl/pages/settings_user_sessions_page.dart';

class SettingsUserPage extends StatefulWidget {
  final User? user;
  const SettingsUserPage({super.key, this.user});

  @override
  _SettingsUserPageState createState() => _SettingsUserPageState();
}

class _SettingsUserPageState extends State<SettingsUserPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  late SettingsUserCubit cubit;

  @override
  void initState() {
    super.initState();
    cubit = SettingsUserCubit(widget.user?.id);
    final user = widget.user ?? BlocProvider.of<AuthCubit>(context).getUser();
    if (user != null) {
      usernameController.text = user.username;
      nameController.text = user.name;
    }
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
                    BlocBuilder<SettingsUserCubit, SettingsUserState>(
                      bloc: cubit,
                      builder: (context, state) => CircleAvatar(
                        foregroundImage: state.user?.image.isEmpty ?? true
                            ? null
                            : getImageProvider(
                                context,
                                state.user!.image,
                              ),
                        radius: 45,
                        child: Text(
                          nameController.text.substring(0, 1),
                          textScaleFactor: 2,
                        ),
                      ),
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
                      textCapitalization: TextCapitalization.sentences,
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
                            trailing: KitchenOwlSwitch(
                              value: state.setAdmin,
                              onChanged: cubit.setAdmin,
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
                    ListTile(
                      title: Text(AppLocalizations.of(context)!.passwordSave),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded),
                      contentPadding: EdgeInsets.zero,
                      onTap: () async {
                        final res = await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => SettingsUserPasswordPage(),
                          ),
                        );
                        if (res != null) {
                          cubit.updateUser(
                            context: context,
                            password: res,
                          );
                        }
                      },
                    ),
                    ListTile(
                      title: Text(AppLocalizations.of(context)!.sessions),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded),
                      contentPadding: EdgeInsets.zero,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => SettingsUserSessionsPage(
                            cubit: cubit,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 16, bottom: 16),
                      child: LoadingElevatedButton(
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all<Color>(
                            Colors.redAccent,
                          ),
                          foregroundColor: MaterialStateProperty.all<Color>(
                            Colors.white,
                          ),
                        ),
                        onPressed: () async {
                          final confirm = await askForConfirmation(
                            context: context,
                            title: Text(
                              AppLocalizations.of(context)!.userDelete,
                            ),
                            content: Text(AppLocalizations.of(context)!
                                .userDeleteConfirmation(
                              nameController.text,
                            )),
                          );
                          if (confirm) {
                            if (await cubit.deleteUser() && mounted) {
                              BlocProvider.of<AuthCubit>(context).logout();
                              Navigator.of(context).pop(UpdateEnum.deleted);
                            }
                          }
                        },
                        child: Text(AppLocalizations.of(context)!.delete),
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(context).padding.bottom),
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
