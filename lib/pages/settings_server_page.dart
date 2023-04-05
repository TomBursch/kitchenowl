import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/settings_server_cubit.dart';
import 'package:kitchenowl/enums/update_enum.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/pages/settings/create_user_page.dart';
import 'package:kitchenowl/services/api/api_service.dart';
import 'package:kitchenowl/widgets/settings_server/server_user_card.dart';

class SettingsServerPage extends StatefulWidget {
  const SettingsServerPage({super.key});

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
      body: BlocProvider.value(
        value: cubit,
        child: Align(
          alignment: Alignment.topCenter,
          child: Scrollbar(
            child: ConstrainedBox(
              constraints: const BoxConstraints.expand(width: 600),
              child: RefreshIndicator(
                onRefresh: cubit.refresh,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: CustomScrollView(
                    primary: true,
                    scrollBehavior: const MaterialScrollBehavior()
                        .copyWith(scrollbars: false),
                    slivers: [
                      SliverList(
                        delegate: SliverChildListDelegate([
                          const SizedBox(height: 16),
                          Text(
                            '${AppLocalizations.of(context)!.server}:',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Card(
                            child: ListTile(
                              title: Text(
                                Uri.parse(ApiService.getInstance().baseUrl)
                                    .authority,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${AppLocalizations.of(context)!.users}:',
                                  style: Theme.of(context).textTheme.titleLarge,
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
                        ]),
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
                              (context, i) =>
                                  ServerUserCard(user: state.users[i]),
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
            ),
          ),
        ),
      ),
    );
  }
}
