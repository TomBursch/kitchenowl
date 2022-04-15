import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

class PhotoViewPage extends StatelessWidget {
  final ImageProvider imageProvider;
  final Object? heroTag;

  const PhotoViewPage({
    Key? key,
    required this.imageProvider,
    this.heroTag,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: PhotoView(
          imageProvider: imageProvider,
          heroAttributes:
              heroTag != null ? PhotoViewHeroAttributes(tag: heroTag!) : null,
        ),
      ),
    );
  }
}
