import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kitchenowl/kitchenowl.dart';

enum Timeframe {
  daily,
  weekly,
  monthly,
  yearly;

  String toLocalizedString(BuildContext context) {
    switch (this) {
      case Timeframe.daily:
        return AppLocalizations.of(context)!.daily;
      case Timeframe.weekly:
        return AppLocalizations.of(context)!.weekly;
      case Timeframe.monthly:
        return AppLocalizations.of(context)!.monthly;
      case Timeframe.yearly:
        return AppLocalizations.of(context)!.yearly;
    }
  }

  String getStringFromDateTime(BuildContext context, DateTime date) {
    switch (this) {
      case Timeframe.daily:
        return DateFormat.EEEE().format(date);
      case Timeframe.weekly:
        return "${DateFormat.d().format(date.subtract(Duration(days: date.weekday - 1)))} - ${DateFormat.d().format(date.add(Duration(days: 7 - date.weekday)))}";
      case Timeframe.monthly:
        return DateFormat.MMMM().dateSymbols.STANDALONEMONTHS[date.month - 1];
      case Timeframe.yearly:
        return date.year.toString();
    }
  }
}
