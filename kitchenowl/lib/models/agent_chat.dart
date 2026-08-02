import 'package:equatable/equatable.dart';
import 'package:kitchenowl/models/model.dart';

/// Parses a JSON datetime field that the backend serializes as UTC
/// milliseconds since epoch (see ``KitchenOwlJSONProvider``). Falls back
/// to ``DateTime.tryParse`` when an older backend still sends an ISO
/// string. The result is always tz-aware UTC, so callers can safely
/// ``.toLocal()`` for display.
DateTime? _parseUtcDateTime(dynamic raw) {
  if (raw == null) return null;
  if (raw is int) {
    return DateTime.fromMillisecondsSinceEpoch(raw, isUtc: true);
  }
  if (raw is double) {
    return DateTime.fromMillisecondsSinceEpoch(raw.round(), isUtc: true);
  }
  if (raw is String) {
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return null;
    // ``DateTime.tryParse`` treats a string without a tz suffix as local
    // time. The server sends UTC, so reinterpret naive results as UTC.
    return parsed.isUtc
        ? parsed
        : DateTime.utc(
            parsed.year,
            parsed.month,
            parsed.day,
            parsed.hour,
            parsed.minute,
            parsed.second,
            parsed.millisecond,
            parsed.microsecond,
          );
  }
  return null;
}

class AgentFileAttachment extends Equatable {
  final String id;
  final String filename;
  final String? mimeType;
  final int? size;
  final DateTime? uploadedAt;

  const AgentFileAttachment({
    required this.id,
    required this.filename,
    this.mimeType,
    this.size,
    this.uploadedAt,
  });

  factory AgentFileAttachment.fromJson(Map<String, dynamic> map) {
    final uploadedAt = _parseUtcDateTime(map['uploaded_at']);

    return AgentFileAttachment(
      id: (map['id'] as String?) ?? '',
      filename: (map['filename'] as String?) ?? (map['id'] as String?) ?? '',
      mimeType: map['mime_type'] as String?,
      size: map['size'] as int?,
      uploadedAt: uploadedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'filename': filename,
        'mime_type': mimeType,
        'size': size,
        'uploaded_at': uploadedAt?.toIso8601String(),
      };

  @override
  List<Object?> get props => [id, filename, mimeType, size, uploadedAt];
}

class AgentMessageAttachments extends Equatable {
  final List<int> recipeIds;
  final List<int> itemIds;
  final List<AgentFileAttachment> files;

  const AgentMessageAttachments({
    this.recipeIds = const [],
    this.itemIds = const [],
    this.files = const [],
  });

  bool get isEmpty => recipeIds.isEmpty && itemIds.isEmpty && files.isEmpty;

  factory AgentMessageAttachments.fromJson(Map<String, dynamic>? map) {
    if (map == null) return const AgentMessageAttachments();
    final r = map['recipe_ids'];
    final i = map['item_ids'];
    final f = map['files'];
    return AgentMessageAttachments(
      recipeIds: r is List ? r.whereType<int>().toList() : const [],
      itemIds: i is List ? i.whereType<int>().toList() : const [],
      files: f is List
          ? f
              .whereType<Map>()
              .map((e) =>
                  AgentFileAttachment.fromJson(Map<String, dynamic>.from(e)))
              .where((e) => e.id.isNotEmpty)
              .toList()
          : const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'recipe_ids': recipeIds,
        'item_ids': itemIds,
        'files': files.map((f) => f.toJson()).toList(),
      };

  @override
  List<Object?> get props => [recipeIds, itemIds, files];
}

enum AgentMessageRole {
  system,
  user,
  assistant,
  tool;

  static AgentMessageRole fromString(String? value) {
    switch (value) {
      case 'system':
        return AgentMessageRole.system;
      case 'user':
        return AgentMessageRole.user;
      case 'tool':
        return AgentMessageRole.tool;
      case 'assistant':
      default:
        return AgentMessageRole.assistant;
    }
  }
}

class AgentMessage extends Model {
  final int? id;
  final int? chatId;
  final AgentMessageRole role;
  final String? content;
  final String? toolName;
  final String? toolCallId;
  final String? toolCallsJson;
  final int? createdRecipeId;
  final bool hasUndo;
  final bool requiresConfirmation;
  final DateTime? createdAt;
  final AgentMessageAttachments attachments;

