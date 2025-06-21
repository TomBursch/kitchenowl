import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// IndexHintBuilder.
typedef IndexHintBuilder = Widget Function(BuildContext context, String tag);

/// IndexBarDragListener.
abstract class IndexBarDragListener {
  /// Creates an [IndexBarDragListener] that can be used by a
  /// [IndexBar] to return the drag listener.
  factory IndexBarDragListener.create() => IndexBarDragNotifier();

  /// drag details.
  ValueListenable<IndexBarDragDetails> get dragDetails;
}

/// Internal implementation of [ItemPositionsListener].
class IndexBarDragNotifier implements IndexBarDragListener {
  @override
  final ValueNotifier<IndexBarDragDetails> dragDetails =
      ValueNotifier(IndexBarDragDetails());
}

/// IndexModel.
class IndexBarDragDetails {
  static const int actionDown = 0;
  static const int actionUp = 1;
  static const int actionUpdate = 2;
  static const int actionEnd = 3;
  static const int actionCancel = 4;

  int? action;
  int? index; //current touch index.
  String? tag; //current touch tag.

  double? localPositionY;
  double? globalPositionY;

  IndexBarDragDetails({
    this.action,
    this.index,
    this.tag,
    this.localPositionY,
    this.globalPositionY,
  });
}

class IndexScrollController extends ScrollController {
  double Function() getRowHeight;
  double Function() getHeaderHeight;
  int Function() getItemRowCount;

  IndexScrollController({
    super.initialScrollOffset,
    super.keepScrollOffset,
    required this.getRowHeight,
    required this.getHeaderHeight,
    required this.getItemRowCount,
  });

  void jumpToIndex(int index) {
    int row = (index / getItemRowCount()).floor();
    if (row == 0) return this.jumpTo(0);
    this.jumpTo(row * getRowHeight() + getHeaderHeight());
  }
}

/// IndexBar.
class IndexBar extends StatefulWidget {
  const IndexBar({
    super.key,
    required this.controller,
    required this.names,
    this.width = 30,
    this.height,
    this.itemHeight = 16,
    this.margin,
    this.indexHintBuilder,
    this.needRebuild = true,
    this.ignoreDragCancel = false,
    this.hapticFeedback = true,
    this.color,
    this.downColor,
    this.decoration,
    this.downDecoration,
    this.textStyle = const TextStyle(fontSize: 12, color: Color(0xFF666666)),
    this.downTextStyle,
    this.selectTextStyle = const TextStyle(fontWeight: FontWeight.bold),
    this.downItemDecoration,
    this.selectItemDecoration,
    this.indexHintWidth = 50,
    this.indexHintHeight = 50,
    this.indexHintDecoration = const BoxDecoration(
      color: Colors.black87,
      shape: BoxShape.rectangle,
      borderRadius: BorderRadius.all(Radius.circular(6)),
    ),
    this.indexHintTextStyle =
        const TextStyle(fontSize: 24.0, color: Colors.white),
    this.indexHintChildAlignment = Alignment.center,
    this.indexHintAlignment = Alignment.centerLeft,
    this.indexHintPosition,
    this.indexHintOffset = Offset.zero,
  });

  /// Index data.
  final List<String> names;

  /// Index ScrollController
  final IndexScrollController controller;

  /// IndexBar width(def:30).
  final double width;

  /// IndexBar height.
  final double? height;

  /// IndexBar item height(def:16).
  final double itemHeight;

  /// Empty space to surround the [decoration] and [child].
  final EdgeInsetsGeometry? margin;

  /// IndexHint Builder
  final IndexHintBuilder? indexHintBuilder;

  /// need to rebuild.
  final bool needRebuild;

  /// Ignore DragCancel.
  final bool ignoreDragCancel;

  /// Haptic feedback.
  final bool hapticFeedback;

  /// IndexBar background color.
  final Color? color;

  /// IndexBar down background color.
  final Color? downColor;

  /// IndexBar decoration.
  final Decoration? decoration;

  /// IndexBar down decoration.
  final Decoration? downDecoration;

  /// IndexBar textStyle.
  final TextStyle textStyle;

  /// IndexBar down textStyle.
  final TextStyle? downTextStyle;

  /// IndexBar select textStyle.
  final TextStyle? selectTextStyle;

  /// IndexBar down item decoration.
  final Decoration? downItemDecoration;

  /// IndexBar select item decoration.
  final Decoration? selectItemDecoration;

  /// Index hint width.
  final double indexHintWidth;

  /// Index hint height.
  final double indexHintHeight;

  /// Index hint decoration.
  final Decoration indexHintDecoration;

  /// Index hint alignment.
  final Alignment indexHintAlignment;

  /// Index hint child alignment.
  final Alignment indexHintChildAlignment;

  /// Index hint textStyle.
  final TextStyle indexHintTextStyle;

  /// Index hint position.
  final Offset? indexHintPosition;

  /// Index hint offset.
  final Offset indexHintOffset;

  @override
  createState() => _IndexBarState();
}

class _IndexBarState extends State<IndexBar> {
  IndexBarDragListener dragListener = IndexBarDragListener.create();

