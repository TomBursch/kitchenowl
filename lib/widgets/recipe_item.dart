import 'dart:io';

import 'package:animations/animations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kitchenowl/cubits/household_cubit.dart';
import 'package:kitchenowl/enums/update_enum.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/models/recipe.dart';
import 'package:kitchenowl/pages/recipe_page.dart';
import 'package:tuple/tuple.dart';

class RecipeItemWidget extends StatelessWidget {
  final Recipe recipe;
  final void Function()? onUpdated;
  final Widget? description;

  const RecipeItemWidget({
    super.key,
    required this.recipe,
    this.onUpdated,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    return OpenContainer<UpdateEnum>(
      useRootNavigator: true,
      closedColor: ElevationOverlay.applySurfaceTint(
        Theme.of(context).colorScheme.surface,
        Theme.of(context).colorScheme.surfaceTint,
        1,
      ).withAlpha(0),
      closedElevation: 0,
      closedShape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(14),
        ),
      ),
      openColor: Theme.of(context).scaffoldBackgroundColor,
      onClosed: _handleUpdate,
      closedBuilder: (context, toggle) => Card(
        child: ListTile(
          title: Text(recipe.name),
          trailing: const Icon(Icons.arrow_right_rounded),
          selected: recipe.isPlanned,
          subtitle: description,
          onTap: (kIsWeb || Platform.isIOS)
              ? () async {
                  final household =
                      BlocProvider.of<HouseholdCubit>(context).state.household;
                  final res = await context.push<UpdateEnum>(
                    "/household/${household.id}/recipes/details/${recipe.id}",
                    extra: Tuple2<Household, Recipe>(household, recipe),
                  );
                  _handleUpdate(res);
                }
              : toggle,
        ),
      ),
      openBuilder: (
        BuildContext ctx,
        toggle,
      ) =>
          BlocProvider.value(
        value: BlocProvider.of<HouseholdCubit>(context),
        child: RecipePage(
          household: BlocProvider.of<HouseholdCubit>(context).state.household,
          recipe: recipe,
        ),
      ),
    );
  }

  void _handleUpdate(UpdateEnum? res) {
    if (onUpdated != null &&
        (res == UpdateEnum.updated || res == UpdateEnum.deleted)) {
      onUpdated!();
    }
  }
}
