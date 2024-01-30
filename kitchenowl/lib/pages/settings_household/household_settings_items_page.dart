import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/household_add_update/household_settings_items_cubit.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/household.dart';

class HouseholdSettingsItemsPage extends StatefulWidget {
  final Household household;

  const HouseholdSettingsItemsPage({
    super.key,
    required this.household,
  });

  @override
  State<HouseholdSettingsItemsPage> createState() =>
      _HouseholdSettingsItemsPageState();
}

class _HouseholdSettingsItemsPageState
    extends State<HouseholdSettingsItemsPage> {
  late HouseholdSettingsItemsCubit cubit;

  @override
  void initState() {
    super.initState();
    cubit = HouseholdSettingsItemsCubit(widget.household);
  }

  @override
  void dispose() {
    cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: Text(AppLocalizations.of(context)!.items),
            floating: true,
          ),
          BlocBuilder<HouseholdSettingsItemsCubit, HouseholdSettingsItemsState>(
            bloc: cubit,
            builder: (context, state) {
              return SliverItemGridList(
                isLoading: state is LoadingHouseholdSettingsItemsState,
                items: state.items,
                household: widget.household,
                categories: state.categories,
                onRefresh: cubit.refresh,
                allRaised: true,
              );
            },
          ),
        ],
      ),
    );
  }
}
