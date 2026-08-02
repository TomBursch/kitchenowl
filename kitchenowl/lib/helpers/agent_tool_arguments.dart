import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/agent_chat.dart';
import 'package:kitchenowl/models/agent_persona.dart';

/// Builds a lookup map from tool-call-id -> argument map by scanning all
/// assistant messages for their [AgentMessage.toolCallsJson].
///
/// The JSON is expected to be an OpenAI-style tool-calls array:
/// ```json
/// [{"id": "call_xxx", "function": {"name": "...", "arguments": "{...}"}}]
/// ```
Map<String, Map<String, dynamic>> buildToolArgumentsIndex(
  List<AgentMessage> messages,
) {
  final result = <String, Map<String, dynamic>>{};
  for (final msg in messages) {
    final raw = msg.toolCallsJson;
    if (raw == null || raw.isEmpty) continue;
    try {
      final calls = jsonDecode(raw) as List;
      for (final call in calls) {
        if (call is! Map) continue;
        final id = call['id'] as String?;
        final fn = call['function'];
        if (id == null || fn is! Map) continue;
        final argsRaw = fn['arguments'];
        if (argsRaw == null) continue;
        try {
          final args = argsRaw is String
              ? Map<String, dynamic>.from(jsonDecode(argsRaw) as Map)
              : Map<String, dynamic>.from(argsRaw as Map);
          result[id] = args;
        } catch (_) {}
      }
    } catch (_) {}
  }
  return result;
}

/// Returns the [IconData] that best represents [persona].
/// Falls back to a generic bot icon when [persona] is null or has no icon.
IconData personaIconFor(AgentPersona? persona) {
  if (persona == null) return Icons.smart_toy_outlined;
  return personaIconForKey(persona.icon);
}

/// Returns the [IconData] for a persona icon catalog key. Used by the
/// persona icon picker as well as [personaIconFor].
IconData personaIconForKey(String? key) {
  switch ((key ?? '').toLowerCase()) {
    case 'chef':
    case 'edelkoch':
      return Icons.restaurant;
    case 'family':
    case 'familie':
      return Icons.family_restroom;
    case 'quick':
    case 'schnell':
      return Icons.bolt;
    case 'vegan':
    case 'vegetarian':
    case 'eco':
      return Icons.eco_outlined;
    case 'baking':
    case 'dessert':
      return Icons.cake_outlined;
    case 'bot':
    case 'robot':
      return Icons.smart_toy_outlined;
    default:
      return Icons.person_outline;
  }
}

/// Catalog entry for a persona icon: a stable [key] persisted in the
/// backend, the [icon] used to render it, and a localization helper that
/// returns a human-readable label for the picker UI.
class AgentPersonaIconChoice {
  final String key;
  final IconData icon;
  final String Function(AppLocalizations loc) label;

  const AgentPersonaIconChoice(this.key, this.icon, this.label);
}

/// Ordered catalog of icons offered by the persona icon picker. The keys
/// must match those handled by [personaIconForKey] above.
const List<AgentPersonaIconChoice> agentPersonaIconCatalog =
    <AgentPersonaIconChoice>[
  AgentPersonaIconChoice('default', Icons.person_outline, _labelDefault),
  AgentPersonaIconChoice('chef', Icons.restaurant, _labelChef),
  AgentPersonaIconChoice('family', Icons.family_restroom, _labelFamily),
  AgentPersonaIconChoice('quick', Icons.bolt, _labelQuick),
  AgentPersonaIconChoice('vegan', Icons.eco_outlined, _labelVegan),
  AgentPersonaIconChoice('baking', Icons.cake_outlined, _labelBaking),
  AgentPersonaIconChoice('bot', Icons.smart_toy_outlined, _labelBot),
];

String _labelDefault(AppLocalizations loc) => loc.agentPersonaIconDefault;
String _labelChef(AppLocalizations loc) => loc.agentPersonaIconChef;
String _labelFamily(AppLocalizations loc) => loc.agentPersonaIconFamily;
String _labelQuick(AppLocalizations loc) => loc.agentPersonaIconQuick;
String _labelVegan(AppLocalizations loc) => loc.agentPersonaIconVegan;
String _labelBaking(AppLocalizations loc) => loc.agentPersonaIconBaking;
String _labelBot(AppLocalizations loc) => loc.agentPersonaIconBot;
