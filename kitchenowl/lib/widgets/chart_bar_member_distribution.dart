import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kitchenowl/models/household.dart';

class ChartBarMemberDistribution extends StatelessWidget {
  final Household household;

  const ChartBarMemberDistribution({super.key, required this.household});

  @override
  Widget build(BuildContext context) {
    double maxBalance = (household.member ?? [])
        .fold<double>(0.0, (p, e) => e.balance.abs() > p ? e.balance.abs() : p);
    maxBalance = maxBalance > 0 ? maxBalance : 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Stack(
        alignment: AlignmentDirectional.topCenter,
        children: [
          Column(
            children: household.member
                    ?.map(
                      (member) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: SizedBox(
                          height: 40,
                          child: Align(
                            alignment: member.balance >= 0
                                ? Alignment.centerLeft
                                : Alignment.centerRight,
                            widthFactor: 2,
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              child: Text(
                                " ${member.name}: ${NumberFormat.simpleCurrency().format(member.balance)}",
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList() ??
                [],
          ),
          RotatedBox(
            quarterTurns: 1,
            child: SizedBox(
              width: (household.member?.length ?? 0) * 50 - 10,
              child: BarChart(
                BarChartData(
                  baselineY: 0,
                  minY: -maxBalance,
                  maxY: maxBalance,
                  groupsSpace: 10,
                  alignment: BarChartAlignment.start,
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(show: false),
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(show: false),
                  barGroups: household.member
                          ?.map((member) => BarChartGroupData(
                                x: member.id,
                                groupVertically: true,
                                barRods: [
                                  BarChartRodData(
                                    toY: member.balance,
                                    width: 35,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    borderRadius: BorderRadius.vertical(
                                      top: member.balance > 0
                                          ? Radius.circular(14)
                                          : Radius.zero,
                                      bottom: member.balance < 0
                                          ? Radius.circular(14)
                                          : Radius.zero,
                                    ),
                                  ),
                                  BarChartRodData(
                                    toY: 0.000001,
                                    fromY: -0.000001,
                                    width: 40,
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                    borderRadius: BorderRadius.circular(2.5),
                                  ),
                                ],
                              ))
                          .toList() ??
                      [],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget amountTitles(double value, TitleMeta meta) {
    final showText = value % 10 == 0;

    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: RotatedBox(
        quarterTurns: -1,
        child: Text(
          showText
              ? NumberFormat.simpleCurrency(decimalDigits: 0).format(value)
              : "",
          style: const TextStyle(fontSize: 10),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
