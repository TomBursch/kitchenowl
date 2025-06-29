import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/auth_cubit.dart';
import 'package:kitchenowl/cubits/household_member_cubit.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/models/member.dart';
import 'package:kitchenowl/models/user.dart';
import 'package:kitchenowl/pages/user_search_page.dart';
import 'package:kitchenowl/widgets/settings_household/update_member_bottom_sheet.dart';
import 'package:kitchenowl/widgets/user_list_tile.dart';

class HouseholdMemberPage extends StatefulWidget {
  final Household household;

  const HouseholdMemberPage({super.key, required this.household});

  @override
  _HouseholdMemberPageState createState() => _HouseholdMemberPageState();
}

class _HouseholdMemberPageState extends State<HouseholdMemberPage> {
  late HouseholdMemberCubit cubit;
  late final TextEditingController nameController;

  @override
  void initState() {
    super.initState();
    cubit = HouseholdMemberCubit(widget.household);
    nameController = TextEditingController(text: widget.household.name);
  }

  @override
  void dispose() {
    cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HouseholdMemberCubit, HouseholdMemberState>(
      bloc: cubit,
      builder: (context, state) {
        final hasAdminRights = state.member
                .firstWhereOrNull(
                  (e) =>
                      e.id == BlocProvider.of<AuthCubit>(context).getUser()?.id,
                )
                ?.hasAdminRights() ??
            false;

        return Scaffold(
          appBar: AppBar(
            title: Text(AppLocalizations.of(context)!.members),
            actions: [
              if (hasAdminRights)
                LoadingIconButton(
                  icon: const Icon(Icons.add),
                  tooltip: AppLocalizations.of(context)!.memberAdd,
                  onPressed: () async {
                    final user = await Navigator.of(context)
                        .push<User>(MaterialPageRoute(
                      builder: (ctx) => UserSearchPage(
                        disabledUser: cubit.state.member,
                      ),
                    ));
                    if (user == null) return;

                    return cubit.putMember(Member.fromUser(user));
                  },
                  padding: EdgeInsets.zero,
                ),
            ],
          ),
          body: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints.expand(width: 600),
              child: RefreshIndicator(
                onRefresh: cubit.refresh,
                child: CustomScrollView(
                  primary: true,
                  slivers: [
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        childCount: state.member.length,
                        (context, i) => Dismissible(
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
                          key: ValueKey<Member>(state.member[i]),
                          confirmDismiss: (direction) async {
                            if (state.member[i].owner) return false;

                            return (await askForConfirmation(
                              context: context,
                              title: Text(
                                AppLocalizations.of(context)!.userDelete,
                              ),
                              confirmText: AppLocalizations.of(context)!.remove,
                              content: Text(
                                AppLocalizations.of(context)!
                                    .userDeleteConfirmation(
                                  state.member[i].name,
                                ),
                              ),
                            ));
                          },
                          onDismissed: (direction) {
                            cubit.removeMember(state.member[i]);
                          },
                          child: UserListTile(
                            user: state.member[i],
                            markSelf: true,
                            trailing: state.member[i].hasAdminRights()
                                ? Icon(Icons.admin_panel_settings_rounded)
                                : null,
                            onTap: () async {
                              showModalBottomSheet<void>(
                                context: context,
                                showDragHandle: true,
                                builder: (ctx) => UpdateMemberBottomSheet(
                                  member: state.member[i],
                                  allowEdit: hasAdminRights,
                                  putMember: cubit.putMember,
                                  removeMember: cubit.removeMember,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: MediaQuery.paddingOf(context).bottom,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
