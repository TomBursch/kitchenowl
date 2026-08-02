import 'package:kitchenowl/models/model.dart';

enum AgentPersonaScope {
  global,
  private;

  static AgentPersonaScope fromString(String? value) {
    switch (value) {
      case 'private':
        return AgentPersonaScope.private;
      case 'global':
      default:
        return AgentPersonaScope.global;
    }
  }
}

class AgentPersona extends Model {
  final int id;
  final int householdId;
  final int? userId;
  final String name;
  final String? icon;
  final String? systemPrompt;
  final String? initialGreeting;
  final double? temperature;
  final bool isDefaultGlobal;

  const AgentPersona({
    required this.id,
    required this.householdId,
    this.userId,
    required this.name,
    this.icon,
    this.systemPrompt,
    this.initialGreeting,
    this.temperature,
    this.isDefaultGlobal = false,
  });

  AgentPersonaScope get scope =>
      userId == null ? AgentPersonaScope.global : AgentPersonaScope.private;

  factory AgentPersona.fromJson(Map<String, dynamic> map) => AgentPersona(
        id: map['id'] as int,
        householdId: map['household_id'] as int,
        userId: map['user_id'] as int?,
        name: map['name'] as String,
        icon: map['icon'] as String?,
        systemPrompt: map['system_prompt'] as String?,
        initialGreeting: map['initial_greeting'] as String?,
        temperature: (map['temperature'] as num?)?.toDouble(),
        isDefaultGlobal: map['is_default_global'] as bool? ?? false,
      );

  AgentPersona copyWith({
    String? name,
    String? icon,
    String? systemPrompt,
    String? initialGreeting,
    double? temperature,
    bool? isDefaultGlobal,
  }) =>
      AgentPersona(
        id: id,
        householdId: householdId,
        userId: userId,
        name: name ?? this.name,
        icon: icon ?? this.icon,
        systemPrompt: systemPrompt ?? this.systemPrompt,
        initialGreeting: initialGreeting ?? this.initialGreeting,
        temperature: temperature ?? this.temperature,
        isDefaultGlobal: isDefaultGlobal ?? this.isDefaultGlobal,
      );

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'household_id': householdId,
        'name': name,
        'icon': icon,
        'system_prompt': systemPrompt,
        'initial_greeting': initialGreeting,
        'temperature': temperature,
        'is_default_global': isDefaultGlobal,
      };

  @override
  List<Object?> get props => [
        id,
        householdId,
        userId,
        name,
        icon,
        systemPrompt,
        initialGreeting,
        temperature,
        isDefaultGlobal,
      ];
}
