import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/flashcard.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_bar_widget.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/page_header.dart';

class AddEditFlashcardScreen extends ConsumerStatefulWidget {
  final String collectionId;
  final String? cardId; // null = add mode

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
      }
    });
    _titleController.addListener(() => setState(() => _isDirty = true));
    _contentController.addListener(() => setState(() => _isDirty = true));
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

    if (_isEdit && _existingCard != null) {
      final updated = _existingCard!.copyWith(title: title, content: content);
      ref.read(flashcardsProvider.notifier).update(updated);
    } else {
      ref.read(flashcardsProvider.notifier).add(
        Flashcard(
          collectionId: widget.collectionId,
          title: title,
          content: content,
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
                backgroundColor: Theme.of(context).colorScheme.error,
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

    // Find the collection title for the header label
    final collection = ref
        .watch(collectionsProvider)
        .where((c) => c.id == widget.collectionId)
        .firstOrNull;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AppBarWidget(
          showBack: true,
          badge: _isDirty ? const AppBarBadge('UNSAVED') : null,
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
                    label: 'Collection',
                    title: collection?.title ?? 'Flashcard',
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── CARD FRONT ─────────────────────────
                        _sectionLabel(context, 'CARD FRONT (TITLE)', right: null),
                        const SizedBox(height: AppSpacing.sm),
                        TextField(
                          controller: _titleController,
                          textCapitalization:
                              TextCapitalization.sentences,
                          style: TextStyle(color: cs.onSurface),
                          decoration: InputDecoration(
                            hintText: 'Enter the core term or question',
                            hintStyle:
                                TextStyle(color: cs.onSurfaceVariant),
                          ),
                        ),

                        const SizedBox(height: AppSpacing.xl),

                        // ── CARD BACK ───────────────────────────
                        _sectionLabel(
                          context,
                          'CARD BACK (EXPLANATION)',
                          trailing: _FormatToolbar(
                            controller: _contentController,
                            onChanged: () => setState(() {}),
                            previewMode: _previewMode,
                            onTogglePreview: () => setState(
                                () => _previewMode = !_previewMode),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),

                        Container(
                          constraints:
                              const BoxConstraints(minHeight: 200),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainer,
                            borderRadius:
                                BorderRadius.circular(AppRadius.md),
                            border: Border.all(color: cs.outline),
                          ),
                          child: _previewMode
                              ? Padding(
                                  padding:
                                      const EdgeInsets.all(AppSpacing.lg),
                                  child:
                                      _contentController.text.isEmpty
                                          ? Text(
                                              'Nothing to preview yet...',
                                              style: TextStyle(
                                                color: cs.onSurfaceVariant,
                                                fontStyle:
                                                    FontStyle.italic,
                                              ),
                                            )
                                          : MarkdownBody(
                                              data:
                                                  _contentController.text,
                                              styleSheet:
                                                  MarkdownStyleSheet
                                                      .fromTheme(
                                                          Theme.of(context))
                                                      .copyWith(
                                                p: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(
                                                      color: cs.onSurface,
                                                    ),
                                              ),
                                            ),
                                )
                              : TextField(
                                  controller: _contentController,
                                  maxLines: null,
                                  minLines: 8,
                                  style: TextStyle(color: cs.onSurface),
                                  decoration: InputDecoration(
                                    hintText:
                                        'Explain using Markdown — **bold**, *italic*, `code`, lists...',
                                    hintStyle: TextStyle(
                                        color: cs.onSurfaceVariant),
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    contentPadding: const EdgeInsets.all(
                                        AppSpacing.lg),
                                  ),
                                ),
                        ),

                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              size: 12,
                              color: cs.primary.withValues(alpha: 0.7),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'MARKDOWN SUPPORTED',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.4,
                                color: cs.primary.withValues(alpha: 0.7),
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
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Fixed bottom action bar ─────────────────────
          _ActionBar(
            onSave: _save,
            onDiscard: _discard,
            canSave: _titleController.text.trim().isNotEmpty,
            isEdit: _isEdit,
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String label,
      {String? right, Widget? trailing}) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: cs.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        if (right case final r?) Text(r, style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
        if (trailing case final t?) t,
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Markdown format toolbar
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
          offset: sel.start + prefix.length + selected.length),
    );
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Widget btn(IconData icon, VoidCallback onTap, {bool active = false}) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          width: 28,
          height: 28,
          margin: const EdgeInsets.only(left: 4),
          decoration: BoxDecoration(
            color: active
                ? cs.primary.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(icon,
              size: 14,
              color: active ? cs.primary : cs.onSurfaceVariant),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        btn(Icons.format_bold_rounded, () => _insert('**', '**')),
        btn(Icons.format_italic_rounded, () => _insert('*', '*')),
        btn(Icons.format_list_bulleted_rounded, () => _insert('\n- ', '')),
        btn(Icons.code_rounded, () => _insert('`', '`')),
        btn(
          previewMode ? Icons.edit_rounded : Icons.visibility_outlined,
          onTogglePreview,
          active: previewMode,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Bottom action bar (fixed, not bottomSheet)
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
        border: Border(top: BorderSide(color: cs.outline, width: 0.5)),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppButton(
            label: isEdit ? 'SAVE CHANGES' : 'SAVE FLASHCARD',
            type: AppButtonType.primary,
            fullWidth: true,
            height: 52,
            onPressed: canSave ? onSave : null,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: 'DISCARD',
            type: AppButtonType.ghost,
            fullWidth: true,
            height: 40,
            onPressed: onDiscard,
          ),
        ],
      ),
    );
  }
}
