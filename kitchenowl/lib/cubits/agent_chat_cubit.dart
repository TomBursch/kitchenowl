import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:kitchenowl/helpers/named_bytearray.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/models/agent_chat.dart';
import 'package:kitchenowl/models/agent_undo.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/services/api/api_service.dart';

class AgentChatState extends Equatable {
  final bool loading;
  final bool sending;
  final AgentChat? chat;
  final List<AgentMessage> messages;
  final String? error;
  final int? lastCreatedRecipeId;
  final List<AgentRecipeCard> cards;
  final List<int> attachedRecipeIds;
  final List<int> attachedItemIds;
  // Display names for the attachment chips. Kept in parallel to the id
  // lists so the composer can render "Pasta" instead of "#581". Missing
  // entries fall back to the id.
  final Map<int, String> attachedRecipeNames;
  final Map<int, String> attachedItemNames;
  final List<NamedByteArray> attachedFiles;
  // Last user message that failed or was cancelled. Kept around so the UI
  // can offer a persistent "Retry" affordance even after the optimistic
  // bubble is rolled back.
  final String? lastFailedUserMessage;
  final List<int> lastFailedRecipeIds;
  final List<int> lastFailedItemIds;
  final Map<int, String> lastFailedRecipeNames;
  final Map<int, String> lastFailedItemNames;
  final List<NamedByteArray> lastFailedFiles;

  const AgentChatState({
    this.loading = false,
    this.sending = false,
    this.chat,
    this.messages = const [],
    this.error,
    this.lastCreatedRecipeId,
    this.cards = const [],
    this.attachedRecipeIds = const [],
    this.attachedItemIds = const [],
    this.attachedRecipeNames = const {},
    this.attachedItemNames = const {},
    this.attachedFiles = const [],
    this.lastFailedUserMessage,
    this.lastFailedRecipeIds = const [],
    this.lastFailedItemIds = const [],
    this.lastFailedRecipeNames = const {},
    this.lastFailedItemNames = const {},
    this.lastFailedFiles = const [],
  });

  AgentChatState copyWith({
    bool? loading,
    bool? sending,
    AgentChat? chat,
    List<AgentMessage>? messages,
    String? error,
    int? lastCreatedRecipeId,
    List<AgentRecipeCard>? cards,
    List<int>? attachedRecipeIds,
    List<int>? attachedItemIds,
    Map<int, String>? attachedRecipeNames,
    Map<int, String>? attachedItemNames,
    List<NamedByteArray>? attachedFiles,
    String? lastFailedUserMessage,
    List<int>? lastFailedRecipeIds,
    List<int>? lastFailedItemIds,
    Map<int, String>? lastFailedRecipeNames,
    Map<int, String>? lastFailedItemNames,
    List<NamedByteArray>? lastFailedFiles,
    bool clearError = false,
    bool clearRecipe = false,
    bool clearAttachments = false,
    bool clearLastFailed = false,
  }) =>
      AgentChatState(
        loading: loading ?? this.loading,
        sending: sending ?? this.sending,
        chat: chat ?? this.chat,
        messages: messages ?? this.messages,
        error: clearError ? null : (error ?? this.error),
        lastCreatedRecipeId: clearRecipe
            ? null
            : (lastCreatedRecipeId ?? this.lastCreatedRecipeId),
        cards: cards ?? this.cards,
        attachedRecipeIds: clearAttachments
            ? const []
            : (attachedRecipeIds ?? this.attachedRecipeIds),
        attachedItemIds: clearAttachments
            ? const []
            : (attachedItemIds ?? this.attachedItemIds),
        attachedRecipeNames: clearAttachments
            ? const {}
            : (attachedRecipeNames ?? this.attachedRecipeNames),
        attachedItemNames: clearAttachments
            ? const {}
            : (attachedItemNames ?? this.attachedItemNames),
        attachedFiles:
            clearAttachments ? const [] : (attachedFiles ?? this.attachedFiles),
        lastFailedUserMessage: clearLastFailed
            ? null
            : (lastFailedUserMessage ?? this.lastFailedUserMessage),
        lastFailedRecipeIds: clearLastFailed
            ? const []
            : (lastFailedRecipeIds ?? this.lastFailedRecipeIds),
        lastFailedItemIds: clearLastFailed
            ? const []
            : (lastFailedItemIds ?? this.lastFailedItemIds),
        lastFailedRecipeNames: clearLastFailed
            ? const {}
            : (lastFailedRecipeNames ?? this.lastFailedRecipeNames),
        lastFailedItemNames: clearLastFailed
            ? const {}
            : (lastFailedItemNames ?? this.lastFailedItemNames),
        lastFailedFiles: clearLastFailed
            ? const []
            : (lastFailedFiles ?? this.lastFailedFiles),
      );

