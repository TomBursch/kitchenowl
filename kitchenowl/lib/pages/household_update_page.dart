import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/household_add_update/household_update_cubit.dart';
import 'package:kitchenowl/helpers/debouncer.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/pages/settings_household/household_settings_category_page.dart';
import 'package:kitchenowl/pages/settings_household/household_settings_items_page.dart';
import 'package:kitchenowl/widgets/settings_household/sliver_household_danger_zone.dart';
import 'package:kitchenowl/pages/settings_household/household_settings_expense_category_page.dart';
import 'package:kitchenowl/widgets/settings_household/sliver_household_feature_settings.dart';
import 'package:kitchenowl/pages/settings_household/household_settings_shoppinglist_page.dart';
import 'package:kitchenowl/pages/settings_household/household_settings_tags_page.dart';
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
  late final TextEditingController linkController;
  late final TextEditingController descriptionController;
  late Debouncer _debouncer;

  @override
  void initState() {
    super.initState();
    cubit = HouseholdUpdateCubit(widget.household);
    nameController = TextEditingController(text: widget.household.name);
    linkController = TextEditingController(text: widget.household.link);
    descriptionController =
        TextEditingController(text: widget.household.description);
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
            linkController.text = state.link;
            descriptionController.text = state.description;
          },
          listenWhen: (previous, current) =>
              previous.name != current.name ||
              previous.link != current.link ||
              previous.description != current.description,
          bloc: cubit,
          child: RefreshIndicator(
            onRefresh: cubit.refresh,
            child: CustomScrollView(
              primary: true,
              slivers: [
                SliverCrossAxisConstrained(
                  maxCrossAxisExtent: 600,
                  child: SliverCrossAxisPadded.symmetric(
                    padding: 16,
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
                          child: TextFormField(
                            controller: nameController,
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            onChanged: (value) => _debouncer.run(
                              () => cubit.setName(value),
                            ),
                            onFieldSubmitted: (value) {
                              _debouncer.cancel();
                              cubit.setName(value);
                            },
                            validator: (value) {
                              if (value != null && value.trim().isEmpty) {
                                return AppLocalizations.of(context)!
                                    .fieldCannotBeEmpty(
                                        AppLocalizations.of(context)!.name);
                              }
                              return null;
                            },
                            textInputAction: TextInputAction.next,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(context)!.name,
                            ),
                          ),
                        ),
                        TextField(
                          controller: linkController,
                          onChanged: (value) => _debouncer.run(
                            () => cubit.setLink(value),
                          ),
                          onSubmitted: (value) {
                            _debouncer.cancel();
                            cubit.setLink(value);
                          },
                          textInputAction: TextInputAction.next,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)!.website,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: TextField(
                            controller: descriptionController,
                            onChanged: (value) => _debouncer.run(
                              () => cubit.setDescription(value),
                            ),
                            onSubmitted: (value) {
                              _debouncer.cancel();
                              cubit.setDescription(value);
                            },
                            maxLines: null,
                            textInputAction: TextInputAction.next,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(14)),
                              ),
                              labelText: AppLocalizations.of(context)!.about,
                            ),
                          ),
                        ),
                      ]),
                    ),
                  ),
                ),
                const SliverCrossAxisConstrained(
                  maxCrossAxisExtent: 600,
                  child: SliverHouseholdFeatureSettings<HouseholdUpdateCubit,
                      HouseholdUpdateState>(),
                ),
                SliverCrossAxisConstrained(
                  maxCrossAxisExtent: 600,
                  child: SliverList(
                    delegate: SliverChildListDelegate([
                      const Divider(indent: 16, endIndent: 16),
                      ListTile(
                        title: Text(AppLocalizations.of(context)!.items),
                        leading: const Icon(Icons.fastfood_rounded),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded),
                        contentPadding:
                            const EdgeInsets.only(left: 16, right: 16),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => HouseholdSettingsItemsPage(
                              household: widget.household,
                            ),
                          ),
                        ),
                      ),
                      ListTile(
                        title:
                            Text(AppLocalizations.of(context)!.shoppingLists),
                        leading: const Icon(Icons.list_rounded),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded),
                        contentPadding:
                            const EdgeInsets.only(left: 16, right: 16),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => BlocProvider.value(
                              value: cubit,
                              child: HouseholdSettingsShoppinglistPage(),
                            ),
                          ),
                        ),
                      ),
                      ListTile(
                        title: Text(AppLocalizations.of(context)!.categories),
                        leading: const Icon(Icons.category_rounded),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded),
                        contentPadding:
                            const EdgeInsets.only(left: 16, right: 16),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => BlocProvider.value(
                              value: cubit,
                              child: HouseholdSettingsCategoryPage(),
                            ),
                          ),
                        ),
                      ),
                      ListTile(
                        title: Text(AppLocalizations.of(context)!.tags),
                        leading: const Icon(Icons.tag_rounded),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded),
                        contentPadding:
                            const EdgeInsets.only(left: 16, right: 16),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => BlocProvider.value(
                              value: cubit,
                              child: HouseholdSettingsTagsPage(),
                            ),
                          ),
                        ),
                      ),
                      if (true)
                        ListTile(
                          title: Text(
                              AppLocalizations.of(context)!.expenseCategories),
                          leading: const Icon(Icons.attach_money_rounded),
                          trailing: const Icon(Icons.arrow_forward_ios_rounded),
                          contentPadding:
                              const EdgeInsets.only(left: 16, right: 16),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => BlocProvider.value(
                                value: cubit,
                                child: HouseholdSettingsExpenseCategoryPage(),
                              ),
                            ),
                          ),
                        )
                    ]),
                  ),
                ),
                SliverCrossAxisConstrained(
                  maxCrossAxisExtent: 600,
                  child: SliverCrossAxisPadded.symmetric(
                    padding: 16,
                    child: SliverHouseholdDangerZone(),
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
  }
}
