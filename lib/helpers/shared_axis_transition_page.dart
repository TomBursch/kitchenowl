import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SharedAxisTransitionPage<T> extends CustomTransitionPage<T> {
  SharedAxisTransitionPage({
    required super.child,
    super.name,
    super.arguments,
    super.restorationId,
    super.key,
    SharedAxisTransitionType transitionType =
        SharedAxisTransitionType.horizontal,
  }) : super(
          transitionsBuilder: _transitionsBuilder(transitionType),
        );

  static Widget Function(
    BuildContext,
    Animation<double>,
    Animation<double>,
    Widget,
  ) _transitionsBuilder(SharedAxisTransitionType transitionType) {
    return (
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child,
    ) {
      return SharedAxisTransition(
        transitionType: transitionType,
        animation: animation,
        secondaryAnimation: secondaryAnimation,
        child: child,
      );
    };
  }
}
