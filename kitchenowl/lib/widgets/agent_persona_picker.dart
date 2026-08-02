import 'package:flutter/material.dart';
import 'package:kitchenowl/helpers/agent_tool_arguments.dart';
import 'package:kitchenowl/models/agent_persona.dart';

/// A horizontal chip-list that lets the user pick one of the available
/// [personas]. The currently selected persona is highlighted. Tapping the
/// active chip again deselects it (calls [onChanged] with `null`).
class AgentPersonaPicker extends StatelessWidget {
  final List<AgentPersona> personas;
  final int? selectedId;
  final ValueChanged<int?> onChanged;

  const AgentPersonaPicker({
    super.key,
    required this.personas,
    this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (personas.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        for (final p in personas)
          ChoiceChip(
            avatar: Icon(personaIconFor(p), size: 18),
            label: Text(p.name),
            selected: p.id == selectedId,
            onSelected: (_) =>
                onChanged(p.id == selectedId ? null : p.id),
          ),
      ],
    );
  }
}
