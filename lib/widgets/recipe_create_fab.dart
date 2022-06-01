import 'package:flutter/material.dart';
import 'package:kitchenowl/cubits/recipe_list_cubit.dart';
import 'package:kitchenowl/enums/update_enum.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/pages/recipe_add_update_page.dart';
import 'package:kitchenowl/pages/recipe_scraper_page.dart';

class RecipeCreateFab extends StatelessWidget {
  final RecipeListCubit recipeListCubit;

  const RecipeCreateFab({
    super.key,
    required this.recipeListCubit,
  });

  @override
  Widget build(BuildContext context) {
    return ExpandableFab(
      distance: 70,
      openIcon: const Icon(Icons.add),
      children: [
        ActionButton(
          onPressed: () async {
            final res =
                await Navigator.of(context).push<UpdateEnum>(MaterialPageRoute(
              builder: (context) => const AddUpdateRecipePage(),
            ));
            if (res == UpdateEnum.updated) {
              recipeListCubit.refresh();
            }
          },
          icon: const Icon(Icons.note_add_rounded),
        ),
        ActionButton(
          onPressed: () async {
            final url = await showDialog<String>(
              context: context,
              builder: (BuildContext context) {
                return TextDialog(
                  title: AppLocalizations.of(context)!.addTag,
                  doneText: AppLocalizations.of(context)!.add,
                  hintText: 'https://recipepage.com/spaghetti',
                  textInputType: TextInputType.url,
                );
              },
            );
            if (url == null || url.isEmpty) return;

            final res =
                await Navigator.of(context).push<UpdateEnum>(MaterialPageRoute(
              builder: (context) => RecipeScraperPage(
                url: url,
              ),
            ));
            if (res == UpdateEnum.updated) {
              recipeListCubit.refresh();
            }
          },
          icon: const Icon(Icons.link_rounded),
        ),
      ],
    );
  }
}
