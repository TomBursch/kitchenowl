import 'dart:io';

import 'package:flutter/material.dart';
import 'package:kitchenowl/kitchenowl.dart';

class ImageSelector extends StatelessWidget {
  final File? image;
  final String originalImage;
  final void Function(File) setImage;

  const ImageSelector({
    super.key,
    this.image,
    required this.originalImage,
    required this.setImage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      constraints: const BoxConstraints.expand(height: 80),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).colorScheme.secondary,
          width: 2,
        ),
        image: (image != null && image!.path.isNotEmpty ||
                image == null && originalImage.isNotEmpty)
            ? DecorationImage(
                fit: BoxFit.cover,
                opacity: .5,
                image: image != null
                    ? FileImage(image!)
                    : getImageProvider(
                        context,
                        originalImage,
                      ),
              )
            : null,
      ),
      child: IconButton(
        icon: (image != null && image!.path.isNotEmpty ||
                image == null && originalImage.isNotEmpty)
            ? const Icon(Icons.edit)
            : const Icon(Icons.add_photo_alternate_rounded),
        color: Theme.of(context).colorScheme.secondary,
        onPressed: () async {
          File? file = await selectFile(
            context: context,
            title: AppLocalizations.of(context)!.recipeImageSelect,
            deleteOption: (image != null && image!.path.isNotEmpty ||
                image == null && originalImage.isNotEmpty),
          );
          if (file != null) {
            setImage(file);
          }
        },
      ),
    );
  }
}
