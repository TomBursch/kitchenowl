import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/auth_cubit.dart';
import 'package:kitchenowl/cubits/settings_server_cubit.dart';
import 'package:kitchenowl/enums/update_enum.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/user.dart';
import 'package:kitchenowl/pages/settings_user_page.dart';
import 'package:kitchenowl/widgets/dismissible_card.dart';

class SliverServerUserSettings extends StatelessWidget {
  const SliverServerUserSettings({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsServerCubit, SettingsServerState>(
      buildWhen: (prev, curr) =>
          prev.users != curr.users || prev is LoadingSettingsServerState,
      builder: (context, state) {
        if (state is LoadingSettingsServerState) {
          return const SliverToBoxAdapter(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            childCount: state.users.length,
            (context, i) => DismissibleCard(
              key: ValueKey<User>(state.users[i]),
              confirmDismiss: (direction) async {
                if (state.users[i].owner) return false;

                return (await askForConfirmation(
                  context: context,
                  title: Text(
                    AppLocalizations.of(context)!.userDelete,
                  ),
                  content:
                      Text(AppLocalizations.of(context)!.userDeleteConfirmation(
                    state.users[i].name,
                  )),
                ));
              },
              onDismissed: (direction) {
                BlocProvider.of<SettingsServerCubit>(context)
                    .deleteUser(state.users[i]);
              },
              title: Text(state.users[i].name),
              subtitle: Text(state.users[i].username +
                  ((state.users[i].id ==
                          (BlocProvider.of<AuthCubit>(
                            context,
                          ).state as Authenticated)
                              .user
                              .id)
                      ? ' (${AppLocalizations.of(context)!.you})'
                      : '')),
              trailing: state.users[i].hasAdminRights()
                  ? Icon(
                      Icons.admin_panel_settings_rounded,
                      color: state.users[i].owner ? Colors.redAccent : null,
                    )
                  : null,
              onTap: () async {
                final res = await Navigator.of(context)
                    .push<UpdateEnum>(MaterialPageRoute(
                  builder: (context) => SettingsUserPage(
                    userId: state.users[i].id,
                  ),
                ));
                if (res == UpdateEnum.updated) {
                  BlocProvider.of<SettingsServerCubit>(context).refresh();
                }
              },
            ),
          ),
        );
      },
    );
  }
}
