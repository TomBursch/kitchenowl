import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:kitchenowl/app.dart';
import 'package:kitchenowl/cubits/expense_list_cubit.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/user.dart';
import 'package:kitchenowl/widgets/expense_item.dart';

class ExpenseListPage extends StatefulWidget {
  const ExpenseListPage({Key? key}) : super(key: key);

  @override
  _ExpensePageState createState() => _ExpensePageState();
}

class _ExpensePageState extends State<ExpenseListPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = BlocProvider.of<ExpenseListCubit>(context);

    return SafeArea(
      child: Scrollbar(
        child: RefreshIndicator(
          onRefresh: cubit.refresh,
          child: BlocBuilder<ExpenseListCubit, ExpenseListCubitState>(
            bloc: cubit,
            builder: (context, state) => CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverToBoxAdapter(
                    child: Container(
                      height: 80,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        AppLocalizations.of(context)!.balances,
                        style: Theme.of(context).textTheme.headline5,
                      ),
                    ),
                  ),
                ),
                if (state is LoadingExpenseListCubitState && !App.isOffline)
                  SliverList(
                    delegate: SliverChildListDelegate([
                      SizedBox(
                        height: (2 * 60 + 30).toDouble(),
                      ),
                      for (int i = 0; i < 3; i++)
                        const Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 16,
                          ),
                          child: ShimmerCard(
                            trailing: ShimmerText(
                              maxWidth: 50,
                            ),
                          ),
                        ),
                    ]),
                  ),
                if (state.users.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: (state.users.length * 60 + 30).toDouble(),
                      child: _getBarChart(context, state),
                    ),
                  ),
                  if (state.expenses.isEmpty && !App.isOffline)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Icon(Icons.money_off_rounded),
                            const SizedBox(height: 16),
                            Text(AppLocalizations.of(context)!.expenseEmpty),
                          ],
                        ),
                      ),
                    ),
                  if (state.expenses.isNotEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, i) => ExpenseItemWidget(
                            key: ObjectKey(state.expenses[i]),
                            expense: state.expenses[i],
                            users: state.users,
                            onUpdated: cubit.refresh,
                          ),
                          childCount: state.expenses.length,
                        ),
                      ),
                    ),
                ],
                if (state.expenses.isEmpty && App.isOffline)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Icon(Icons.cloud_off),
                          const SizedBox(height: 16),
                          Text(AppLocalizations.of(context)!.offlineMessage),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ignore: long-method
  Widget _getBarChart(BuildContext context, ExpenseListCubitState state) {
    double maxBalance = state.users
        .fold<double>(0.0, (p, e) => e.balance.abs() > p ? e.balance.abs() : p);
    maxBalance = maxBalance > 0 ? maxBalance : 1;

    final zeroDividerColor = Theme.of(context).colorScheme.onBackground;

    return charts.BarChart(
      [
        charts.Series<User, String>(
          id: 'Balance',
          data: state.users,
          colorFn: (user, _) => charts.Color(
            r: Theme.of(context).colorScheme.primary.red,
            g: Theme.of(context).colorScheme.primary.green,
            b: Theme.of(context).colorScheme.primary.blue,
          ),
          domainFn: (user, _) => user.username,
          measureFn: (user, _) => user.balance,
          labelAccessorFn: (user, _) =>
              "  ${user.name}: ${NumberFormat.simpleCurrency().format(user.balance)}",
        ),
        charts.Series<User, String>(
          id: 'zero',
          domainFn: (user, _) => user.username,
          measureFn: (user, _) => 0,
          data: state.users,
          colorFn: (user, _) => charts.Color(
            r: zeroDividerColor.red,
            g: zeroDividerColor.green,
            b: zeroDividerColor.blue,
          ),
          strokeWidthPxFn: (user, _) => 5,
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
    );
  }
}
