import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kitchenowl/cubits/agent_chat_list_cubit.dart';
import 'package:kitchenowl/cubits/auth_cubit.dart';
import 'package:kitchenowl/cubits/household_cubit.dart';
import 'package:kitchenowl/helpers/agent_tool_arguments.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/agent_chat.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/pages/agent_settings_page.dart';
import 'package:kitchenowl/widgets/agent_new_chat_fab.dart';

class AgentChatListPage extends StatelessWidget {
  const AgentChatListPage({super.key});

  Future<void> _openSettings(BuildContext context, Household household) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AgentSettingsPage(household: household),
      ),
    );
  }

  Widget _settingsActionBar(
    BuildContext context,
    Household household,
  ) {
    final loc = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(top: 4, right: 4),
      child: Row(
        children: [
          const Spacer(),
          IconButton(
            tooltip: loc.agentSettings,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _openSettings(context, household),
          ),
        ],
      ),
    );
  }

  List<_ChatGroup> _groupChatsByDay(List<AgentChat> chats, DateTime now) {
    final sorted = [...chats]
      ..sort((a, b) {
        final ad = a.displayTimestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bd = b.displayTimestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bd.compareTo(ad);
      });

    final buckets = <_ChatBucket, List<AgentChat>>{
      _ChatBucket.today: [],
      _ChatBucket.yesterday: [],
      _ChatBucket.twoDaysAgo: [],
      _ChatBucket.older: [],
    };

    for (final chat in sorted) {
      final bucket = _bucketForDate(chat.displayTimestamp, now);
      buckets[bucket]!.add(chat);
    }

    return [
      for (final bucket in _ChatBucket.values)
        if (buckets[bucket]!.isNotEmpty)
          _ChatGroup(bucket: bucket, chats: buckets[bucket]!),
    ];
  }

  _ChatBucket _bucketForDate(DateTime? date, DateTime now) {
    if (date == null) return _ChatBucket.older;
    final local = date.toLocal();
    final nowLocal = now.toLocal();
    final today = DateTime(nowLocal.year, nowLocal.month, nowLocal.day);
    final chatDay = DateTime(local.year, local.month, local.day);
    final diffDays = today.difference(chatDay).inDays;

    if (diffDays <= 0) return _ChatBucket.today;
    if (diffDays == 1) return _ChatBucket.yesterday;
    if (diffDays == 2) return _ChatBucket.twoDaysAgo;
    return _ChatBucket.older;
  }

  String _bucketLabel(BuildContext context, _ChatBucket bucket) {
    final loc = AppLocalizations.of(context)!;
    switch (bucket) {
      case _ChatBucket.today:
        return loc.agentBucketToday;
      case _ChatBucket.yesterday:
        return loc.agentBucketYesterday;
      case _ChatBucket.twoDaysAgo:
        final code = Localizations.localeOf(context).languageCode;
        return code == 'de' ? 'Vor 2 Tagen' : '2 days ago';
      case _ChatBucket.older:
        return loc.agentBucketOlder;
    }
  }

  String _formatLastUpdated(BuildContext context, DateTime? updatedAt) {
    if (updatedAt == null) return '';
    final loc = AppLocalizations.of(context)!;
    final local = updatedAt.toLocal();
    final now = DateTime.now().toLocal();
    final dayNow = DateTime(now.year, now.month, now.day);
    final dayChat = DateTime(local.year, local.month, local.day);
    final diffDays = dayNow.difference(dayChat).inDays;
    final time = MaterialLocalizations.of(context)
        .formatTimeOfDay(TimeOfDay.fromDateTime(local));

    if (diffDays == 0) return time;
    if (diffDays == 1) return '${loc.yesterday}, $time';
    return '${MaterialLocalizations.of(context).formatShortDate(local)}, $time';
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return BlocBuilder<AgentChatListCubit, AgentChatListState>(
      builder: (context, state) {
        final cubit = context.read<AgentChatListCubit>();
        final household =
            context.read<HouseholdCubit>().state.household;
        final isOffline =
            context.watch<AuthCubit>().state.isOffline;
        final showFab = state.agentReady && !isOffline;

        return Scaffold(
          backgroundColor: Colors.transparent,
          floatingActionButton: showFab
              ? AgentNewChatFab(
                  personaId:
                      state.filterPersonaId ?? state.userDefaultPersonaId,
                )
              : null,
          body: _buildBody(context, state, cubit, household, loc),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    AgentChatListState state,
    AgentChatListCubit cubit,
    Household household,
    AppLocalizations loc,
  ) {
    if (state.loading && state.chats.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!state.agentReady) {
      return SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _settingsActionBar(context, household),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    loc.agentNotConfigured,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final chats = state.visibleChats;
    final groupedChats = _groupChatsByDay(chats, DateTime.now());
    final hasFilter =
        state.filterPersonaId != null || state.search.trim().isNotEmpty;

    return SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Compact menu: search bar + persona filter + settings in one row
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: loc.agentSearchChats,
                          prefixIcon: const Icon(Icons.search),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        onChanged: cubit.setSearch,
                      ),
                    ),
                    if (state.personas.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      // NOTE: PopupMenuButton treats a `null` selection value
                      // as a "menu dismissed" event and never invokes
                      // `onSelected`. We therefore use a non-null sentinel
                      // (`_kFilterAllSentinel`) for the "All" entry so that
                      // clearing the persona filter actually works.
                      PopupMenuButton<int>(
                        tooltip: 'Filter',
                        icon: Icon(
                          state.filterPersonaId != null
                              ? Icons.filter_alt
                              : Icons.filter_alt_outlined,
                        ),
                        onSelected: (value) => cubit.setFilterPersona(
                          value == _kFilterAllSentinel ? null : value,
                        ),
                        itemBuilder: (ctx) => [
                          PopupMenuItem<int>(
                            value: _kFilterAllSentinel,
                            child: Row(
                              children: [
                                const Icon(Icons.clear, size: 18),
                                const SizedBox(width: 8),
                                Text(loc.agentFilterAll),
                              ],
                            ),
                          ),
                          const PopupMenuDivider(),
                          for (final p in state.personas)
                            PopupMenuItem<int>(
                              value: p.id,
                              child: Row(
                                children: [
                                  Icon(personaIconFor(p), size: 18),
                                  const SizedBox(width: 8),
                                  Text(p.name),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(width: 4),
                    IconButton(
                      tooltip: loc.agentSettings,
                      icon: const Icon(Icons.settings_outlined),
                      onPressed: () => _openSettings(context, household),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: chats.isEmpty
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Spacer(),
                          Icon(
                            Icons.forum_outlined,
                            size: 64,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              hasFilter
                                  ? loc.agentNoChatsForFilter
                                  : loc.agentNoChats,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ),
                          const Spacer(),
                        ],
                      )
                    : ListView(
                        children: [
                          for (final group in groupedChats) ...[
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                              child: Text(
                                _bucketLabel(context, group.bucket),
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            ),
                            for (final chat in group.chats)
                              Builder(
                                builder: (ctx) {
                                  final persona = state.personas
                                      .cast<dynamic>()
                                      .firstWhere(
                                        (p) => p.id == chat.personaId,
                                        orElse: () => null,
                                      );
                                  final timestampText = _formatLastUpdated(
                                      context, chat.displayTimestamp);
                                  return ListTile(
                                    contentPadding: const EdgeInsets.fromLTRB(
                                        16, 0, 4, 0),
                                    leading: CircleAvatar(
                                      child: Icon(personaIconFor(persona)),
                                    ),
                                    title: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.baseline,
                                      textBaseline: TextBaseline.alphabetic,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            chat.title?.isNotEmpty == true
                                                ? chat.title!
                                                : loc.agentChat,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (timestampText.isNotEmpty) ...[
                                          const SizedBox(width: 8),
                                          Text(
                                            timestampText,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall,
                                          ),
                                        ],
                                      ],
                                    ),
                                    subtitle:
                                        chat.lastUserMessage?.isNotEmpty == true
                                            ? Text(
                                                chat.lastUserMessage!,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              )
                                            : null,
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        PopupMenuButton<_ChatAction>(
                                          tooltip: loc.more,
                                          icon: const Icon(Icons.more_vert),
                                          onSelected: (value) async {
                                            switch (value) {
                                              case _ChatAction.rename:
                                                await _renameChat(
                                                  context,
                                                  cubit,
                                                  chat,
                                                  loc,
                                                );
                                                break;
                                              case _ChatAction.delete:
                                                await _confirmDelete(
                                                  context,
                                                  cubit,
                                                  chat,
                                                  loc,
                                                );
                                                break;
                                            }
                                          },
                                          itemBuilder: (ctx) => [
                                            PopupMenuItem<_ChatAction>(
                                              value: _ChatAction.rename,
                                              child: Row(
                                                children: [
                                                  const Icon(
                                                    Icons.edit_outlined,
                                                    size: 18,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(loc.agentRenameChat),
                                                ],
                                              ),
                                            ),
                                            PopupMenuItem<_ChatAction>(
                                              value: _ChatAction.delete,
                                              child: Row(
                                                children: [
                                                  const Icon(
                                                    Icons.delete_outline,
                                                    size: 18,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(loc.agentDeleteChat),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    onTap: () => context.push(
                                      '/household/${household.id}/agent/${chat.id}',
                                      extra: household,
                                    ),
                                  );
                                },
                              ),
                          ],
                          const SizedBox(height: 12),
                        ],
                      ),
              ),
            ],
          ),
        );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    AgentChatListCubit cubit,
    AgentChat chat,
    AppLocalizations loc,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.agentDeleteChat),
        content: Text(loc.agentDeleteChatConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(loc.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(loc.delete),
          ),
        ],
      ),
    );
    if (confirmed == true && chat.id != null) {
      await cubit.deleteChat(chat.id!);
    }
  }

  Future<void> _renameChat(
    BuildContext context,
    AgentChatListCubit cubit,
    AgentChat chat,
    AppLocalizations loc,
  ) async {
    if (chat.id == null) return;
    final controller = TextEditingController(text: chat.title ?? '');
    final result = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.agentRenameChat),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: loc.agentChatTitleHint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(''),
            child: Text(loc.agentResetTitle),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: Text(loc.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: Text(loc.save),
          ),
        ],
      ),
    );
    if (result == null) return;
    await cubit.renameChat(chat.id!, result);
  }
}

/// Sentinel used by the persona filter popup menu to represent the
/// "All personas" choice. Cannot collide with a real persona id (those are
/// non-negative auto-increment integers from the backend).
const int _kFilterAllSentinel = -1;

enum _ChatBucket {
  today,
  yesterday,
  twoDaysAgo,
  older,
}

enum _ChatAction {
  rename,
  delete,
}

class _ChatGroup {
  final _ChatBucket bucket;
  final List<AgentChat> chats;

  const _ChatGroup({
    required this.bucket,
    required this.chats,
  });
}
