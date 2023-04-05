import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/auth_cubit.dart';
import 'package:kitchenowl/cubits/household_add_update/household_update_cubit.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/member.dart';
import 'package:kitchenowl/models/user.dart';
import 'package:kitchenowl/pages/user_search_page.dart';
import 'package:kitchenowl/widgets/dismissible_card.dart';
import 'package:kitchenowl/widgets/settings_household/update_member_bottom_sheet.dart';
import 'package:kitchenowl/widgets/user_list_tile.dart';
import 'package:sliver_tools/sliver_tools.dart';

class SliverHouseholdMemberSettings extends StatelessWidget {
  const SliverHouseholdMemberSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiSliver(children: [
      SliverList(
        delegate: SliverChildListDelegate([
          Row(
            children: [
              Expanded(
                child: Text(
                  '${AppLocalizations.of(context)!.members}:',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              SizedBox(
                height: 40,
                child: LoadingIconButton(
                  icon: const Icon(Icons.add),
                  tooltip: AppLocalizations.of(context)!.memberAdd,
                  onPressed: () async {
                    final user = await Navigator.of(context)
                        .push<User>(MaterialPageRoute(
                      builder: (ctx) => UserSearchPage(
                        disabledUser:
                            BlocProvider.of<HouseholdUpdateCubit>(context)
                                .state
                                .member,
                      ),
                    ));
                    if (user == null) return;

                    return BlocProvider.of<HouseholdUpdateCubit>(context)
                        .putMember(Member.fromUser(user));
                  },
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ]),
      ),
      BlocBuilder<HouseholdUpdateCubit, HouseholdUpdateState>(
        buildWhen: (prev, curr) =>
            prev.member != curr.member || prev is LoadingHouseholdUpdateState,
        builder: (context, state) {
          if (state is LoadingHouseholdUpdateState) {
            return const SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator()),
            );
          }

          return SliverList(
            delegate: SliverChildBuilderDelegate(
              childCount: state.member.length,
              (context, i) => DismissibleCard(
                key: ValueKey<Member>(state.member[i]),
                confirmDismiss: (direction) async {
                  if (state.member[i].owner) return false;

                  return (await askForConfirmation(
                    context: context,
                    title: Text(
                      AppLocalizations.of(context)!.userDelete,
                    ),
                    content: Text(
                      AppLocalizations.of(context)!.userDeleteConfirmation(
                        state.member[i].name,
                      ),
                    ),
                  ));
                },
                onDismissed: (direction) {
                  BlocProvider.of<HouseholdUpdateCubit>(context)
                      .removeMember(state.member[i]);
                },
                title: Text(state.member[i].name),
                subtitle: Text(
                  "@${state.member[i].username}${(state.member[i].id == (BlocProvider.of<AuthCubit>(
                        context,
                      ).state as Authenticated).user.id) ? ' (${AppLocalizations.of(context)!.you})' : ''}",
                ),
                trailing: state.member[i].hasAdminRights()
                    ? Icon(
                        Icons.admin_panel_settings_rounded,
                        color: state.member[i].owner ? Colors.redAccent : null,
                      )
                    : null,
                onTap: () async {
                  showModalBottomSheet<void>(
                    context: context,
                    builder: (ctx) => BlocProvider<HouseholdUpdateCubit>.value(
                      value: BlocProvider.of<HouseholdUpdateCubit>(context),
                      child: UpdateMemberBottomSheet(
                        member: state.member[i],
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
      SliverList(
        delegate: SliverChildListDelegate([
          Text(
            AppLocalizations.of(context)!.swipeToRemove,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          SizedBox(
            height: MediaQuery.of(context).padding.bottom + 4,
          ),
        ]),
      ),
    ]);
  }
}
