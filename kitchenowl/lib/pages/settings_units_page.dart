import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/settings_cubit.dart';
import 'package:kitchenowl/kitchenowl.dart';

class SettingsUnitsPage extends StatefulWidget {
  const SettingsUnitsPage({super.key});

  @override
  State<SettingsUnitsPage> createState() => _SettingsUnitsPageState();
}

class _SettingsUnitsPageState extends State<SettingsUnitsPage> {
  final controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _addUnit() {
    BlocProvider.of<SettingsCubit>(context)
        .addShoppingListCustomUnit(controller.text);
    controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.units),
      ),
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) => ListView(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text(
                AppLocalizations.of(context)!.unitsHint,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            for (final unit in state.allShoppingListUnits)
              ListTile(
                title: Text(unit),
                onTap: () => BlocProvider.of<SettingsCubit>(context)
                    .setShoppingListUnitEnabled(
                  unit,
                  !state.shoppingListUnits.contains(unit),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (state.shoppingListCustomUnits.contains(unit))
                      IconButton(
                        icon: const Icon(Icons.delete_rounded),
                        tooltip: AppLocalizations.of(context)!.delete,
                        onPressed: () => BlocProvider.of<SettingsCubit>(context)
                            .removeShoppingListCustomUnit(unit),
                      ),
                    KitchenOwlSwitch(
                      value: state.shoppingListUnits.contains(unit),
                      onChanged: (value) =>
                          BlocProvider.of<SettingsCubit>(context)
                              .setShoppingListUnitEnabled(unit, value),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                8,
                16,
                16 + MediaQuery.paddingOf(context).bottom,
              ),
              child: TextField(
                controller: controller,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _addUnit(),
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.unitAdd,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.add_rounded),
                    tooltip: AppLocalizations.of(context)!.add,
                    onPressed: _addUnit,
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
