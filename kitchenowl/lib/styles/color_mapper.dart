import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:kitchenowl/styles/colors.dart';

class KitchenOwlColorMapper extends ColorMapper {
  const KitchenOwlColorMapper({
    this.accentColor,
  });

  static const _rawAccentColor = AppColors.green;

  final Color? accentColor;

  @override
  Color substitute(
    String? id,
    String elementName,
    String attributeName,
    Color color,
  ) {
    final accentColor = this.accentColor;
    if (accentColor != null && color.value == _rawAccentColor.value)
      return accentColor;

    return color;
  }
}
