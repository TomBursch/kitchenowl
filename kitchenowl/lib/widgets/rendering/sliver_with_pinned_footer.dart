import 'dart:math';

import 'package:flutter/rendering.dart';

class RenderSliverWithPinnedFooterParentData extends ParentData
    with ContainerParentDataMixin<RenderObject> {}

class RenderSliverWithPinnedFooter extends RenderSliver
    with
        ContainerRenderObjectMixin<RenderObject,
            RenderSliverWithPinnedFooterParentData> {
  @override
  void setupParentData(covariant RenderObject child) {
    if (child.parentData is! RenderSliverWithPinnedFooterParentData) {
      child.parentData = RenderSliverWithPinnedFooterParentData();
    }
  }

  @override
  void applyPaintTransform(covariant RenderObject child, Matrix4 transform) {
    if (child == lastChild) {
      final geometry = this.geometry!;
      final footer = child as RenderBox;
      final footerTop =
          geometry.paintOrigin + geometry.paintExtent - footer.size.height;
      transform.translate(0.0, footerTop);
    }
  }

  @override
  void performLayout() {
    final sliver = firstChild as RenderSliver;
    final footer = lastChild as RenderBox;
    sliver.layout(constraints, parentUsesSize: true);
    footer.layout(constraints.asBoxConstraints(), parentUsesSize: true);
    final paintExtent = min(constraints.remainingPaintExtent,
        sliver.geometry!.paintExtent + footer.size.height);
    final layoutExtent = min(constraints.remainingPaintExtent,
        sliver.geometry!.layoutExtent + footer.size.height);
    final cacheExtent = min(constraints.remainingPaintExtent,
        sliver.geometry!.cacheExtent + footer.size.height);
    geometry = SliverGeometry(
      scrollExtent: sliver.geometry!.scrollExtent + footer.size.height,
      paintExtent: paintExtent,
      paintOrigin: sliver.geometry!.paintOrigin,
      layoutExtent: layoutExtent,
      maxPaintExtent: sliver.geometry!.maxPaintExtent + footer.size.height,
      maxScrollObstructionExtent: sliver.geometry!.maxScrollObstructionExtent,
      hitTestExtent: paintExtent,
      visible: sliver.geometry!.visible,
      hasVisualOverflow: sliver.geometry!.hasVisualOverflow,
      scrollOffsetCorrection: sliver.geometry!.scrollOffsetCorrection,
      cacheExtent: cacheExtent,
    );
  }

  @override
  bool hitTestChildren(
    SliverHitTestResult result, {
    double? mainAxisPosition,
    double? crossAxisPosition,
  }) {
    if (mainAxisPosition == null || crossAxisPosition == null) return false;

    final geometry = this.geometry!;
    final sliver = firstChild as RenderSliver;
    final footer = lastChild as RenderBox;
    final footerTop = geometry.paintOrigin +
        geometry.paintExtent -
        min(footer.size.height, geometry.paintExtent);
    if (mainAxisPosition >= footerTop) {
      final hit = footer.hitTest(
        BoxHitTestResult.wrap(result),
        position: Offset(crossAxisPosition, mainAxisPosition - footerTop),
      );
      if (hit) {
        return true;
      }
    }
    return sliver.hitTest(
      result,
      mainAxisPosition: mainAxisPosition,
      crossAxisPosition: crossAxisPosition,
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final geometry = this.geometry!;
    final sliver = firstChild as RenderSliver;
    final footer = lastChild as RenderBox;
    context.paintChild(sliver, offset);
    context.paintChild(
      footer,
      Offset(
        offset.dx,
        offset.dy +
            geometry.paintOrigin +
            geometry.paintExtent -
            min(footer.size.height, geometry.paintExtent),
      ),
    );
  }
}
