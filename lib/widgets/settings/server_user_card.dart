import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/settings_server_cubit.dart';
import 'package:kitchenowl/enums/update_enum.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/user.dart';
import 'package:kitchenowl/pages/settings_user_page.dart';
import 'package:kitchenowl/widgets/user_list_tile.dart';

class ServerUserListTile extends StatelessWidget {
  final User user;

  const ServerUserListTile({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey<User>(user),
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.redAccent,
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
          borderRadius: BorderRadius.circular(14),
          color: Colors.redAccent,
        ),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      confirmDismiss: (direction) async {
        if (user.serverAdmin) return false;

        return (await askForConfirmation(
          context: context,
          title: Text(
            AppLocalizations.of(context)!.userDelete,
          ),
          content: Text(AppLocalizations.of(context)!.userDeleteConfirmation(
            user.name,
          )),
        ));
      },
      onDismissed: (direction) {
        BlocProvider.of<SettingsServerCubit>(context).deleteUser(user);
      },
      child: UserListTile(
        user: user,
        markSelf: true,
        trailing: user.hasServerAdminRights()
            ? Icon(
                Icons.admin_panel_settings_rounded,
                color: user.serverAdmin ? Colors.redAccent : null,
              )
            : null,
        onTap: () async {
          final res =
              await Navigator.of(context).push<UpdateEnum>(MaterialPageRoute(
            builder: (context) => SettingsUserPage(
              user: user,
            ),
          ));
          if (res == UpdateEnum.updated) {
            BlocProvider.of<SettingsServerCubit>(context).refresh();
          }
        },
      ),
    );
  }
}