  const AgentMessage({
    this.id,
    this.chatId,
    required this.role,
    this.content,
    this.toolName,
    this.toolCallId,
    this.toolCallsJson,
    this.createdRecipeId,
    this.hasUndo = false,
    this.requiresConfirmation = false,
    this.createdAt,
    this.attachments = const AgentMessageAttachments(),
  });

  factory AgentMessage.fromJson(Map<String, dynamic> map) {
    final parsed = _parseUtcDateTime(map['created_at']);
    return AgentMessage(
      id: map['id'],
      chatId: map['chat_id'],
      role: AgentMessageRole.fromString(map['role'] as String?),
      content: map['content'] as String?,
      toolName: map['tool_name'] as String?,
      toolCallId: map['tool_call_id'] as String?,
      toolCallsJson: map['tool_calls'] as String?,
      createdRecipeId: map['created_recipe_id'] as int?,
      hasUndo: map['has_undo'] as bool? ?? false,
      requiresConfirmation: map['requires_confirmation'] as bool? ?? false,
      createdAt: parsed,
      attachments: AgentMessageAttachments.fromJson(
        map['attachments'] is Map
            ? Map<String, dynamic>.from(map['attachments'] as Map)
            : null,
      ),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        "role": role.name,
        "content": content,
        "tool_name": toolName,
        "tool_call_id": toolCallId,
        "created_recipe_id": createdRecipeId,
      };

  @override
  List<Object?> get props => [
        id,
        chatId,
        role,
        content,
        toolName,
        toolCallId,
        toolCallsJson,
        createdRecipeId,
        hasUndo,
        requiresConfirmation,
        createdAt,
        attachments,
      ];
}

enum AgentRecipeCardSource {
  existing,
  created,
  proposed;

  static AgentRecipeCardSource fromString(String? value) {
    switch (value) {
      case 'created':
        return AgentRecipeCardSource.created;
      case 'proposed':
        return AgentRecipeCardSource.proposed;
      case 'existing':
      default:
        return AgentRecipeCardSource.existing;
    }
  }
}

class AgentRecipeCard extends Model {
  final int id;
  final int chatId;
  final int? recipeId;
  final AgentRecipeCardSource source;
  final String? title;
  final String? description;
  final String? groupLabel;
  final bool closed;

  const AgentRecipeCard({
    required this.id,
    required this.chatId,
    required this.source,
    this.recipeId,
    this.title,
    this.description,
    this.groupLabel,
    this.closed = false,
  });

  factory AgentRecipeCard.fromJson(Map<String, dynamic> map) => AgentRecipeCard(
        id: map['id'] as int,
        chatId: map['chat_id'] as int,
        recipeId: map['recipe_id'] as int?,
        source: AgentRecipeCardSource.fromString(map['source'] as String?),
        title: map['title'] as String?,
        description: map['description'] as String?,
        groupLabel: map['group_label'] as String?,
        closed: map['closed'] as bool? ?? false,
      );

  AgentRecipeCard copyWith({
    String? groupLabel,
    bool clearGroup = false,
  }) =>
      AgentRecipeCard(
        id: id,
        chatId: chatId,
        source: source,
        recipeId: recipeId,
        title: title,
        description: description,
        groupLabel: clearGroup ? null : (groupLabel ?? this.groupLabel),
        closed: closed,
      );

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'chat_id': chatId,
        'recipe_id': recipeId,
        'source': source.name,
        'title': title,
        'description': description,
        'group_label': groupLabel,
        'closed': closed,
      };

  @override
  List<Object?> get props =>
      [id, chatId, recipeId, source, title, description, groupLabel, closed];
}

class AgentChat extends Model {
  final int? id;
  final int? householdId;
  final int? userId;
  final String? title;
  final bool titleLocked;
  final bool titleAuto;
  final int? personaId;
  final int messageCount;
  final String? lastUserMessage;
  final DateTime? updatedAt;
  final DateTime? lastMessageAt;
  final List<AgentMessage> messages;
  final List<AgentRecipeCard> cards;

