import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/models/agent_chat.dart';
import 'package:kitchenowl/models/agent_persona.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/services/api/api_service.dart';

class AgentChatListState extends Equatable {
  final bool loading;
  final List<AgentChat> chats;
  final bool agentReady;
  final List<AgentPersona> personas;
  final int? userDefaultPersonaId;
  final String search;
  final int? filterPersonaId;

  const AgentChatListState({
    this.loading = false,
    this.chats = const [],
    this.agentReady = true,
    this.personas = const [],
    this.userDefaultPersonaId,
    this.search = '',
    this.filterPersonaId,
  });

  AgentChatListState copyWith({
    bool? loading,
    List<AgentChat>? chats,
    bool? agentReady,
    List<AgentPersona>? personas,
    int? userDefaultPersonaId,
    bool clearUserDefault = false,
    String? search,
    int? filterPersonaId,
    bool clearFilter = false,
  }) =>
      AgentChatListState(
        loading: loading ?? this.loading,
        chats: chats ?? this.chats,
        agentReady: agentReady ?? this.agentReady,
        personas: personas ?? this.personas,
        userDefaultPersonaId: clearUserDefault
            ? null
            : (userDefaultPersonaId ?? this.userDefaultPersonaId),
        search: search ?? this.search,
        filterPersonaId:
            clearFilter ? null : (filterPersonaId ?? this.filterPersonaId),
      );

  /// Returns chats filtered by [search] and [filterPersonaId].
  List<AgentChat> get visibleChats {
    Iterable<AgentChat> result = chats;
    if (filterPersonaId != null) {
      result = result.where((c) => c.personaId == filterPersonaId);
    }
    final q = search.trim().toLowerCase();
    if (q.isNotEmpty) {
      result = result.where((c) {
        final t = (c.title ?? '').toLowerCase();
        final last = (c.lastUserMessage ?? '').toLowerCase();
        return t.contains(q) || last.contains(q);
      });
    }
    return result.toList();
  }

  @override
  List<Object?> get props => [
        loading,
        chats,
        agentReady,
        personas,
        userDefaultPersonaId,
        search,
        filterPersonaId,
      ];
}

class AgentChatListCubit extends Cubit<AgentChatListState> {
  final Household household;

  AgentChatListCubit(this.household) : super(const AgentChatListState()) {
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
      if (updatedChat.id == null) return;

      // Update the chat in the current state
      final updated = state.chats
          .map((c) => c.id == updatedChat.id ? updatedChat : c)
          .toList();

      emit(state.copyWith(chats: updated));
    } catch (_) {
      // Silently ignore parsing errors
    }
  }

  Future<void> refresh() async {
    emit(state.copyWith(loading: true));
    final api = ApiService.getInstance();
    final config = await api.getAgentConfig(household);
    final ready = config?.isReady ?? false;
    // Preserve the previously known chats on transient API failures: a
    // null response (offline, 5xx, ...) must NOT clear the visible list,
    // otherwise the user sees their chats "disappear" on every flaky
    // refresh and only get them back on the next successful fetch.
    final fetched = await api.getAgentChats(household);
    final chats = fetched ?? state.chats;
    AgentPersonaList? personaList;
    if (ready) {
      personaList = await api.getAgentPersonas(household);
    }
    emit(AgentChatListState(
      loading: false,
      chats: chats,
      agentReady: ready,
      personas: personaList?.personas ?? state.personas,
      userDefaultPersonaId:
          personaList?.userDefaultPersonaId ?? state.userDefaultPersonaId,
      search: state.search,
      filterPersonaId: state.filterPersonaId,
    ));
  }

  /// Returns the new chat id, or `null` on failure.
  Future<int?> createChat({int? personaId}) async {
    final chat = await ApiService.getInstance()
        .createAgentChat(household, personaId: personaId);
    if (chat == null) return null;
    emit(state.copyWith(chats: [chat, ...state.chats]));
    return chat.id;
  }

  Future<void> deleteChat(int chatId) async {
    final ok = await ApiService.getInstance().deleteAgentChat(household, chatId);
    if (ok) {
      emit(state.copyWith(
        chats: state.chats.where((c) => c.id != chatId).toList(),
      ));
    }
  }

  Future<bool> renameChat(int chatId, String title) async {
    final res = await ApiService.getInstance()
        .renameAgentChat(household, chatId, title);
    if (res == null) return false;
    final updated = state.chats
        .map((c) => c.id == chatId
            ? c.copyWith(
                title: res.title,
                titleLocked: res.titleLocked,
                titleAuto: res.titleAuto,
              )
            : c)
        .toList();
    emit(state.copyWith(chats: updated));
    return true;
  }

  void setSearch(String value) => emit(state.copyWith(search: value));

  void setFilterPersona(int? personaId) {
    if (personaId == null) {
      emit(state.copyWith(clearFilter: true));
    } else {
      emit(state.copyWith(filterPersonaId: personaId));
    }
  }

  Future<void> setUserDefaultPersona(int? personaId) async {
    final ok = await ApiService.getInstance()
        .setUserDefaultAgentPersona(household, personaId);
    if (ok) {
      if (personaId == null) {
        emit(state.copyWith(clearUserDefault: true));
      } else {
        emit(state.copyWith(userDefaultPersonaId: personaId));
      }
    }
  }

  @override
  Future<void> close() async {
    ApiService.getInstance().offAgentChatUpdate(_handleAgentChatUpdate);
    return super.close();
  }
}
