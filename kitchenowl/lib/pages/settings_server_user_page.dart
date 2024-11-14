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
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    cubit = SettingsServerCubit();
  }

  @override
  void dispose() {
    cubit.close();
    searchController.dispose();
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
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 70,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                    child: SearchTextField(
                      controller: searchController,
                      labelText: Nullable.empty(),
                      hintText: AppLocalizations.of(context)!.userSearchHint,
                      clearOnSubmit: false,
                      onSearch: (s) async {
                        cubit.filter(s);
                      },
                      textInputAction: TextInputAction.search,
                    ),
                  ),
                ),
              ),
              BlocBuilder<SettingsServerCubit, SettingsServerState>(
                builder: (context, state) {
                  if (state is LoadingSettingsServerState) {
                    return const SliverToBoxAdapter(
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final filteredUsers = state.users
                      .where((u) =>
                          (u.email
                                  ?.toLowerCase()
                                  .contains(state.filter.toLowerCase()) ??
                              false) ||
                          u.username
                              .toLowerCase()
                              .contains(state.filter.toLowerCase()))
                      .toList();

                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      childCount: filteredUsers.length,
                      (context, i) =>
                          ServerUserListTile(user: filteredUsers[i]),
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
                    height: MediaQuery.paddingOf(context).bottom + 4,
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
