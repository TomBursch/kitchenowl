part of '../agent_chat_page.dart';

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSubmit;
  final VoidCallback? onCancel;
  final String hint;
  final List<int> attachedRecipeIds;
  final List<int> attachedItemIds;
  final Map<int, String> attachedRecipeNames;
  final Map<int, String> attachedItemNames;
  final List<String> attachedFiles;
  final ValueChanged<int> onRemoveRecipe;
  final ValueChanged<int> onRemoveItem;
  final ValueChanged<String> onRemoveFile;
  final VoidCallback onPickRecipe;
  final VoidCallback onPickItem;
  final VoidCallback onPickImage;
  final VoidCallback onPickPdf;

  const _Composer({
    required this.controller,
    required this.sending,
    required this.onSubmit,
    this.onCancel,
    required this.hint,
    required this.attachedRecipeIds,
    required this.attachedItemIds,
    required this.attachedRecipeNames,
    required this.attachedItemNames,
    required this.attachedFiles,
    required this.onRemoveRecipe,
    required this.onRemoveItem,
    required this.onRemoveFile,
    required this.onPickRecipe,
    required this.onPickItem,
    required this.onPickImage,
    required this.onPickPdf,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final hasAttachments = attachedRecipeIds.isNotEmpty ||
        attachedItemIds.isNotEmpty ||
        attachedFiles.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hasAttachments)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final rid in attachedRecipeIds)
                    InputChip(
                      avatar: const Icon(Icons.menu_book_outlined, size: 16),
                      label: Text(attachedRecipeNames[rid] ?? '#$rid'),
                      onDeleted: sending ? null : () => onRemoveRecipe(rid),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  for (final iid in attachedItemIds)
                    InputChip(
                      avatar:
                          const Icon(Icons.shopping_basket_outlined, size: 16),
                      label: Text(attachedItemNames[iid] ?? '#$iid'),
                      onDeleted: sending ? null : () => onRemoveItem(iid),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  for (final fileName in attachedFiles)
                    InputChip(
                      avatar: Icon(
                        fileName.toLowerCase().endsWith('.pdf')
                            ? Icons.picture_as_pdf_outlined
                            : Icons.image_outlined,
                        size: 16,
                      ),
                      label: Text(fileName),
                      onDeleted: sending ? null : () => onRemoveFile(fileName),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                ],
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              PopupMenuButton<String>(
                tooltip: loc.agentAttachContext,
                icon: const Icon(Icons.attach_file_rounded),
                onSelected: (v) {
                  switch (v) {
                    case 'recipe':
                      onPickRecipe();
                      break;
                    case 'item':
                      onPickItem();
                      break;
                    case 'image':
                      onPickImage();
                      break;
                    case 'pdf':
                      onPickPdf();
                      break;
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'recipe',
                    child: Row(children: [
                      const Icon(Icons.menu_book_outlined, size: 18),
                      const SizedBox(width: 8),
                      Text(loc.agentAttachRecipe),
                    ]),
                  ),
                  PopupMenuItem(
                    value: 'item',
                    child: Row(children: [
                      const Icon(Icons.shopping_basket_outlined, size: 18),
                      const SizedBox(width: 8),
                      Text(loc.agentAttachItem),
                    ]),
                  ),
                  const PopupMenuItem(
                    value: 'image',
                    child: _AttachImageMenuLabel(),
                  ),
                  const PopupMenuItem(
                    value: 'pdf',
                    child: _AttachPdfMenuLabel(),
                  ),
                ],
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  minLines: 1,
                  maxLines: 6,
                  enabled: !sending,
                  decoration: InputDecoration(
                    hintText: hint,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                  textInputAction: TextInputAction.newline,
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                tooltip: sending ? loc.cancel : null,
                icon: sending
                    ? const Icon(Icons.stop_rounded)
                    : const Icon(Icons.send_rounded),
                onPressed: sending ? (onCancel ?? () {}) : onSubmit,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AttachImageMenuLabel extends StatelessWidget {
  const _AttachImageMenuLabel();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Row(children: [
      const Icon(Icons.image_outlined, size: 18),
      const SizedBox(width: 8),
      Text(loc.agentAttachImage),
    ]);
  }
}

class _AttachPdfMenuLabel extends StatelessWidget {
  const _AttachPdfMenuLabel();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Row(children: [
      const Icon(Icons.picture_as_pdf_outlined, size: 18),
      const SizedBox(width: 8),
      Text(loc.agentAttachPdf),
    ]);
  }
}
