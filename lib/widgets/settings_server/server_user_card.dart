import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/auth_cubit.dart';
import 'package:kitchenowl/cubits/settings_server_cubit.dart';
import 'package:kitchenowl/enums/update_enum.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/user.dart';
import 'package:kitchenowl/pages/settings_user_page.dart';
import 'package:kitchenowl/widgets/dismissible_card.dart';

class ServerUserCard extends StatelessWidget {
  final User user;

  const ServerUserCard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return DismissibleCard(
      key: ValueKey<User>(user),
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
      title: Text(user.name +
          ((user.id ==
                  (BlocProvider.of<AuthCubit>(
                    context,
                  ).state as Authenticated)
                      .user
                      .id)
              ? ' (${AppLocalizations.of(context)!.you})'
              : '')),
      subtitle: Text("@${user.username}"),
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
    );
  }
}
