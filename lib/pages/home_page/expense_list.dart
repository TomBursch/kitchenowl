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
  const ExpenseListPage({Key key}) : super(key: key);

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
                        AppLocalizations.of(context).balances,
                        style: Theme.of(context).textTheme.headline5,
                      ),
                    ),
                  ),
                ),
                if (state.users.isNotEmpty) ...[
                  SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverToBoxAdapter(
                        child: SizedBox(
                          height: (state.users.length * 60 + 30).toDouble(),
                          child: charts.BarChart(
                            [
                              charts.Series<User, String>(
                                id: 'Balance',
                                data: state.users,
                                colorFn: (user, _) => charts.Color(
                                  r: Theme.of(context)
                                      .colorScheme
                                      .secondary
                                      .red,
                                  g: Theme.of(context)
                                      .colorScheme
                                      .secondary
                                      .green,
                                  b: Theme.of(context)
                                      .colorScheme
                                      .secondary
                                      .blue,
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
                                  r: Theme.of(context).disabledColor.red,
                                  g: Theme.of(context).disabledColor.green,
                                  b: Theme.of(context).disabledColor.blue,
                                ),
                                strokeWidthPxFn: (user, _) => 5,
                              )..setAttribute(charts.rendererIdKey, 'zero'),
                            ],
                            vertical: false,
                            barRendererDecorator:
                                charts.BarLabelDecorator<String>(
                              outsideLabelStyleSpec: charts.TextStyleSpec(
                                color: charts.Color(
                                  r: Theme.of(context)
                                      .textTheme
                                      .bodyText2
                                      .color
                                      .red,
                                  g: Theme.of(context)
                                      .textTheme
                                      .bodyText2
                                      .color
                                      .green,
                                  b: Theme.of(context)
                                      .textTheme
                                      .bodyText2
                                      .color
                                      .blue,
                                ),
                              ),
                            ),
                            customSeriesRenderers: [
                              charts.BarTargetLineRendererConfig<String>(
                                customRendererId: 'zero',
                              )
                            ],
                            defaultInteractions: false,
                            primaryMeasureAxis: const charts.NumericAxisSpec(
                                showAxisLine: false,
                                renderSpec: charts.NoneRenderSpec()),
                            domainAxis: const charts.OrdinalAxisSpec(
                                renderSpec: charts.NoneRenderSpec()),
                          ),
                        ),
                      )),
                  if (state.expenses.isEmpty && !App.isOffline(context))
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Icon(Icons.money_off_rounded),
                            const SizedBox(height: 16),
                            Text(AppLocalizations.of(context).expenseEmpty),
                          ],
                        ),
                      ),
                    ),
                  if (state.expenses.isEmpty && App.isOffline(context))
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Icon(Icons.cloud_off),
                            const SizedBox(height: 16),
                            Text(AppLocalizations.of(context).offlineMessage),
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
                            expense: state.expenses[i],
                            users: state.users,
                            onUpdated: cubit.refresh,
                          ),
                          childCount: state.expenses.length,
                        ),
                      ),
                    ),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}
