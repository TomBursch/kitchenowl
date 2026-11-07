import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/models/item.dart';
import 'package:kitchenowl/models/planner.dart';

class ItemSelectionCubit extends Cubit<ItemSelectionState> {
  ItemSelectionCubit(List<RecipePlan> plans) : super(ItemSelectionState(plans));

  bool _isPastPlan(RecipePlan plan) {
    if (plan.cookingDate == null || plan.isWithoutPlannedDay) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final planDay = DateTime(
      plan.cookingDate!.year,
      plan.cookingDate!.month,
      plan.cookingDate!.day,
    );
    return planDay.isBefore(today);
  }

  void toggleItem(RecipePlan recipe, RecipeItem item) {
    final s = Map.of(state.selectedItems);
    if (!s.containsKey(recipe)) return;
    final l = Set.of(s[recipe]!);
    if (l.contains(item)) {
      l.remove(item);
    } else {
      l.add(item);
    }
    s[recipe] = l;
    emit(state.copyWith(selectedItems: s));
  }

  void remove(RecipePlan recipe) {
    final s = Map.of(state.selectedItems);
    if (!s.containsKey(recipe)) return;
    s[recipe] = {};
    emit(state.copyWith(selectedItems: s));
  }

  void add(RecipePlan recipe) {
    final s = Map.of(state.selectedItems);
    if (!s.containsKey(recipe)) return;
    s[recipe] = Set.of(recipe.recipeWithYields.mandatoryItems);
    emit(state.copyWith(selectedItems: s));
  }

  void toggleHidePastPlans() {
    final newHide = !state.hidePastPlans;
    if (newHide) {
      final s = Map.of(state.selectedItems);
      for (final plan in s.keys) {
        if (_isPastPlan(plan)) s[plan] = {};
      }
      emit(state.copyWith(hidePastPlans: newHide, selectedItems: s));
    } else {
      emit(state.copyWith(hidePastPlans: newHide));
    }
  }

  List<RecipeItem> getResult() {
    return state.getResult();
  }
}

class ItemSelectionState extends Equatable {
  final List<RecipePlan> plans;
  final Map<RecipePlan, Set<RecipeItem>> selectedItems;
  final bool hidePastPlans;

  ItemSelectionState(
    this.plans, {
    this.hidePastPlans = true,
  }) : selectedItems = Map.fromEntries(
          plans.map((plan) {
            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);
            var isPast = false;
            if (plan.cookingDate != null && !plan.isWithoutPlannedDay) {
              final planDay = DateTime(
                plan.cookingDate!.year,
                plan.cookingDate!.month,
                plan.cookingDate!.day,
              );
              isPast = planDay.isBefore(today);
            }
            return MapEntry(
              plan,
              isPast
                  ? <RecipeItem>{}
                  : plan.recipeWithYields.mandatoryItems.toSet(),
            );
          }),
        );

  const ItemSelectionState._({
    required this.plans,
    required this.selectedItems,
    required this.hidePastPlans,
  });

  ItemSelectionState copyWith({
    List<RecipePlan>? plans,
    Map<RecipePlan, Set<RecipeItem>>? selectedItems,
    bool? hidePastPlans,
  }) =>
      ItemSelectionState._(
        plans: plans ?? this.plans,
        selectedItems: selectedItems ?? this.selectedItems,
        hidePastPlans: hidePastPlans ?? this.hidePastPlans,
      );

  List<RecipePlan> get filteredPlans {
    if (!hidePastPlans) return plans;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return plans.where((plan) {
      if (plan.cookingDate == null || plan.isWithoutPlannedDay) return true;
      final planDay = DateTime(
        plan.cookingDate!.year,
        plan.cookingDate!.month,
        plan.cookingDate!.day,
      );
      return !planDay.isBefore(today);
    }).toList();
  }

  @override
  List<Object?> get props => [plans, selectedItems, hidePastPlans];

  List<RecipeItem> getResult() {
    return selectedItems.values.expand((e) => e).toList();
  }
}
