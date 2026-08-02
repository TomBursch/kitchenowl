import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:kitchenowl/cubits/agent_chat_cubit.dart';
import 'package:kitchenowl/cubits/agent_chat_list_cubit.dart';
import 'package:kitchenowl/helpers/agent_tool_arguments.dart';
import 'package:kitchenowl/helpers/named_bytearray.dart';
import 'package:kitchenowl/helpers/recipe_item_markdown_extension.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/agent_chat.dart';
import 'package:kitchenowl/models/agent_persona.dart';
import 'package:kitchenowl/models/agent_undo.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/models/item.dart';
import 'package:kitchenowl/models/recipe.dart';
import 'package:kitchenowl/services/api/api_service.dart';
import 'package:kitchenowl/widgets/agent_tool_call_card.dart';
import 'package:kitchenowl/widgets/recipe_markdown_body.dart';
import 'package:kitchenowl/widgets/typing_indicator.dart';
import 'package:tuple/tuple.dart';

part 'agent_chat_page/undo_dialog.dart';
part 'agent_chat_page/composer.dart';

class AgentChatPage extends StatefulWidget {
  final Household household;
  final int chatId;

  const AgentChatPage({
    super.key,
    required this.household,
    required this.chatId,
  });

  @override
  State<AgentChatPage> createState() => _AgentChatPageState();
}

class _AgentChatPageState extends State<AgentChatPage> {
  late final AgentChatCubit _cubit;
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _showJumpToBottom = false;
  int _smallScreenTab = 0;

  // Width of the right-side recipe panel on wide layouts. Adjustable via
  // the vertical drag handle between the chat and the panel.
  static const double _kWideLayoutMinWidth = 1000;
  static const double _kChatMinWidth = 460;
  static const double _kPanelMinWidth = 280;
  static const double _kPanelMaxWidth = 640;
  static const double _kPanelDefaultWidth = 380;
  double _panelWidth = _kPanelDefaultWidth;

  // Maximum PDF file size accepted by the backend (AGENT_MAX_FILE_SIZE default: 20 MB).
  static const int _kMaxPdfFileSizeBytes = 20 * 1000 * 1000;

  @override
  void initState() {
    super.initState();
    _cubit = AgentChatCubit(widget.household, widget.chatId);
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _cubit.close();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    final position = _scrollCtrl.position;
    final farFromBottom = position.maxScrollExtent - position.pixels > 240;
    if (farFromBottom != _showJumpToBottom) {
      setState(() => _showJumpToBottom = farFromBottom);
    }
  }

  void _scrollToEnd({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      final target = _scrollCtrl.position.maxScrollExtent;
      if (animate) {
        _scrollCtrl.animateTo(
          target,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      } else {
        _scrollCtrl.jumpTo(target);
      }
    });
  }

  Future<void> _send() async {
    final text = _inputCtrl.text;
    final state = _cubit.state;
    final hasAttachments = state.attachedRecipeIds.isNotEmpty ||
        state.attachedItemIds.isNotEmpty ||
        state.attachedFiles.isNotEmpty;
    if (text.trim().isEmpty && !hasAttachments) return;
    _inputCtrl.clear();
    await _cubit.sendMessage(text);
    _scrollToEnd();
  }