  String selectTag = '';
  late List<String> tags;

  String toTag(String name) {
    return name[0].toUpperCase();
  }

  @override
  void initState() {
    super.initState();
    tags = [];
    String? tempTag;
    for (int i = 0, length = widget.names.length; i < length; i++) {
      String tag = toTag(widget.names[i]);
      if (tempTag != tag) {
        tags.add(tag);
        tempTag = tag;
      }
    }
    dragListener.dragDetails.addListener(_valueChanged);
    if (widget.selectItemDecoration != null || widget.selectTextStyle != null) {
      widget.controller.addListener(_positionsChanged);
    }
  }

  @override
  void dispose() {
    dragListener.dragDetails.removeListener(_valueChanged);
    if (widget.selectItemDecoration != null || widget.selectTextStyle != null) {
      widget.controller.removeListener(_positionsChanged);
    }
    _removeOverlay();
    super.dispose();
  }

  int _getIndex(String tag) {
    for (int i = 0; i < widget.names.length; i++) {
      if (tag == toTag(widget.names[i])) {
        return i;
      }
    }
    return -1;
  }

  void _scrollTopIndex(String tag) {
    int index = _getIndex(tag);
    if (index != -1) {
      widget.controller.jumpToIndex(index);
    }
  }

  void _valueChanged() {
    IndexBarDragDetails details = dragListener.dragDetails.value;
    String tag = details.tag!;
    if (details.action == IndexBarDragDetails.actionDown ||
        details.action == IndexBarDragDetails.actionUpdate) {
      selectTag = tag;
      _scrollTopIndex(tag);
    }

    selectIndex = details.index!;
    indexTag = details.tag!;
    action = details.action!;
    floatTop = details.globalPositionY! +
        widget.itemHeight / 2 -
        widget.indexHintHeight / 2;

    if (_isActionDown()) {
      _addOverlay(context);
    } else {
      _removeOverlay();
    }

    if (widget.needRebuild) {
      if (widget.ignoreDragCancel &&
          action == IndexBarDragDetails.actionCancel) {
      } else {
        setState(() {});
      }
    }
  }

  void _positionsChanged() {
    int index =
        ((widget.controller.offset - widget.controller.getHeaderHeight()) /
                widget.controller.getRowHeight() *
                widget.controller.getItemRowCount())
            .round();
    if (index > 0 && index < widget.names.length) {
      String tag = toTag(widget.names[index]);
      if (selectTag != tag) {
        selectTag = tag;
        _updateTagIndex(tag);
      }
    }
  }

  /// overlay entry.
  static OverlayEntry? overlayEntry;

  double floatTop = 0;
  String indexTag = '';
  int selectIndex = 0;
  int action = IndexBarDragDetails.actionEnd;

  bool _isActionDown() {
    return action == IndexBarDragDetails.actionDown ||
        action == IndexBarDragDetails.actionUpdate;
  }

  Widget _buildIndexHint(BuildContext context, String tag) {
    if (widget.indexHintBuilder != null) {
      return widget.indexHintBuilder!(context, tag);
    }
    TextStyle textStyle = widget.indexHintTextStyle;
    return Container(
      width: widget.indexHintWidth,
      height: widget.indexHintHeight,
      alignment: widget.indexHintChildAlignment,
      decoration: widget.indexHintDecoration,
      child: Text(tag, style: textStyle),
    );
  }

  /// add overlay.
  void _addOverlay(BuildContext context) {
    OverlayState overlayState = Overlay.of(context);
    if (overlayEntry == null) {
      overlayEntry = OverlayEntry(builder: (BuildContext ctx) {
        double left;
        double top;
        if (widget.indexHintPosition != null) {
          left = widget.indexHintPosition!.dx;
          top = widget.indexHintPosition!.dy;
        } else {
          if (widget.indexHintAlignment == Alignment.centerRight) {
            left = MediaQuery.of(context).size.width -
                widget.width -
                widget.indexHintWidth +
                widget.indexHintOffset.dx;
            top = floatTop + widget.indexHintOffset.dy;
          } else if (widget.indexHintAlignment == Alignment.centerLeft) {
            left = widget.width + widget.indexHintOffset.dx;
            top = floatTop + widget.indexHintOffset.dy;
          } else {
            left = MediaQuery.of(context).size.width / 2 -
                widget.indexHintWidth / 2 +
                widget.indexHintOffset.dx;
            top = MediaQuery.of(context).size.height / 2 -
                widget.indexHintHeight / 2 +
                widget.indexHintOffset.dy;
          }
        }
        return Positioned(
            left: left,
            top: top,
            child: Material(
              color: Colors.transparent,
              child: _buildIndexHint(ctx, indexTag),
            ));
      });
      overlayState.insert(overlayEntry!);
    } else {
      //重新绘制UI，类似setState
      overlayEntry?.markNeedsBuild();
    }
  }

  /// remove overlay.
  void _removeOverlay() {
    overlayEntry?.remove();
    overlayEntry = null;
  }

