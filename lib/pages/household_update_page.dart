import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/household_add_update/household_update_cubit.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/widgets/settings_household/sliver_household_category_settings.dart';
import 'package:kitchenowl/widgets/settings_household/sliver_household_danger_zone.dart';
import 'package:kitchenowl/widgets/settings_household/sliver_household_expense_category_settings.dart';
import 'package:kitchenowl/widgets/settings_household/sliver_household_feature_settings.dart';
import 'package:kitchenowl/widgets/settings_household/sliver_household_member_settings.dart';
import 'package:kitchenowl/widgets/settings_household/sliver_household_shoppinglist_settings.dart';
import 'package:kitchenowl/widgets/settings_household/sliver_household_tags_settings.dart';

class HouseholdUpdatePage extends StatefulWidget {
  final Household household;

  const HouseholdUpdatePage({super.key, required this.household});

  @override
  _HouseholdUpdatePageState createState() => _HouseholdUpdatePageState();
}

class _HouseholdUpdatePageState extends State<HouseholdUpdatePage> {
  late HouseholdUpdateCubit cubit;
  late final TextEditingController nameController;

  @override
  void initState() {
    super.initState();
    cubit = HouseholdUpdateCubit(widget.household);
    nameController = TextEditingController(text: widget.household.name);
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
        title: Text(AppLocalizations.of(context)!.household),
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
                          BlocBuilder<HouseholdUpdateCubit,
                              HouseholdUpdateState>(
                            bloc: cubit,
                            buildWhen: (previous, current) =>
                                previous.image != current.image,
                            builder: (context, state) => ImageSelector(
                              padding: null,
                              originalImage: state.image,
                              setImage: cubit.setImage,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: TextField(
                              controller: nameController,
                              onSubmitted: (s) => cubit.setName(s),
                              textInputAction: TextInputAction.next,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: InputDecoration(
                                labelText: AppLocalizations.of(context)!.name,
                              ),
                            ),
                          ),
                        ]),
                      ),
                      const SliverHouseholdFeatureSettings<HouseholdUpdateCubit,
                          HouseholdUpdateState>(),
                      const SliverHouseholdShoppinglistSettings(),
                      const SliverHouseholdCategorySettings(),
                      const SliverHouseholdTagsSettings(),
                      const SliverHouseholdExpenseCategorySettings(),
                      const SliverHouseholdMemberSettings(),
                      const SliverHouseholdDangerZone(),
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
