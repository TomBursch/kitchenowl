import 'package:animations/animations.dart';
import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

class FadeThroughTransitionPage<T> extends CustomTransitionPage<T> {
  const FadeThroughTransitionPage({
    required super.child,
    super.name,
    super.arguments,
    super.restorationId,
    super.key,
  }) : super(
          transitionsBuilder: _transitionsBuilder,
        );

  static Widget _transitionsBuilder(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeThroughTransition(
      animation: animation,
      secondaryAnimation: secondaryAnimation,
      child: child,
      fillColor: Colors.transparent,
    );
  }
}
