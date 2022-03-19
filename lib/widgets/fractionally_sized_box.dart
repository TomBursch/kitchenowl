import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// A widget that sizes its child to a fraction of the total available space.
/// For more details about the layout algorithm, see
/// [KitchenOwlRenderFractionallySizedOverflowBox].
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=PEsY654EGZ0}
///
/// {@tool dartpad}
/// This sample shows a [KitchenOwlFractionallySizedBox] whose one child is 50% of
/// the box's size per the width and height factor parameters, and centered
/// within that box by the alignment parameter.
///
/// ** See code in examples/api/lib/widgets/basic/fractionally_sized_box.0.dart **
/// {@end-tool}
///
/// See also:
///
///  * [Align], which sizes itself based on its child's size and positions
///    the child according to an [Alignment] value.
///  * [OverflowBox], a widget that imposes different constraints on its child
///    than it gets from its parent, possibly allowing the child to overflow the
///    parent.
///  * The [catalog of layout widgets](https://flutter.dev/widgets/layout/).
class KitchenOwlFractionallySizedBox extends SingleChildRenderObjectWidget {
  /// Creates a widget that sizes its child to a fraction of the total available space.
  ///
  /// If non-null, the [widthFactor] and [heightFactor] arguments must be
  /// non-negative.
  const KitchenOwlFractionallySizedBox({
    Key? key,
    this.alignment = Alignment.center,
    this.widthFactor,
    this.widthSubstract,
    this.heightFactor,
    this.heightSubstract,
    Widget? child,
  })  : assert(widthFactor == null || widthFactor >= 0.0),
        assert(widthSubstract == null || widthSubstract >= 0.0),
        assert(heightFactor == null || heightFactor >= 0.0),
        assert(heightSubstract == null || heightSubstract >= 0.0),
        super(key: key, child: child);

  /// If non-null, the fraction of the incoming width given to the child.
  ///
  /// If non-null, the child is given a tight width constraint that is the max
  /// incoming width constraint multiplied by this factor.
  ///
  /// If null, the incoming width constraints are passed to the child
  /// unmodified.
  final double? widthFactor;

  /// If non-null, the fraction of the incoming height given to the child.
  ///
  /// If non-null, the child is given a tight height constraint that is the max
  /// incoming height constraint multiplied by this factor.
  ///
  /// If null, the incoming height constraints are passed to the child
  /// unmodified.
  final double? heightFactor;

  /// How to align the child.
  ///
  /// The x and y values of the alignment control the horizontal and vertical
  /// alignment, respectively. An x value of -1.0 means that the left edge of
  /// the child is aligned with the left edge of the parent whereas an x value
  /// of 1.0 means that the right edge of the child is aligned with the right
  /// edge of the parent. Other values interpolate (and extrapolate) linearly.
  /// For example, a value of 0.0 means that the center of the child is aligned
  /// with the center of the parent.
  ///
  /// Defaults to [Alignment.center].
  ///
  /// See also:
  ///
  ///  * [Alignment], a class with convenient constants typically used to
  ///    specify an [AlignmentGeometry].
  ///  * [AlignmentDirectional], like [Alignment] for specifying alignments
  ///    relative to text direction.
  final AlignmentGeometry alignment;

  final double? widthSubstract;

  final double? heightSubstract;

  @override
  KitchenOwlRenderFractionallySizedOverflowBox createRenderObject(
      BuildContext context) {
    return KitchenOwlRenderFractionallySizedOverflowBox(
      alignment: alignment,
      widthFactor: widthFactor,
      widthSubstract: widthSubstract,
      heightFactor: heightFactor,
      heightSubstract: heightSubstract,
      textDirection: Directionality.maybeOf(context),
    );
  }

  @override
  void updateRenderObject(BuildContext context,
      KitchenOwlRenderFractionallySizedOverflowBox renderObject) {
    renderObject
      ..alignment = alignment
      ..widthFactor = widthFactor
      ..widthSubstract = widthSubstract
      ..heightFactor = heightFactor
      ..heightSubstract = heightSubstract
      ..textDirection = Directionality.maybeOf(context);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
        .add(DiagnosticsProperty<AlignmentGeometry>('alignment', alignment));
    properties
        .add(DoubleProperty('widthFactor', widthFactor, defaultValue: null));
    properties.add(
        DoubleProperty('widthSubstract', heightFactor, defaultValue: null));
    properties
        .add(DoubleProperty('heightFactor', heightFactor, defaultValue: null));
    properties.add(
        DoubleProperty('heightSubstract', heightFactor, defaultValue: null));
  }
}

