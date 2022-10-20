import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kitchenowl/cubits/recipe_add_update_cubit.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/recipe.dart';

class RecipeTimeSettings extends StatefulWidget {
  final Recipe recipe;
  final AddUpdateRecipeCubit cubit;
  final Duration animationDuration;

  const RecipeTimeSettings({
    super.key,
    required this.recipe,
    required this.cubit,
    this.animationDuration = const Duration(milliseconds: 250),
  });

  @override
  State<RecipeTimeSettings> createState() => _RecipeTimeSettingsState();
}

class _RecipeTimeSettingsState extends State<RecipeTimeSettings> {
  final TextEditingController timeController = TextEditingController();
  final TextEditingController cookTimeController = TextEditingController();
  final TextEditingController prepTimeController = TextEditingController();
  bool isExpanded = false;

  @override
  void initState() {
    super.initState();
    if (widget.recipe.time > 0) {
      timeController.text = widget.recipe.time.toString();
    }
    isExpanded = widget.recipe.cookTime + widget.recipe.prepTime > 0;
    if (widget.recipe.cookTime > 0) {
      cookTimeController.text = widget.recipe.cookTime.toString();
    }
    if (widget.recipe.prepTime > 0) {
      prepTimeController.text = widget.recipe.prepTime.toString();
    }
  }

  @override
  void dispose() {
    timeController.dispose();
    cookTimeController.dispose();
    prepTimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: timeController,
                onChanged: (s) => widget.cubit.setTime(int.tryParse(s) ?? 0),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.totalTime,
                  suffix: Text(
                    AppLocalizations.of(context)!.minutesAbbrev,
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: () => setState(() {
                isExpanded = !isExpanded;
              }),
              icon: AnimatedRotation(
                duration: widget.animationDuration,
                turns: isExpanded ? 0 : .25,
                child: const Icon(Icons.expand_more_rounded),
              ),
            ),
          ],
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox(),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 2),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: prepTimeController,
                    onChanged: (s) =>
                        widget.cubit.setPrepTime(int.tryParse(s) ?? 0),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.preparationTime,
                      suffix: Text(AppLocalizations.of(context)!.minutesAbbrev),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: cookTimeController,
                    onChanged: (s) =>
                        widget.cubit.setCookTime(int.tryParse(s) ?? 0),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.cookingTime,
                      suffix: Text(AppLocalizations.of(context)!.minutesAbbrev),
                    ),
                  ),
                ),
              ],
            ),
          ),
          crossFadeState:
              isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: widget.animationDuration,
        ),
      ],
    );
  }
}
