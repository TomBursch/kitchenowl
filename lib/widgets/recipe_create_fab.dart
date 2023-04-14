import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kitchenowl/cubits/recipe_list_cubit.dart';
import 'package:kitchenowl/enums/update_enum.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/pages/recipe_add_update_page.dart';

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
        KitchenOwlFab(
          openBuilder: (BuildContext ctx, VoidCallback _) {
            return AddUpdateRecipePage(
              household: BlocProvider.of<RecipeListCubit>(context).household,
            );
          },
          onClosed: (data) {
            _fabKey.currentState?.reset();
            if (data == UpdateEnum.updated) {
              BlocProvider.of<RecipeListCubit>(context).refresh();
            }
          },
          icon: Icons.note_add_rounded,
        ),
        FloatingActionButton(
          heroTag: null,
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

            const res = null;

            // final res =
            //     await Navigator.of(context, rootNavigator: true).push<UpdateEnum>(MaterialPageRoute(
            //   builder: (context) => RecipeScraperPage(
            //     household: BlocProvider.of<RecipeListCubit>(context).household,
            //     url: url,
            //   ),
            // ));

            context.go(Uri(
              path:
                  "/household/${BlocProvider.of<RecipeListCubit>(context).household.id}/recipes/scrape",
              queryParameters: {"url": url},
            ).toString());

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
