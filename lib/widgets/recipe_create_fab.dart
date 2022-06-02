import 'package:animations/animations.dart';
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
        OpenContainer(
          transitionType: ContainerTransitionType.fade,
          openBuilder: (BuildContext context, VoidCallback _) {
            return const AddUpdateRecipePage();
          },
          openColor: Theme.of(context).scaffoldBackgroundColor,
          onClosed: (data) {
            if (data == UpdateEnum.updated) {
              recipeListCubit.refresh();
            }
          },
          closedElevation: 4.0,
          closedShape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(56 / 2),
            ),
          ),
          closedColor: Theme.of(context).colorScheme.secondary,
          closedBuilder: (BuildContext context, VoidCallback openContainer) {
            return SizedBox(
              height: 56,
              width: 56,
              child: Center(
                child: Icon(
                  Icons.note_add_rounded,
                  color: Theme.of(context).colorScheme.onSecondary,
                ),
              ),
            );
          },
        ),
        FloatingActionButton(
          onPressed: () async {
            final url = await showDialog<String>(
              context: context,
              builder: (BuildContext context) {
                return TextDialog(
                  title: AppLocalizations.of(context)!.recipeAddUrl,
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
          elevation: 4.0,
          child: const Icon(Icons.link_rounded),
        ),
      ],
    );
  }
}
