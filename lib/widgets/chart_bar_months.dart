import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/expense_category.dart';

class ChartBarMonths extends StatefulWidget {
  final Map<int, Map<int, double>> data;
  final Map<int, ExpenseCategory> categoriesById;
  final void Function(int) onMonthSelect;
  final int selectedMonth;

  ChartBarMonths({
    super.key,
    required this.data,
    required List<ExpenseCategory> categories,
    required this.onMonthSelect,
    required this.selectedMonth,
  }) : categoriesById =
            Map.fromEntries(categories.map((e) => MapEntry(e.id!, e)));

  @override
  State<ChartBarMonths> createState() => _ChartBarMonthsState();
}

class _ChartBarMonthsState extends State<ChartBarMonths> {
  static const double barWidth = 35;
  static const double barSpacing = 45;

  @override
  Widget build(BuildContext context) {
    final minY = widget.data
        .map((key, value) => MapEntry(
              key,
              value.values.fold<double>(0, (p, e) => e < 0 ? p + e : p),
            ))
        .values
        .fold<double>(0, (p, e) => p < e ? p : e);
    final maxY = widget.data
        .map((key, value) => MapEntry(
              key,
              value.values.fold<double>(0, (p, e) => e > 0 ? p + e : p),
            ))
        .values
        .fold<double>(0, (p, e) => p > e ? p : e);

    return BarChart(
      swapAnimationDuration: const Duration(milliseconds: 150),
      swapAnimationCurve: Curves.linear,
      BarChartData(
        alignment: BarChartAlignment.center,
        groupsSpace: barSpacing,
        minY: minY.toDouble(),
        maxY: maxY.toDouble(),
        baselineY: 0,
        barTouchData: BarTouchData(
          enabled: true,
          handleBuiltInTouches: false,
          touchCallback: (event, response) {
            if (response != null &&
                response.spot != null &&
                event is FlTapUpEvent) {
              widget.onMonthSelect(response.spot!.touchedBarGroup.x);
            }
          },
          mouseCursorResolver: (event, response) {
            return response == null || response.spot == null
                ? MouseCursor.defer
                : SystemMouseCursors.click;
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: bottomTitles,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: leftTitles,
              reservedSize: 45,
            ),
          ),
          rightTitles: AxisTitles(),
          topTitles: AxisTitles(),
        ),
        gridData: FlGridData(
          show: true,
          checkToShowHorizontalLine: (value) => value % 5 == 0,
          getDrawingHorizontalLine: (value) {
            if (value == 0) {
              return FlLine(
                color: Theme.of(context).colorScheme.onSurface,
                strokeWidth: 2,
              );
            }

            return FlLine(
              color: Theme.of(context).dividerColor,
              strokeWidth: 0.8,
            );
          },
          drawVerticalLine: false,
        ),
        borderData: FlBorderData(
          show: false,
        ),
        barGroups: widget.data.entries
            .toList()
            .reversed
            .map(
              (e) => generateGroup(
                e.key,
                e.value,
              ),
            )
            .toList(),
      ),
    );
  }

  Widget leftTitles(double value, TitleMeta meta) {
    final showText = value % 10 == 0;

    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(
        showText
            ? NumberFormat.simpleCurrency(decimalDigits: 0).format(value)
            : "",
        style: const TextStyle(fontSize: 10),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget bottomTitles(double value, TitleMeta meta) {
    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(_monthOffsetToString(value.toInt())),
    );
  }

  String _monthOffsetToString(int offset) {
    return DateFormat.MMMM()
        .dateSymbols
        .STANDALONEMONTHS[(DateTime.now().month - 1 - offset) % 12];
  }

  // ignore: long-method, long-parameter-list
  BarChartGroupData generateGroup(
    int month,
    Map<int, double> values,
  ) {
    final isTop = values.values.any((e) => e > 0);
    final isBottom = values.values.any((e) => e < 0);
    final sumPos = values.values.fold<double>(0, (v, e) => e > 0 ? v + e : v);
    final sumNeg = values.values.fold<double>(0, (v, e) => e < 0 ? v + e : v);

    return BarChartGroupData(
      x: month,
      groupVertically: true,
      barRods: [
        BarChartRodData(
          fromY: sumNeg,
          toY: sumPos,
          width: barWidth,
          color: Colors.transparent,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(isTop ? 14 : 0),
            topRight: Radius.circular(isTop ? 14 : 0),
            bottomLeft: Radius.circular(isBottom ? 14 : 0),
            bottomRight: Radius.circular(isBottom ? 14 : 0),
          ),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.onBackground,
            width: widget.selectedMonth == month ? 5 : 0,
          ),
          rodStackItems:
              generateStack(values, isTouched: widget.selectedMonth == month),
        ),
      ],
    );
  }

  List<BarChartRodStackItem> generateStack(
    Map<int, double> values, {
    bool isTouched = false,
  }) {
    double sumPos = 0;
    double sumNeg = 0;

    return values.entries.map((e) {
      final res = BarChartRodStackItem(
        e.value > 0 ? sumPos : sumNeg,
        (e.value > 0 ? sumPos : sumNeg) + e.value,
        _colorFn(e.key),
      );

      if (e.value > 0) {
        sumPos += e.value;
      } else {
        sumNeg += e.value;
      }

      return res;
    }).toList();
  }

  Color _colorFn(int key) {
    if (widget.categoriesById[key]?.color != null) {
      return widget.categoriesById[key]!.color!;
    }
    final i = widget.data[0]!.keys.toList().indexOf(key) % 5;
    final l = List.generate(5, (i) {
      Color c = lighten(Theme.of(context).colorScheme.primary, -0.2);
      for (int j = 0; j < i; j++) {
        c = lighten(c);
      }

      return c;
    });

    return l[i];
  }

  Color lighten(Color color, [double amount = 0.1]) {
    assert(amount >= -1 && amount <= 1);

    final hsl = HSLColor.fromColor(color);
    final hslLight =
        hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));

    return hslLight.toColor();
  }
}