  /// True when the last send was cancelled or failed and a retry is
  /// available.
  bool get canRetryLast => !sending && lastFailedUserMessage != null;

  @override
  List<Object?> get props => [
        loading,
        sending,
        chat,
        messages,
        error,
        lastCreatedRecipeId,
        cards,
        attachedRecipeIds,
        attachedItemIds,
        attachedRecipeNames,
        attachedItemNames,
        attachedFiles,
        lastFailedUserMessage,
        lastFailedRecipeIds,
        lastFailedItemIds,
        lastFailedRecipeNames,
        lastFailedItemNames,
        lastFailedFiles,
      ];
}

class AgentChatCubit extends Cubit<AgentChatState> {
  final Household household;
  final int chatId;
  List<NamedByteArray> _inFlightFiles = const [];

  // Monotonic token incremented on every send. A response whose token does
  // not match [_sendSeq] when it returns is treated as cancelled — its
  // result is dropped on the floor. Combined with [_aborted] this gives us
  // a best-effort client-side cancel: the in-flight HTTP request still
  // completes server-side (no real abort wire), but the UI immediately
  // returns to an idle state.
  int _sendSeq = 0;
  bool _aborted = false;

  AgentChatCubit(this.household, this.chatId) : super(const AgentChatState()) {
    refresh();
    _setupEventListeners();
  }

  void _setupEventListeners() {
    // Listen for agent chat updates (rename, persona change, etc.)
    ApiService.getInstance().onAgentChatUpdate(_handleAgentChatUpdate);
  }

  void _handleAgentChatUpdate(dynamic data) {
    if (data is! Map) return;
    final chatData = data['chat'];
    if (chatData is! Map) return;

    try {
      final updatedChat = AgentChat.fromJson(
        Map<String, dynamic>.from(chatData),
      );
      // Only react to updates for the chat currently shown.
      if (updatedChat.id == null || updatedChat.id != state.chat?.id) return;

      // Update only metadata (title / persona / timestamps). Do NOT
      // overwrite ``messages`` / ``cards`` here -- the WebSocket payload
      // may race with optimistic local updates (an in-flight send) and
      // would otherwise drop the user's just-typed message bubble or any
      // recipe card the agent just produced.
      final current = state.chat;
      final merged = current == null
          ? updatedChat
          : current.copyWith(
              title: updatedChat.title,
              titleLocked: updatedChat.titleLocked,
              titleAuto: updatedChat.titleAuto,
              personaId: updatedChat.personaId,
              clearPersona: updatedChat.personaId == null,
            );
      emit(state.copyWith(chat: merged));
    } catch (_) {
      // Silently ignore parsing errors
    }
  }

  Future<void> refresh() async {
    emit(state.copyWith(loading: true, clearError: true));
    final chat = await ApiService.getInstance().getAgentChat(household, chatId);
    if (chat == null) {
      emit(state.copyWith(loading: false, error: 'load_failed'));
      return;
    }
    emit(AgentChatState(
      loading: false,
      chat: chat,
      messages: chat.messages,
      cards: chat.cards,
      attachedRecipeIds: state.attachedRecipeIds,
      attachedItemIds: state.attachedItemIds,
      attachedFiles: state.attachedFiles,
    ));
  }

  void addAttachedRecipe(int recipeId, {String? name}) {
    if (state.attachedRecipeIds.contains(recipeId)) return;
    final names = Map<int, String>.from(state.attachedRecipeNames);
    if (name != null && name.isNotEmpty) names[recipeId] = name;
    emit(state.copyWith(
      attachedRecipeIds: [...state.attachedRecipeIds, recipeId],
      attachedRecipeNames: names,
    ));
  }

