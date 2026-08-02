import 'dart:convert';

import 'package:kitchenowl/models/agent_chat.dart';
import 'package:kitchenowl/models/agent_persona.dart';
import 'package:kitchenowl/models/agent_undo.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/models/llm_config.dart';
import 'package:kitchenowl/services/api/api_service.dart';

class AgentTestResult {
  final bool ok;
  final String? reply;
  final String? error;

  const AgentTestResult({required this.ok, this.reply, this.error});
}

class AgentMessageResponse {
  final List<AgentMessage> messages;
  final AgentChat chat;

  const AgentMessageResponse({required this.messages, required this.chat});

  /// Recipe id created during this round of messages, if any.
  int? get createdRecipeId {
    for (final m in messages.reversed) {
      if (m.createdRecipeId != null) return m.createdRecipeId;
    }
    return null;
  }
}

/// Result of a confirmed rewind/edit/regenerate call. For rewind/edit
/// [messages] is the FULL chat after the operation; for regenerate it only
/// contains the freshly generated assistant/tool messages (see [isRegenerate]).
class AgentRewindResult {
  final AgentChat? chat;
  final List<AgentMessage> messages;
  final List<AgentUndoSkipped> skipped;
  final bool isRegenerate;

  const AgentRewindResult({
    required this.chat,
    required this.messages,
    required this.skipped,
    required this.isRegenerate,
  });
}

/// Tagged union: a rewind/edit/regenerate API call returns either a preview
/// or the post-confirm result. Inspect [preview] / [result] to disambiguate.
class AgentRewindOutcome {
  final AgentRewindPreview? preview;
  final AgentRewindResult? result;

  const AgentRewindOutcome._({this.preview, this.result});

  factory AgentRewindOutcome.preview(AgentRewindPreview p) =>
      AgentRewindOutcome._(preview: p);
  factory AgentRewindOutcome.result(AgentRewindResult r) =>
      AgentRewindOutcome._(result: r);

  bool get isPreview => preview != null;
}

extension AgentApi on ApiService {
  static const _agentSuffix = '/agent';

  String _agentBase(Household household) =>
      '${householdPath(household)}$_agentSuffix';

  // -------------------------------------------------------------- config

  Future<LLMConfig?> getAgentConfig(Household household) async {
    final res = await get('${_agentBase(household)}/config');
    if (res.statusCode != 200) return null;
    return LLMConfig.fromJson(jsonDecode(res.body));
  }

