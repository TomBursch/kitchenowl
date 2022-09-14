import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:kitchenowl/cubits/expense_overview_cubit.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:responsive_builder/responsive_builder.dart';

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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context)!
                              .expenseOverviewTotalTitle(
                            _monthOffsetToString(0),
                          ),
                          style: Theme.of(context).textTheme.headline5,
                        ),
                      ),
                      Text(
                        NumberFormat.simpleCurrency()
                            .format(state.getTotalForMonth(0)),
                        style: Theme.of(context).textTheme.headline5,
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 300,
                    child: charts.PieChart(
                      [_getSeriesCurrentMonth(state.categoryOverviewsByMonth)],
                      animate: true,
                      // defaultRenderer: charts.ArcRendererConfig(
                      //     // arcWidth: 60,
                      //     // arcRendererDecorators: [charts.ArcLabelDecorator()],
                      //     // strokeWidthPx: 0,
                      //     ),
                      // behaviors: [
                      //   charts.DatumLegend(),
                      // ],
                    ),
                  ),
                  Text(
                    AppLocalizations.of(context)!
                        .expenseOverviewComparedToPreviousMonth,
                    style: Theme.of(context).textTheme.headline5,
                  ),
                  SizedBox(
                    height: 300,
                    child: charts.BarChart(
                      _getSeriesAllMonth(state.categoryOverviewsByMonth),
                      animate: true,
                      defaultInteractions: true,
                      defaultRenderer: charts.BarRendererConfig(
                        groupingType: charts.BarGroupingType.stacked,
                        stackedBarPaddingPx: 0,
                      ),
                      behaviors: [
                        charts.SeriesLegend(
                          desiredMaxColumns: getValueForScreenType(
                            context: context,
                            mobile: 3,
                            tablet: 6,
                            desktop: 10,
                          ),
                        ),
                      ],
                      domainAxis: charts.OrdinalAxisSpec(
                        renderSpec: charts.SmallTickRendererSpec(
                          labelStyle: charts.TextStyleSpec(
                            fontSize: Theme.of(context)
                                .textTheme
                                .bodyText2!
                                .fontSize!
                                .round(),
                            color: _toChartsColors(
                              Theme.of(context).textTheme.bodyText2!.color!,
                            ),
                          ),
                          lineStyle: charts.LineStyleSpec(
                            color: _toChartsColors(
                              Theme.of(context).textTheme.bodyText2!.color!,
                            ),
                          ),
                        ),
                      ),
                      primaryMeasureAxis: charts.NumericAxisSpec(
                        tickFormatterSpec: charts.BasicNumericTickFormatterSpec
                            .fromNumberFormat(
                          NumberFormat.compactSimpleCurrency(),
                        ),
                        renderSpec: charts.GridlineRendererSpec(
                          labelStyle: charts.TextStyleSpec(
                            fontSize: Theme.of(context)
                                .textTheme
                                .bodyText2!
                                .fontSize!
                                .round(),
                            color: _toChartsColors(
                              Theme.of(context).textTheme.bodyText2!.color!,
                            ),
                          ),
                          lineStyle: charts.LineStyleSpec(
                            color: _toChartsColors(
                              Theme.of(context).textTheme.bodyText2!.color!,
                            ),
                          ),
                        ),
                      ),
                      selectionModels: [
                        charts.SelectionModelConfig(
                          type: charts.SelectionModelType.info,
                          changedListener: (model) {
                            if (model.hasDatumSelection &&
                                model.selectedDatum.isNotEmpty) {
                              final monthIndex = int.tryParse(
                                    model.selectedDatum.first.datum.key,
                                  ) ??
                                  0;
                              askForConfirmation(
                                context: context,
                                showCancel: false,
                                confirmText: AppLocalizations.of(context)!.done,
                                confirmColor: null,
                                title: Text(_monthOffsetToString(monthIndex)),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ...model.selectedDatum
                                        .map((e) => Row(
                                              children: [
                                                Expanded(
                                                  child:
                                                      Text("${e.series.id}:"),
                                                ),
                                                Text(NumberFormat
                                                        .simpleCurrency()
                                                    .format(e.datum.value)),
                                              ],
                                            ))
                                        .toList(),
                                    const Divider(),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            AppLocalizations.of(context)!.total,
                                          ),
                                        ),
                                        Text(NumberFormat.simpleCurrency()
                                            .format(state
                                                .getTotalForMonth(monthIndex))),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            }
                          },
                        ),
                      ],
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
      measureFn: (v, _) => v.value["0"]?.abs(),
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
                id: e.key.isEmpty ? AppLocalizations.of(context)!.other : e.key,
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

  charts.Color _toChartsColors(Color c) => charts.Color(
        r: c.red,
        g: c.green,
        b: c.blue,
      );
}
