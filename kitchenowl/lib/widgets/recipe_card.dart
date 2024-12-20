import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:go_router/go_router.dart';
import 'package:kitchenowl/cubits/household_cubit.dart';
import 'package:kitchenowl/enums/update_enum.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/models/recipe.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:tuple/tuple.dart';

class RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final void Function()? onUpdated;
  final void Function()? onPressed;
  final Future<void> Function()? onLongPressed;
  final Future<void> Function()? onAddToDate;

  const RecipeCard({
    super.key,
    required this.recipe,
    this.onUpdated,
    this.onPressed,
    this.onLongPressed,
    this.onAddToDate,
  });

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
          onTap: onPressed ??
              () async {
                final household =
                    BlocProvider.of<HouseholdCubit>(context).state.household;
                final res = await context.push<UpdateEnum>(
                  "/household/${household.id}/recipes/details/${recipe.id}",
                  extra: Tuple2<Household, Recipe>(household, recipe),
                );
                _handleUpdate(res);
              },
          onLongPress: onLongPressed,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (recipe.image?.isNotEmpty ?? false)
                Expanded(
                  flex: 3,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(14),
                    ),
                    child: FadeInImage(
                      fit: BoxFit.cover,
                      placeholder: recipe.imageHash != null
                          ? BlurHashImage(recipe.imageHash!)
                          : MemoryImage(kTransparentImage) as ImageProvider,
                      image: getImageProvider(
                        context,
                        recipe.image!,
                        maxWidth: 512,
                      ),
                    ),
                  ),
                ),
              if (recipe.image?.isEmpty ?? true)
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
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      const Spacer(),
                      if (onLongPressed != null) const Divider(),
                      if (onLongPressed != null)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (onAddToDate != null)
                              LoadingElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  foregroundColor:
                                      Theme.of(context).colorScheme.onPrimary,
                                  backgroundColor:
                                      Theme.of(context).colorScheme.primary,
                                  padding: EdgeInsets.zero,
                                ).copyWith(
                                  elevation: ButtonStyleButton.allOrNull(0.0),
                                  iconColor: WidgetStatePropertyAll(
                                      Theme.of(context).colorScheme.onPrimary),
                                ),
                                onPressed: onAddToDate,
                                child: const Icon(Icons.calendar_month_rounded),
                              ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: LoadingElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  foregroundColor:
                                      Theme.of(context).colorScheme.onPrimary,
                                  backgroundColor:
                                      Theme.of(context).colorScheme.primary,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                ).copyWith(
                                  elevation: ButtonStyleButton.allOrNull(0.0),
                                ),
                                onPressed: onLongPressed,
                                child: LayoutBuilder(builder:
                                    (BuildContext context,
                                        BoxConstraints size) {
                                  final TextPainter painter = TextPainter(
                                    maxLines: 1,
                                    textAlign: TextAlign.left,
                                    textDirection: TextDirection.ltr,
                                    text: TextSpan(
                                      text: AppLocalizations.of(context)!
                                          .addRecipeToPlannerShort,
                                    ),
                                  );

                                  painter.layout(maxWidth: size.maxWidth);

                                  return Text(
                                    painter.didExceedMaxLines
                                        ? AppLocalizations.of(context)!.add
                                        : AppLocalizations.of(context)!
                                            .addRecipeToPlannerShort,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  );
                                }),
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

  void _handleUpdate(UpdateEnum? res) {
    if (onUpdated != null &&
        (res == UpdateEnum.updated || res == UpdateEnum.deleted)) {
      onUpdated!();
    }
  }
}
