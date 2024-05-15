import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

class PhotoViewPage extends StatelessWidget {
  final ImageProvider imageProvider;
  final Object? heroTag;
  final String? title;

  const PhotoViewPage({
    super.key,
    required this.imageProvider,
    this.title,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: title != null ? Text(title!) : null,
      ),
      body: Center(
        child: PhotoView(
          imageProvider: imageProvider,
          maxScale: PhotoViewComputedScale.contained * 4,
          minScale: PhotoViewComputedScale.contained,
          heroAttributes:
              heroTag != null ? PhotoViewHeroAttributes(tag: heroTag!) : null,
          backgroundDecoration:
              BoxDecoration(color: Theme.of(context).colorScheme.surface),
        ),
      ),
    );
  }
}