/// Sizes its child to a fraction of the total available space.
///
/// For both its width and height, this render object imposes a tight
/// constraint on its child that is a multiple (typically less than 1.0) of the
/// maximum constraint it received from its parent on that axis. If the factor
/// for a given axis is null, then the constraints from the parent are just
/// passed through instead.
///
/// It then tries to size itself to the size of its child. Where this is not
/// possible (e.g. if the constraints from the parent are themselves tight), the
/// child is aligned according to [alignment].
class KitchenOwlRenderFractionallySizedOverflowBox
    extends RenderAligningShiftedBox {
  /// Creates a render box that sizes its child to a fraction of the total available space.
  ///
  /// If non-null, the [widthFactor] and [heightFactor] arguments must be
  /// non-negative.
  ///
  /// The [alignment] must not be null.
  ///
  /// The [textDirection] must be non-null if the [alignment] is
  /// direction-sensitive.
  KitchenOwlRenderFractionallySizedOverflowBox({
    RenderBox? child,
    double? widthFactor,
    double? widthSubstract,
    double? heightFactor,
    double? heightSubstract,
    AlignmentGeometry alignment = Alignment.center,
    TextDirection? textDirection,
  })  : _widthFactor = widthFactor,
        _widthSubstract = widthSubstract,
        _heightFactor = heightFactor,
        _heightSubstract = heightSubstract,
        super(
            child: child, alignment: alignment, textDirection: textDirection) {
    assert(_widthFactor == null || _widthFactor! >= 0.0);
    assert(_widthSubstract == null || _widthSubstract! >= 0.0);
    assert(_heightFactor == null || _heightFactor! >= 0.0);
    assert(_heightSubstract == null || _heightSubstract! >= 0.0);
  }

  /// If non-null, the factor of the incoming width to use.
  ///
  /// If non-null, the child is given a tight width constraint that is the max
  /// incoming width constraint multiplied by this factor. If null, the child is
  /// given the incoming width constraints.
  double? get widthFactor => _widthFactor;
  double? _widthFactor;
  set widthFactor(double? value) {
    assert(value == null || value >= 0.0);
    if (_widthFactor == value) return;
    _widthFactor = value;
    markNeedsLayout();
  }

  /// If non-null, the factor of the incoming height to use.
  ///
  /// If non-null, the child is given a tight height constraint that is the max
  /// incoming width constraint multiplied by this factor. If null, the child is
  /// given the incoming width constraints.
  double? get heightFactor => _heightFactor;
  double? _heightFactor;
  set heightFactor(double? value) {
    assert(value == null || value >= 0.0);
    if (_heightFactor == value) return;
    _heightFactor = value;
    markNeedsLayout();
  }

  double? get widthSubstract => _widthSubstract;
  double? _widthSubstract;
  set widthSubstract(double? value) {
    assert(value == null || value >= 0.0);
    if (_widthSubstract == value) return;
    _widthSubstract = value;
    markNeedsLayout();
  }

  double? get heightSubstract => _heightSubstract;
  double? _heightSubstract;
  set heightSubstract(double? value) {
    assert(value == null || value >= 0.0);
    if (_heightSubstract == value) return;
    _heightSubstract = value;
    markNeedsLayout();
  }

  BoxConstraints _getInnerConstraints(BoxConstraints constraints) {
    double minWidth = constraints.minWidth;
    double maxWidth = constraints.maxWidth - (widthSubstract ?? 0);
    if (_widthFactor != null) {
      final double width = maxWidth * _widthFactor!;
      minWidth = width;
      maxWidth = width;
    }
    double minHeight = constraints.minHeight;
    double maxHeight = constraints.maxHeight - (heightSubstract ?? 0);
    if (_heightFactor != null) {
      final double height = maxHeight * _heightFactor!;
      minHeight = height;
      maxHeight = height;
    }
    return BoxConstraints(
      minWidth: minWidth,
      maxWidth: maxWidth,
      minHeight: minHeight,
      maxHeight: maxHeight,
    );
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    final double result;
    if (child == null) {
      result = super.computeMinIntrinsicWidth(height);
    } else {
      // the following line relies on double.infinity absorption
      result = child!.getMinIntrinsicWidth(height * (_heightFactor ?? 1.0));
    }
    assert(result.isFinite);
    return result / (_widthFactor ?? 1.0);
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    final double result;
    if (child == null) {
      result = super.computeMaxIntrinsicWidth(height);
    } else {
      // the following line relies on double.infinity absorption
      result = child!.getMaxIntrinsicWidth(
          (height - (heightSubstract ?? 0)) * (_heightFactor ?? 1.0));
    }
    assert(result.isFinite);
    return result / (_widthFactor ?? 1.0);
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    final double result;
    if (child == null) {
      result = super.computeMinIntrinsicHeight(width);
    } else {
      // the following line relies on double.infinity absorption
      result = child!.getMinIntrinsicHeight(width * (_widthFactor ?? 1.0));
    }
    assert(result.isFinite);
    return result / (_heightFactor ?? 1.0);
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    final double result;
    if (child == null) {
      result = super.computeMaxIntrinsicHeight(width);
    } else {
      // the following line relies on double.infinity absorption
      result = child!.getMaxIntrinsicHeight(
          (width - (widthSubstract ?? 0)) * (_widthFactor ?? 1.0));
    }
    assert(result.isFinite);
    return result / (_heightFactor ?? 1.0);
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    if (child != null) {
      final Size childSize =
          child!.getDryLayout(_getInnerConstraints(constraints));
      return constraints.constrain(childSize);
    }
    return constraints
        .constrain(_getInnerConstraints(constraints).constrain(Size.zero));
  }

  @override
  void performLayout() {
    if (child != null) {
      child!.layout(_getInnerConstraints(constraints), parentUsesSize: true);
      size = constraints.constrain(child!.size);
      alignChild();
    } else {
      size = constraints
          .constrain(_getInnerConstraints(constraints).constrain(Size.zero));
    }
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
        DoubleProperty('widthFactor', _widthFactor, ifNull: 'pass-through'));
    properties.add(DoubleProperty('widthSubstract', _widthSubstract,
        ifNull: 'pass-through'));
    properties.add(
        DoubleProperty('heightFactor', _heightFactor, ifNull: 'pass-through'));
    properties.add(DoubleProperty('heightSubstract', _heightSubstract,
        ifNull: 'pass-through'));
  }
}
