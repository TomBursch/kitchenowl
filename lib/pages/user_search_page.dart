import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/user_search_cubit.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/user.dart';
import 'package:kitchenowl/widgets/user_list_tile.dart';

class UserSearchPage extends StatefulWidget {
  final List<User> disabledUser;

  const UserSearchPage({super.key, this.disabledUser = const []});

  @override
  State<UserSearchPage> createState() => _UserSearchPageState();
}

class _UserSearchPageState extends State<UserSearchPage> {
  final TextEditingController searchController = TextEditingController();
  late UserSearchCubit cubit;

  @override
  void initState() {
    super.initState();
    cubit = UserSearchCubit();
  }

  @override
  void dispose() {
    cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appbar = AppBar(
      title: Text(AppLocalizations.of(context)!.memberAdd),
      flexibleSpace: Align(
        alignment: Alignment.bottomCenter,
        child: SizedBox(
          height: 64,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: BlocListener<UserSearchCubit, UserSearchState>(
              bloc: cubit,
              listener: (context, state) {
                if (state.query.isEmpty && searchController.text.isNotEmpty) {
                  searchController.clear();
                }
              },
              child: SearchTextField(
                controller: searchController,
                onSearch: cubit.search,
                autofocus: true,
                alwaysExpanded: true,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    onPressed: () {
                      if (searchController.text.isNotEmpty) {
                        cubit.search('');
                      }
                      FocusScope.of(context).unfocus();
                    },
                    icon: const Icon(
                      Icons.close,
                      color: Colors.grey,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  hintText: AppLocalizations.of(context)!.userSearchHint,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(appbar.preferredSize.height + 56),
        child: appbar,
      ),
      body: BlocBuilder<UserSearchCubit, UserSearchState>(
        bloc: cubit,
        builder: (context, state) => CustomScrollView(
          slivers: [
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => UserListTile(
                  user: state.searchResult[i],
                  disabled: widget.disabledUser
                      .map((e) => e.id)
                      .contains(state.searchResult[i].id),
                  onTap: () => Navigator.of(context).pop(state.searchResult[i]),
                  trailing: widget.disabledUser
                          .map((e) => e.id)
                          .contains(state.searchResult[i].id)
                      ? const Icon(Icons.people_alt_rounded)
                      : null,
                ),
                childCount: state.searchResult.length,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