  Future<LLMConfig?> updateAgentConfig(
    Household household, {
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
    final body = <String, dynamic>{};
    if (provider != null) body['provider'] = provider.value;
    if (baseUrl != null) body['base_url'] = baseUrl;
    if (model != null) body['model'] = model;
    if (apiKey != null) body['api_key'] = apiKey;
    if (braveSearchApiKey != null) {
      body['brave_search_api_key'] = braveSearchApiKey;
    }
    if (systemPrompt != null) body['system_prompt'] = systemPrompt;
    if (initialGreeting != null) body['initial_greeting'] = initialGreeting;
    if (enabled != null) body['enabled'] = enabled;
    if (maxTokens != null) body['max_tokens'] = maxTokens;
    if (temperature != null) body['temperature'] = temperature;

    final res = await put('${_agentBase(household)}/config', jsonEncode(body));
    if (res.statusCode != 200) return null;
    return LLMConfig.fromJson(jsonDecode(res.body));
  }

  Future<AgentTestResult> testAgentConfig(Household household) async {
    final res = await post('${_agentBase(household)}/config/test', '');
    if (res.statusCode != 200) {
      return AgentTestResult(ok: false, error: 'HTTP ${res.statusCode}');
    }
    final body = Map<String, dynamic>.from(jsonDecode(res.body));
    return AgentTestResult(
      ok: body['ok'] == true,
      reply: body['reply'] as String?,
      error: body['error'] as String?,
    );
  }

  // -------------------------------------------------------------- chats

  Future<List<AgentChat>?> getAgentChats(Household household) async {
    final res = await get('${_agentBase(household)}/chats');
    if (res.statusCode != 200) return null;
    final body = List.from(jsonDecode(res.body));
    return body
        .map((e) => AgentChat.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<AgentChat?> createAgentChat(
    Household household, {
    String? title,
    int? personaId,
  }) async {
    final res = await post(
      '${_agentBase(household)}/chats',
      jsonEncode({
        if (title != null) 'title': title,
        if (personaId != null) 'persona_id': personaId,
      }),
    );
    if (res.statusCode != 200) return null;
    return AgentChat.fromJson(jsonDecode(res.body));
  }

  /// Manually rename a chat. Pass an empty string to clear the title and
  /// re-enable auto-rename.
  Future<AgentChat?> renameAgentChat(
    Household household,
    int chatId,
    String? title,
  ) async {
    final res = await patch(
      '${_agentBase(household)}/chats/$chatId',
      jsonEncode({'title': title}),
    );
    if (res.statusCode != 200) return null;
    return AgentChat.fromJson(jsonDecode(res.body));
  }

  /// Change the persona attached to a chat. Backend rejects the change
  /// once any user message exists in the chat. Pass ``null`` to clear the
  /// persona link.
  Future<AgentChat?> updateAgentChatPersona(
    Household household,
    int chatId,
    int? personaId,
  ) async {
    final res = await patch(
      '${_agentBase(household)}/chats/$chatId',
      jsonEncode({'persona_id': personaId}),
    );
    if (res.statusCode != 200) return null;
    return AgentChat.fromJson(jsonDecode(res.body));
  }

  Future<AgentChat?> getAgentChat(Household household, int chatId) async {
    final res = await get('${_agentBase(household)}/chats/$chatId');
    if (res.statusCode != 200) return null;
    return AgentChat.fromJson(jsonDecode(res.body));
  }

  Future<AgentMessageResponse?> postAgentMessage(
    Household household,
    int chatId,
    String content, {
    List<int>? attachedRecipeIds,
    List<int>? attachedItemIds,
    List<String>? attachedFiles,
  }) async {
    final body = <String, dynamic>{'content': content};
    if (attachedRecipeIds != null && attachedRecipeIds.isNotEmpty) {
      body['attached_recipe_ids'] = attachedRecipeIds;
    }
    if (attachedItemIds != null && attachedItemIds.isNotEmpty) {
      body['attached_item_ids'] = attachedItemIds;
    }
    if (attachedFiles != null && attachedFiles.isNotEmpty) {
      body['attached_files'] = attachedFiles;
    }
    final res = await post(
      '${_agentBase(household)}/chats/$chatId/messages',
      jsonEncode(body),
      // Agent calls can take a while when tools chain.
      timeout: const Duration(minutes: 2),
    );
    if (res.statusCode != 200) return null;
    final resBody = Map<String, dynamic>.from(jsonDecode(res.body));
    final rawMsgs = List.from(resBody['messages'] as List);
    final chat = AgentChat.fromJson(Map<String, dynamic>.from(resBody['chat']));
    return AgentMessageResponse(
      chat: chat,
      messages: rawMsgs
          .map((e) => AgentMessage.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }

  Future<AgentMessageResponse?> confirmAgentToolCall(
    Household household,
    int chatId,
    int messageId,
  ) async {
    final res = await post(
      '${_agentBase(household)}/chats/$chatId/messages/$messageId/confirm',
      '{}',
      timeout: const Duration(minutes: 2),
    );
    if (res.statusCode != 200) return null;
    final body = Map<String, dynamic>.from(jsonDecode(res.body));
    return AgentMessageResponse(
      chat: AgentChat.fromJson(Map<String, dynamic>.from(body['chat'])),
      messages: List.from(body['messages'] as List)
          .map((e) => AgentMessage.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }

  Future<bool> deleteAgentChat(Household household, int chatId) async {
    final res = await delete('${_agentBase(household)}/chats/$chatId');
    return res.statusCode == 200;
  }

  // ------------------------------------------------------ rewind/edit/regen

  /// One-shot result of a rewind/edit/regenerate confirmation. Either holds
  /// a [preview] (when ``confirm`` was not set) or the new chat state.
  ///
  /// Callers can switch on [isPreview] to disambiguate.
  Future<AgentRewindOutcome?> _patchAgentMessage(
    Household household,
    int chatId,
    int messageId, {
    required String action,
    String? newContent,
    bool confirm = false,
    List<int>? skipUndoMessageIds,
  }) async {
    final body = <String, dynamic>{'action': action};
    if (newContent != null) body['new_content'] = newContent;
    if (confirm) body['confirm'] = true;
    if (skipUndoMessageIds != null && skipUndoMessageIds.isNotEmpty) {
      body['skip_undo_message_ids'] = skipUndoMessageIds;
    }
    final res = await patch(
      '${_agentBase(household)}/chats/$chatId/messages/$messageId',
      jsonEncode(body),
      timeout: const Duration(minutes: 2),
    );
    if (res.statusCode != 200) return null;
    return _parseRewindOutcome(jsonDecode(res.body));
  }

  /// Preview: list which side-effects would be undone if rewinding to
  /// [messageId]. The server returns reversibility per side-effect so the UI
  /// can disable / explain blocked entries.
  Future<AgentRewindPreview?> previewRewindAgentMessage(
    Household household,
    int chatId,
    int messageId,
  ) async {
    final outcome = await _patchAgentMessage(
      household,
      chatId,
      messageId,
      action: 'rewind',
    );
    return outcome?.preview;
  }

  /// Confirm a rewind. Returns the post-rewind chat state and the list of
  /// side-effects that were skipped (with reason).
  Future<AgentRewindResult?> confirmRewindAgentMessage(
    Household household,
    int chatId,
    int messageId, {
    List<int>? skipUndoMessageIds,
  }) async {
    final outcome = await _patchAgentMessage(
      household,
      chatId,
      messageId,
      action: 'rewind',
      confirm: true,
      skipUndoMessageIds: skipUndoMessageIds,
    );
    return outcome?.result;
  }

  /// Preview an edit (same conflict info as rewind, since editing implicitly
  /// rewinds everything after the edited message).
  Future<AgentRewindPreview?> previewEditAgentMessage(
    Household household,
    int chatId,
    int messageId,
  ) async {
    final outcome = await _patchAgentMessage(
      household,
      chatId,
      messageId,
      action: 'edit',
    );
    return outcome?.preview;
  }

  /// Apply an edit: replaces the user message's content and undoes everything
  /// after it. Does NOT auto-rerun the agent -- the caller can follow up by
  /// posting a new message if desired.
  Future<AgentRewindResult?> confirmEditAgentMessage(
    Household household,
    int chatId,
    int messageId,
    String newContent, {
    List<int>? skipUndoMessageIds,
  }) async {
    final outcome = await _patchAgentMessage(
      household,
      chatId,
      messageId,
      action: 'edit',
      newContent: newContent,
      confirm: true,
      skipUndoMessageIds: skipUndoMessageIds,
    );
    return outcome?.result;
  }

  Future<AgentRewindOutcome?> _postRegenerate(
    Household household,
    int chatId,
    int messageId, {
    bool confirm = false,
    List<int>? skipUndoMessageIds,
  }) async {
    final body = <String, dynamic>{};
    if (confirm) body['confirm'] = true;
    if (skipUndoMessageIds != null && skipUndoMessageIds.isNotEmpty) {
      body['skip_undo_message_ids'] = skipUndoMessageIds;
    }
    final res = await post(
      '${_agentBase(household)}/chats/$chatId/messages/$messageId/regenerate',
      jsonEncode(body),
      timeout: const Duration(minutes: 2),
    );
    if (res.statusCode != 200) return null;
    return _parseRewindOutcome(jsonDecode(res.body), isRegenerate: true);
  }

  Future<AgentRewindPreview?> previewRegenerateAgentMessage(
    Household household,
    int chatId,
    int messageId,
  ) async {
    final outcome = await _postRegenerate(household, chatId, messageId);
    return outcome?.preview;
  }

  /// Confirm regenerate. The server replays the agent loop starting from the
  /// trailing user message, so the response only contains the freshly
  /// generated assistant + tool messages -- callers should append them to the
  /// surviving prefix.
  Future<AgentRewindResult?> confirmRegenerateAgentMessage(
    Household household,
    int chatId,
    int messageId, {
    List<int>? skipUndoMessageIds,
  }) async {
    final outcome = await _postRegenerate(
      household,
      chatId,
      messageId,
      confirm: true,
      skipUndoMessageIds: skipUndoMessageIds,
    );
    return outcome?.result;
  }

  AgentRewindOutcome _parseRewindOutcome(
    dynamic decoded, {
    bool isRegenerate = false,
  }) {
    final body = Map<String, dynamic>.from(decoded as Map);
    if (body.containsKey('preview')) {
      return AgentRewindOutcome.preview(AgentRewindPreview.fromJson(body));
    }
    final rawMsgs = (body['messages'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => AgentMessage.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    final chat = body['chat'] is Map
        ? AgentChat.fromJson(Map<String, dynamic>.from(body['chat'] as Map))
        : null;
    final skipped = (body['skipped'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => AgentUndoSkipped.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    return AgentRewindOutcome.result(
      AgentRewindResult(
        chat: chat,
        messages: rawMsgs,
        skipped: skipped,
        isRegenerate: isRegenerate,
      ),
    );
  }

  // ------------------------------------------------------------- personas

  Future<AgentPersonaList?> getAgentPersonas(Household household) async {
    final res = await get('${_agentBase(household)}/personas');
    if (res.statusCode != 200) return null;
    final body = Map<String, dynamic>.from(jsonDecode(res.body));
    final raw = List.from(body['personas'] as List);
    return AgentPersonaList(
      personas: raw
          .map((e) => AgentPersona.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      userDefaultPersonaId: body['user_default_persona_id'] as int?,
    );
  }

  Future<AgentPersona?> createAgentPersona(
    Household household, {
    required String name,
    required AgentPersonaScope scope,
    String? icon,
    String? systemPrompt,
    String? initialGreeting,
    double? temperature,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'scope': scope.name,
    };
    if (icon != null) body['icon'] = icon;
    if (systemPrompt != null) body['system_prompt'] = systemPrompt;
    if (initialGreeting != null) body['initial_greeting'] = initialGreeting;
    if (temperature != null) body['temperature'] = temperature;
    final res = await post(
      '${_agentBase(household)}/personas',
      jsonEncode(body),
    );
    if (res.statusCode != 200) return null;
    return AgentPersona.fromJson(jsonDecode(res.body));
  }

  Future<AgentPersona?> updateAgentPersona(
    Household household,
    int personaId, {
    String? name,
    String? icon,
    String? systemPrompt,
    String? initialGreeting,
    double? temperature,
    bool? isDefaultGlobal,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (icon != null) body['icon'] = icon;
    if (systemPrompt != null) body['system_prompt'] = systemPrompt;
    if (initialGreeting != null) body['initial_greeting'] = initialGreeting;
    if (temperature != null) body['temperature'] = temperature;
    if (isDefaultGlobal != null) body['is_default_global'] = isDefaultGlobal;
    final res = await patch(
      '${_agentBase(household)}/personas/$personaId',
      jsonEncode(body),
    );
    if (res.statusCode != 200) return null;
    return AgentPersona.fromJson(jsonDecode(res.body));
  }

  Future<bool> deleteAgentPersona(Household household, int personaId) async {
    final res = await delete('${_agentBase(household)}/personas/$personaId');
    return res.statusCode == 200;
  }

  /// Sets the calling user's default persona for ``household``. Pass null to
  /// clear it.
  Future<bool> setUserDefaultAgentPersona(
    Household household,
    int? personaId,
  ) async {
    final res = await put(
      '${_agentBase(household)}/personas/default',
      jsonEncode({'persona_id': personaId}),
    );
    return res.statusCode == 200;
  }

  // ----------------------------------------------------------- recipe cards

  Future<List<AgentRecipeCard>?> getAgentChatCards(
    Household household,
    int chatId,
  ) async {
    final res = await get('${_agentBase(household)}/chats/$chatId/cards');
    if (res.statusCode != 200) return null;
    final raw = jsonDecode(res.body);
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => AgentRecipeCard.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<bool> closeAgentChatCard(
    Household household,
    int chatId,
    int cardId,
  ) async {
    final res = await post(
      '${_agentBase(household)}/chats/$chatId/cards/$cardId/close',
      '',
    );
    return res.statusCode == 200;
  }

  /// Attach an existing household recipe to a chat as a recipe card.
  /// Returns the freshly created (or pre-existing) card.
  Future<AgentRecipeCard?> attachAgentChatRecipeCard(
    Household household,
    int chatId,
    int recipeId, {
    String? groupLabel,
  }) async {
    final body = <String, dynamic>{'recipe_id': recipeId};
    if (groupLabel != null) body['group_label'] = groupLabel;
    final res = await post(
      '${_agentBase(household)}/chats/$chatId/cards',
      jsonEncode(body),
    );
    if (res.statusCode != 200) return null;
    return AgentRecipeCard.fromJson(
      Map<String, dynamic>.from(jsonDecode(res.body) as Map),
    );
  }

  /// Update a card's group label and/or position. Pass an empty string for
  /// [groupLabel] to clear the group.
  Future<AgentRecipeCard?> updateAgentChatCard(
    Household household,
    int chatId,
    int cardId, {
    String? groupLabel,
    int? position,
  }) async {
    final body = <String, dynamic>{};
    if (groupLabel != null) body['group_label'] = groupLabel;
    if (position != null) body['position'] = position;
    if (body.isEmpty) return null;
    final res = await patch(
      '${_agentBase(household)}/chats/$chatId/cards/$cardId',
      jsonEncode(body),
    );
    if (res.statusCode != 200) return null;
    return AgentRecipeCard.fromJson(
      Map<String, dynamic>.from(jsonDecode(res.body) as Map),
    );
  }

  // -------------------------------------------------------------- WebSocket listeners

  /// Register a listener for agent chat updates (rename, persona change, etc).
  void onAgentChatUpdate(dynamic Function(dynamic) handler) {
    socket.on("agent_chat:update", handler);
  }

  /// Unregister a listener for agent chat updates.
  void offAgentChatUpdate(dynamic Function(dynamic) handler) {
    socket.off("agent_chat:update", handler);
  }
}

class AgentPersonaList {
  final List<AgentPersona> personas;
  final int? userDefaultPersonaId;

  const AgentPersonaList({
    required this.personas,
    this.userDefaultPersonaId,
  });
}
