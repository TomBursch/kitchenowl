import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:kitchenowl/cubits/expense_overview_cubit.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/widgets/current_month_pie_chart.dart';
import 'package:kitchenowl/widgets/months_bar_chart.dart';

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
                    child: CurrentMonthPieChart(
                      data: state.categoryOverviewsByCategory['0']!,
                      availableHeight: 270,
                    ),
                  ),
                  const Divider(),
                  Text(
                    AppLocalizations.of(context)!
                        .expenseOverviewComparedToPreviousMonth,
                    style: Theme.of(context).textTheme.headline5,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 300,
                    child: MonthsBarChart(
                      data: state.categoryOverviewsByCategory,
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

  String _monthOffsetToString(int offset) {
    return DateFormat.MMMM()
        .dateSymbols
        .STANDALONEMONTHS[(DateTime.now().month - 1 - offset) % 12];
  }
}