  Future<void> _pickRecipe(BuildContext context) async {
    final loc = AppLocalizations.of(context)!;
    final picked = await showModalBottomSheet<Recipe>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _AgentRecipePickerSheet(
        household: widget.household,
        title: loc.agentAttachRecipe,
      ),
    );
    if (picked?.id != null) {
      _cubit.addAttachedRecipe(picked!.id!, name: picked.name);
    }
  }

  /// Pick a recipe from the household collection and pin it to the current
  /// chat as a recipe card on the right-side panel. Optionally prompts for
  /// a group label.
  Future<void> _attachExistingRecipeFromCollection() async {
    final loc = AppLocalizations.of(context)!;
    final picked = await showModalBottomSheet<Recipe>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _AgentRecipePickerSheet(
        household: widget.household,
        title: loc.agentRecipeAddFromCollection,
      ),
    );
    if (picked?.id == null) return;
    await _cubit.attachExistingRecipeAsCard(picked!.id!);
  }

  Future<void> _pickItem(BuildContext context) async {
    final loc = AppLocalizations.of(context)!;
    final picked = await showModalBottomSheet<ItemWithDescription>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _AgentItemPickerSheet(
        household: widget.household,
        title: loc.agentAttachItem,
      ),
    );
    if (picked?.id != null) {
      _cubit.addAttachedItem(picked!.id!, name: picked.name);
    }
  }

  Future<void> _pickImageAttachment(BuildContext context) async {
    final loc = AppLocalizations.of(context)!;
    final file = await selectFile(
      context: context,
      title: loc.agentAttachImage,
    );
    if (!context.mounted || file == null || file.isEmpty) return;
    _cubit.addAttachedFile(file);
  }

  Future<void> _pickPdfAttachment(BuildContext context) async {
    final loc = AppLocalizations.of(context)!;
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      withData: true,
    );
    if (!context.mounted) return;
    if (result == null || result.files.isEmpty) return;
    final picked = result.files.first;
    if ((picked.name).isEmpty ||
        picked.bytes == null ||
        picked.bytes!.isEmpty) {
      return;
    }
    // Guard against oversized files (aligned with the backend AGENT_MAX_FILE_SIZE
    // default of 20 MB) to avoid excessive memory usage and unnecessary uploads.
    if (picked.size > _kMaxPdfFileSizeBytes) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.agentFileTooLarge)),
      );
      return;
    }
    _cubit.addAttachedFile(NamedByteArray(picked.name, picked.bytes!));
  }

  Future<void> _renameDialog(BuildContext context, AgentChat? chat) async {
    if (chat == null) return;
    final loc = AppLocalizations.of(context)!;
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
    await _cubit.rename(result);
  }

  AgentPersona? _personaFor(int? id) {
    if (id == null) return null;
    final listState = context.read<AgentChatListCubit?>()?.state;
    if (listState == null) return null;
    for (final p in listState.personas) {
      if (p.id == id) return p;
    }
    return null;
  }

  Future<void> _showPersonaPicker(
    BuildContext context,
    AgentPersona? current,
  ) async {
    final loc = AppLocalizations.of(context)!;
    final listState = context.read<AgentChatListCubit?>()?.state;
    final personas = listState?.personas ?? const <AgentPersona>[];
    var wasPicked = false;
    final selected = await showModalBottomSheet<AgentPersona?>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Text(
                  loc.agentChoosePersona,
                  style: Theme.of(ctx).textTheme.titleMedium,
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final p in personas)
                      ListTile(
                        leading: CircleAvatar(child: Icon(personaIconFor(p))),
                        title: Text(p.name),
                        selected: current?.id == p.id,
                        onTap: () {
                          wasPicked = true;
                          Navigator.of(ctx).pop(p);
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
    if (!context.mounted || !wasPicked) return;
    if (selected?.id == current?.id) return;
    final ok = await _cubit.changePersona(selected?.id);
    if (!context.mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.error)),
      );
      return;
    }
    context.read<AgentChatListCubit?>()?.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return BlocProvider.value(
      value: _cubit,
      child: BlocBuilder<AgentChatCubit, AgentChatState>(
        builder: (context, state) {
          final persona = _personaFor(state.chat?.personaId);
          final title = state.chat?.title?.isNotEmpty == true
              ? state.chat!.title!
              : loc.agentChat;
          final isEmpty = !state.loading && state.messages.isEmpty;
          // Persona can be changed until the first user message has been
          // sent. The backend seeds an assistant greeting on chat create,
          // so checking ``messages.isEmpty`` is not enough.
          final noUserMessages =
              !state.messages.any((m) => m.role == AgentMessageRole.user);
          final personaListState = context.watch<AgentChatListCubit?>()?.state;
          // Only consider the persona switcher "available" once the chat
          // payload has been loaded; otherwise the banner briefly flashes
          // a default-persona label before the real chat data arrives.
          final canChangePersona = !state.loading &&
              state.chat != null &&
              noUserMessages &&
              (personaListState?.personas.isNotEmpty ?? false);

          return Scaffold(
            appBar: AppBar(
              titleSpacing: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                    return;
                  }
                  context.go('/household/${widget.household.id}/agent',
                      extra: widget.household);
                },
              ),
              title: LayoutBuilder(builder: (ctx, constraints) {
                final narrow = MediaQuery.of(ctx).size.width < 420;
                return InkWell(
                  onTap: () => _renameDialog(context, state.chat),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: narrow
                              ? Theme.of(ctx).textTheme.titleMedium
                              : Theme.of(ctx).textTheme.titleLarge,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.edit_outlined, size: narrow ? 14 : 16),
                    ],
                  ),
                );
              }),
              actions: [
                if (persona != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Center(
                      child: _PersonaChip(persona: persona),
                    ),
                  ),
              ],
            ),
            body: SafeArea(
              child: LayoutBuilder(builder: (context, constraints) {
                final wide = constraints.maxWidth >= _kWideLayoutMinWidth;
                final chatColumn = Column(
                  children: [
                    if (state.canRetryLast || state.error != null)
                      Material(
                        color: state.error == 'cancelled'
                            ? Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                            : Theme.of(context).colorScheme.errorContainer,
                        child: ListTile(
                          leading: Icon(
                            state.error == 'cancelled'
                                ? Icons.stop_circle_outlined
                                : Icons.error_outline,
                            color: state.error == 'cancelled'
                                ? Theme.of(context).colorScheme.onSurface
                                : Theme.of(context)
                                    .colorScheme
                                    .onErrorContainer,
                          ),
                          title: Text(
                            state.error == 'cancelled'
                                ? loc.agentSendCancelled
                                : loc.agentSendFailed,
                            style: TextStyle(
                              color: state.error == 'cancelled'
                                  ? Theme.of(context).colorScheme.onSurface
                                  : Theme.of(context)
                                      .colorScheme
                                      .onErrorContainer,
                            ),
                          ),
                          trailing: TextButton(
                            onPressed: state.sending || !state.canRetryLast
                                ? null
                                : () async {
                                    await _cubit.retryLastUserMessage();
                                    _scrollToEnd();
                                  },
                            child: Text(loc.retry),
                          ),
                        ),
                      ),
                    Expanded(
                      child: Stack(
                        children: [
                          if (state.loading && state.messages.isEmpty)
                            const Center(child: CircularProgressIndicator())
                          else if (isEmpty)
                            _EmptyChatHero(
                              persona: persona,
                              onPrompt: (s) async {
                                await _cubit.sendMessage(s);
                                _scrollToEnd();
                              },
                            )
                          else
                            Builder(builder: (context) {
                              final argsByCallId =
                                  buildToolArgumentsIndex(state.messages);
                              final lastAssistantIdx = state.messages
                                  .lastIndexWhere((m) =>
                                      m.role == AgentMessageRole.assistant);
                              return ListView.builder(
                                controller: _scrollCtrl,
                                padding:
                                    const EdgeInsets.fromLTRB(12, 12, 12, 12),
                                itemCount: state.messages.length +
                                    (state.sending ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index >= state.messages.length) {
                                    return const Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 8),
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: _AssistantTypingBubble(),
                                      ),
                                    );
                                  }
                                  final msg = state.messages[index];
                                  final isLastAssistant = !state.sending &&
                                      index == lastAssistantIdx &&
                                      msg.role == AgentMessageRole.assistant;
                                  return _MessageBubble(
                                    message: msg,
                                    household: widget.household,
                                    isLastAssistant: isLastAssistant,
                                    argumentsByToolCallId: argsByCallId,
                                    onSuggestionTap: (s) async {
                                      await _cubit.sendMessage(s);
                                      _scrollToEnd();
                                    },
                                    onConfirmToolCall: _cubit.confirmToolCall,
                                  );
                                },
                              );
                            }),
                          if (_showJumpToBottom)
                            Positioned(
                              right: 12,
                              bottom: 8,
                              child: FloatingActionButton.small(
                                onPressed: () => _scrollToEnd(),
                                child: const Icon(Icons.arrow_downward),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    if (canChangePersona)
                      _PersonaSwitcherBanner(
                        persona: persona,
                        onTap: () => _showPersonaPicker(context, persona),
                      ),
                    _Composer(
                      controller: _inputCtrl,
                      sending: state.sending,
                      onSubmit: _send,
                      onCancel: _cubit.cancelSend,
                      hint: loc.agentInputHint,
                      attachedRecipeIds: state.attachedRecipeIds,
                      attachedItemIds: state.attachedItemIds,
                      attachedRecipeNames: state.attachedRecipeNames,
                      attachedItemNames: state.attachedItemNames,
                      attachedFiles:
                          state.attachedFiles.map((f) => f.filename).toList(),
                      onRemoveRecipe: _cubit.removeAttachedRecipe,
                      onRemoveItem: _cubit.removeAttachedItem,
                      onRemoveFile: _cubit.removeAttachedFile,
                      onPickRecipe: () => _pickRecipe(context),
                      onPickItem: () => _pickItem(context),
                      onPickImage: () => _pickImageAttachment(context),
                      onPickPdf: () => _pickPdfAttachment(context),
                    ),
                  ],
                );
                final recipePanel = _AgentCardsPanel(
                  cards: state.cards,
                  household: widget.household,
                  onClose: _cubit.closeCard,
                  onAttachExisting: _attachExistingRecipeFromCollection,
                  onSetGroup: (cardId, label) =>
                      _cubit.setCardGroup(cardId, label),
                );
                if (!wide) {
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
                        child: SegmentedButton<int>(
                          showSelectedIcon: false,
                          segments: [
                            ButtonSegment<int>(
                              value: 0,
                              icon: const Icon(Icons.chat_bubble_outline),
                              label: Text(loc.agentChat),
                            ),
                            ButtonSegment<int>(
                              value: 1,
                              icon: const Icon(Icons.push_pin_outlined),
                              label: Text(loc.agentRecipePanel),
                            ),
                          ],
                          selected: {_smallScreenTab},
                          onSelectionChanged: (selected) {
                            setState(() => _smallScreenTab = selected.first);
                          },
                        ),
                      ),
                      const SizedBox(height: 6),
                      Expanded(
                        child: IndexedStack(
                          index: _smallScreenTab,
                          children: [
                            chatColumn,
                            recipePanel,
                          ],
                        ),
                      ),
                    ],
                  );
                }
                final maxPanelWidth = (constraints.maxWidth - _kChatMinWidth)
                    .clamp(_kPanelMinWidth, _kPanelMaxWidth);
                final clampedPanelWidth =
                    _panelWidth.clamp(_kPanelMinWidth, maxPanelWidth);
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: chatColumn),
                    _PanelResizeHandle(
                      tooltip: loc.agentResizePanel,
                      onDrag: (delta) {
                        setState(() {
                          _panelWidth = (_panelWidth - delta)
                              .clamp(_kPanelMinWidth, maxPanelWidth);
                        });
                      },
                    ),
                    SizedBox(
                      width: clampedPanelWidth,
                      child: recipePanel,
                    ),
                  ],
                );
              }),
            ),
          );
        },
      ),
    );
  }
}