  void removeAttachedRecipe(int recipeId) {
    final names = Map<int, String>.from(state.attachedRecipeNames)
      ..remove(recipeId);
    emit(state.copyWith(
      attachedRecipeIds:
          state.attachedRecipeIds.where((id) => id != recipeId).toList(),
      attachedRecipeNames: names,
    ));
  }

  void addAttachedItem(int itemId, {String? name}) {
    if (state.attachedItemIds.contains(itemId)) return;
    final names = Map<int, String>.from(state.attachedItemNames);
    if (name != null && name.isNotEmpty) names[itemId] = name;
    emit(state.copyWith(
      attachedItemIds: [...state.attachedItemIds, itemId],
      attachedItemNames: names,
    ));
  }

  void removeAttachedItem(int itemId) {
    final names = Map<int, String>.from(state.attachedItemNames)
      ..remove(itemId);
    emit(state.copyWith(
      attachedItemIds:
          state.attachedItemIds.where((id) => id != itemId).toList(),
      attachedItemNames: names,
    ));
  }

  void addAttachedFile(NamedByteArray file) {
    if (state.attachedFiles.any((f) => f.filename == file.filename)) return;
    emit(state.copyWith(attachedFiles: [...state.attachedFiles, file]));
  }

  void removeAttachedFile(String filename) {
    emit(state.copyWith(
      attachedFiles:
          state.attachedFiles.where((f) => f.filename != filename).toList(),
    ));
  }

  Future<void> closeCard(int cardId) async {
    // Optimistically remove the card.
    final remaining =
        state.cards.where((c) => c.id != cardId).toList(growable: false);
    emit(state.copyWith(cards: remaining));
    final ok = await ApiService.getInstance()
        .closeAgentChatCard(household, chatId, cardId);
    if (!ok) {
      // Roll back on failure by re-fetching.
      await reloadCards();
    }
  }

  Future<void> reloadCards() async {
    final cards =
        await ApiService.getInstance().getAgentChatCards(household, chatId);
    if (cards == null) return;
    emit(state.copyWith(cards: cards));
  }

  /// Attach an existing household recipe to this chat as a card.
  Future<bool> attachExistingRecipeAsCard(int recipeId,
      {String? groupLabel}) async {
    final card = await ApiService.getInstance().attachAgentChatRecipeCard(
      household,
      chatId,
      recipeId,
      groupLabel: groupLabel,
    );
    if (card == null) return false;
    // Replace if already present (id-match), else append.
    final next = state.cards.where((c) => c.id != card.id).toList()..add(card);
    emit(state.copyWith(cards: next));
    return true;
  }

  /// Update a card's group label. Pass an empty string or null to clear.
  Future<void> setCardGroup(int cardId, String? groupLabel) async {
    final clean = (groupLabel ?? '').trim();
    final updated = await ApiService.getInstance().updateAgentChatCard(
      household,
      chatId,
      cardId,
      groupLabel: clean,
    );
    if (updated == null) return;
    final next = state.cards
        .map((c) => c.id == cardId ? updated : c)
        .toList(growable: false);
    emit(state.copyWith(cards: next));
  }

