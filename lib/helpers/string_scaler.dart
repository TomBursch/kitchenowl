import 'package:intl/intl.dart';
import 'dart:math' as math;

abstract class StringScaler {
  // ignore: long-method
  static String scale(String str, double factor, [int decimals = 2]) {
    if (str.isEmpty) return "${factor}x";
    // Replace custom unicode
    str = str.replaceAllMapped(
      RegExp('¼|½|¾|⅐|⅑|⅒|⅓|⅔|⅕|⅖|⅗|⅘|⅙|⅚|⅛|⅜|⅝|⅞'),
      (match) {
        switch (match.group(0)!) {
          case '¼':
            return '0.25';
          case '½':
            return '0.5';
          case '¾':
            return '0.75';
          case '⅐':
            return '0.142857142857';
          case '⅑':
            return '0.111111111111';
          case '⅒':
            return '0.1';
          case '⅓':
            return '0.333333333333';
          case '⅔':
            return '0.666666666667';
          case '⅕':
            return '0.2';
          case '⅖':
            return '0.4';
          case '⅗':
            return '0.6';
          case '⅘':
            return '0.8';
          case '⅙':
            return '0.166666666667';
          case '⅚':
            return '0.833333333333';
          case '⅛':
            return '0.125';
          case '⅜':
            return '0.375';
          case '⅝':
            return '0.625';
          case '⅞':
            return '0.875';
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
    str = str.replaceAllMapped(
      RegExp(r'\d+((\.)\d+)?((e|E)\d+)?'),
      (match) => NumberFormat.decimalPattern().format(
        (double.tryParse(match.group(0)!)! * factor * math.pow(10, decimals))
                .round() /
            math.pow(10, decimals),
      ),
    );

    return str;
  }
}
