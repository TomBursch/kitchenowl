import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/models/recipe.dart';
import 'package:kitchenowl/services/api/api_service.dart';

typedef AiRecipeReply = ({
  Recipe recipe,
  int promptTokens,
  int completionTokens,
});

class RecipeGenerateCubit extends Cubit<RecipeGenerateState> {
  final Household household;
  int _requestId = 0;

  RecipeGenerateCubit(this.household) : super(const RecipeGenerateState());

  /// Returns true on success, false on error and null if aborted
  Future<bool?> send(String text) async {
    final requestId = ++_requestId;
    final previous = state.entries;
    final entries = [...previous, text];
    emit(RecipeGenerateState(entries: entries, loading: true));

    final res = await ApiService.getInstance().generateRecipe(
      household,
      entries
          .map((e) => e is AiRecipeReply
              ? {'role': 'assistant', 'content': jsonEncode(e.recipe.toJson())}
              : {'role': 'user', 'content': e as String})
          .toList(),
    );
    if (isClosed || requestId != _requestId) return null;
    if (res == null) {
      emit(RecipeGenerateState(entries: previous));
      return false;
    }
    emit(RecipeGenerateState(entries: [
      ...entries,
      (recipe: res.$1, promptTokens: res.$2, completionTokens: res.$3),
    ]));
    return true;
  }

  /// Drops the pending request and returns the user message that was sent
  // ponytail: client-side abort only, the server still finishes (and bills) the LLM call; real cancellation needs a streaming endpoint
  String? abort() {
    if (!state.loading) return null;
    _requestId++;
    final text = state.entries.last as String;
    emit(RecipeGenerateState(
      entries: state.entries.sublist(0, state.entries.length - 1),
    ));
    return text;
  }
}

class RecipeGenerateState extends Equatable {
  /// User messages (String) and AI replies (AiRecipeReply) in chat order
  final List<Object> entries;
  final bool loading;

  const RecipeGenerateState({this.entries = const [], this.loading = false});

  int get totalTokens => entries
      .whereType<AiRecipeReply>()
      .fold(0, (sum, e) => sum + e.promptTokens + e.completionTokens);

  @override
  List<Object?> get props => [entries, loading];
}
