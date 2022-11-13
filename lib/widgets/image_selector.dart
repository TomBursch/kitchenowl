import 'package:flutter/material.dart';
import 'package:kitchenowl/helpers/named_bytearray.dart';
import 'package:kitchenowl/kitchenowl.dart';

class ImageSelector extends StatelessWidget {
  final NamedByteArray? image;
  final String originalImage;
  final void Function(NamedByteArray) setImage;

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
        image: hasDominantImage()
            ? DecorationImage(
                fit: BoxFit.cover,
                opacity: .5,
                image: getDominantImage(context)!,
              )
            : null,
      ),
      child: IconButton(
        icon: hasDominantImage()
            ? const Icon(Icons.edit)
            : const Icon(Icons.add_photo_alternate_rounded),
        color: Theme.of(context).colorScheme.secondary,
        onPressed: () async {
          NamedByteArray? file = await selectFile(
            context: context,
            title: AppLocalizations.of(context)!.recipeImageSelect,
            deleteOption: hasDominantImage(),
          );
          if (file != null) {
            setImage(file);
          }
        },
      ),
    );
  }

  bool hasDominantImage()  {
    if (image != null && image!.isNotEmpty) {
      return true;
    } else if (originalImage.isNotEmpty) {
      return true;
    } else {
      return false;
    }
  }
  ImageProvider<Object>? getDominantImage(BuildContext context) {
    if (image != null && image!.isNotEmpty) {
      return MemoryImage(image!.bytes);
    } else if (originalImage.isNotEmpty) {
      return getImageProvider(context, originalImage);
    } else {
      return null;
    }
  }
}