  Future<void> sendMessage(String content) async {
    if (state.sending) return;
    final trimmed = content.trim();
    final attachedRecipeIds = List<int>.from(state.attachedRecipeIds);
    final attachedItemIds = List<int>.from(state.attachedItemIds);
    final attachedRecipeNames =
        Map<int, String>.from(state.attachedRecipeNames);
    final attachedItemNames = Map<int, String>.from(state.attachedItemNames);
    final attachedFiles = List<NamedByteArray>.from(state.attachedFiles);
    if (trimmed.isEmpty &&
        attachedRecipeIds.isEmpty &&
        attachedItemIds.isEmpty &&
        attachedFiles.isEmpty) {
      return;
    }

    // Optimistically append the user message so the UI reacts instantly.
    final optimistic = AgentMessage(
      role: AgentMessageRole.user,
      content: trimmed,
      attachments: AgentMessageAttachments(
        recipeIds: attachedRecipeIds,
        itemIds: attachedItemIds,
        files: attachedFiles
            .map(
              (f) => AgentFileAttachment(
                id: f.filename,
                filename: f.filename,
              ),
            )
            .toList(),
      ),
    );
    final mySeq = ++_sendSeq;
    _aborted = false;
    _inFlightFiles = attachedFiles;
    emit(state.copyWith(
      sending: true,
      messages: [...state.messages, optimistic],
      clearError: true,
      clearRecipe: true,
      clearAttachments: true,
      clearLastFailed: true,
    ));

    final uploadedFileIds = <String>[];
    for (final file in attachedFiles) {
      if (mySeq != _sendSeq || _aborted || isClosed) {
        _inFlightFiles = const [];
        return;
      }
      final uploaded = await ApiService.getInstance().uploadBytes(file);
      if (uploaded == null) {
        // Keep the optimistic user bubble visible so the user does not
        // get the impression their message was "lost" -- it just failed
        // to send. ``retryLastUserMessage`` removes it before resending
        // and the next ``refresh()`` reconciles with the server.
        emit(state.copyWith(
          sending: false,
          error: 'send_failed',
          attachedRecipeIds: attachedRecipeIds,
          attachedItemIds: attachedItemIds,
          attachedRecipeNames: attachedRecipeNames,
          attachedItemNames: attachedItemNames,
          attachedFiles: attachedFiles,
          lastFailedUserMessage: trimmed,
          lastFailedRecipeIds: attachedRecipeIds,
          lastFailedItemIds: attachedItemIds,
          lastFailedRecipeNames: attachedRecipeNames,
          lastFailedItemNames: attachedItemNames,
          lastFailedFiles: attachedFiles,
        ));
        _inFlightFiles = const [];
        return;
      }
      uploadedFileIds.add(uploaded);
    }

    if (mySeq != _sendSeq || _aborted || isClosed) {
      _inFlightFiles = const [];
      return;
    }

    final response = await ApiService.getInstance().postAgentMessage(
      household,
      chatId,
      trimmed,
      attachedRecipeIds: attachedRecipeIds.isEmpty ? null : attachedRecipeIds,
      attachedItemIds: attachedItemIds.isEmpty ? null : attachedItemIds,
      attachedFiles: uploadedFileIds.isEmpty ? null : uploadedFileIds,
    );

    // The send was cancelled while the request was in flight: the cubit
    // already rolled the optimistic message back and surfaced
    // ``error: 'cancelled'``. Drop the late response.
    if (mySeq != _sendSeq || _aborted || isClosed) {
      _inFlightFiles = const [];
      return;
    }

    if (response == null) {
      // Do NOT silently drop the optimistic bubble: the request may have
      // timed out client-side while the backend already persisted the
      // user message (and possibly the assistant reply). Keep the bubble
      // visible, surface a retry hint, and trigger a background refresh
      // so the server's authoritative state replaces the optimistic one
      // (or stays as-is if nothing was persisted). ``retryLastUserMessage``
      // removes the trailing bubble before resending to avoid duplicates.
      emit(state.copyWith(
        sending: false,
        error: 'send_failed',
        attachedRecipeIds: attachedRecipeIds,
        attachedItemIds: attachedItemIds,
        attachedRecipeNames: attachedRecipeNames,
        attachedItemNames: attachedItemNames,
        attachedFiles: attachedFiles,
        lastFailedUserMessage: trimmed,
        lastFailedRecipeIds: attachedRecipeIds,
        lastFailedItemIds: attachedItemIds,
        lastFailedRecipeNames: attachedRecipeNames,
        lastFailedItemNames: attachedItemNames,
        lastFailedFiles: attachedFiles,
      ));
      _inFlightFiles = const [];
      // Fire-and-forget reconcile; ignore errors (e.g. offline) -- the
      // user can pull-to-refresh later.
      // ignore: discarded_futures
      refresh();
      return;
    }

    // Replace the optimistic user message with the persisted ones returned
    // by the backend (which now include the assistant + tool messages).
    final without = state.messages.toList()..removeLast();
    final combined = [...without, ...response.messages];
    emit(state.copyWith(
      sending: false,
      chat: response.chat,
      messages: combined,
      lastCreatedRecipeId: response.createdRecipeId,
      clearLastFailed: true,
    ));
    _inFlightFiles = const [];
    // Refresh open cards in case the agent created or closed any.
    await reloadCards();
  }

