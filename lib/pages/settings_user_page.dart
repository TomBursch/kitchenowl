import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/settings_user_cubit.dart';
import 'package:kitchenowl/kitchenowl.dart';

class SettingsUserPage extends StatefulWidget {
  final int userId;
  SettingsUserPage({Key key, this.userId}) : super(key: key);

  @override
  _SettingsUserPageState createState() => _SettingsUserPageState();
}

class _SettingsUserPageState extends State<SettingsUserPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  SettingsUserCubit cubit;

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
    return BlocListener<SettingsUserCubit, SettingsUserState>(
      cubit: cubit,
      listener: (context, state) {
        if (state.user != null) {
          usernameController.text = state.user.username;
          nameController.text = state.user.name;
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context).user),
        ),
        body: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints.expand(width: 600),
            child: ListView(
              padding: EdgeInsets.all(16),
              children: [
                Icon(
                  Icons.account_circle_rounded,
                  size: 90,
                  color: Theme.of(context).accentColor,
                ),
                TextField(
                  controller: usernameController,
                  autofocus: true,
                  enabled: false,
                  textInputAction: TextInputAction.next,
                  onEditingComplete: () => FocusScope.of(context).nextFocus(),
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context).username,
                  ),
                ),
                TextField(
                  controller: nameController,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context).name,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 8),
                  child: ElevatedButton(
                    onPressed: () => cubit.updateUser(
                      context: context,
                      name: nameController.text,
                    ),
                    child: Text(AppLocalizations.of(context).save),
                  ),
                ),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context).password,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 8),
                  child: ElevatedButton(
                    onPressed: () =>
                        cubit.updateUser(password: passwordController.text),
                    child: Text(AppLocalizations.of(context).passwordSave),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
