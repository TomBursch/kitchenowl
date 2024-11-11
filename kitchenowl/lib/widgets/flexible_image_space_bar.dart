import 'package:flutter/material.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:kitchenowl/pages/photo_view_page.dart';
import 'package:kitchenowl/widgets/image_provider.dart';
import 'package:transparent_image/transparent_image.dart';

class FlexibleImageSpaceBar extends StatelessWidget {
  final String title;
  final int actionCount;
  final String imageUrl;
  final String? imageHash;
  final bool isCollapsed;

  const FlexibleImageSpaceBar({
    super.key,
    required this.title,
    this.isCollapsed = false,
    String? imageUrl,
    this.imageHash,
    this.actionCount = 1,
  }) : imageUrl = imageUrl ?? "";

  @override
  Widget build(BuildContext context) {
    return FlexibleSpaceBar(
      titlePadding: EdgeInsetsDirectional.only(
        start: 60,
        bottom: 16,
        end: 16 + actionCount * 40,
      ),
      title: Text(
        title,
        maxLines: isCollapsed ? 1 : 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      background: imageUrl.isNotEmpty
          ? GestureDetector(
              onTap: () => Navigator.of(context, rootNavigator: true)
                  .push(MaterialPageRoute(
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
                  ShaderMask(
                shaderCallback: (rect) {
                  return const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [.6, .85],
                    colors: [Colors.black, Colors.transparent],
                  ).createShader(Rect.fromLTRB(0, 0, rect.width, rect.height));
                },
                blendMode: BlendMode.dstIn,
                child: FadeInImage(
                  placeholder: imageHash != null
                      ? BlurHashImage(imageHash!)
                      : MemoryImage(kTransparentImage) as ImageProvider,
                  image: getImageProvider(
                    context,
                    imageUrl,
                    maxWidth: MediaQuery.sizeOf(context).width.toInt(),
                  ),
                  fit: BoxFit.cover,
                ),
              ),
            )
          : null,
    );
  }
}
