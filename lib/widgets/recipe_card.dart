import 'package:flutter/material.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/recipe.dart';
import 'package:responsive_builder/responsive_builder.dart';

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
    return Card(
      child: InkWell(
        onTap: onPressed,
        onLongPress: onLongPressed,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (recipe.image.isNotEmpty)
              Expanded(
                flex: 3,
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
            if (recipe.image.isEmpty) const Spacer(flex: 3),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      recipe.name,
                      maxLines: getValueForScreenType(
                        context: context,
                        mobile: 1,
                        tablet: 2,
                        desktop: 2,
                      ),
                      overflow: TextOverflow.ellipsis,
                      softWrap: true,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    if (recipe.time > 0)
                      Text(
                        "${recipe.time} min",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const Spacer(),
                    if (recipe.tags.isNotEmpty)
                      ShaderMask(
                        shaderCallback: (rect) {
                          return const LinearGradient(
                            begin: Alignment(.7, 0),
                            end: Alignment.centerRight,
                            colors: [Colors.black, Colors.transparent],
                          ).createShader(
                            Rect.fromLTRB(0, 0, rect.width, rect.height),
                          );
                        },
                        blendMode: BlendMode.dstIn,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const NeverScrollableScrollPhysics(),
                          child: Row(
                            children: recipe.tags
                                .map((e) => Chip(label: Text(e.name)))
                                .toList(),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