/// Slim banner shown above the composer while no user message has been
/// sent yet, advertising that the chat's persona can still be changed.
/// Tapping it opens the persona picker bottom sheet on [AgentChatPage].
class _PersonaSwitcherBanner extends StatelessWidget {
  final AgentPersona? persona;
  final VoidCallback onTap;

  const _PersonaSwitcherBanner({
    required this.persona,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final label = persona?.name ?? loc.agentUseDefault;
    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Icon(personaIconFor(persona),
                  size: 18, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${loc.agentChoosePersona}: $label',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(Icons.swap_horiz,
                  size: 18, color: theme.colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyChatHero extends StatelessWidget {
  final AgentPersona? persona;
  final ValueChanged<String> onPrompt;

  const _EmptyChatHero({required this.persona, required this.onPrompt});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final greeting = persona?.initialGreeting?.isNotEmpty == true
        ? persona!.initialGreeting!
        : loc.agentEmptyChatGreeting;
    final prompts = <String>[
      loc.agentPromptQuickDinner,
      loc.agentPromptUseLeftovers,
      loc.agentPromptVegetarian,
      loc.agentPromptDessert,
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: theme.colorScheme.primaryContainer,
            foregroundColor: theme.colorScheme.onPrimaryContainer,
            child: Icon(personaIconFor(persona), size: 36),
          ),
          const SizedBox(height: 16),
          Text(
            persona?.name ?? loc.agent,
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            greeting,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final p in prompts)
                ActionChip(
                  label: Text(p),
                  onPressed: () => onPrompt(p),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AssistantTypingBubble extends StatelessWidget {
  const _AssistantTypingBubble();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
          bottomLeft: Radius.circular(4),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: TypingIndicator(color: theme.colorScheme.onSecondaryContainer),
    );
  }
}

/// AppBar chip showing the chat's current persona as a static label.
/// The persona is changed via the banner above the composer (see
/// [_PersonaSwitcherBanner]) while the chat still has no user messages.
class _PersonaChip extends StatelessWidget {
  final AgentPersona? persona;

  const _PersonaChip({required this.persona});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final label = persona?.name ?? loc.agentUseDefault;
    final icon = personaIconFor(persona);
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final AgentMessage message;
  final Household household;
  final bool isLastAssistant;
  final ValueChanged<String>? onSuggestionTap;
  final Future<void> Function(int messageId)? onConfirmToolCall;
  final Map<String, Map<String, dynamic>> argumentsByToolCallId;

  const _MessageBubble({
    required this.message,
    required this.household,
    this.isLastAssistant = false,
    this.onSuggestionTap,
    this.onConfirmToolCall,
    this.argumentsByToolCallId = const {},
  });

  static final RegExp _suggestionsRe = RegExp(
    r'\[suggestions:\s*([^\]\n]+)\]\s*$',
    caseSensitive: false,
  );

  static (String, List<String>) _extractSuggestions(String content) {
    final match = _suggestionsRe.firstMatch(content);
    if (match == null) return (content, const []);
    final raw = match.group(1) ?? '';
    final list = raw
        .split('|')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .take(6)
        .toList();
    final cleaned = content.replaceFirst(_suggestionsRe, '').trimRight();
    return (cleaned, list);
  }

  String _formatTime(DateTime t) {
    final local = t.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  List<int> _openRecipeIds() {
    final ids = <int>{};
    if (message.createdRecipeId != null) {
      ids.add(message.createdRecipeId!);
    }
    ids.addAll(message.attachments.recipeIds);
    return ids.toList(growable: false);
  }

  void _openRecipe(BuildContext context, int recipeId) {
    final fallbackName = message.content?.trim().isNotEmpty == true
        ? message.content!.trim().split('\n').first
        : 'Recipe';
    context.push(
      '/household/${household.id}/recipes/details/$recipeId',
      extra: Tuple2(
        household,
        Recipe(id: recipeId, name: fallbackName),
      ),
    );
  }

  Future<void> _runEdit(
    BuildContext context,
    int messageId,
    String currentContent,
  ) async {
    final cubit = context.read<AgentChatCubit>();
    final preview = await cubit.previewEdit(messageId);
    if (preview == null || !context.mounted) return;
    final result = await _showUndoDialog(
      context,
      mode: _UndoMode.edit,
      preview: preview,
      initialContent: currentContent,
    );
    if (result == null || !context.mounted) return;
    final newContent = (result.newContent ?? '').trim();
    if (newContent.isEmpty) return;
    final skipped = await cubit.confirmEdit(
      messageId,
      newContent,
      skipUndoMessageIds: result.skipUndoIds,
    );
    if (!context.mounted) return;
    _showSkippedSnack(context, skipped);
  }

  Future<void> _runRegenerate(BuildContext context, int messageId) async {
    final cubit = context.read<AgentChatCubit>();
    final preview = await cubit.previewRegenerate(messageId);
    if (preview == null || !context.mounted) return;
    final result = await _showUndoDialog(
      context,
      mode: _UndoMode.regenerate,
      preview: preview,
      initialContent: null,
    );
    if (result == null || !context.mounted) return;
    final skipped = await cubit.confirmRegenerate(
      messageId,
      skipUndoMessageIds: result.skipUndoIds,
    );
    if (!context.mounted) return;
    _showSkippedSnack(context, skipped);
  }

  void _showSkippedSnack(
    BuildContext context,
    List<AgentUndoSkipped>? skipped,
  ) {
    if (skipped == null || skipped.isEmpty) return;
    final loc = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(loc.agentUndoSkippedSummary(skipped.length))),
    );
  }

  Future<_UndoDialogResult?> _showUndoDialog(
    BuildContext context, {
    required _UndoMode mode,
    required AgentRewindPreview preview,
    required String? initialContent,
  }) =>
      showDialog<_UndoDialogResult>(
        context: context,
        builder: (ctx) => _AgentUndoDialog(
          mode: mode,
          preview: preview,
          initialContent: initialContent,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isUser = message.role == AgentMessageRole.user;
    final isTool = message.role == AgentMessageRole.tool;
    final isAssistant = message.role == AgentMessageRole.assistant;
    final openRecipeIds = _openRecipeIds();

    if (isTool) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: AgentToolCallCard(
          message: message,
          household: household,
          arguments: message.toolCallId == null
              ? null
              : argumentsByToolCallId[message.toolCallId!],
          onOpenRecipe: (recipeId) => _openRecipe(context, recipeId),
          onConfirm: message.id == null || onConfirmToolCall == null
              ? null
              : () => onConfirmToolCall!(message.id!),
        ),
      );
    }

    if (!isUser && !isAssistant) return const SizedBox.shrink();

    final color = isUser
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.secondaryContainer;
    final align = isUser ? Alignment.centerRight : Alignment.centerLeft;
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft: Radius.circular(isUser ? 16 : 4),
      bottomRight: Radius.circular(isUser ? 4 : 16),
    );

    var content = (message.content ?? '').trim();
    List<String> suggestions = const [];
    if (isAssistant) {
      final extracted = _extractSuggestions(content);
      content = extracted.$1;
      suggestions = extracted.$2;
    }
    if (content.isEmpty && suggestions.isEmpty && openRecipeIds.isEmpty) {
      return const SizedBox.shrink();
    }

    final time = message.createdAt;
    final messageId = message.id;
    final canEdit = isUser && messageId != null;
    final canRegenerate = isAssistant && isLastAssistant && messageId != null;
    final showMenu = canEdit || canRegenerate;

    final bubble = Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: color, borderRadius: radius),
      child: isAssistant
          ? KitchenOwlMarkdownBody(data: content)
          : SelectableText(content),
    );

