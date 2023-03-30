import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kitchenowl/cubits/household_list_cubit.dart';

class HouseholdListPage extends StatefulWidget {
  const HouseholdListPage({super.key});

  @override
  State<HouseholdListPage> createState() => _HouseholdListPageState();
}

class _HouseholdListPageState extends State<HouseholdListPage> {
  late final HouseholdListCubit cubit;

  @override
  void initState() {
    super.initState();
    cubit = HouseholdListCubit();
  }

  @override
  void dispose() {
    cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: cubit.refresh,
        child: SafeArea(
          child: BlocBuilder<HouseholdListCubit, HouseholdListState>(
            bloc: cubit,
            builder: (context, state) {
              return ListView.builder(
                itemBuilder: (context, i) => ListTile(
                  title: Text(state.households[i].name),
                  onTap: () => context.go(
                    '/household/${state.households[i].id}',
                    extra: state.households[i],
                  ),
                ),
                itemCount: state.households.length,
              );
            },
          ),
        ),
      ),
    );
  }
}
