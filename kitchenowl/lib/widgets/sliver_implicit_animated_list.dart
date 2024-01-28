import 'package:flutter/material.dart';
import 'package:diffutil_dart/diffutil.dart' as diffutil;

class SliverImplicitAnimatedList<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(BuildContext, int, Animation<double>) itemBuilder;
  final Widget Function(BuildContext, T, Animation<double>) removeItemBuilder;
  final bool Function(T, T)? equalityChecker;
  final int? Function(Key)? findChildIndexCallback;

  const SliverImplicitAnimatedList({
    super.key,
    required this.items,
    required this.itemBuilder,
    required this.removeItemBuilder,
    this.equalityChecker,
    this.findChildIndexCallback,
  });

  @override
  State<SliverImplicitAnimatedList> createState() =>
      _SliverImplicitAnimatedListState<T>();
}

class _SliverImplicitAnimatedListState<T>
    extends State<SliverImplicitAnimatedList<T>> {
  final GlobalKey<SliverAnimatedListState> _listKey =
      GlobalKey<SliverAnimatedListState>();

  @override
  void didUpdateWidget(SliverImplicitAnimatedList<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.items != widget.items) {
      final updates = diffutil
          .calculateListDiff<T>(
            oldWidget.items,
            widget.items,
            equalityChecker: widget.equalityChecker,
            detectMoves: false,
          )
          .getUpdates();

      for (final update in updates) {
        update.when(
          insert: (pos, count) => _onInsert(pos, count),
          remove: (pos, count) => _onRemove(pos, count, oldWidget.items),
          change: (_, __) => throw UnimplementedError(),
          move: (_, __) => throw UnimplementedError(),
        );
      }
    }
  }

  void _onRemove(int index, int count, List<T> oldList) {
    final state = _listKey.currentState!;
    for (int i = index; i < index + count; i++) {
      state.removeItem(
        index,
        (context, animation) => widget.removeItemBuilder(
          context,
          oldList[i],
          animation,
        ),
      );
    }
  }

  void _onInsert(int index, int count) {
    final state = _listKey.currentState!;
    for (int i = index; i < index + count; i++) {
      state.insertItem(i);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SliverAnimatedList(
      key: _listKey,
      itemBuilder: widget.itemBuilder,
      findChildIndexCallback: widget.findChildIndexCallback,
      initialItemCount: widget.items.length,
    );
  }
}