    return Align(
      alignment: align,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (content.isNotEmpty)
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: isUser
                    ? [
                        if (showMenu)
                          _MessageActionMenu(
                            canEdit: canEdit,
                            canRegenerate: canRegenerate,
                            onEdit: () => _runEdit(context, messageId, content),
                            onRegenerate: () =>
                                _runRegenerate(context, messageId),
                          ),
                        Flexible(child: bubble),
                      ]
                    : [
                        Flexible(child: bubble),
                        if (showMenu)
                          _MessageActionMenu(
                            canEdit: canEdit,
                            canRegenerate: canRegenerate,
                            onEdit: () => _runEdit(context, messageId, content),
                            onRegenerate: () =>
                                _runRegenerate(context, messageId),
                          ),
                      ],
              ),
            if (time != null)
              Padding(
                padding: const EdgeInsets.only(left: 6, right: 6, bottom: 2),
                child: Text(
                  _formatTime(time),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            if (isAssistant && isLastAssistant && suggestions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 4),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    for (final s in suggestions)
                      ActionChip(
                        label: Text(s),
                        onPressed: onSuggestionTap == null
                            ? null
                            : () => onSuggestionTap!(s),
                      ),
                  ],
                ),
              ),
            if (!isUser && openRecipeIds.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2, bottom: 2),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    for (final recipeId in openRecipeIds)
                      OutlinedButton.icon(
                        icon: const Icon(Icons.menu_book_outlined, size: 16),
                        label: Text(loc.agentOpenRecipe),
                        onPressed: () => _openRecipe(context, recipeId),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MessageActionMenu extends StatelessWidget {
  final bool canEdit;
  final bool canRegenerate;
  final VoidCallback onEdit;
  final VoidCallback onRegenerate;

  const _MessageActionMenu({
    required this.canEdit,
    required this.canRegenerate,
    required this.onEdit,
    required this.onRegenerate,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: PopupMenuButton<String>(
        tooltip: loc.agentMessageActions,
        icon: const Icon(Icons.more_vert, size: 18),
        padding: EdgeInsets.zero,
        iconSize: 18,
        splashRadius: 18,
        onSelected: (v) {
          switch (v) {
            case 'edit':
              onEdit();
              break;
            case 'regenerate':
              onRegenerate();
              break;
          }
        },
        itemBuilder: (_) => [
          if (canEdit)
            PopupMenuItem(
              value: 'edit',
              child: Row(children: [
                const Icon(Icons.edit_outlined, size: 18),
                const SizedBox(width: 8),
                Text(loc.agentEditAction),
              ]),
            ),
          if (canRegenerate)
            PopupMenuItem(
              value: 'regenerate',
              child: Row(children: [
                const Icon(Icons.refresh, size: 18),
                const SizedBox(width: 8),
                Text(loc.agentRegenerateAction),
              ]),
            ),
        ],
      ),
    );
  }
}

/// A 6 px wide vertical bar between chat and recipe panel that the user
/// can drag horizontally to resize the panel. Shows a resize cursor on
/// desktop / web and renders a subtle grip indicator.
class _PanelResizeHandle extends StatefulWidget {
  final ValueChanged<double> onDrag;
  final String tooltip;

  const _PanelResizeHandle({required this.onDrag, required this.tooltip});

  @override
  State<_PanelResizeHandle> createState() => _PanelResizeHandleState();
}

class _PanelResizeHandleState extends State<_PanelResizeHandle> {
  bool _hovered = false;
  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final highlight = _hovered || _dragging;
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragStart: (_) => setState(() => _dragging = true),
        onHorizontalDragEnd: (_) => setState(() => _dragging = false),
        onHorizontalDragCancel: () => setState(() => _dragging = false),
        onHorizontalDragUpdate: (d) => widget.onDrag(d.delta.dx),
        child: Tooltip(
          message: widget.tooltip,
          waitDuration: const Duration(milliseconds: 600),
          child: SizedBox(
            width: 8,
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                width: highlight ? 4 : 1,
                color: highlight
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outlineVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _CardSort { added, title, group }

enum _CardGrouping { none, byLabel }

class _AgentCardsPanel extends StatefulWidget {
  final List<AgentRecipeCard> cards;
  final Household household;
  final Future<void> Function(int cardId) onClose;
  final Future<void> Function() onAttachExisting;
  final Future<void> Function(int cardId, String? label) onSetGroup;

  const _AgentCardsPanel({
    required this.cards,
    required this.household,
    required this.onClose,
    required this.onAttachExisting,
    required this.onSetGroup,
  });

  @override
  State<_AgentCardsPanel> createState() => _AgentCardsPanelState();
}

class _AgentCardsPanelState extends State<_AgentCardsPanel> {
  _CardSort _sort = _CardSort.added;
  _CardGrouping _grouping = _CardGrouping.none;

  // Cache the loaded full ``Recipe`` for each card so toggling the panel
  // does not re-trigger the network call. The map is keyed by card id.
  final Map<int, _RecipeLoadResult> _recipeCache = {};

  @override
  void didUpdateWidget(covariant _AgentCardsPanel old) {
    super.didUpdateWidget(old);
    final liveIds = widget.cards.map((c) => c.id).toSet();
    _recipeCache.removeWhere((k, _) => !liveIds.contains(k));
  }

  Future<_RecipeLoadResult> _loadRecipe(AgentRecipeCard card) async {
    final cached = _recipeCache[card.id];
    if (cached != null) return cached;
    if (card.recipeId == null) {
      final res = const _RecipeLoadResult(recipe: null, failed: false);
      _recipeCache[card.id] = res;
      return res;
    }
    final loaded = await ApiService.getInstance()
        .getRecipe(Recipe(id: card.recipeId, name: card.title ?? ''));
    final result = _RecipeLoadResult(
      recipe: loaded.$1,
      failed: loaded.$1 == null,
    );
    if (mounted) {
      setState(() => _recipeCache[card.id] = result);
    }
    return result;
  }

  List<AgentRecipeCard> _sorted(List<AgentRecipeCard> cards) {
    final list = List<AgentRecipeCard>.from(cards);
    switch (_sort) {
      case _CardSort.added:
        list.sort((a, b) => a.id.compareTo(b.id));
        break;
      case _CardSort.title:
        list.sort((a, b) => (a.title ?? '')
            .toLowerCase()
            .compareTo((b.title ?? '').toLowerCase()));
        break;
      case _CardSort.group:
        list.sort((a, b) {
          final ga = (a.groupLabel ?? '\uFFFF').toLowerCase();
          final gb = (b.groupLabel ?? '\uFFFF').toLowerCase();
          final cmp = ga.compareTo(gb);
          if (cmp != 0) return cmp;
          return (a.title ?? '')
              .toLowerCase()
              .compareTo((b.title ?? '').toLowerCase());
        });
        break;
    }
    return list;
  }

  /// Build the visible list, optionally splitting into [(label, cards)]
  /// sections for grouped rendering. ``label`` is null for the
  /// "ungrouped" bucket.
  List<MapEntry<String?, List<AgentRecipeCard>>> _grouped(
      List<AgentRecipeCard> cards) {
    if (_grouping == _CardGrouping.none) {
      return [MapEntry(null, cards)];
    }
    final ordered = <String, List<AgentRecipeCard>>{};
    final ungrouped = <AgentRecipeCard>[];
    for (final c in cards) {
      final label = (c.groupLabel ?? '').trim();
      if (label.isEmpty) {
        ungrouped.add(c);
      } else {
        ordered.putIfAbsent(label, () => []).add(c);
      }
    }
    final result = <MapEntry<String?, List<AgentRecipeCard>>>[];
    final keys = ordered.keys.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    for (final k in keys) {
      result.add(MapEntry(k, ordered[k]!));
    }
    if (ungrouped.isNotEmpty) {
      result.add(MapEntry(null, ungrouped));
    }
    return result;
  }

  Future<void> _editGroupLabel(AgentRecipeCard card) async {
    final loc = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: card.groupLabel ?? '');
    final result = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.agentRecipeSetGroup),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: loc.agentRecipeGroupHint),
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
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: Text(loc.save),
          ),
        ],
      ),
    );
    if (result == null) return;
    await widget.onSetGroup(card.id, result);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final sortedCards = _sorted(widget.cards);
    final sections = _grouped(sortedCards);

    return Container(
      color: theme.colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(loc.agentRecipePanel,
                      style: theme.textTheme.titleMedium),
                ),
                PopupMenuButton<_CardSort>(
                  tooltip: loc.agentRecipeSortBy,
                  icon: const Icon(Icons.sort, size: 20),
                  initialValue: _sort,
                  onSelected: (v) => setState(() => _sort = v),
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: _CardSort.added,
                      child: Text(loc.agentRecipeSortAdded),
                    ),
                    PopupMenuItem(
                      value: _CardSort.title,
                      child: Text(loc.agentRecipeSortTitle),
                    ),
                    PopupMenuItem(
                      value: _CardSort.group,
                      child: Text(loc.agentRecipeSortGroup),
                    ),
                  ],
                ),
                PopupMenuButton<_CardGrouping>(
                  tooltip: loc.agentRecipeGroupBy,
                  icon: const Icon(Icons.dashboard_outlined, size: 20),
                  initialValue: _grouping,
                  onSelected: (v) => setState(() => _grouping = v),
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: _CardGrouping.none,
                      child: Text(loc.agentRecipeGroupNone),
                    ),
                    PopupMenuItem(
                      value: _CardGrouping.byLabel,
                      child: Text(loc.agentRecipeGroupByLabel),
                    ),
                  ],
                ),
                IconButton(
                  tooltip: loc.agentRecipeAddFromCollection,
                  icon: const Icon(Icons.add, size: 22),
                  onPressed: () => widget.onAttachExisting(),
                ),
              ],
            ),
          ),
          Expanded(
            child: widget.cards.isEmpty
                ? _EmptyCardsPanel(
                    onAttach: widget.onAttachExisting,
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                    itemCount: _flattenLength(sections),
                    itemBuilder: (ctx, i) =>
                        _buildItem(ctx, sections, i, theme, loc),
                  ),
          ),
        ],
      ),
    );
  }

  int _flattenLength(List<MapEntry<String?, List<AgentRecipeCard>>> sections) {
    if (_grouping == _CardGrouping.none) {
      return sections.fold<int>(0, (acc, s) => acc + s.value.length);
    }
    return sections.fold<int>(
        0, (acc, s) => acc + 1 /* header */ + s.value.length);
  }

  Widget _buildItem(
    BuildContext ctx,
    List<MapEntry<String?, List<AgentRecipeCard>>> sections,
    int index,
    ThemeData theme,
    AppLocalizations loc,
  ) {
    int cursor = 0;
    for (final section in sections) {
      if (_grouping == _CardGrouping.byLabel) {
        if (cursor == index) {
          final label = section.key ?? loc.agentRecipeGroupUnassigned;
          return Padding(
            padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
            child: Text(
              label,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }
        cursor += 1;
      }
      if (index < cursor + section.value.length) {
        final card = section.value[index - cursor];
        return _AgentCardTile(
          key: ValueKey(card.id),
          card: card,
          household: widget.household,
          loader: () => _loadRecipe(card),
          cached: _recipeCache[card.id],
          onClose: () => widget.onClose(card.id),
          onEditGroup: () => _editGroupLabel(card),
        );
      }
      cursor += section.value.length;
    }
    return const SizedBox.shrink();
  }
}

class _EmptyCardsPanel extends StatelessWidget {
  final Future<void> Function() onAttach;
  const _EmptyCardsPanel({required this.onAttach});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.menu_book_outlined,
              size: 48, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 8),
          Text(
            loc.agentRecipePanelEmpty,
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => onAttach(),
            icon: const Icon(Icons.add),
            label: Text(loc.agentRecipeAddFromCollection),
          ),
        ],
      ),
    );
  }
}

