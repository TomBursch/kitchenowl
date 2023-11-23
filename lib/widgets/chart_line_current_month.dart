import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kitchenowl/models/month_overview.dart';
import 'package:responsive_builder/responsive_builder.dart';

class ChartLineCurrentMonth extends StatefulWidget {
  final ExpenseOverview data;
  final bool incomplete;
  final double? average;

  const ChartLineCurrentMonth({
    super.key,
    required this.data,
    this.incomplete = false,
    this.average,
  });

  @override
  State<ChartLineCurrentMonth> createState() => _ChartLineCurrentMonthState();
}

class _ChartLineCurrentMonthState extends State<ChartLineCurrentMonth> {
  late DateTime firstDay;
  late int days;

  @override
  Widget build(BuildContext context) {
    double min = 0, max = 0, sum = 0;
    final data = widget.data.byDay.map((key, value) {
      sum += value;
      if (sum < min) min = sum;
      if (sum > max) max = sum;
      return MapEntry(key.day, sum);
    });
    firstDay = widget.data.byDay.keys.first.copyWith(day: 1);
    data.putIfAbsent(0, () => 0);

    days = DateTimeRange(
      start: firstDay,
      end: DateTime(firstDay.year, firstDay.month + 1),
    ).duration.inDays;
    if (!widget.incomplete) {
      data[days] = sum;
    } else {
      data[DateTime.now().day] = sum;
    }

    return LineChart(
      LineChartData(
          minX: 1,
          maxX: days.toDouble(),
          minY: math.min(min, -2),
          maxY: widget.average != null && widget.average! > max
              ? widget.average
              : max + 5,
          clipData: const FlClipData.vertical(),
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
          lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Theme.of(context).cardTheme.color ??
                Theme.of(context).colorScheme.surface,
            tooltipRoundedRadius: 14,
            getTooltipItems: (touchedSpots) =>
                touchedSpots.map((LineBarSpot touchedSpot) {
              return LineTooltipItem(
                NumberFormat.simpleCurrency(decimalDigits: 0)
                    .format(touchedSpot.y),
                const TextStyle(),
              );
            }).toList(),
          )),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                getTitlesWidget: bottomTitles,
                interval: 1,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: leftTitles,
                reservedSize: 45,
              ),
            ),
            rightTitles: const AxisTitles(),
            topTitles: const AxisTitles(),
          ),
          lineBarsData: [
            if (widget.average != null)
              LineChartBarData(
                color: Theme.of(context).colorScheme.onSurface,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                dashArray: [5],
                spots: [
                  const FlSpot(0, 0),
                  FlSpot(
                    // Add one day so point is not clickable
                    days.toDouble() + 1,
                    widget.average! + widget.average! / days,
                  ),
                ],
              ),
            if (widget.incomplete && DateTime.now().day > 6)
              LineChartBarData(
                color: Theme.of(context).colorScheme.primary,
                barWidth: 2,
                dashArray: [5],
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                spots: [
                  FlSpot(
                    DateTime.now().day.toDouble(),
                    sum,
                  ),
                  FlSpot(
                    days.toDouble() + 1,
                    sum / DateTime.now().day * days,
                  ),
                ],
              ),
            LineChartBarData(
              color: Theme.of(context).colorScheme.primary,
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              spots: data.entries
                  .map((e) => FlSpot(e.key.toDouble(), e.value))
                  .toList()
                ..sort((a, b) => a.x.compareTo(b.x)),
            ),
          ]),
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
    final showText = (value + 1) %
                getValueForScreenType<int>(
                  context: context,
                  mobile: 2,
                  tablet: 2,
                  desktop: 1,
                ) ==
            0 ||
        value == days;

    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(
        showText
            ? DateFormat.d().format(firstDay.copyWith(day: value.ceil()))
            : "",
      ),
    );
  }
}
