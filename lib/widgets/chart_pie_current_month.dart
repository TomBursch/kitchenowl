import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kitchenowl/kitchenowl.dart';

class ChartPieCurrentMonth extends StatefulWidget {
  final Map<String, double> data;
  final double availableHeight;

  const ChartPieCurrentMonth({
    super.key,
    required this.data,
    this.availableHeight = 240,
  });

  @override
  State<ChartPieCurrentMonth> createState() => _ChartPieCurrentMonthState();
}

class _ChartPieCurrentMonthState extends State<ChartPieCurrentMonth> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    return PieChart(
      PieChartData(
        pieTouchData: PieTouchData(
          enabled: true,
          touchCallback: (FlTouchEvent event, pieTouchResponse) {
            if (!event.isInterestedForInteractions ||
                pieTouchResponse == null ||
                pieTouchResponse.touchedSection == null) {
              setState(() {
                touchedIndex = -1;
              });

              return;
            }
            setState(() {
              touchedIndex =
                  pieTouchResponse.touchedSection!.touchedSectionIndex;
            });
          },
        ),
        borderData: FlBorderData(
          show: false,
        ),
        sectionsSpace: 5,
        centerSpaceRadius: 0,
        sections: _getData(),
      ),
      swapAnimationDuration: const Duration(milliseconds: 150),
      swapAnimationCurve: Curves.linear,
    );
  }

  // ignore: long-method
  List<PieChartSectionData> _getData() {
    return widget.data.entries.map((e) {
      final isTouched = touchedIndex >= 0 &&
          e.key ==
              widget.data.entries
                  .where((e) => e.value != 0)
                  .map((e) => e.key)
                  .elementAt(touchedIndex);
      final radius = widget.availableHeight / 2 + (isTouched ? 0 : -10) - 20;

      return PieChartSectionData(
        color: _colorFn(e.key),
        value: e.value.abs(),
        radius: radius,
        badgeWidget: Card(
          child: AnimatedSize(
            duration: const Duration(milliseconds: 200),
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    e.key.isEmpty ? AppLocalizations.of(context)!.other : e.key,
                  ),
                  if (isTouched)
                    Text(": ${NumberFormat.simpleCurrency().format(e.value)}"),
                ],
              ),
            ),
          ),
        ),
        showTitle: false,
        badgePositionPercentageOffset: 1.05,
      );
    }).toList();
  }

  Color _colorFn(String key) {
    final i = widget.data.keys.toList().indexOf(key) % 5;
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
