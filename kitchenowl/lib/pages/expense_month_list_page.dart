import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/app.dart';
import 'package:kitchenowl/cubits/expense_month_list_cubit.dart';
import 'package:kitchenowl/enums/expenselist_sorting.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/expense_category.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/widgets/expense_item.dart';
import 'package:sliver_tools/sliver_tools.dart';

class ExpenseMonthListPage extends StatefulWidget {
  final Household household;
  final List<ExpenseCategory?> filter;
  final ExpenselistSorting sorting;
  final DateTime startAfter;
  final DateTime endBefore;

  const ExpenseMonthListPage({
    super.key,
    this.filter = const [],
    required this.sorting,
    required this.startAfter,
    required this.endBefore,
    required this.household,
  });

  @override
  State<ExpenseMonthListPage> createState() => _ExpenseMonthListPageState();
}

class _ExpenseMonthListPageState extends State<ExpenseMonthListPage> {
  late ExpenseMonthListCubit cubit;
  final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    cubit = ExpenseMonthListCubit(
      widget.household,
      widget.filter,
      widget.sorting,
      widget.startAfter,
      widget.endBefore,
    );
    scrollController.addListener(_scrollListen);
  }

  @override
  void dispose() {
    scrollController.removeListener(_scrollListen);
    cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<ExpenseMonthListCubit, ExpenseListCubitState>(
        bloc: cubit,
        builder: (context, state) => CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
            ),
            if (state.expenses.isNotEmpty)
              SliverCrossAxisConstrained(
                maxCrossAxisExtent: 1600,
                child: SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverImplicitAnimatedList(
                    itemBuilder: (context, i, animation) => SizeTransition(
                      key: ValueKey(state.expenses[i].id),
                      sizeFactor: animation,
                      child: ExpenseItemWidget(
                        household: state.household,
                        expense: state.expenses[i],
                        onUpdated: cubit.refresh,
                        displayPersonalAmount:
                            widget.sorting == ExpenselistSorting.personal,
                        locale: state.household.language,
                      ),
                    ),
                    removeItemBuilder: (context, expense, animation) =>
                        SizeTransition(
                      key: ValueKey(expense.id),
                      sizeFactor: animation,
                      child: ExpenseItemWidget(
                        household: state.household,
                        expense: expense,
                        onUpdated: cubit.refresh,
                        displayPersonalAmount:
                            widget.sorting == ExpenselistSorting.personal,
                        locale: state.household.language,
                      ),
                    ),
                    items: state.expenses,
                    equalityChecker: (p0, p1) => p0.id == p1.id,
                  ),
                ),
              ),
            if (state is LoadingExpenseListCubitState && !App.isOffline)
              SliverCrossAxisConstrained(
                maxCrossAxisExtent: 1600,
                child: SliverList(
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
          ],
        ),
      ),
    );
  }

  void _scrollListen() {
    if ((scrollController.position.pixels ==
        scrollController.position.maxScrollExtent)) {
      cubit.loadMore();
    }
  }
}
