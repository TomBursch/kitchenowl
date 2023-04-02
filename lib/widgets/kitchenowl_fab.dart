import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

class KitchenOwlFab extends StatelessWidget {
  final Widget Function(BuildContext, void Function({Object? returnValue}))
      openBuilder;
  final Function(Object?)? onClosed;
  final IconData? icon;

  const KitchenOwlFab({
    super.key,
    required this.openBuilder,
    this.onClosed,
    this.icon = Icons.add,
  });

  @override
  Widget build(BuildContext context) {
    return OpenContainer(
      useRootNavigator: true,
      transitionType: ContainerTransitionType.fade,
      openBuilder: openBuilder,
      openColor: Theme.of(context).scaffoldBackgroundColor,
      onClosed: onClosed,
      closedElevation: 4.0,
      closedShape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(14),
        ),
      ),
      closedColor:
          Theme.of(context).floatingActionButtonTheme.backgroundColor ??
              Theme.of(context).colorScheme.secondary,
      closedBuilder: (
        BuildContext context,
        VoidCallback openContainer,
      ) {
        return SizedBox(
          height: 56,
          width: 56,
          child: Center(
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.onSecondary,
            ),
          ),
        );
      },
    );
  }
}