  /// Cancel an in-flight send. Surfaces a ``'cancelled'`` error so the UI
  /// can offer a retry. The optimistic user bubble is intentionally kept
  /// visible: the underlying HTTP request is *not* aborted on the wire,
  /// so the backend may still persist the message. A background refresh
  /// reconciles the visible list with the server's authoritative state.
  void cancelSend() {
    if (!state.sending) return;
    _aborted = true;
    _sendSeq++;
    String? failedText;
    List<int> failedRecipes = state.attachedRecipeIds;
    List<int> failedItems = state.attachedItemIds;
    Map<int, String> failedRecipeNames = state.attachedRecipeNames;
    Map<int, String> failedItemNames = state.attachedItemNames;
    List<NamedByteArray> failedFiles = _inFlightFiles;
    if (state.messages.isNotEmpty &&
        state.messages.last.role == AgentMessageRole.user) {
      final last = state.messages.last;
      failedText = last.content;
      final att = last.attachments;
      failedRecipes = att.recipeIds;
      failedItems = att.itemIds;
    }
    emit(state.copyWith(
      sending: false,
      error: 'cancelled',
      lastFailedUserMessage: failedText,
      lastFailedRecipeIds: failedRecipes,
      lastFailedItemIds: failedItems,
      lastFailedRecipeNames: failedRecipeNames,
      lastFailedItemNames: failedItemNames,
      lastFailedFiles: failedFiles,
    ));
    _inFlightFiles = const [];
    // Fire-and-forget reconcile; if the backend did persist the message
    // (and possibly the assistant reply) it will replace the optimistic
    // bubble. Errors are swallowed -- the user can pull-to-refresh later.
    // ignore: discarded_futures
    refresh();
  }

  void clearRecipeNotification() {
    emit(state.copyWith(clearRecipe: true));
  }

  /// Manually rename the chat. Pass an empty string to clear the title.
  Future<bool> rename(String title) async {
    final res = await ApiService.getInstance()
        .renameAgentChat(household, chatId, title);
    if (res == null) return false;
    emit(state.copyWith(chat: res));
    return true;
  }

  /// Retry the most recent failed/cancelled user message. No-op if there
  /// isn't one (or a send is already in flight).
  Future<void> retryLastUserMessage() async {
    if (state.sending) return;
    final text = state.lastFailedUserMessage ??
        // Backwards compatibility for the older 'send_failed' path that
        // didn't populate lastFailedUserMessage: peek at the trailing
        // user message instead.
        (state.error != null &&
                state.messages.isNotEmpty &&
                state.messages.last.role == AgentMessageRole.user
            ? state.messages.last.content
            : null);
    final hasFailedAttachments = state.lastFailedRecipeIds.isNotEmpty ||
        state.lastFailedItemIds.isNotEmpty ||
        state.lastFailedFiles.isNotEmpty;
    if ((text == null || text.isEmpty) && !hasFailedAttachments) return;
    // Drop the trailing failed user bubble (kept around so the user could
    // see their message did not disappear) before resending, otherwise the
    // optimistic bubble added by ``sendMessage`` would duplicate it.
    final pruned = state.messages.toList();
    if (pruned.isNotEmpty && pruned.last.role == AgentMessageRole.user) {
      pruned.removeLast();
    }
    // Restore the last failed attachments so the retry mirrors the
    // original send 1:1.
    emit(state.copyWith(
      messages: pruned,
      attachedRecipeIds: state.lastFailedRecipeIds,
      attachedItemIds: state.lastFailedItemIds,
      attachedRecipeNames: state.lastFailedRecipeNames,
      attachedItemNames: state.lastFailedItemNames,
      attachedFiles: state.lastFailedFiles,
      clearError: true,
    ));
    await sendMessage(text ?? '');
  }

  Future<void> confirmToolCall(int messageId) async {
    if (state.sending) return;
    emit(state.copyWith(sending: true, clearError: true));
    final result = await ApiService.getInstance().confirmAgentToolCall(
      household,
      chatId,
      messageId,
    );
    if (result == null) {
      emit(state.copyWith(sending: false, error: 'tool_confirmation_failed'));
      return;
    }
    await refresh();
    emit(state.copyWith(sending: false, clearError: true));
  }