  const AgentChat({
    this.id,
    this.householdId,
    this.userId,
    this.title,
    this.titleLocked = false,
    this.titleAuto = true,
    this.personaId,
    this.messageCount = 0,
    this.lastUserMessage,
    this.updatedAt,
    this.lastMessageAt,
    this.messages = const [],
    this.cards = const [],
  });

  /// Timestamp shown in the chat list. Prefers the timestamp of the most
  /// recent message so renames / persona changes do not visually "bump"
  /// every chat to the same time. Falls back to the chat row's
  /// ``updated_at`` when the server did not provide one (older backend).
  DateTime? get displayTimestamp => lastMessageAt ?? updatedAt;

  factory AgentChat.fromJson(Map<String, dynamic> map) {
    final parsed = _parseUtcDateTime(map['updated_at']);
    final lastMsg = _parseUtcDateTime(map['last_message_at']);

    final rawMsgs = map['messages'];
    final rawCards = map['cards'];
    return AgentChat(
      id: map['id'],
      householdId: map['household_id'],
      userId: map['user_id'],
      title: map['title'] as String?,
      titleLocked: map['title_locked'] as bool? ?? false,
      titleAuto: map['title_auto'] as bool? ?? true,
      personaId: map['persona_id'] as int?,
      messageCount: map['message_count'] as int? ?? 0,
      lastUserMessage: map['last_user_message'] as String?,
      updatedAt: parsed,
      lastMessageAt: lastMsg,
      messages: rawMsgs is List
          ? rawMsgs
              .whereType<Map>()
              .map((e) => AgentMessage.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
      cards: rawCards is List
          ? rawCards
              .whereType<Map>()
              .map(
                  (e) => AgentRecipeCard.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
    );
  }

  AgentChat copyWith({
    String? title,
    bool? titleLocked,
    bool? titleAuto,
    int? personaId,
    bool clearPersona = false,
  }) =>
      AgentChat(
        id: id,
        householdId: householdId,
        userId: userId,
        title: title ?? this.title,
        titleLocked: titleLocked ?? this.titleLocked,
        titleAuto: titleAuto ?? this.titleAuto,
        personaId: clearPersona ? null : (personaId ?? this.personaId),
        messageCount: messageCount,
        lastUserMessage: lastUserMessage,
        updatedAt: updatedAt,
        lastMessageAt: lastMessageAt,
        messages: messages,
        cards: cards,
      );

  AgentChat withCards(List<AgentRecipeCard> newCards) => AgentChat(
        id: id,
        householdId: householdId,
        userId: userId,
        title: title,
        titleLocked: titleLocked,
        titleAuto: titleAuto,
        personaId: personaId,
        messageCount: messageCount,
        lastUserMessage: lastUserMessage,
        updatedAt: updatedAt,
        lastMessageAt: lastMessageAt,
        messages: messages,
        cards: newCards,
      );

  AgentChat withMessages(List<AgentMessage> newMessages) => AgentChat(
        id: id,
        householdId: householdId,
        userId: userId,
        title: title,
        titleLocked: titleLocked,
        titleAuto: titleAuto,
        personaId: personaId,
        messageCount: newMessages.length,
        lastUserMessage: newMessages
            .lastWhere(
              (m) => m.role == AgentMessageRole.user,
              orElse: () =>
                  const AgentMessage(role: AgentMessageRole.assistant),
            )
            .content,
        updatedAt: updatedAt,
        lastMessageAt: lastMessageAt,
        messages: newMessages,
        cards: cards,
      );

  @override
  Map<String, dynamic> toJson() => {
        "id": id,
        "title": title,
      };

  @override
  List<Object?> get props => [
        id,
        householdId,
        userId,
        title,
        titleLocked,
        titleAuto,
        personaId,
        messageCount,
        lastUserMessage,
        updatedAt,
        lastMessageAt,
        messages,
        cards,
      ];
}
