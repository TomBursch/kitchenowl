import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/settings_server_cubit.dart';
import 'package:kitchenowl/enums/update_enum.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/pages/settings/create_user_page.dart';
import 'package:kitchenowl/widgets/settings/server_user_card.dart';

class SettingsServerUserPage extends StatefulWidget {
  const SettingsServerUserPage({super.key});

  @override
  _SettingsServerUserPageState createState() => _SettingsServerUserPageState();
}

class _SettingsServerUserPageState extends State<SettingsServerUserPage> {
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
      body: BlocProvider.value(
        value: cubit,
        child: RefreshIndicator(
          onRefresh: cubit.refresh,
          child: CustomScrollView(
            primary: true,
            slivers: [
              SliverAppBar(
                title: Text(AppLocalizations.of(context)!.users),
                floating: true,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.add),
                    tooltip: AppLocalizations.of(context)!.userAdd,
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
                buildWhen: (prev, curr) =>
                    prev.users != curr.users ||
                    prev is LoadingSettingsServerState,
                builder: (context, state) {
                  if (state is LoadingSettingsServerState) {
                    return const SliverToBoxAdapter(
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      childCount: state.users.length,
                      (context, i) => ServerUserListTile(user: state.users[i]),
                    ),
                  );
                },
              ),
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
    );
  }
}
