import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

class OpenContainerNavigator<T> extends StatefulWidget {
  final CloseContainerActionCallback<T> closeContainer;
  final Widget child;

  const OpenContainerNavigator({
    super.key,
    required this.closeContainer,
    required this.child,
  });

  static bool isInside(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<_OpenContainerNavigatorScope>() !=
      null;

  @override
  State<OpenContainerNavigator<T>> createState() =>
      _OpenContainerNavigatorState<T>();
}

class _OpenContainerNavigatorState<T> extends State<OpenContainerNavigator<T>> {
  final HeroController _heroController = HeroController();

  @override
  Widget build(BuildContext context) {
    return Navigator(
      observers: [_heroController],
      onGenerateRoute: (settings) => _OpenContainerPageRoute<T>(
        settings: settings,
        closeContainer: widget.closeContainer,
        builder: (context) => _OpenContainerNavigatorScope(child: widget.child),
      ),
    );
  }
}

class _OpenContainerPageRoute<T> extends MaterialPageRoute<T> {
  final CloseContainerActionCallback<T> closeContainer;

  _OpenContainerPageRoute({
    required this.closeContainer,
    required super.builder,
    super.settings,
  });

  @override
  // ignore: must_call_super
  bool didPop(T? result) {
    closeContainer(returnValue: result);
    return false;
  }
}

class _OpenContainerNavigatorScope extends InheritedWidget {
  const _OpenContainerNavigatorScope({required super.child});

  @override
  bool updateShouldNotify(_OpenContainerNavigatorScope oldWidget) => false;
}
