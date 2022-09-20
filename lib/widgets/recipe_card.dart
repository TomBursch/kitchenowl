import 'package:flutter/material.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/recipe.dart';
import 'package:responsive_builder/responsive_builder.dart';

class RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final void Function()? onPressed;
  final Future<void> Function()? onLongPressed;
  final Future<void> Function()? onAddToDate;

  const RecipeCard({
    Key? key,
    required this.recipe,
    this.onPressed,
    this.onLongPressed,
    this.onAddToDate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: getValueForScreenType(
        context: context,
        mobile: 250,
        tablet: 275,
        desktop: 275,
      ),
      child: Card(
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
              if (recipe.image.isEmpty)
                Expanded(
                  flex: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(14),
                      ),
                    ),
                    child: Icon(
                      Icons.fastfood_rounded,
                      size: 48,
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
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
                                  .map((e) => Padding(
                                        padding:
                                            const EdgeInsets.only(right: 4),
                                        child: Chip(
                                          materialTapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                          label: Text(e.name),
                                        ),
                                      ))
                                  .toList(),
                            ),
                          ),
                        ),
                      const SizedBox(height: 2),
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
                          style: Theme.of(context).textTheme.caption,
                        ),
                      const Spacer(),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (onAddToDate != null)
                            LoadingElevatedButton(
                              style: ElevatedButton.styleFrom(
                                // Foreground color
                                // ignore: deprecated_member_use
                                onPrimary:
                                    Theme.of(context).colorScheme.onPrimary,
                                // Background color
                                // ignore: deprecated_member_use
                                primary: Theme.of(context).colorScheme.primary,
                              ).copyWith(
                                elevation: ButtonStyleButton.allOrNull(0.0),
                              ),
                              onPressed: onAddToDate,
                              child: const Icon(Icons.calendar_month_rounded),
                            ),
                          const SizedBox(width: 8),
                          LoadingElevatedButton(
                            style: ElevatedButton.styleFrom(
                              // Foreground color
                              // ignore: deprecated_member_use
                              onPrimary:
                                  Theme.of(context).colorScheme.onPrimary,
                              // Background color
                              // ignore: deprecated_member_use
                              primary: Theme.of(context).colorScheme.primary,
                            ).copyWith(
                              elevation: ButtonStyleButton.allOrNull(0.0),
                            ),
                            onPressed: onLongPressed,
                            child: Text(
                              AppLocalizations.of(context)!
                                  .addRecipeToPlannerShort,
                            ),
                          ),
                        ],
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
