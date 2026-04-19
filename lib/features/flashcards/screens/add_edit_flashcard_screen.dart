import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/flashcard.dart';
import '../../../core/models/tag.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_bar_widget.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/page_header.dart';

class AddEditFlashcardScreen extends ConsumerStatefulWidget {
  final String collectionId;
  final String? cardId;

  const AddEditFlashcardScreen({
    super.key,
    required this.collectionId,
    this.cardId,
  });

  @override
  ConsumerState<AddEditFlashcardScreen> createState() =>
      _AddEditFlashcardScreenState();
}

class _AddEditFlashcardScreenState
    extends ConsumerState<AddEditFlashcardScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _previewMode = false;
  bool _isDirty = false;
  Set<String> _selectedTagIds = {};

  bool get _isEdit => widget.cardId != null;

  Flashcard? get _existingCard {
    if (!_isEdit) return null;
    return ref
        .read(flashcardsProvider)
        .where((f) => f.id == widget.cardId)
        .cast<Flashcard?>()
        .firstOrNull;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final card = _existingCard;
      if (card != null) {
        _titleController.text = card.title;
        _contentController.text = card.content;
        setState(() {
          _selectedTagIds = Set.from(card.tagIds);
        });
      }
    });
    _titleController
        .addListener(() => setState(() => _isDirty = true));
    _contentController
        .addListener(() => setState(() => _isDirty = true));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _save() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;
    final content = _contentController.text.trim();
    final tagIds = _selectedTagIds.toList();

    if (_isEdit && _existingCard != null) {
      ref.read(flashcardsProvider.notifier).update(
            _existingCard!
                .copyWith(title: title, content: content, tagIds: tagIds),
          );
    } else {
      ref.read(flashcardsProvider.notifier).add(
            Flashcard(
              collectionId: widget.collectionId,
              title: title,
              content: content,
              tagIds: tagIds,
            ),
          );
    }
    context.pop();
  }

  void _discard() {
    if (_isDirty) {
      showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Discard changes?'),
          content:
              const Text('Your unsaved changes will be lost.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Keep Editing'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.pop();
              },
              style: FilledButton.styleFrom(
                backgroundColor:
                    Theme.of(context).colorScheme.error,
              ),
              child: const Text('Discard'),
            ),
          ],
        ),
      );
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final charCount = _contentController.text.length;
    final allTags = ref.watch(tagsProvider);

    final collection = ref
        .watch(collectionsProvider)
        .where((c) => c.id == widget.collectionId)
        .firstOrNull;

    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _discard();
      },
      child: Scaffold(
      backgroundColor: cs.surface,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AppBarWidget(
          showBack: true,
          title: _isEdit ? 'Edit Card' : 'Add Card',
          badge: _isDirty ? const AppBarBadge('UNSAVED') : null,
          onBack: _discard,
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PageHeader(
                    title: collection?.title ?? 'New Card',
                    icon: collection != null
                        ? IconData(collection.iconCodePoint,
                            fontFamily: 'MaterialIcons')
                        : null,
                    iconColor: collection?.color,
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        // ── CARD FRONT ────────────────────────
                        _Label('CARD FRONT (TITLE)'),
                        const SizedBox(height: AppSpacing.sm),
                        TextField(
                          controller: _titleController,
                          textCapitalization:
                              TextCapitalization.sentences,
                          style: TextStyle(color: cs.onSurface),
                          decoration: InputDecoration(
                            hintText:
                                'Enter the core term or question',
                            hintStyle: TextStyle(
                                color: cs.onSurfaceVariant),
                          ),
                        ),

                        const SizedBox(height: AppSpacing.xl),

                        // ── CARD BACK label ───────────────────
                        _Label('CARD BACK (EXPLANATION)'),
                        const SizedBox(height: AppSpacing.sm),

                        // ── Format toolbar ────────────────────
                        _FormatToolbar(
                          controller: _contentController,
                          onChanged: () => setState(() {}),
                          previewMode: _previewMode,
                          onTogglePreview: () => setState(
                              () => _previewMode = !_previewMode),
                        ),
                        const SizedBox(height: AppSpacing.sm),

                        // ── Editor / Preview ──────────────────
                        ClipRRect(
                          borderRadius: BorderRadius.circular(
                              AppRadius.md),
                          child: Container(
                            constraints: const BoxConstraints(
                                minHeight: 280),
                            decoration: BoxDecoration(
                              color: cs.surfaceContainer,
                              borderRadius: BorderRadius.circular(
                                  AppRadius.md),
                              border: Border.all(
                                  color: cs.outline),
                            ),
                            child: _previewMode
                                ? Padding(
                                    padding: const EdgeInsets.all(
                                        AppSpacing.lg),
                                    child: _contentController
                                            .text.isEmpty
                                        ? Text(
                                            'Nothing to preview yet...',
                                            style: TextStyle(
                                              color:
                                                  cs.onSurfaceVariant,
                                              fontStyle:
                                                  FontStyle.italic,
                                            ),
                                          )
                                        : MarkdownBody(
                                            data: _contentController
                                                .text,
                                            styleSheet:
                                                MarkdownStyleSheet
                                                    .fromTheme(
                                                        Theme.of(
                                                            context))
                                                    .copyWith(
                                              p: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.copyWith(
                                                    color:
                                                        cs.onSurface,
                                                  ),
                                              blockquoteDecoration:
                                                  BoxDecoration(
                                                color: cs
                                                    .surfaceContainerHigh,
                                                borderRadius:
                                                    BorderRadius
                                                        .circular(
                                                            AppRadius
                                                                .sm),
                                                border: Border(
                                                  left: BorderSide(
                                                      color: cs.primary,
                                                      width: 3),
                                                ),
                                              ),
                                              blockquotePadding:
                                                  const EdgeInsets
                                                      .fromLTRB(
                                                          12, 8, 12, 8),
                                            ),
                                          ),
                                  )
                                : TextField(
                                    controller:
                                        _contentController,
                                    maxLines: null,
                                    minLines: 12,
                                    style: TextStyle(
                                        color: cs.onSurface),
                                    decoration: InputDecoration(
                                      hintText:
                                          'Explain using Markdown — **bold**, *italic*, `code`, lists...',
                                      hintStyle: TextStyle(
                                          color:
                                              cs.onSurfaceVariant),
                                      border: InputBorder.none,
                                      enabledBorder:
                                          InputBorder.none,
                                      focusedBorder:
                                          InputBorder.none,
                                      contentPadding:
                                          const EdgeInsets.all(
                                              AppSpacing.lg),
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: AppSpacing.sm),
                        // Char count + markdown hint
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              size: 12,
                              color: cs.primary
                                  .withValues(alpha: 0.7),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'MARKDOWN SUPPORTED',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.4,
                                color: cs.primary
                                    .withValues(alpha: 0.7),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '$charCount characters',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: cs.onSurfaceVariant),
                            ),
                          ],
                        ),

                        const SizedBox(height: AppSpacing.xl),

                        // ── TAGS ──────────────────────────────
                        Row(
                          children: [
                            _Label('TAGS'),
                            const Spacer(),
                            GestureDetector(
                              onTap: () =>
                                  _showAddTagDialog(context, allTags),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.add_rounded,
                                      size: 14, color: cs.primary),
                                  const SizedBox(width: 2),
                                  Text(
                                    'New Tag',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: cs.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        if (allTags.isEmpty)
                          Text(
                            'No tags yet. Tap "New Tag" to create one.',
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurfaceVariant
                                  .withValues(alpha: 0.55),
                              fontStyle: FontStyle.italic,
                            ),
                          )
                        else
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: allTags.map((tag) {
                              final isSelected =
                                  _selectedTagIds.contains(tag.id);
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _isDirty = true;
                                    if (isSelected) {
                                      _selectedTagIds =
                                          Set.from(_selectedTagIds)
                                            ..remove(tag.id);
                                    } else {
                                      _selectedTagIds =
                                          Set.from(_selectedTagIds)
                                            ..add(tag.id);
                                    }
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(
                                      milliseconds: 150),
                                  padding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? cs.primary
                                            .withValues(alpha: 0.12)
                                        : cs.surfaceContainerHigh,
                                    borderRadius:
                                        BorderRadius.circular(
                                            AppRadius.full),
                                    border: Border.all(
                                      color: isSelected
                                          ? cs.primary
                                              .withValues(alpha: 0.5)
                                          : cs.outline,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (isSelected) ...[
                                        Icon(Icons.check_rounded,
                                            size: 12,
                                            color: cs.primary),
                                        const SizedBox(width: 4),
                                      ],
                                      Text(
                                        '#${tag.name}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: isSelected
                                              ? cs.primary
                                              : cs.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Fixed bottom action bar ──────────────
          _ActionBar(
            onSave: _save,
            onDiscard: _discard,
            canSave: _titleController.text.trim().isNotEmpty,
            isEdit: _isEdit,
          ),
        ],
      ),
    ),
    );
  }

  void _showAddTagDialog(BuildContext context, List<Tag> existingTags) {
    final cs = Theme.of(context).colorScheme;
    final controller = TextEditingController();
    String? error;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            side: BorderSide(color: cs.outline),
          ),
          backgroundColor: cs.surfaceContainer,
          title: const Text('New Tag'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                textCapitalization: TextCapitalization.none,
                style: TextStyle(color: cs.onSurface),
                decoration: InputDecoration(
                  hintText: 'e.g. vocabulary, physics',
                  hintStyle:
                      TextStyle(color: cs.onSurfaceVariant),
                  prefixText: '# ',
                  errorText: error,
                ),
                onChanged: (_) {
                  if (error != null) {
                    setDialogState(() => error = null);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final name = controller.text.trim().toLowerCase();
                if (name.isEmpty) return;
                if (existingTags.any((t) => t.name == name)) {
                  setDialogState(
                      () => error = 'Tag already exists');
                  return;
                }
                final newTag = Tag(name: name);
                ref.read(tagsProvider.notifier).add(newTag);
                setState(() {
                  _selectedTagIds =
                      Set.from(_selectedTagIds)..add(newTag.id);
                  _isDirty = true;
                });
                Navigator.pop(ctx);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Section label
// ─────────────────────────────────────────────
class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Text(
      text,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: cs.onSurfaceVariant,
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Format toolbar
// ─────────────────────────────────────────────
class _FormatToolbar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onChanged;
  final bool previewMode;
  final VoidCallback onTogglePreview;

  const _FormatToolbar({
    required this.controller,
    required this.onChanged,
    required this.previewMode,
    required this.onTogglePreview,
  });

  void _insert(String prefix, String suffix) {
    final text = controller.text;
    final sel = controller.selection;
    if (!sel.isValid) {
      controller.text = '$text$prefix$suffix';
      return;
    }
    final selected = sel.textInside(text);
    final newText = text.replaceRange(
        sel.start, sel.end, '$prefix$selected$suffix');
    controller.value = controller.value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(
          offset:
              sel.start + prefix.length + selected.length),
    );
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Widget btn(IconData icon, VoidCallback onTap,
        {bool active = false, String? tooltip}) {
      return Tooltip(
        message: tooltip ?? '',
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 36,
            height: 36,
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(
              color: active
                  ? cs.primary.withValues(alpha: 0.12)
                  : cs.surfaceContainerHigh,
              borderRadius:
                  BorderRadius.circular(AppRadius.sm),
              border: Border.all(
                color: active
                    ? cs.primary.withValues(alpha: 0.4)
                    : cs.outline,
              ),
            ),
            child: Icon(icon,
                size: 16,
                color: active ? cs.primary : cs.onSurface),
          ),
        ),
      );
    }

    return Row(
      children: [
        btn(Icons.format_bold_rounded,
            () => _insert('**', '**'),
            tooltip: 'Bold'),
        btn(Icons.format_italic_rounded,
            () => _insert('*', '*'),
            tooltip: 'Italic'),
        btn(Icons.format_list_bulleted_rounded,
            () => _insert('\n- ', ''),
            tooltip: 'Bullet list'),
        btn(Icons.code_rounded, () => _insert('`', '`'),
            tooltip: 'Inline code'),
        btn(Icons.format_quote_rounded,
            () => _insert('\n> ', ''),
            tooltip: 'Blockquote'),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Bottom action bar
// ─────────────────────────────────────────────
class _ActionBar extends StatelessWidget {
  final VoidCallback onSave;
  final VoidCallback onDiscard;
  final bool canSave;
  final bool isEdit;

  const _ActionBar({
    required this.onSave,
    required this.onDiscard,
    required this.canSave,
    required this.isEdit,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
            top: BorderSide(color: cs.outline, width: 0.5)),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md + MediaQuery.of(context).padding.bottom,
      ),
      child: Row(
        children: [
          Expanded(
            child: AppButton(
              label: 'DISCARD',
              type: AppButtonType.outline,
              height: 52,
              onPressed: onDiscard,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: AppButton(
              label: 'SAVE',
              type: AppButtonType.primary,
              height: 52,
              onPressed: canSave ? onSave : null,
            ),
          ),
        ],
      ),
    );
  }
}
