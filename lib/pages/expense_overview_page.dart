import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:kitchenowl/cubits/expense_overview_cubit.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:charts_flutter/flutter.dart' as charts;

class ExpenseOverviewPage extends StatefulWidget {
  const ExpenseOverviewPage({super.key});

  @override
  State<ExpenseOverviewPage> createState() => _ExpenseOverviewPageState();
}

class _ExpenseOverviewPageState extends State<ExpenseOverviewPage> {
  late final ExpenseOverviewCubit cubit;

  @override
  void initState() {
    super.initState();
    cubit = ExpenseOverviewCubit();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.overview),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints.expand(width: 1600),
          child: BlocBuilder<ExpenseOverviewCubit, ExpenseOverviewState>(
            bloc: cubit,
            builder: (context, state) {
              if (state is! ExpenseOverviewLoaded) {
                return const Center(child: CircularProgressIndicator());
              }

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text("This month by category"),
                  SizedBox(
                    height: 300,
                    child: charts.PieChart(
                      [_getSeriesCurrentMonth(state.categoryOverviewsByMonth)],
                      animate: true,
                      // defaultRenderer: charts.ArcRendererConfig(
                      //   // arcWidth: 60,
                      //   // arcRendererDecorators: [charts.ArcLabelDecorator()],
                      //   strokeWidthPx: 0,
                      // ),
                    ),
                  ),
                  Text("Previous months"),
                  SizedBox(
                    height: 300,
                    child: charts.BarChart(
                      _getSeriesAllMonth(state.categoryOverviewsByMonth),
                      animate: true,
                      defaultRenderer: charts.BarRendererConfig(
                        groupingType: charts.BarGroupingType.stacked,
                        stackedBarPaddingPx: 0,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  charts.Series<MapEntry<String, Map<String, double>>, String>
      _getSeriesCurrentMonth(
    Map<String, Map<String, double>> data,
  ) {
    return charts.Series<MapEntry<String, Map<String, double>>, String>(
      id: "0",
      data: data.entries.toList(),
      domainFn: (v, _) => v.key,
      measureFn: (v, _) => v.value["0"],
      labelAccessorFn: (v, _) =>
          "${v.key}: ${NumberFormat.simpleCurrency().format(v.value["0"])}",
      colorFn: (_, i) => _colorFn(i ?? 0),
    );
  }

  List<charts.Series<MapEntry<String, double>, String>> _getSeriesAllMonth(
    Map<String, Map<String, double>> data,
  ) {
    return data.entries
        .toList()
        .asMap()
        .map((i, e) => MapEntry(
              i,
              charts.Series<MapEntry<String, double>, String>(
                id: e.key,
                data: e.value.entries.toList().reversed.toList(),
                domainFn: (v, _) => _monthOffsetToString(int.tryParse(v.key)!),
                measureFn: (v, _) => v.value,
                labelAccessorFn: (v, _) =>
                    "${_monthOffsetToString(int.tryParse(v.key)!)}: ${NumberFormat.simpleCurrency().format(v.value)}",
                colorFn: (v, _) => _colorFn(i),
              ),
            ))
        .entries
        .map((e) => e.value)
        .toList();
  }

  String _monthOffsetToString(int offset) {
    return DateFormat.MMMM()
        .dateSymbols
        .STANDALONEMONTHS[(DateTime.now().month - 1 - offset) % 12];
  }

  charts.Color _colorFn(int i) {
    i = i % 5;
    final l = List.generate(5, (i) {
      Color c = lighten(Theme.of(context).colorScheme.primary, -0.2);
      for (int j = 0; j < i; j++) {
        c = lighten(c);
      }

      return c;
    });

    return charts.Color(
      r: l[i].red,
      g: l[i].green,
      b: l[i].blue,
    );
  }

  Color lighten(Color color, [double amount = 0.1]) {
    assert(amount >= -1 && amount <= 1);

    final hsl = HSLColor.fromColor(color);
    final hslLight =
        hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));

    return hslLight.toColor();
  }
}
