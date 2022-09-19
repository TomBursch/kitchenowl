import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';

class RecipeSourceChip extends StatefulWidget {
  final String source;
  const RecipeSourceChip({Key? key, required this.source}) : super(key: key);

  @override
  State<RecipeSourceChip> createState() => _RecipeSourceChipState();
}

class _RecipeSourceChipState extends State<RecipeSourceChip> {
  late Future<bool> canLaunchUrl;

  @override
  void initState() {
    super.initState();
    canLaunchUrl = canLaunchUrlString(widget.source);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: canLaunchUrl,
      initialData: false,
      builder: (
        context,
        AsyncSnapshot<bool> snapshot,
      ) =>
          snapshot.data!
              ? ActionChip(
                  avatar: Icon(
                    Icons.link,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                  label: Text(
                    snapshot.data!
                        ? Uri.tryParse(widget.source)?.host ?? widget.source
                        : widget.source,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  elevation: 3,
                  onPressed: () async {
                    if (await canLaunchUrlString(
                      widget.source,
                    )) {
                      await launchUrlString(
                        widget.source,
                      );
                    }
                  },
                )
              : Chip(
                  avatar: Icon(
                    Icons.book_rounded,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                  label: Text(
                    widget.source,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  elevation: 3,
                ),
    );
  }
}
