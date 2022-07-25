import 'package:flutter/material.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/recipe.dart';

class RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final void Function()? onPressed;
  final void Function()? onLongPressed;

  const RecipeCard({
    Key? key,
    required this.recipe,
    this.onPressed,
    this.onLongPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 250,
      width: 200,
      child: Card(
        child: InkWell(
          onTap: onPressed,
          onLongPress: onLongPressed,
          child: Column(
            children: [
              if (recipe.image.isNotEmpty)
                Expanded(
                  flex: 2,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(14),
                    ),
                    child: Image(
                      fit: BoxFit.cover,
                      image: getImageProvider(
                        context,
                        recipe.image,
                      ),
                    ),
                  ),
                ),
              if (recipe.image.isEmpty) const Spacer(flex: 2),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        recipe.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        softWrap: true,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      if (recipe.time > 0)
                        Text(
                          "${recipe.time} min",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
