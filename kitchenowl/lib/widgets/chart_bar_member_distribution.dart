import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:community_charts_flutter/community_charts_flutter.dart'
    as charts;
import 'package:kitchenowl/models/member.dart';
import 'package:kitchenowl/models/user.dart';

class ChartBarMemberDistribution extends StatelessWidget {
  final Household household;

  const ChartBarMemberDistribution({super.key, required this.household});

  @override
  Widget build(BuildContext context) {
    double maxBalance = (household.member ?? [])
        .fold<double>(0.0, (p, e) => e.balance.abs() > p ? e.balance.abs() : p);
    maxBalance = maxBalance > 0 ? maxBalance : 1;

    final zeroDividerColor = Theme.of(context).colorScheme.onSurface;

    return SizedBox(
      height: ((household.member?.length ?? 0) * 60 + 30).toDouble(),
      child: charts.BarChart(
        [
          charts.Series<Member, String>(
            id: 'Balance',
            data: household.member ?? [],
            colorFn: (member, _) => charts.Color(
              r: Theme.of(context).colorScheme.primary.red,
              g: Theme.of(context).colorScheme.primary.green,
              b: Theme.of(context).colorScheme.primary.blue,
            ),
            domainFn: (member, _) => member.username,
            measureFn: (member, _) => member.balance,
            labelAccessorFn: (member, _) =>
                "  ${member.name}: ${NumberFormat.simpleCurrency().format(member.balance)}",
          ),
          charts.Series<User, String>(
            id: 'zero',
            domainFn: (member, _) => member.username,
            measureFn: (member, _) => 0,
            data: household.member ?? [],
            colorFn: (member, _) => charts.Color(
              r: zeroDividerColor.red,
              g: zeroDividerColor.green,
              b: zeroDividerColor.blue,
            ),
            strokeWidthPxFn: (member, _) => 5,
          )..setAttribute(charts.rendererIdKey, 'zero'),
        ],
        vertical: false,
        defaultRenderer: charts.BarRendererConfig(
          barRendererDecorator: charts.BarLabelDecorator<String>(
            insideLabelStyleSpec: charts.TextStyleSpec(
              color: charts.Color(
                r: Theme.of(context).colorScheme.onPrimary.red,
                g: Theme.of(context).colorScheme.onPrimary.green,
                b: Theme.of(context).colorScheme.onPrimary.blue,
              ),
            ),
            outsideLabelStyleSpec: charts.TextStyleSpec(
              color: charts.Color(
                r: Theme.of(context).colorScheme.onBackground.red,
                g: Theme.of(context).colorScheme.onBackground.green,
                b: Theme.of(context).colorScheme.onBackground.blue,
              ),
            ),
          ),
          cornerStrategy: const charts.ConstCornerStrategy(14),
        ),
        customSeriesRenderers: [
          charts.BarTargetLineRendererConfig<String>(
            customRendererId: 'zero',
          ),
        ],
        defaultInteractions: false,
        primaryMeasureAxis: charts.NumericAxisSpec(
          showAxisLine: false,
          renderSpec: const charts.NoneRenderSpec(),
          tickProviderSpec: charts.StaticNumericTickProviderSpec([
            charts.TickSpec(-maxBalance),
            const charts.TickSpec<double>(0.0),
            charts.TickSpec(maxBalance),
          ]),
        ),
        domainAxis: const charts.OrdinalAxisSpec(
          renderSpec: charts.NoneRenderSpec(),
        ),
      ),
    );
  }
}
