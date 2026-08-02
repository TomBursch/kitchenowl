/// A single side-effect entry in the rewind/edit preview returned by the server.
class AgentUndoPreviewItem {
  final int messageId;
  final String tool;
  final String entityName;
  final bool reversible;
  final String? reason;

  const AgentUndoPreviewItem({
    required this.messageId,
    required this.tool,
    required this.entityName,
    required this.reversible,
    this.reason,
  });

  factory AgentUndoPreviewItem.fromJson(Map<String, dynamic> map) =>
      AgentUndoPreviewItem(
        messageId: map['message_id'] as int,
        tool: map['tool'] as String? ?? '',
        entityName: map['entity_name'] as String? ?? '',
        reversible: map['reversible'] as bool? ?? false,
        reason: map['reason'] as String?,
      );
}

/// The preview payload returned before the user confirms a rewind / edit /
/// regenerate. Contains the list of side-effects that would be undone along
/// with reversibility metadata.
class AgentRewindPreview {
  final List<AgentUndoPreviewItem> preview;

  const AgentRewindPreview({required this.preview});

  factory AgentRewindPreview.fromJson(Map<String, dynamic> map) {
    final raw = map['preview'];
    return AgentRewindPreview(
      preview: raw is List
          ? raw
              .whereType<Map>()
              .map((e) => AgentUndoPreviewItem.fromJson(
                    Map<String, dynamic>.from(e),
                  ))
              .toList()
          : const [],
    );
  }
}

/// A side-effect that was skipped (not undone) during a confirmed
/// rewind / edit / regenerate operation.
class AgentUndoSkipped {
  final int messageId;
  final String tool;
  final String entityName;
  final String? reason;

  const AgentUndoSkipped({
    required this.messageId,
    required this.tool,
    required this.entityName,
    this.reason,
  });

  factory AgentUndoSkipped.fromJson(Map<String, dynamic> map) =>
      AgentUndoSkipped(
        messageId: map['message_id'] as int,
        tool: map['tool'] as String? ?? '',
        entityName: map['entity_name'] as String? ?? '',
        reason: map['reason'] as String?,
      );
}
