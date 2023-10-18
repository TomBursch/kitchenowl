import 'package:fraction/fraction.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

abstract class StringScaler {
  static String scale(String str, Fraction factor, [int decimals = 2]) {
    if (str.isEmpty) str = "1x";
    // Replace custom unicode
    str = str.replaceAllMapped(
      RegExp('¼|½|¾|⅐|⅑|⅒|⅓|⅔|⅕|⅖|⅗|⅘|⅙|⅚|⅛|⅜|⅝|⅞'),
      (match) {
        switch (match.group(0)!) {
          case '¼':
            return '.25';
          case '½':
            return '.5';
          case '¾':
            return '.75';
          case '⅐':
            return '.142857142857';
          case '⅑':
            return '.111111111111';
          case '⅒':
            return '.1';
          case '⅓':
            return '.333333333333';
          case '⅔':
            return '.666666666667';
          case '⅕':
            return '.2';
          case '⅖':
            return '.4';
          case '⅗':
            return '.6';
          case '⅘':
            return '.8';
          case '⅙':
            return '.166666666667';
          case '⅚':
            return '.833333333333';
          case '⅛':
            return '.125';
          case '⅜':
            return '.375';
          case '⅝':
            return '.625';
          case '⅞':
            return '.875';
          default:
            return match.group(0)!;
        }
      },
    );
    // replace , with .
    str = str.replaceAllMapped(
      RegExp(r',(\d)'),
      (match) => '.${match.group(1)}',
    );

    // replace 1/2 with .5
    str = str.replaceAllMapped(
      RegExp(r'(\d+((\.)\d+)?)\/(\d+((\.)\d+)?)'),
      (match) => (double.tryParse(match.group(1)!)! /
              double.tryParse(match.group(4)!)!)
          .toString(),
    );

    // find numbers and scale
    str = str.replaceAllMapped(RegExp(r'\d+((\.)\d+)?((e|E)\d+)?'), (match) {
      final scaledNumber =
          (double.tryParse(match.group(0)!)!.toFraction() * factor)
              .toMixedFraction();

      if (scaledNumber.fractionalPart.isFractionGlyph) {
        final prefix =
            scaledNumber.whole >= 1 ? scaledNumber.whole.toString() : '';

        return '$prefix${scaledNumber.fractionalPart.toStringAsGlyph()}';
      }

      return NumberFormat.decimalPattern().format(
        (scaledNumber.toDouble() * math.pow(10, decimals)).round() /
            math.pow(10, decimals),
      );
    });

    return str;
  }
}
