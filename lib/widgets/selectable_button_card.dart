import 'package:flutter/material.dart';

class SelectableButtonCard extends StatelessWidget {
  final String title;
  final String description;
  final bool selected;
  final void Function() onPressed;
  final void Function() onLongPressed;

  const SelectableButtonCard({
    Key key,
    this.title,
    this.description,
    this.onPressed,
    this.onLongPressed,
    this.selected = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all<Color>(
          selected
              ? Theme.of(context).colorScheme.secondary
              : Theme.of(context).brightness == Brightness.dark
                  ? Theme.of(context).cardColor
                  : Theme.of(context).disabledColor,
        ),
        elevation: MaterialStateProperty.all<double>(0),
      ),
      onPressed: onPressed,
      onLongPress: onLongPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            softWrap: true,
            textAlign: TextAlign.center,
          ),
          if (description != null && description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                description,
                style: Theme.of(context).textTheme.caption.copyWith(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? null
                        : Colors.white70),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                softWrap: true,
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}
