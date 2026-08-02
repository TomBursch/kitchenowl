import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/agent_chat.dart';
import 'package:kitchenowl/models/household.dart';

/// Displays the result of a single agent tool call in a compact card.
class AgentToolCallCard extends StatefulWidget {
  final AgentMessage message;
  final Household household;

  /// The parsed input arguments for this call, keyed by argument name.
  /// Sourced from the preceding assistant message's tool_calls JSON.
  final Map<String, dynamic>? arguments;

  /// Optional callback to open a recipe id referenced by this tool run.
  final ValueChanged<int>? onOpenRecipe;
  final Future<void> Function()? onConfirm;

  const AgentToolCallCard({
    super.key,
    required this.message,
    required this.household,
    this.arguments,
    this.onOpenRecipe,
    this.onConfirm,
  });

  @override
  State<AgentToolCallCard> createState() => _AgentToolCallCardState();
}

class _AgentToolCallCardState extends State<AgentToolCallCard> {
  bool _showRawJson = false;

  dynamic _tryDecodeJson(String content) {
    if (content.isEmpty) return null;
    try {
      return jsonDecode(content);
    } catch (_) {
      return null;
    }
  }

  String _prettyJson(dynamic value) {
    try {
      return const JsonEncoder.withIndent('  ').convert(value);
    } catch (_) {
      return value?.toString() ?? '';
    }
  }

  bool _looksLikeError(dynamic parsed, String content) {
    if (parsed is Map<String, dynamic>) {
      return parsed.containsKey('error') || parsed.containsKey('detail');
    }
    final lowered = content.toLowerCase();
    return lowered.contains('error') || lowered.contains('failed');
  }

  String _toolLabel(AppLocalizations loc, String? rawName) {
    switch ((rawName ?? '').toLowerCase()) {
      case 'list_recipes':
        return loc.agentToolListRecipes;
      case 'search_recipes':
        return loc.agentToolSearchRecipes;
      case 'get_recipe':
        return loc.agentToolGetRecipe;
      case 'create_recipe':
        return loc.agentToolCreateRecipe;
      case 'update_recipe':
        return loc.agentToolUpdateRecipe;
      case 'delete_recipe':
        return loc.agentToolDeleteRecipe;
      case 'list_items':
        return loc.agentToolListItems;
      case 'list_tags':
        return loc.agentToolListTags;
      case 'create_tag':
        return loc.agentToolCreateTag;
      case 'web_search_recipes':
        return loc.agentToolWebSearchRecipes;
      case 'scrape_recipe':
        return loc.agentToolScrapeRecipe;
      default:
        return rawName ?? loc.agentToolCall;
    }
  }

  bool _toolTargetsRecipe(String? toolName) {
    switch ((toolName ?? '').toLowerCase()) {
      case 'get_recipe':
      case 'create_recipe':
      case 'update_recipe':
      case 'delete_recipe':
        return true;
      default:
        return false;
    }
  }

  void _collectRecipeIds(
    dynamic value,
    Set<int> ids, {
    String? key,
    required bool toolTargetsRecipe,
  }) {
    if (value is int) {
      final normalizedKey = (key ?? '').toLowerCase();
      if (normalizedKey == 'recipe_id' ||
          normalizedKey == 'created_recipe_id' ||
          (normalizedKey == 'id' && toolTargetsRecipe)) {
        ids.add(value);
      }
      return;
    }
    if (value is List) {
      for (final e in value) {
        _collectRecipeIds(
          e,
          ids,
          key: key,
          toolTargetsRecipe: toolTargetsRecipe,
        );
      }
      return;
    }
    if (value is Map) {
      value.forEach((k, v) {
        _collectRecipeIds(
          v,
          ids,
          key: k.toString(),
          toolTargetsRecipe: toolTargetsRecipe,
        );
      });
    }
  }

  List<int> _extractRecipeIds({
    required AgentMessage message,
    required Map<String, dynamic>? args,
    required dynamic parsedResult,
  }) {
    final ids = <int>{};
    if (message.createdRecipeId != null) ids.add(message.createdRecipeId!);
    ids.addAll(message.attachments.recipeIds);
    final targetsRecipe = _toolTargetsRecipe(message.toolName);
    _collectRecipeIds(
      args,
      ids,
      toolTargetsRecipe: targetsRecipe,
    );
    _collectRecipeIds(
      parsedResult,
      ids,
      toolTargetsRecipe: targetsRecipe,
    );
    return ids.toList(growable: false);
  }

  Widget _sectionTitle(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 4),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }

  Widget _valueBlock(BuildContext context, String text) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
      ),
      child: SelectableText(
        text,
        style: theme.textTheme.bodySmall,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final message = widget.message;
    final toolName = _toolLabel(loc, message.toolName);
    final content = (message.content ?? '').trim();
    final parsedResult = _tryDecodeJson(content);
    final hasError = _looksLikeError(parsedResult, content);
    final args = widget.arguments;
    final recipeIds = _extractRecipeIds(
      message: message,
      args: args,
      parsedResult: parsedResult,
    );

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 2),
      color: theme.colorScheme.surfaceContainerHighest,
      elevation: 0,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        leading: Icon(
          hasError ? Icons.error_outline : Icons.build_outlined,
          size: 18,
          color: hasError
              ? theme.colorScheme.error
              : theme.colorScheme.onSurfaceVariant,
        ),
        title: Text(
          toolName,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          hasError ? loc.agentToolError : loc.agentToolCall,
          style: theme.textTheme.labelSmall?.copyWith(
            color: hasError
                ? theme.colorScheme.error
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
        children: [
          _sectionTitle(context, loc.agentToolArguments),
          _valueBlock(
            context,
            (args == null || args.isEmpty)
                ? loc.agentToolNoArguments
                : _prettyJson(args),
          ),
          _sectionTitle(context, loc.agentToolResult),
          _valueBlock(
            context,
            content.isEmpty
                ? loc.agentToolNoResult
                : (_showRawJson
                    ? ((parsedResult == null)
                        ? content
                        : _prettyJson(parsedResult))
                    : ((parsedResult is Map || parsedResult is List)
                        ? _prettyJson(parsedResult)
                        : content)),
          ),
          if (content.isNotEmpty)
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(loc.agentToolRawJson),
              value: _showRawJson,
              onChanged: (v) => setState(() => _showRawJson = v),
            ),
          if (recipeIds.isNotEmpty && widget.onOpenRecipe != null) ...[
            _sectionTitle(context, loc.agentOpenRecipe),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final recipeId in recipeIds)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.menu_book_outlined, size: 16),
                    label: Text(loc.agentOpenRecipe),
                    onPressed: () => widget.onOpenRecipe!(recipeId),
                  ),
              ],
            ),
          ],
          if (message.requiresConfirmation && widget.onConfirm != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: FilledButton.icon(
                icon: const Icon(Icons.check),
                label: Text(loc.confirm),
                onPressed: widget.onConfirm,
              ),
            ),
        ],
      ),
    );
  }
}
