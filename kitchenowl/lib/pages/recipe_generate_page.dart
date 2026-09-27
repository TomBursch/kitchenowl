import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:kitchenowl/cubits/recipe_generate_cubit.dart';
import 'package:kitchenowl/enums/update_enum.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/models/recipe.dart';
import 'package:kitchenowl/pages/recipe_add_update_page.dart';

class RecipeGeneratePage extends StatefulWidget {
  final Household household;

  const RecipeGeneratePage({
    super.key,
    required this.household,
  });

  @override
  _RecipeGeneratePageState createState() => _RecipeGeneratePageState();
}

class _RecipeGeneratePageState extends State<RecipeGeneratePage> {
  late final RecipeGenerateCubit cubit = RecipeGenerateCubit(widget.household);
  final TextEditingController controller = TextEditingController();
  final FocusNode focusNode = FocusNode();

  @override
  void dispose() {
    cubit.close();
    controller.dispose();
    focusNode.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = controller.text.trim();
    if (text.isEmpty || cubit.state.loading) return;
    controller.clear();
    if (await cubit.send(text) == false && mounted) {
      controller.text = text;
      showSnackbar(
        context: context,
        content: Text(AppLocalizations.of(context)!.error),
        width: null,
      );
    }
  }

  void _abort() {
    final text = cubit.abort();
    if (text != null) controller.text = text;
  }

  /// Puts a suggested prompt into the input so the user can adjust it before sending
  void _usePrompt(String prompt) {
    controller.value = TextEditingValue(
      text: prompt,
      selection: TextSelection.collapsed(offset: prompt.length),
    );
    focusNode.requestFocus();
  }

  Future<void> _addRecipe(Recipe recipe) async {
    final res = await Navigator.of(context).push<UpdateEnum>(MaterialPageRoute(
      builder: (context) => AddUpdateRecipePage(
        household: widget.household,
        recipe: recipe,
        canSaveWithoutChanges: true,
      ),
    ));
    if (res == UpdateEnum.updated && mounted) {
      Navigator.of(context).pop(UpdateEnum.updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RecipeGenerateCubit, RecipeGenerateState>(
      bloc: cubit,
      builder: (context, state) => Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppLocalizations.of(context)!.recipeGenerate),
              if (state.totalTokens > 0)
                Text(
                  AppLocalizations.of(context)!
                      .recipeGenerateTokens(state.totalTokens),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
        ),
        body: SafeArea(
          top: false,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                children: [
                  Expanded(
                    child: state.entries.isEmpty
                        ? _EmptyChat(onPrompt: _usePrompt)
                        // reversed so the list sticks to the newest message
                        : ListView(
                            reverse: true,
                            padding: const EdgeInsets.all(16),
                            children: [
                              if (!state.loading &&
                                  state.entries.lastOrNull is AiRecipeReply)
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: [
                                    for (final prompt in [
                                      AppLocalizations.of(context)!
                                          .recipeGenerateFollowUpAnother,
                                      AppLocalizations.of(context)!
                                          .recipeGenerateFollowUpVegetarian,
                                      AppLocalizations.of(context)!
                                          .recipeGenerateFollowUpDetailed,
                                    ])
                                      ActionChip(
                                        label: Text(prompt),
                                        onPressed: () {
                                          controller.text = prompt;
                                          _send();
                                        },
                                      ),
                                  ],
                                ),
                              for (final entry in state.entries.reversed)
                                entry is AiRecipeReply
                                    ? _RecipePreview(
                                        reply: entry,
                                        onAdd:
                                            identical(entry, state.entries.last)
                                                ? () => _addRecipe(entry.recipe)
                                                : null,
                                      )
                                    : _UserMessage(text: entry as String),
                            ],
                          ),
                  ),
                  if (state.loading) const LinearProgressIndicator(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: controller,
                            focusNode: focusNode,
                            decoration: InputDecoration(
                              hintText: AppLocalizations.of(context)!
                                  .recipeGenerateHint,
                            ),
                            minLines: 1,
                            maxLines: 5,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _send(),
                          ),
                        ),
                        state.loading
                            ? IconButton(
                                icon: const Icon(Icons.stop_rounded),
                                tooltip: AppLocalizations.of(context)!
                                    .recipeGenerateAbort,
                                onPressed: _abort,
                              )
                            : IconButton(
                                icon: const Icon(Icons.send_rounded),
                                tooltip: AppLocalizations.of(context)!.send,
                                onPressed: _send,
                              ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyChat extends StatelessWidget {
  final void Function(String) onPrompt;

  const _EmptyChat({required this.onPrompt});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return CustomScrollView(
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.auto_awesome_rounded,
                          size: 48,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.recipeGenerateQuestion,
                          style: theme.textTheme.headlineMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.recipeGenerateSuggestions,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 8),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final prompt in [
                      l10n.recipeGenerateSuggestionFewIngredients,
                      l10n.recipeGenerateSuggestionFridge,
                      l10n.recipeGenerateSuggestionQuick,
                      l10n.recipeGenerateSuggestionMealPrep,
                    ])
                      SizedBox(
                        width: 260,
                        child: Card.outlined(
                          margin: EdgeInsets.zero,
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () => onPrompt(prompt),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.lightbulb_outline_rounded,
                                    size: 16,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      prompt,
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _UserMessage extends StatelessWidget {
  final String text;

  const _UserMessage({required this.text});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.fromLTRB(48, 8, 0, 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
      ),
    );
  }
}

class _RecipePreview extends StatelessWidget {
  final AiRecipeReply reply;
  final VoidCallback? onAdd;

  const _RecipePreview({required this.reply, this.onAdd});

  @override
  Widget build(BuildContext context) {
    final recipe = reply.recipe;
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(recipe.name, style: textTheme.titleLarge),
            if (recipe.time > 0 || recipe.yields > 0)
              Text([
                if (recipe.time > 0)
                  '${l10n.totalTime}: ${recipe.time} ${l10n.minutesAbbrev}',
                if (recipe.yields > 0) '${l10n.yields}: ${recipe.yields}',
              ].join(' · ')),
            for (final (title, items) in [
              (l10n.ingredients, recipe.mandatoryItems),
              (l10n.ingredientsOptional, recipe.optionalItems),
            ])
              if (items.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('$title:', style: textTheme.titleMedium),
                for (final item in items)
                  Text(
                    '• ${[
                      item.description,
                      item.name
                    ].where((e) => e.isNotEmpty).join(' ')}',
                  ),
              ],
            const SizedBox(height: 12),
            MarkdownBody(data: recipe.description),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${l10n.recipeGenerateTokens(reply.promptTokens + reply.completionTokens)}'
                    ' (↑${reply.promptTokens} ↓${reply.completionTokens})',
                    style: textTheme.bodySmall,
                  ),
                ),
                if (onAdd != null)
                  ElevatedButton(
                    onPressed: onAdd,
                    child: Text(l10n.recipeGenerateAdd),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