class _RecipeLoadResult {
  final Recipe? recipe;
  final bool failed;
  const _RecipeLoadResult({required this.recipe, required this.failed});
}

class _AgentCardTile extends StatefulWidget {
  final AgentRecipeCard card;
  final Household household;
  final VoidCallback onClose;
  final VoidCallback onEditGroup;
  final Future<_RecipeLoadResult> Function() loader;
  final _RecipeLoadResult? cached;

  const _AgentCardTile({
    super.key,
    required this.card,
    required this.household,
    required this.onClose,
    required this.onEditGroup,
    required this.loader,
    required this.cached,
  });

  @override
  State<_AgentCardTile> createState() => _AgentCardTileState();
}

class _AgentCardTileState extends State<_AgentCardTile> {
  late Future<_RecipeLoadResult> _future;
  bool _expanded = true;

  @override
  void initState() {
    super.initState();
    _future =
        widget.cached != null ? Future.value(widget.cached!) : widget.loader();
  }

  @override
  void didUpdateWidget(covariant _AgentCardTile old) {
    super.didUpdateWidget(old);
    if (old.card.id != widget.card.id) {
      _future = widget.cached != null
          ? Future.value(widget.cached!)
          : widget.loader();
    } else if (widget.cached != null && old.cached == null) {
      _future = Future.value(widget.cached!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final card = widget.card;
    final hasRecipe = card.recipeId != null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: FutureBuilder<_RecipeLoadResult>(
          future: _future,
          builder: (context, snapshot) {
            final loaded = snapshot.data;
            final loading =
                snapshot.connectionState != ConnectionState.done && hasRecipe;
            final recipe = loaded?.recipe;
            final failed = loaded?.failed ?? false;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                InkWell(
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 4, 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                card.title?.isNotEmpty == true
                                    ? card.title!
                                    : (recipe?.name ?? loc.agentRecipePanel),
                                style: theme.textTheme.titleMedium,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if ((card.groupLabel ?? '').isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  card.groupLabel!,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Icon(
                          _expanded
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        PopupMenuButton<String>(
                          tooltip: '',
                          icon: const Icon(Icons.more_vert, size: 20),
                          onSelected: (v) {
                            switch (v) {
                              case 'group':
                                widget.onEditGroup();
                                break;
                              case 'close':
                                widget.onClose();
                                break;
                            }
                          },
                          itemBuilder: (_) => [
                            PopupMenuItem(
                              value: 'group',
                              child: Row(
                                children: [
                                  const Icon(Icons.label_outline, size: 18),
                                  const SizedBox(width: 8),
                                  Text(loc.agentRecipeSetGroup),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'close',
                              child: Row(
                                children: [
                                  const Icon(Icons.close, size: 18),
                                  const SizedBox(width: 8),
                                  Text(loc.agentCloseCard),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (_expanded)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (loading)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (failed)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Text(
                              loc.agentRecipeLoadFailed,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.error,
                              ),
                            ),
                          )
                        else ...[
                          _RecipeMetaChips(recipe: recipe, fallback: card),
                          const SizedBox(height: 12),
                          // Ingredients first.
                          Text(
                            loc.agentRecipeIngredients,
                            style: theme.textTheme.titleSmall,
                          ),
                          const SizedBox(height: 4),
                          if (recipe == null || recipe.items.isEmpty)
                            Text(
                              loc.agentRecipeNoIngredients,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            )
                          else
                            ...recipe.items.map(
                              (it) => Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 2),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '\u2022 ',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                    Expanded(
                                      child: Text.rich(
                                        TextSpan(
                                          children: [
                                            TextSpan(
                                              text: it.name,
                                              style: theme.textTheme.bodySmall,
                                            ),
                                            if (it.description.isNotEmpty)
                                              TextSpan(
                                                text:
                                                    ' \u2014 ${it.description}',
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                  color: theme.colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                              ),
                                            if (it.optional)
                                              TextSpan(
                                                text: ' (${loc.optional})',
                                                style: theme
                                                    .textTheme.labelSmall
                                                    ?.copyWith(
                                                  color: theme.colorScheme
                                                      .onSurfaceVariant,
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          // Then steps from the recipe description, rendered
                          // exactly like the recipe page (numbered list,
                          // ingredient mentions become chips instead of
                          // raw "@name" tokens).
                          if (recipe != null &&
                              recipe.description.trim().isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Text(
                              loc.agentRecipeSteps,
                              style: theme.textTheme.titleSmall,
                            ),
                            const SizedBox(height: 4),
                            RecipeMarkdownBody(
                              recipe: recipe,
                              recipeItemBuilder: RecipeItemMarkdownBuilder(
                                items: recipe.items,
                              ),
                            ),
                          ] else if (recipe == null &&
                              (card.description ?? '').isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(
                              card.description!,
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                          if (recipe != null && recipe.tags.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                for (final t in recipe.tags)
                                  Chip(
                                    label: Text(
                                      t.name,
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                    visualDensity: VisualDensity.compact,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                              ],
                            ),
                          ],
                          if (hasRecipe) ...[
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: FilledButton.icon(
                                icon: const Icon(Icons.menu_book_outlined,
                                    size: 18),
                                label: Text(loc.agentOpenRecipe),
                                onPressed: () => context.push(
                                  '/household/${widget.household.id}/recipes/details/${card.recipeId}',
                                  // Recipe details route expects a
                                  // Tuple2<Household, Recipe> as extra.
                                  extra: Tuple2(
                                    widget.household,
                                    recipe ??
                                        Recipe(
                                          id: card.recipeId,
                                          name: card.title ?? '',
                                        ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _RecipeMetaChips extends StatelessWidget {
  final Recipe? recipe;
  final AgentRecipeCard fallback;
  const _RecipeMetaChips({required this.recipe, required this.fallback});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final chips = <Widget>[];
    final r = recipe;
    if (r != null) {
      final totalTime = r.time > 0 ? r.time : (r.prepTime + r.cookTime);
      if (totalTime > 0) {
        chips.add(_metaChip(
          theme,
          icon: Icons.schedule,
          label: loc.agentRecipeMinutes(totalTime),
        ));
      }
      if (r.yields > 0) {
        chips.add(_metaChip(
          theme,
          icon: Icons.people_alt_outlined,
          label: loc.agentRecipeServings(r.yields),
        ));
      }
    }
    chips.add(_sourceChip(theme, fallback.source));
    if (chips.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: chips,
    );
  }

  Widget _metaChip(ThemeData theme,
      {required IconData icon, required String label}) {
    return Chip(
      avatar: Icon(icon, size: 14),
      label: Text(label, style: const TextStyle(fontSize: 11)),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      side: BorderSide(color: theme.colorScheme.outlineVariant),
      backgroundColor: theme.colorScheme.surfaceContainerHigh,
    );
  }

  Widget _sourceChip(ThemeData theme, AgentRecipeCardSource src) {
    IconData icon;
    Color bg;
    Color fg;
    String label;
    switch (src) {
      case AgentRecipeCardSource.created:
        icon = Icons.auto_awesome;
        bg = theme.colorScheme.primaryContainer;
        fg = theme.colorScheme.onPrimaryContainer;
        label = 'Neu';
        break;
      case AgentRecipeCardSource.proposed:
        icon = Icons.lightbulb_outline;
        bg = theme.colorScheme.tertiaryContainer;
        fg = theme.colorScheme.onTertiaryContainer;
        label = 'Vorschlag';
        break;
      case AgentRecipeCardSource.existing:
        icon = Icons.bookmark_border;
        bg = theme.colorScheme.secondaryContainer;
        fg = theme.colorScheme.onSecondaryContainer;
        label = 'Aus Sammlung';
        break;
    }
    return Chip(
      avatar: Icon(icon, size: 14, color: fg),
      label: Text(label, style: TextStyle(fontSize: 11, color: fg)),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      backgroundColor: bg,
      side: BorderSide(color: bg),
    );
  }
}

class _AgentRecipePickerSheet extends StatefulWidget {
  final Household household;
  final String title;

  const _AgentRecipePickerSheet({required this.household, required this.title});

  @override
  State<_AgentRecipePickerSheet> createState() =>
      _AgentRecipePickerSheetState();
}

class _AgentRecipePickerSheetState extends State<_AgentRecipePickerSheet> {
  List<Recipe> _recipes = const [];
  bool _loading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await ApiService.getInstance().getRecipes(widget.household);
    if (!mounted) return;
    setState(() {
      _recipes = list ?? const [];
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final filtered = _query.isEmpty
        ? _recipes
        : _recipes
            .where((r) => (r.name).toLowerCase().contains(_query.toLowerCase()))
            .toList();
    return SafeArea(
      child: Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(widget.title,
                          style: Theme.of(context).textTheme.titleMedium),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : filtered.isEmpty
                        ? Center(child: Text(loc.agentNothingFound))
                        : ListView.builder(
                            itemCount: filtered.length,
                            itemBuilder: (_, i) {
                              final r = filtered[i];
                              return ListTile(
                                leading: const Icon(Icons.menu_book_outlined),
                                title: Text(r.name),
                                subtitle: r.description.isNotEmpty
                                    ? Text(r.description,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis)
                                    : null,
                                onTap: () => Navigator.of(context).pop(r),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AgentItemPickerSheet extends StatefulWidget {
  final Household household;
  final String title;

  const _AgentItemPickerSheet({required this.household, required this.title});

  @override
  State<_AgentItemPickerSheet> createState() => _AgentItemPickerSheetState();
}

class _AgentItemPickerSheetState extends State<_AgentItemPickerSheet> {
  List<ItemWithDescription> _items = const [];
  bool _loading = false;
  String _query = '';

  Future<void> _search(String q) async {
    setState(() {
      _query = q;
      _loading = true;
    });
    final list = await ApiService.getInstance().searchItem(widget.household, q);
    if (!mounted || _query != q) return;
    setState(() {
      _items = list ?? const [];
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return SafeArea(
      child: Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(widget.title,
                          style: Theme.of(context).textTheme.titleMedium),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  autofocus: true,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                  ),
                  onChanged: _search,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _items.isEmpty
                        ? Center(child: Text(loc.agentNothingFound))
                        : ListView.builder(
                            itemCount: _items.length,
                            itemBuilder: (_, i) {
                              final it = _items[i];
                              return ListTile(
                                leading:
                                    const Icon(Icons.shopping_basket_outlined),
                                title: Text(it.name),
                                onTap: () => Navigator.of(context).pop(it),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
