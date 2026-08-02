import 'package:flutter/material.dart';
import 'package:kitchenowl/helpers/agent_tool_arguments.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/agent_persona.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/services/api/api_service.dart';

/// Displays the list of agent personas for the household and allows household
/// admins to create, edit, and delete them.
class AgentPersonasPage extends StatefulWidget {
  final Household household;

  const AgentPersonasPage({super.key, required this.household});

  @override
  State<AgentPersonasPage> createState() => _AgentPersonasPageState();
}

class _AgentPersonasPageState extends State<AgentPersonasPage> {
  List<AgentPersona> _personas = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result =
        await ApiService.getInstance().getAgentPersonas(widget.household);
    if (!mounted) return;
    setState(() {
      _personas = result?.personas ?? const [];
      _loading = false;
    });
  }

  Future<void> _delete(AgentPersona persona) async {
    final ok = await ApiService.getInstance()
        .deleteAgentPersona(widget.household, persona.id);
    if (ok && mounted) {
      setState(() => _personas.removeWhere((p) => p.id == persona.id));
    }
  }

  Future<void> _showEditDialog({AgentPersona? existing}) async {
    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (ctx) => _PersonaDialog(
        household: widget.household,
        existing: existing,
      ),
    );
    if (result == null || !mounted) return;
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.agentPersonas),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: loc.refresh,
            onPressed: _load,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEditDialog(),
        tooltip: loc.agentPersonaNew,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _personas.isEmpty
              ? Center(child: Text(loc.agentPersonaNone))
              : ListView.builder(
                  itemCount: _personas.length,
                  itemBuilder: (ctx, i) {
                    final p = _personas[i];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Icon(personaIconFor(p)),
                      ),
                      title: Text(p.name),
                      subtitle: p.isDefaultGlobal
                          ? Text(loc.agentPersonaGlobal)
                          : null,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => _showEditDialog(existing: p),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _delete(p),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}

class _PersonaDialog extends StatefulWidget {
  final Household household;
  final AgentPersona? existing;

  const _PersonaDialog({required this.household, this.existing});

  @override
  State<_PersonaDialog> createState() => _PersonaDialogState();
}

class _PersonaDialogState extends State<_PersonaDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _greetingCtrl;
  late final TextEditingController _promptCtrl;
  String? _selectedIconKey;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _selectedIconKey = _normalizeIconKey(e?.icon);
    _greetingCtrl = TextEditingController(text: e?.initialGreeting ?? '');
    _promptCtrl = TextEditingController(text: e?.systemPrompt ?? '');
  }

  /// Map any persisted icon string onto a key from
  /// [agentPersonaIconCatalog]. Returns ``null`` if the persona has no
  /// icon stored, falls back to ``'default'`` for unknown values so the
  /// picker still shows a selection.
  String? _normalizeIconKey(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final lower = raw.trim().toLowerCase();
    for (final c in agentPersonaIconCatalog) {
      if (c.key == lower) return c.key;
    }
    // Aliases handled by personaIconForKey but not in the catalog.
    const aliases = <String, String>{
      'edelkoch': 'chef',
      'familie': 'family',
      'schnell': 'quick',
      'vegetarian': 'vegan',
      'eco': 'vegan',
      'dessert': 'baking',
      'robot': 'bot',
    };
    return aliases[lower] ?? 'default';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _greetingCtrl.dispose();
    _promptCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _saving = true);
    final api = ApiService.getInstance();
    final iconKey =
        _selectedIconKey == null || _selectedIconKey == 'default'
            ? null
            : _selectedIconKey;
    if (widget.existing == null) {
      await api.createAgentPersona(
        widget.household,
        name: name,
        scope: AgentPersonaScope.global,
        icon: iconKey,
        initialGreeting: _greetingCtrl.text.trim().isEmpty
            ? null
            : _greetingCtrl.text.trim(),
        systemPrompt:
            _promptCtrl.text.trim().isEmpty ? null : _promptCtrl.text.trim(),
      );
    } else {
      await api.updateAgentPersona(
        widget.household,
        widget.existing!.id,
        name: name,
        icon: iconKey,
        initialGreeting: _greetingCtrl.text.trim().isEmpty
            ? null
            : _greetingCtrl.text.trim(),
        systemPrompt:
            _promptCtrl.text.trim().isEmpty ? null : _promptCtrl.text.trim(),
      );
    }
    if (!mounted) return;
    Navigator.of(context).pop(<String, dynamic>{});
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final isNew = widget.existing == null;
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(isNew ? loc.agentPersonaNew : loc.agentPersonaEdit),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameCtrl,
              autofocus: true,
              decoration: InputDecoration(labelText: loc.agentPersonaName),
            ),
            const SizedBox(height: 16),
            Text(
              loc.agentPersonaIcon,
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final choice in agentPersonaIconCatalog)
                  ChoiceChip(
                    avatar: Icon(
                      choice.icon,
                      size: 18,
                      color: _selectedIconKey == choice.key
                          ? theme.colorScheme.onSecondaryContainer
                          : theme.iconTheme.color,
                    ),
                    label: Text(choice.label(loc)),
                    selected: _selectedIconKey == choice.key,
                    onSelected: (sel) {
                      setState(() {
                        _selectedIconKey = sel ? choice.key : null;
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _greetingCtrl,
              decoration: InputDecoration(labelText: loc.agentInitialGreeting),
              minLines: 2,
              maxLines: 4,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _promptCtrl,
              decoration: InputDecoration(labelText: loc.agentPersonaSystemPrompt),
              minLines: 3,
              maxLines: 6,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(null),
          child: Text(loc.cancel),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(loc.save),
        ),
      ],
    );
  }
}
