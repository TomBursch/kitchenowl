import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/recipe_list_cubit.dart';
import 'package:kitchenowl/enums/update_enum.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/pages/recipe_add_update_page.dart';
import 'package:kitchenowl/pages/recipe_scraper_page.dart';

class RecipeCreateFab extends StatelessWidget {
  final _fabKey = GlobalKey<ExpandableFabState>();

  RecipeCreateFab({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ExpandableFab(
      key: _fabKey,
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
            _fabKey.currentState?.reset();
            if (data == UpdateEnum.updated) {
              BlocProvider.of<RecipeListCubit>(context).refresh();
            }
          },
          closedElevation: 4,
          closedShape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(14),
            ),
          ),
          closedColor:
              Theme.of(context).floatingActionButtonTheme.backgroundColor ??
                  Theme.of(context).colorScheme.secondary,
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
                  isInputValid: (s) => s.isNotEmpty,
                );
              },
            );
            if (url == null) return;

            final res =
                await Navigator.of(context).push<UpdateEnum>(MaterialPageRoute(
              builder: (context) => RecipeScraperPage(
                url: url,
              ),
            ));

            _fabKey.currentState?.reset();
            if (res == UpdateEnum.updated) {
              BlocProvider.of<RecipeListCubit>(context).refresh();
            }
          },
          child: const Icon(Icons.link_rounded),
        ),
      ],
    );
  }
}
