part of '../agent_chat_page.dart';

enum _UndoMode { edit, regenerate }

class _UndoDialogResult {
  final List<int> skipUndoIds;
  final String? newContent;

  const _UndoDialogResult({required this.skipUndoIds, this.newContent});
}

class _AgentUndoDialog extends StatefulWidget {
  final _UndoMode mode;
  final AgentRewindPreview preview;
  final String? initialContent;

  const _AgentUndoDialog({
    required this.mode,
    required this.preview,
    this.initialContent,
  });

  @override
  State<_AgentUndoDialog> createState() => _AgentUndoDialogState();
}

class _AgentUndoDialogState extends State<_AgentUndoDialog> {
  late final Map<int, bool> _applyUndo;
  late final TextEditingController _editCtrl;

  @override
  void initState() {
    super.initState();
    _applyUndo = {
      for (final p in widget.preview.preview) p.messageId: p.reversible,
    };
    _editCtrl = TextEditingController(text: widget.initialContent ?? '');
  }

  @override
  void dispose() {
    _editCtrl.dispose();
    super.dispose();
  }

  String? _reasonLabel(BuildContext context, String? reason) {
    final loc = AppLocalizations.of(context)!;
    switch (reason) {
      case 'conflict':
        return loc.agentUndoConflict;
      case 'irreversible':
        return loc.agentUndoIrreversible;
      case 'missing':
        return loc.agentUndoMissing;
      case 'failed':
        return loc.agentUndoFailed;
      default:
        return null;
    }
  }

  String _description(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    switch (widget.mode) {
      case _UndoMode.edit:
        return loc.agentEditDescription;
      case _UndoMode.regenerate:
        return loc.agentRegenerateDescription;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final items = widget.preview.preview;
    final isEdit = widget.mode == _UndoMode.edit;

    return AlertDialog(
      title: Text(loc.agentUndoTitle),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_description(context)),
              if (isEdit) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _editCtrl,
                  autofocus: true,
                  maxLines: 5,
                  minLines: 2,
                  decoration: InputDecoration(
                    labelText: loc.agentEditedMessage,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              if (items.isEmpty)
                Text(
                  loc.agentUndoEmpty,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                )
              else
                ...items.map((item) {
                  final reasonText = _reasonLabel(context, item.reason);
                  final apply = _applyUndo[item.messageId] ?? false;
                  return CheckboxListTile(
                    value: apply,
                    onChanged: item.reversible
                        ? (v) => setState(
                              () => _applyUndo[item.messageId] = v ?? false,
                            )
                        : null,
                    title: Text(
                      item.entityName.isNotEmpty ? item.entityName : item.tool,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      reasonText ?? item.tool,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: item.reversible
                            ? theme.colorScheme.onSurfaceVariant
                            : theme.colorScheme.error,
                      ),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  );
                }),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(loc.cancel),
        ),
        FilledButton(
          onPressed: () {
            if (isEdit) {
              final newText = _editCtrl.text.trim();
              if (newText.isEmpty) return;
            }
            final skip = <int>[
              for (final entry in _applyUndo.entries)
                if (!entry.value) entry.key,
            ];
            Navigator.of(context).pop(_UndoDialogResult(
              skipUndoIds: skip,
              newContent: isEdit ? _editCtrl.text : null,
            ));
          },
          child: Text(isEdit ? loc.send : loc.confirm),
        ),
      ],
    );
  }
}