  /// Change the persona attached to this chat. Only allowed before the
  /// first user message has been sent — the backend rejects later
  /// changes. Returns ``true`` on success.
  Future<bool> changePersona(int? personaId) async {
    final hasUserMessages =
        state.messages.any((m) => m.role == AgentMessageRole.user);
    if (hasUserMessages) return false;
    final updated = await ApiService.getInstance().updateAgentChatPersona(
      household,
      chatId,
      personaId,
    );
    if (updated == null) return false;
    // The backend rewrites the seeded greeting to match the new persona, so
    // pull the refreshed messages along with the chat to keep the bubble
    // shown to the user in sync with the chosen persona.
    emit(state.copyWith(
      chat: updated,
      messages: updated.messages,
    ));
    return true;
  }

  // ----------------------------------------------- rewind / edit / regenerate

  /// Fetch the conflict-aware preview for rewinding to / editing [messageId].
  Future<AgentRewindPreview?> previewRewind(int messageId) =>
      ApiService.getInstance()
          .previewRewindAgentMessage(household, chatId, messageId);

  Future<AgentRewindPreview?> previewEdit(int messageId) =>
      ApiService.getInstance()
          .previewEditAgentMessage(household, chatId, messageId);

  Future<AgentRewindPreview?> previewRegenerate(int messageId) =>
      ApiService.getInstance()
          .previewRegenerateAgentMessage(household, chatId, messageId);

  /// Confirm a rewind. Returns the skipped-ops list so the UI can surface
  /// any conflicts; the cubit's own state is updated with the new messages.
  Future<List<AgentUndoSkipped>?> confirmRewind(
    int messageId, {
    List<int>? skipUndoMessageIds,
  }) async {
    final res = await ApiService.getInstance().confirmRewindAgentMessage(
      household,
      chatId,
      messageId,
      skipUndoMessageIds: skipUndoMessageIds,
    );
    if (res == null) {
      emit(state.copyWith(error: 'rewind_failed'));
      return null;
    }
    emit(state.copyWith(
      chat: res.chat,
      messages: res.messages,
      clearError: true,
      clearRecipe: true,
    ));
    return res.skipped;
  }

  /// Confirm an edit. Backend rewinds + replaces the user-message text but
  /// does NOT auto-rerun the agent; surface the new content and let the user
  /// re-send manually if desired.
  Future<List<AgentUndoSkipped>?> confirmEdit(
    int messageId,
    String newContent, {
    List<int>? skipUndoMessageIds,
  }) async {
    final res = await ApiService.getInstance().confirmEditAgentMessage(
      household,
      chatId,
      messageId,
      newContent,
      skipUndoMessageIds: skipUndoMessageIds,
    );
    if (res == null) {
      emit(state.copyWith(error: 'edit_failed'));
      return null;
    }
    emit(state.copyWith(
      chat: res.chat,
      messages: res.messages,
      clearError: true,
      clearRecipe: true,
    ));
    return res.skipped;
  }

  /// Confirm regenerate: server returns only the new tail, so we replace the
  /// stale tail (everything from the regenerated assistant turn onwards).
  Future<List<AgentUndoSkipped>?> confirmRegenerate(
    int messageId, {
    List<int>? skipUndoMessageIds,
  }) async {
    emit(state.copyWith(sending: true, clearError: true, clearRecipe: true));
    final res = await ApiService.getInstance().confirmRegenerateAgentMessage(
      household,
      chatId,
      messageId,
      skipUndoMessageIds: skipUndoMessageIds,
    );
    if (res == null) {
      emit(state.copyWith(sending: false, error: 'regenerate_failed'));
      return null;
    }
    // The regenerate response is partial -- refresh from the server to get a
    // consistent message list rather than trying to splice client-side.
    await refresh();
    emit(state.copyWith(sending: false));
    return res.skipped;
  }

  @override
  Future<void> close() async {
    ApiService.getInstance().offAgentChatUpdate(_handleAgentChatUpdate);
    return super.close();
  }
}
