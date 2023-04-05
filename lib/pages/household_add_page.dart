import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/household_add_update/household_add_cubit.dart';
import 'package:kitchenowl/enums/update_enum.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/widgets/settings_household/sliver_household_feature_settings.dart';

class HouseholdAddPage extends StatefulWidget {
  final String? locale;

  const HouseholdAddPage({super.key, this.locale});

  @override
  State<HouseholdAddPage> createState() => _HouseholdAddPageState();
}

class _HouseholdAddPageState extends State<HouseholdAddPage> {
  late final HouseholdAddCubit cubit;

  @override
  void initState() {
    super.initState();
    cubit = HouseholdAddCubit(widget.locale);
  }

  @override
  void dispose() {
    cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: cubit,
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.householdNew),
        ),
        body: CustomScrollView(
          primary: true,
          slivers: [
            SliverList(
              delegate: SliverChildListDelegate([
                BlocBuilder<HouseholdAddCubit, HouseholdAddState>(
                  bloc: cubit,
                  buildWhen: (previous, current) =>
                      previous.image != current.image,
                  builder: (context, state) => ImageSelector(
                    image: state.image,
                    setImage: cubit.setImage,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: TextField(
                    onChanged: (s) => cubit.setName(s),
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.name,
                    ),
                  ),
                ),
              ]),
            ),
            const SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverHouseholdFeatureSettings<HouseholdAddCubit,
                  HouseholdAddState>(
                askConfirmation: false,
                languageCanBeChanged: true,
                showProfile: false,
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverToBoxAdapter(
                child: BlocBuilder<HouseholdAddCubit, HouseholdAddState>(
                  bloc: cubit,
                  builder: (context, state) => LoadingElevatedButton(
                    onPressed: state.isValid()
                        ? () async {
                            await cubit.create();
                            if (!mounted) return;
                            Navigator.of(context).pop(UpdateEnum.updated);
                          }
                        : null,
                    child: Text(
                      AppLocalizations.of(context)!.add,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
