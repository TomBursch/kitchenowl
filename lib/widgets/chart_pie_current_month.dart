import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/expense_category.dart';
import 'package:kitchenowl/models/expense_overview.dart';

class ChartPieCurrentMonth extends StatefulWidget {
  final ExpenseOverview data;
  final double availableHeight;
  final Map<int, ExpenseCategory> categoriesById;

  ChartPieCurrentMonth({
    super.key,
    required this.data,
    required List<ExpenseCategory> categories,
    this.availableHeight = 270,
  }) : categoriesById =
            Map.fromEntries(categories.map((e) => MapEntry(e.id!, e)));

  @override
  State<ChartPieCurrentMonth> createState() => _ChartPieCurrentMonthState();
}

class _ChartPieCurrentMonthState extends State<ChartPieCurrentMonth> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.data.byCategory.values.reduce((v, e) => v + e) == 0) {
      return const SizedBox();
    }

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

  List<PieChartSectionData> _getData() {
    final sum = widget.data.byCategory.values
        .where((e) => e > 0)
        .fold(0.0, (p, e) => p + e);

    return widget.data.byCategory.entries.map((e) {
      final isTouched = touchedIndex >= 0 &&
          e.key ==
              widget.data.byCategory.entries
                  .where((e) => e.value != 0)
                  .map((e) => e.key)
                  .elementAt(touchedIndex);
      final radius = widget.availableHeight / 2 + (isTouched ? 0 : -10) - 20;

      return PieChartSectionData(
        color: _colorFn(e.key),
        value: e.value < 0 ? 0 : e.value,
        radius: radius,
        badgeWidget: (isTouched || e.value / sum > .15)
            ? Card(
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isTouched)
                          Text(
                            '${widget.categoriesById[e.key]?.name ?? AppLocalizations.of(context)!.other}: ',
                          ),
                        if (!isTouched)
                          Text(
                            '${widget.categoriesById[e.key]?.name.characters.first ?? '🪙'}: ',
                          ),
                        Text(NumberFormat.simpleCurrency().format(e.value)),
                      ],
                    ),
                  ),
                ),
              )
            : null,
        showTitle: false,
        badgePositionPercentageOffset: isTouched ? .85 : 1,
      );
    }).toList();
  }

  Color _colorFn(int key) {
    if (widget.categoriesById[key]?.color != null) {
      return widget.categoriesById[key]!.color!;
    }
    final i = widget.categoriesById.keys.toList().indexOf(key) % 5;
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
