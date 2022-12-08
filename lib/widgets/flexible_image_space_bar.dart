import 'package:flutter/material.dart';
import 'package:kitchenowl/pages/photo_view_page.dart';
import 'package:kitchenowl/widgets/image_provider.dart';

class FlexibleImageSpaceBar extends StatelessWidget {
  final String title;
  final String imageUrl;

  const FlexibleImageSpaceBar({
    super.key,
    required this.title,
    String? imageUrl,
  }) : imageUrl = imageUrl ?? "";

  @override
  Widget build(BuildContext context) {
    return FlexibleSpaceBar(
      titlePadding: const EdgeInsetsDirectional.only(
        start: 60,
        bottom: 16,
        end: 36,
      ),
      title: LayoutBuilder(builder: (context, constraints) {
        final isCollapsed = constraints.biggest.height <=
            MediaQuery.of(context).padding.top + kToolbarHeight - 16 + 32;

        return Text(
          title,
          maxLines: isCollapsed ? 1 : 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onBackground,
          ),
        );
      }),
      background: imageUrl.isNotEmpty
          ? GestureDetector(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => PhotoViewPage(
                  title: title,
                  imageProvider: getImageProvider(
                    context,
                    imageUrl,
                  ),
                  // heroTag: imageUrl, # TODO cannot use Hero inside OpenContainer
                ),
              )),
              child:
                  // Hero(
                  // tag: imageUrl,
                  // flightShuttleBuilder: (
                  //   BuildContext flightContext,
                  //   Animation<double> animation,
                  //   HeroFlightDirection flightDirection,
                  //   BuildContext fromHeroContext,
                  //   BuildContext toHeroContext,
                  // ) {
                  //   final Hero hero = flightDirection ==
                  //           HeroFlightDirection.push
                  //       ? fromHeroContext.widget as Hero
                  //       : toHeroContext.widget as Hero;

                  //   return hero.child;
                  // },
                  Image(
                image: getImageProvider(
                  context,
                  imageUrl,
                  maxWidth: MediaQuery.of(context).size.width.toInt(),
                ),
                color: Theme.of(context).backgroundColor.withOpacity(.25),
                colorBlendMode: BlendMode.srcATop,
                fit: BoxFit.cover,
              ),
              // ),
            )
          : null,
    );
  }
}
