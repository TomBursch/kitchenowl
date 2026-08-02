import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/models/llm_config.dart';
import 'package:kitchenowl/services/api/api_service.dart';

class AgentSettingsState extends Equatable {
  final bool loading;
  final bool saving;
  final bool testing;
  final LLMConfig? config;
  final String? error;
  final String? testMessage;
  final bool? testOk;

  const AgentSettingsState({
    this.loading = false,
    this.saving = false,
    this.testing = false,
    this.config,
    this.error,
    this.testMessage,
    this.testOk,
  });

  AgentSettingsState copyWith({
    bool? loading,
    bool? saving,
    bool? testing,
    LLMConfig? config,
    String? error,
    String? testMessage,
    bool? testOk,
    bool clearTest = false,
    bool clearError = false,
  }) =>
      AgentSettingsState(
        loading: loading ?? this.loading,
        saving: saving ?? this.saving,
        testing: testing ?? this.testing,
        config: config ?? this.config,
        error: clearError ? null : (error ?? this.error),
        testMessage: clearTest ? null : (testMessage ?? this.testMessage),
        testOk: clearTest ? null : (testOk ?? this.testOk),
      );

  @override
  List<Object?> get props =>
      [loading, saving, testing, config, error, testMessage, testOk];
}

class AgentSettingsCubit extends Cubit<AgentSettingsState> {
  final Household household;

  AgentSettingsCubit(this.household) : super(const AgentSettingsState()) {
    refresh();
  }

  Future<void> refresh() async {
    emit(state.copyWith(loading: true, clearError: true, clearTest: true));
    final config = await ApiService.getInstance().getAgentConfig(household);
    emit(AgentSettingsState(loading: false, config: config));
  }

  Future<bool> save({
    LLMProvider? provider,
    String? baseUrl,
    String? model,
    String? apiKey,
    String? braveSearchApiKey,
    String? systemPrompt,
    String? initialGreeting,
    bool? enabled,
    int? maxTokens,
    double? temperature,
  }) async {
    emit(state.copyWith(saving: true, clearError: true, clearTest: true));
    final updated = await ApiService.getInstance().updateAgentConfig(
      household,
      provider: provider,
      baseUrl: baseUrl,
      model: model,
      apiKey: apiKey,
      braveSearchApiKey: braveSearchApiKey,
      systemPrompt: systemPrompt,
      initialGreeting: initialGreeting,
      enabled: enabled,
      maxTokens: maxTokens,
      temperature: temperature,
    );
    if (updated == null) {
      emit(state.copyWith(saving: false, error: 'save_failed'));
      return false;
    }
    emit(AgentSettingsState(saving: false, config: updated));
    return true;
  }

  Future<void> testConnection() async {
    emit(state.copyWith(testing: true, clearTest: true));
    final result = await ApiService.getInstance().testAgentConfig(household);
    emit(state.copyWith(
      testing: false,
      testOk: result.ok,
      testMessage: result.ok ? result.reply : result.error,
    ));
  }
}
