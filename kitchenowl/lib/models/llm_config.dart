import 'package:kitchenowl/models/model.dart';

/// Mirrors the backend ``LLMProviderType`` enum.
enum LLMProvider {
  openai('openai'),
  gemini('gemini'),
  custom('custom');

  final String value;
  const LLMProvider(this.value);

  static LLMProvider fromString(String? value) {
    return LLMProvider.values.firstWhere(
      (p) => p.value == value,
      orElse: () => LLMProvider.openai,
    );
  }
}

class LLMConfig extends Model {
  final int? id;
  final int? householdId;
  final LLMProvider provider;
  final String? baseUrl;
  final String? model;
  final String? systemPrompt;
  final String? initialGreeting;
  final bool enabled;
  final bool apiKeySet;
  final bool braveSearchApiKeySet;
  final int? maxTokens;
  final double? temperature;
  final String? defaultBaseUrl;
  final String? effectiveBaseUrl;

  const LLMConfig({
    this.id,
    this.householdId,
    this.provider = LLMProvider.openai,
    this.baseUrl,
    this.model,
    this.systemPrompt,
    this.initialGreeting,
    this.enabled = false,
    this.apiKeySet = false,
    this.braveSearchApiKeySet = false,
    this.maxTokens,
    this.temperature,
    this.defaultBaseUrl,
    this.effectiveBaseUrl,
  });

  factory LLMConfig.fromJson(Map<String, dynamic> map) {
    return LLMConfig(
      id: map['id'],
      householdId: map['household_id'],
      provider: LLMProvider.fromString(map['provider'] as String?),
      baseUrl: map['base_url'] as String?,
      model: map['model'] as String?,
      systemPrompt: map['system_prompt'] as String?,
      initialGreeting: map['initial_greeting'] as String?,
      enabled: map['enabled'] as bool? ?? false,
      apiKeySet: map['api_key_set'] as bool? ?? false,
      braveSearchApiKeySet: map['brave_search_api_key_set'] as bool? ?? false,
      maxTokens: map['max_tokens'] as int?,
      temperature: (map['temperature'] as num?)?.toDouble(),
      defaultBaseUrl: map['default_base_url'] as String?,
      effectiveBaseUrl: map['effective_base_url'] as String?,
    );
  }

  /// Whether the config has the minimum needed to call the LLM.
  bool get isReady => enabled && (model?.isNotEmpty ?? false) && apiKeySet;

  LLMConfig copyWith({
    LLMProvider? provider,
    String? baseUrl,
    String? model,
    String? systemPrompt,
    String? initialGreeting,
    bool? enabled,
    bool? apiKeySet,
    bool? braveSearchApiKeySet,
    int? maxTokens,
    double? temperature,
  }) =>
      LLMConfig(
        id: id,
        householdId: householdId,
        provider: provider ?? this.provider,
        baseUrl: baseUrl ?? this.baseUrl,
        model: model ?? this.model,
        systemPrompt: systemPrompt ?? this.systemPrompt,
        initialGreeting: initialGreeting ?? this.initialGreeting,
        enabled: enabled ?? this.enabled,
        apiKeySet: apiKeySet ?? this.apiKeySet,
        braveSearchApiKeySet: braveSearchApiKeySet ?? this.braveSearchApiKeySet,
        maxTokens: maxTokens ?? this.maxTokens,
        temperature: temperature ?? this.temperature,
        defaultBaseUrl: defaultBaseUrl,
        effectiveBaseUrl: effectiveBaseUrl,
      );

  @override
  Map<String, dynamic> toJson() => {
        "provider": provider.value,
        "base_url": baseUrl,
        "model": model,
        "system_prompt": systemPrompt,
        "initial_greeting": initialGreeting,
        "enabled": enabled,
        "max_tokens": maxTokens,
        "temperature": temperature,
      };

  @override
  List<Object?> get props => [
        id,
        householdId,
        provider,
        baseUrl,
        model,
        systemPrompt,
        initialGreeting,
        enabled,
        apiKeySet,
        braveSearchApiKeySet,
        maxTokens,
        temperature,
      ];
}
