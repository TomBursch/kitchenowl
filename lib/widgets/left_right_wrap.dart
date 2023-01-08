import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';
import 'dart:math' as math;

class LeftRightWrap extends MultiChildRenderObjectWidget {
  LeftRightWrap({
    super.key,
    required Widget left,
    required Widget right,
  }) : super(children: [left, right]);

  @override
  RenderLeftRightWrap createRenderObject(BuildContext context) =>
      RenderLeftRightWrap();
}

class LeftRightWrapParentData extends ContainerBoxParentData<RenderBox> {}

class RenderLeftRightWrap extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, LeftRightWrapParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, LeftRightWrapParentData> {
  RenderLeftRightWrap({
    List<RenderBox>? children,
  }) {
    addAll(children);
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! LeftRightWrapParentData) {
      child.parentData = LeftRightWrapParentData();
    }
  }

  @override
  void performLayout() {
    final BoxConstraints childConstraints = constraints.loosen();

    final RenderBox? leftChild = firstChild;
    final RenderBox? rightChild = lastChild;

    if (leftChild == null || rightChild == null) {
      size = constraints.smallest;

      return;
    }

    leftChild.layout(childConstraints, parentUsesSize: true);
    rightChild.layout(childConstraints, parentUsesSize: true);

    final LeftRightWrapParentData leftParentData =
        leftChild.parentData! as LeftRightWrapParentData;
    final LeftRightWrapParentData rightParentData =
        rightChild.parentData! as LeftRightWrapParentData;

    final bool wrapped =
        leftChild.size.width + rightChild.size.width > constraints.maxWidth;

    leftParentData.offset = Offset.zero;
    rightParentData.offset = Offset(
      constraints.maxWidth - rightChild.size.width,
      wrapped ? leftChild.size.height : 0,
    );

    size = Size(
      constraints.maxWidth,
      wrapped
          ? leftChild.size.height + rightChild.size.height
          : math.max(leftChild.size.height, rightChild.size.height),
    );
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return defaultHitTestChildren(result, position: position);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    defaultPaint(context, offset);
  }
}
