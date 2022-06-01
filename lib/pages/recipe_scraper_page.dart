import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/recipe_scraper_cubit.dart';

class RecipeScraperPage extends StatefulWidget {
  final String url;

  const RecipeScraperPage({
    super.key,
    required this.url,
  });

  @override
  _RecipeScraperPageState createState() => _RecipeScraperPageState();
}

class _RecipeScraperPageState extends State<RecipeScraperPage> {
  late RecipeScraperCubit bloc;

  @override
  void initState() {
    super.initState();
    bloc = RecipeScraperCubit(widget.url);
  }

  @override
  void dispose() {
    bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<RecipeScraperCubit, RecipeScraperState>(
        bloc: bloc,
        builder: (context, state) {
          if (state is! RecipeScraperLoadedState) {
            return Scaffold(
              appBar: AppBar(
                title: Text(widget.url),
              ),
              body: const Center(child: CircularProgressIndicator()),
            );
          }

          return Scaffold(
            appBar: AppBar(
              title: Text(state.recipe.name),
            ),
          );
        },
      );
}