  Widget _buildItem(BuildContext context, int index) {
    String tag = tags[index];
    Decoration? decoration;
    TextStyle? textStyle;
    if (widget.downItemDecoration != null) {
      decoration = (_isActionDown() && selectIndex == index)
          ? widget.downItemDecoration
          : null;
      textStyle = (_isActionDown() && selectIndex == index)
          ? widget.downTextStyle
          : widget.textStyle;
    } else if (widget.selectItemDecoration != null ||
        widget.selectTextStyle != null) {
      decoration = (selectIndex == index) ? widget.selectItemDecoration : null;
      textStyle =
          (selectIndex == index) ? widget.selectTextStyle : widget.textStyle;
    } else {
      textStyle = _isActionDown()
          ? (widget.downTextStyle ?? widget.textStyle)
          : widget.textStyle;
    }

    return Container(
      alignment: Alignment.center,
      decoration: decoration,
      child: Text(tag, style: textStyle),
    );
  }

  void _updateTagIndex(String tag) {
    if (_isActionDown()) return;
    selectIndex = tags.indexOf(tag);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _isActionDown() ? widget.downColor : widget.color,
      decoration: _isActionDown() ? widget.downDecoration : widget.decoration,
      width: widget.width,
      height: widget.height,
      margin: widget.margin,
      alignment: Alignment.center,
      child: BaseIndexBar(
        tags: tags,
        width: widget.width,
        itemHeight: widget.itemHeight,
        hapticFeedback: widget.hapticFeedback,
        itemBuilder: (BuildContext context, int index) {
          return _buildItem(context, index);
        },
        indexBarDragNotifier: dragListener as IndexBarDragNotifier?,
      ),
    );
  }
}

class BaseIndexBar extends StatefulWidget {
  const BaseIndexBar({
    super.key,
    required this.tags,
    required this.width,
    required this.itemHeight,
    this.hapticFeedback = false,
    this.textStyle = const TextStyle(fontSize: 12.0, color: Color(0xFF666666)),
    this.itemBuilder,
    this.indexBarDragNotifier,
  });

  /// index data.
  final List<String> tags;

  /// IndexBar width(def:30).
  final double width;

  /// IndexBar item height(def:16).
  final double itemHeight;

  /// Haptic feedback.
  final bool hapticFeedback;

  /// IndexBar text style.
  final TextStyle textStyle;

  final IndexedWidgetBuilder? itemBuilder;

  final IndexBarDragNotifier? indexBarDragNotifier;

  @override
  createState() => _BaseIndexBarState();
}

class _BaseIndexBarState extends State<BaseIndexBar> {
  int lastIndex = -1;
  int _widgetTop = 0;

  /// get index.
  int _getIndex(double offset) {
    int index = offset ~/ widget.itemHeight;
    return math.min(index, widget.tags.length - 1);
  }

  /// trigger drag event.
  _triggerDragEvent(int action) {
    if (widget.hapticFeedback &&
        (action == IndexBarDragDetails.actionDown ||
            action == IndexBarDragDetails.actionUpdate)) {
      HapticFeedback.lightImpact();
    }
    widget.indexBarDragNotifier?.dragDetails.value = IndexBarDragDetails(
      action: action,
      index: lastIndex,
      tag: widget.tags[lastIndex],
      localPositionY: lastIndex * widget.itemHeight,
      globalPositionY: lastIndex * widget.itemHeight + _widgetTop,
    );
  }

  RenderBox? _getRenderBox(BuildContext context) {
    RenderObject? renderObject = context.findRenderObject();
    RenderBox? box;
    if (renderObject != null) {
      box = renderObject as RenderBox;
    }
    return box;
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> children = List.generate(widget.tags.length, (index) {
      Widget child = widget.itemBuilder == null
          ? Center(child: Text(widget.tags[index], style: widget.textStyle))
          : widget.itemBuilder!(context, index);
      return SizedBox(
        width: widget.width,
        height: widget.itemHeight,
        child: child,
      );
    });

    return GestureDetector(
      onVerticalDragDown: (DragDownDetails details) {
        RenderBox? box = _getRenderBox(context);
        if (box == null) return;
        Offset topLeftPosition = box.localToGlobal(Offset.zero);
        _widgetTop = topLeftPosition.dy.toInt();
        int index = _getIndex(details.localPosition.dy);
        if (index >= 0) {
          lastIndex = index;
          _triggerDragEvent(IndexBarDragDetails.actionDown);
        }
      },
      onVerticalDragUpdate: (DragUpdateDetails details) {
        int index = _getIndex(details.localPosition.dy);
        if (index >= 0 && lastIndex != index) {
          lastIndex = index;
          //HapticFeedback.lightImpact();
          //HapticFeedback.vibrate();
          _triggerDragEvent(IndexBarDragDetails.actionUpdate);
        }
      },
      onVerticalDragEnd: (DragEndDetails details) {
        _triggerDragEvent(IndexBarDragDetails.actionEnd);
      },
      onVerticalDragCancel: () {
        _triggerDragEvent(IndexBarDragDetails.actionCancel);
      },
      onTapUp: (TapUpDetails details) {
        //_triggerDragEvent(IndexBarDragDetails.actionUp);
      },
      behavior: HitTestBehavior.translucent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}
