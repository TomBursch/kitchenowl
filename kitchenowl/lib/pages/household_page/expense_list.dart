import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kitchenowl/app.dart';
import 'package:kitchenowl/cubits/expense_list_cubit.dart';
import 'package:kitchenowl/cubits/household_cubit.dart';
import 'package:kitchenowl/enums/expenselist_sorting.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/widgets/chart_bar_member_distribution.dart';
import 'package:kitchenowl/widgets/chart_pie_current_month.dart';
import 'package:kitchenowl/widgets/choice_scroll.dart';
import 'package:kitchenowl/widgets/expense/timeframe_dropdown_button.dart';
import 'package:kitchenowl/widgets/expense_item.dart';
import 'package:responsive_builder/responsive_builder.dart';

class ExpenseListPage extends StatefulWidget {
  const ExpenseListPage({super.key});

  @override
  _ExpensePageState createState() => _ExpensePageState();
}

class _ExpensePageState extends State<ExpenseListPage> {
  final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    scrollController.addListener(_scrollListen);
  }

  @override
  void dispose() {
    scrollController.removeListener(_scrollListen);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = BlocProvider.of<ExpenseListCubit>(context);

    return SafeArea(
      child: Scrollbar(
        controller: scrollController,
        child: RefreshIndicator(
          onRefresh: () => Future.wait<void>([
            cubit.refresh(),
            BlocProvider.of<HouseholdCubit>(context).refresh(),
          ]),
          child: BlocBuilder<HouseholdCubit, HouseholdState>(
            builder: (context, householdState) {
              final searchAnchor = KitchenowlSearchAnchor(
                onSearch: (search) => cubit.setSearch(search),
                suggestionsBuilder: (context, controller) => (cubit
                        .state.expenses
                        .map((e) => e.name.trim())
                        .where((e) => e
                            .toLowerCase()
                            .startsWith(controller.text.toLowerCase()))
                        .take(25)
                        .fold<Map<String, int>>(
                            <String, int>{},
                            (map, letter) => map
                              ..update(letter, (value) => value + 1,
                                  ifAbsent: () => 1))
                        .entries
                        .where((e) => e.value > 1 || controller.text.isNotEmpty)
                        .toList()
                      ..sort((a, b) => b.value.compareTo(a.value)))
                    .map((e) => e.key),
              );

              return BlocBuilder<ExpenseListCubit, ExpenseListCubitState>(
                bloc: cubit,
                builder: (context, state) {
                  final isDesktop = getValueForScreenType(
                    context: context,
                    mobile: false,
                    tablet: false,
                    desktop: true,
                  );

                  final title = Container(
                    height: 80,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            AppLocalizations.of(context)!.balances,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ),
                        if (state.sorting == ExpenselistSorting.personal ||
                            isDesktop)
                          TimeframeDropdownButton(
                            value: state.timeframe,
                            onChanged: cubit.setTimeframe,
                          ),
                        const SizedBox(width: 2),
                        IconButton(
                          onPressed: () {
                            final household =
                                BlocProvider.of<HouseholdCubit>(context)
                                    .state
                                    .household;
                            context.go(
                              "/household/${household.id}/balances/overview",
                              extra: state.sorting,
                            );
                          },
                          icon: const Icon(Icons.bar_chart_rounded),
                          tooltip: AppLocalizations.of(context)!.overview,
                        ),
                      ],
                    ),
                  );

                  final expenseList = [
                    SliverToBoxAdapter(
                      child: LeftRightWrap(
                        left: (state.categories.isEmpty)
                            ? searchAnchor
                            : ChoiceScroll(
                                collapsable: true,
                                icon: Icons.filter_list_rounded,
                                onCollapse: cubit.clearFilter,
                                actions: [
                                  searchAnchor,
                                ],
                                children: state.categories.map((category) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    child: FilterChip(
                                      label: Text(
                                        category.name,
                                        style: TextStyle(
                                          color: state.filter.contains(category)
                                              ? Theme.of(context)
                                                  .colorScheme
                                                  .onPrimary
                                              : null,
                                        ),
                                      ),
                                      selected: state.filter.contains(category),
                                      selectedColor: Theme.of(context)
                                          .colorScheme
                                          .secondary,
                                      onSelected: (v) =>
                                          cubit.setFilter(category, v),
                                    ),
                                  );
                                }).toList()
                                  ..insert(
                                    0,
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                      ),
                                      child: FilterChip(
                                        label: Text(
                                          AppLocalizations.of(context)!.other,
                                          style: TextStyle(
                                            color: state.filter.contains(null)
                                                ? Theme.of(context)
                                                    .colorScheme
                                                    .onPrimary
                                                : null,
                                          ),
                                        ),
                                        selected: state.filter.contains(null),
                                        selectedColor: Theme.of(context)
                                            .colorScheme
                                            .secondary,
                                        onSelected: (v) =>
                                            cubit.setFilter(null, v),
                                      ),
                                    ),
                                  ),
                              ),
                        right: Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: TrailingIconTextButton(
                            text: state.sorting == ExpenselistSorting.all
                                ? AppLocalizations.of(context)!.household
                                : state.sorting == ExpenselistSorting.personal
                                    ? AppLocalizations.of(context)!.personal
                                    : AppLocalizations.of(context)!.other,
                            icon: const Icon(Icons.sort),
                            onPressed: cubit.incrementSorting,
                          ),
                        ),
                      ),
                    ),
                    if (state.expenses.isNotEmpty)
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverImplicitAnimatedList(
                          itemBuilder: (context, i, animation) =>
                              SizeTransition(
                            key: ValueKey(state.expenses[i].id),
                            sizeFactor: animation,
                            child: ExpenseItemWidget(
                              expense: state.expenses[i],
                              onUpdated: cubit.refresh,
                              displayPersonalAmount:
                                  state.sorting == ExpenselistSorting.personal,
                            ),
                          ),
                          removeItemBuilder: (context, expense, animation) =>
                              SizeTransition(
                            key: ValueKey(expense.id),
                            sizeFactor: animation,
                            child: ExpenseItemWidget(
                              expense: expense,
                              onUpdated: cubit.refresh,
                              displayPersonalAmount:
                                  state.sorting == ExpenselistSorting.personal,
                            ),
                          ),
                          items: state.expenses,
                          equalityChecker: (p0, p1) => p0.id == p1.id,
                        ),
                      ),
                    if (state is LoadingExpenseListCubitState && !App.isOffline)
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, i) => const Padding(
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
                          childCount: 3,
                        ),
                      ),
                    if (state is! LoadingExpenseListCubitState &&
                        state.expenses.isEmpty &&
                        !App.isOffline)
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
                              Text(
                                AppLocalizations.of(context)!.offlineMessage,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ];

                  final charts;
                  if (isDesktop)
                    charts = Expanded(
                      flex: 4,
                      child: ListView(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: title,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: SizedBox(
                              height: 270,
                              child: Row(
                                children: [
                                  if (state.expenseOverview[state.sorting]!
                                          .byCategory.values
                                          .fold(0.0, (a, b) => a + b) !=
                                      0)
                                    Expanded(
                                      flex: 2,
                                      child: ChartPieCurrentMonth(
                                        data: state
                                            .expenseOverview[state.sorting]!,
                                        categories: state.categories,
                                      ),
                                    ),
                                  Expanded(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          state.timeframe.getStringFromDateTime(
                                            context,
                                            DateTime.now(),
                                          ),
                                          style: Theme.of(context)
                                              .textTheme
                                              .headlineSmall,
                                        ),
                                        const Divider(),
                                        Text(
                                          NumberFormat.simpleCurrency().format(
                                            state
                                                .expenseOverview[state.sorting]!
                                                .byCategory
                                                .values
                                                .fold(0.0, (a, b) => a + b),
                                          ),
                                          style: Theme.of(context)
                                              .textTheme
                                              .headlineSmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Divider(
                            height: 50,
                            indent: 25,
                            endIndent: 25,
                          ),
                          if (householdState.household.member?.isNotEmpty ??
                              false)
                            ChartBarMemberDistribution(
                              household: householdState.household,
                            ),
                        ],
                        shrinkWrap: true,
                      ),
                    );
                  else if (householdState.household.member?.isNotEmpty ?? false)
                    charts = SliverToBoxAdapter(
                      child: AnimatedCrossFade(
                        crossFadeState:
                            state.sorting == ExpenselistSorting.all ||
                                    state.expenseOverview[state.sorting]!
                                        .byCategory.isEmpty
                                ? CrossFadeState.showFirst
                                : CrossFadeState.showSecond,
                        duration: const Duration(milliseconds: 100),
                        firstChild: ChartBarMemberDistribution(
                          household: householdState.household,
                        ),
                        secondChild: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: SizedBox(
                            height: 270,
                            child: Row(
                              children: [
                                if (state
                                        .expenseOverview[
                                            ExpenselistSorting.personal]!
                                        .byCategory
                                        .values
                                        .fold(0.0, (a, b) => a + b) !=
                                    0)
                                  Expanded(
                                    flex: 2,
                                    child: ChartPieCurrentMonth(
                                      data: state.expenseOverview[
                                          ExpenselistSorting.personal]!,
                                      categories: state.categories,
                                    ),
                                  ),
                                Expanded(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        state.timeframe.getStringFromDateTime(
                                          context,
                                          DateTime.now(),
                                        ),
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall,
                                      ),
                                      const Divider(),
                                      Text(
                                        NumberFormat.simpleCurrency().format(
                                          state
                                              .expenseOverview[
                                                  ExpenselistSorting.personal]!
                                              .byCategory
                                              .values
                                              .fold(0.0, (a, b) => a + b),
                                        ),
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  else
                    charts = null;

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isDesktop) charts,
                      Expanded(
                        flex: 5,
                        child: CustomScrollView(
                          controller: scrollController,
                          slivers: [
                            if (!isDesktop) ...[
                              SliverPadding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                sliver: SliverToBoxAdapter(
                                  child: title,
                                ),
                              ),
                              if (householdState.household.member?.isNotEmpty ??
                                  false)
                                charts,
                            ] else
                              SliverToBoxAdapter(
                                child: const SizedBox(height: 16),
                              ),
                            ...expenseList,
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _scrollListen() {
    if ((scrollController.position.pixels ==
        scrollController.position.maxScrollExtent)) {
      BlocProvider.of<ExpenseListCubit>(context).loadMore();
    }
  }
}
