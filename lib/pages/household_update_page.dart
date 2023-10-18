import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/household_add_update/household_update_cubit.dart';
import 'package:kitchenowl/helpers/debouncer.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/widgets/settings_household/sliver_household_category_settings.dart';
import 'package:kitchenowl/widgets/settings_household/sliver_household_danger_zone.dart';
import 'package:kitchenowl/widgets/settings_household/sliver_household_expense_category_settings.dart';
import 'package:kitchenowl/widgets/settings_household/sliver_household_feature_settings.dart';
import 'package:kitchenowl/widgets/settings_household/sliver_household_shoppinglist_settings.dart';
import 'package:kitchenowl/widgets/settings_household/sliver_household_tags_settings.dart';
import 'package:sliver_tools/sliver_tools.dart';

class HouseholdUpdatePage extends StatefulWidget {
  final Household household;

  const HouseholdUpdatePage({super.key, required this.household});

  @override
  _HouseholdUpdatePageState createState() => _HouseholdUpdatePageState();
}

class _HouseholdUpdatePageState extends State<HouseholdUpdatePage> {
  late HouseholdUpdateCubit cubit;
  late final TextEditingController nameController;
  late Debouncer _debouncer;

  @override
  void initState() {
    super.initState();
    cubit = HouseholdUpdateCubit(widget.household);
    nameController = TextEditingController(text: widget.household.name);
    _debouncer = Debouncer(duration: const Duration(milliseconds: 1000));
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
        child: BlocListener<HouseholdUpdateCubit, HouseholdUpdateState>(
          listener: (context, state) {
            nameController.text = state.name;
          },
          listenWhen: (previous, current) => previous.name != current.name,
          bloc: cubit,
          child: RefreshIndicator(
            onRefresh: cubit.refresh,
            child: CustomScrollView(
              primary: true,
              slivers: [
                SliverCrossAxisPadded.symmetric(
                  padding: 16,
                  child: SliverCrossAxisConstrained(
                    maxCrossAxisExtent: 600,
                    child: SliverList(
                      delegate: SliverChildListDelegate([
                        BlocBuilder<HouseholdUpdateCubit, HouseholdUpdateState>(
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
                            onChanged: (value) => _debouncer.run(
                              () => cubit.setName(value),
                            ),
                            onSubmitted: (value) {
                              _debouncer.cancel();
                              cubit.setName(value);
                            },
                            textInputAction: TextInputAction.next,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(context)!.name,
                            ),
                          ),
                        ),
                      ]),
                    ),
                  ),
                ),
                SliverCrossAxisPadded.symmetric(
                  padding: 16,
                  child: const SliverCrossAxisConstrained(
                    maxCrossAxisExtent: 600,
                    child: SliverHouseholdFeatureSettings<HouseholdUpdateCubit,
                        HouseholdUpdateState>(),
                  ),
                ),
                SliverCrossAxisPadded.symmetric(
                  padding: 16,
                  child: const SliverCrossAxisConstrained(
                    maxCrossAxisExtent: 600,
                    child: SliverHouseholdShoppinglistSettings(),
                  ),
                ),
                SliverCrossAxisPadded.symmetric(
                  padding: 16,
                  child: const SliverCrossAxisConstrained(
                    maxCrossAxisExtent: 600,
                    child: SliverHouseholdCategorySettings(),
                  ),
                ),
                SliverCrossAxisPadded.symmetric(
                  padding: 16,
                  child: const SliverCrossAxisConstrained(
                    maxCrossAxisExtent: 600,
                    child: SliverHouseholdTagsSettings(),
                  ),
                ),
                SliverCrossAxisPadded.symmetric(
                  padding: 16,
                  child: const SliverCrossAxisConstrained(
                    maxCrossAxisExtent: 600,
                    child: SliverHouseholdExpenseCategorySettings(),
                  ),
                ),
                SliverCrossAxisPadded.symmetric(
                  padding: 16,
                  child: const SliverCrossAxisConstrained(
                    maxCrossAxisExtent: 600,
                    child: SliverHouseholdDangerZone(),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: MediaQuery.of(context).padding.bottom,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
