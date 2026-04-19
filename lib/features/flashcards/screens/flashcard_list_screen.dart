
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/collection.dart';
import '../../../core/models/flashcard.dart';
import '../../../core/models/tag.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/markdown_utils.dart';
import '../../../shared/widgets/app_bar_widget.dart';
import '../../../shared/widgets/app_bottom_sheet.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_how_to_sheet.dart';
import '../../../shared/widgets/fmu_fab.dart';
import '../../../shared/widgets/page_header.dart';
import '../../import_export/widgets/import_export_sheet.dart';

enum _ViewMode { card, table }

class FlashcardListScreen extends ConsumerStatefulWidget {
  final String collectionId;

  const FlashcardListScreen({super.key, required this.collectionId});

  @override
  ConsumerState<FlashcardListScreen> createState() =>
      _FlashcardListScreenState();
}

class _FlashcardListScreenState
    extends ConsumerState<FlashcardListScreen> {
  _ViewMode _viewMode = _ViewMode.card;

  late final PageController _pageController;
  late final ScrollController _outerScrollController;
  int _currentPage = 0;
  int _openSheets = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _outerScrollController = ScrollController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _outerScrollController.dispose();
    super.dispose();
  }

  void _goToPage(int page, int maxPage) {
    if (page < 0 || page >= maxPage) return;
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOut,
    );
  }

  Future<T?> _showSheet<T>({required WidgetBuilder builder}) {
    setState(() => _openSheets++);
    return showModalBottomSheet<T>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: builder,
    ).whenComplete(() => setState(() => _openSheets--));
  }

  void _showCardOptions(Flashcard card) {
    final collection = ref
        .read(collectionsProvider)
        .where((c) => c.id == widget.collectionId)
        .cast<FlashcardCollection?>()
        .firstOrNull;
    if (collection == null) return;
    _showSheet(
      builder: (_) => _CardOptionsSheet(
        card: card,
        collection: collection,
        onEdit: () {
          Navigator.of(context, rootNavigator: true).pop();
          context.push(
              '/collections/${card.collectionId}/card/${card.id}');
        },
        onDelete: () {
          Navigator.of(context, rootNavigator: true).pop();
          _confirmDelete(card);
        },
      ),
    );
  }

  void _showCardDetail(Flashcard card) {
    final collection = ref
        .read(collectionsProvider)
        .where((c) => c.id == widget.collectionId)
        .cast<FlashcardCollection?>()
        .firstOrNull;
    if (collection == null) return;
    _showSheet(
      builder: (_) => _CardDetailSheet(
        card: card,
        collection: collection,
        onEdit: () {
          Navigator.of(context, rootNavigator: true).pop();
          context.push(
              '/collections/${card.collectionId}/card/${card.id}');
        },
        onDeleteConfirm: () => _confirmDelete(card),
      ),
    );
  }

  Future<void> _confirmDelete(Flashcard card) async {
    final cs = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(color: cs.outline),
        ),
        backgroundColor: cs.surfaceContainer,
        title: const Text('Delete Card?'),
        content: Text('"${card.title}" will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: cs.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(flashcardsProvider.notifier).delete(card.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final collections = ref.watch(collectionsProvider);
    final collection = collections
        .where((c) => c.id == widget.collectionId)
        .cast<FlashcardCollection?>()
        .firstOrNull;

    if (collection == null) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => context.go('/collections'));
      return const SizedBox.shrink();
    }

    final flashcards =
        ref.watch(collectionFlashcardsProvider(widget.collectionId));
    final cs = Theme.of(context).colorScheme;

    return PopScope(
      canPop: _openSheets == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _openSheets > 0) {
          Navigator.of(context, rootNavigator: true).pop();
        }
      },
      child: Scaffold(
        backgroundColor: cs.surface,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: AppBarWidget(
            showBack: true,
            title: 'Collection',
            onBack: () {
              if (_openSheets > 0) {
                Navigator.of(context, rootNavigator: true).pop();
              } else if (context.canPop()) {
                context.pop();
              }
            },
            actions: [
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'quiz':
                      _startQuiz(context, flashcards);
                    case 'how_to':
                      AppHowToSheet.show(context);
                    case 'edit':
                      context.push(
                          '/collections/${widget.collectionId}/edit');
                    case 'import_export':
                      ImportExportSheet.show(context);
                  }
                },
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                    value: 'quiz',
                    child: _menuRow(
                        cs, Icons.play_arrow_rounded, 'Start Quiz'),
                  ),
                  PopupMenuItem(
                    value: 'how_to',
                    child: _menuRow(
                        cs, Icons.help_outline_rounded, 'How to use'),
                  ),
                  PopupMenuItem(
                    value: 'edit',
                    child: _menuRow(
                        cs, Icons.edit_outlined, 'Edit Collection'),
                  ),
                  PopupMenuItem(
                    value: 'import_export',
                    child: _menuRow(
                        cs, Icons.swap_vert_rounded, 'Import / Export'),
                  ),
                ],
                icon: Icon(Icons.more_vert_rounded,
                    color: cs.onSurfaceVariant, size: 22),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  side: BorderSide(color: cs.outline),
                ),
                elevation: 0,
                color: cs.surfaceContainerHigh,
              ),
            ],
          ),
        ),
        body: CustomScrollView(
          controller: _outerScrollController,
          slivers: [
            SliverToBoxAdapter(
              child: PageHeader(
                title: collection.title,
                icon: collection.iconData,
                iconColor: collection.color,
              ),
            ),

            if (flashcards.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyCardPlaceholder(
                  collectionId: widget.collectionId,
                ),
              )
            else ...[
              // View toggle
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg),
                sliver: SliverToBoxAdapter(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _ViewToggle(
                      viewMode: _viewMode,
                      onToggle: (v) => setState(() => _viewMode = v),
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.md)),

              // Main content
              if (_viewMode == _ViewMode.card)
                SliverToBoxAdapter(
                  child: _CardSection(
                    flashcards: flashcards,
                    collection: collection,
                    pageController: _pageController,
                    currentPage: _currentPage,
                    onPageChanged: (i) =>
                        setState(() => _currentPage = i),
                    onNavigate: (page) =>
                        _goToPage(page, flashcards.length),
                    collectionId: widget.collectionId,
                    outerController: _outerScrollController,
                    onCardLongPress: _showCardOptions,
                  ),
                )
              else
                _TableView(
                  flashcards: flashcards,
                  collection: collection,
                  collectionId: widget.collectionId,
                  onCardTap: _showCardDetail,
                  onCardLongPress: _showCardOptions,
                ),
            ],

            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
        floatingActionButton: FmuFab(
          label: 'Add Card',
          icon: Icons.add_rounded,
          onPressed: () =>
              context.push('/collections/${widget.collectionId}/add'),
        ),
      ),
    );
  }

  void _startQuiz(BuildContext context, List<Flashcard> cards) {
    if (cards.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Add some cards first to start a quiz!'),
            duration: Duration(seconds: 2)),
      );
      return;
    }
    _pageController.jumpToPage(0);
    setState(() {
      _currentPage = 0;
      _viewMode = _ViewMode.card;
    });
  }

  Widget _menuRow(ColorScheme cs, IconData icon, String label) =>
      Row(children: [
        Icon(icon, size: 18, color: cs.onSurface),
        const SizedBox(width: 12),
        Text(label),
      ]);
}

// ─────────────────────────────────────────────
// View toggle (Card / Table)
// ─────────────────────────────────────────────
class _ViewToggle extends StatelessWidget {
  final _ViewMode viewMode;
  final ValueChanged<_ViewMode> onToggle;

  const _ViewToggle({required this.viewMode, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Widget tab(IconData icon, String label, bool selected,
        VoidCallback onTap) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? cs.primary.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: selected
                ? Border.all(
                    color: cs.primary.withValues(alpha: 0.4))
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 14,
                  color: selected
                      ? cs.primary
                      : cs.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? cs.primary
                      : cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: cs.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          tab(Icons.grid_view_rounded, 'Card',
              viewMode == _ViewMode.card,
              () => onToggle(_ViewMode.card)),
          const SizedBox(width: 2),
          tab(Icons.table_rows_rounded, 'Table',
              viewMode == _ViewMode.table,
              () => onToggle(_ViewMode.table)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// CARD SECTION
// ─────────────────────────────────────────────
class _CardSection extends StatelessWidget {
  final List<Flashcard> flashcards;
  final FlashcardCollection collection;
  final PageController pageController;
  final int currentPage;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onNavigate;
  final String collectionId;
  final ScrollController outerController;
  final void Function(Flashcard) onCardLongPress;

  const _CardSection({
    required this.flashcards,
    required this.collection,
    required this.pageController,
    required this.currentPage,
    required this.onPageChanged,
    required this.onNavigate,
    required this.collectionId,
    required this.outerController,
    required this.onCardLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final total = flashcards.length;
    final displayNum = currentPage + 1;

    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (total > 0)
            Padding(
              padding:
                  const EdgeInsets.only(bottom: AppSpacing.sm),
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurfaceVariant,
                    letterSpacing: 0.5,
                  ),
                  children: [
                    const TextSpan(text: 'SHOWING '),
                    TextSpan(
                      text: '$displayNum',
                      style: TextStyle(color: cs.primary),
                    ),
                    const TextSpan(text: ' OF '),
                    TextSpan(
                      text: '$total',
                      style: TextStyle(color: cs.primary),
                    ),
                    const TextSpan(text: ' CARDS'),
                  ],
                ),
              ),
            ),

          SizedBox(
            height: 380,
            child: PageView.builder(
              controller: pageController,
              itemCount: total,
              onPageChanged: onPageChanged,
              itemBuilder: (ctx, index) {
                final card = flashcards[index];
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4),
                  child: _FlashCardPage(
                    key: ValueKey(card.id),
                    card: card,
                    isFocused: index == currentPage,
                    outerController: outerController,
                    onLongPress: () => onCardLongPress(card),
                  ),
                );
              },
            ),
          ),

          if (total > 0) ...[
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                _NavArrow(
                  direction: -1,
                  enabled: currentPage > 0,
                  onTap: () => onNavigate(currentPage - 1),
                ),
                const Spacer(),
                Text(
                  '$displayNum / $total',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                const Spacer(),
                _NavArrow(
                  direction: 1,
                  enabled: currentPage < total - 1,
                  onTap: () => onNavigate(currentPage + 1),
                ),
              ],
            ),
          ],

          const SizedBox(height: AppSpacing.xl),

          // Deck tags — tags used in this collection
          Text(
            'DECK TAGS',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Consumer(
            builder: (context, ref, _) {
              final allTags = ref.watch(tagsProvider);
              final usedTagIds =
                  flashcards.expand((c) => c.tagIds).toSet();
              final usedTags = allTags
                  .where((t) => usedTagIds.contains(t.id))
                  .toList();
              if (usedTags.isEmpty) {
                return Text(
                  'No tags assigned yet.',
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurfaceVariant
                        .withValues(alpha: 0.55),
                    fontStyle: FontStyle.italic,
                  ),
                );
              }
              return Wrap(
                spacing: 6,
                runSpacing: 4,
                children: usedTags
                    .map((tag) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(
                                AppRadius.full),
                            border: Border.all(color: cs.outline),
                          ),
                          child: Text(
                            '#${tag.name}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ))
                    .toList(),
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Navigation arrow button
// ─────────────────────────────────────────────
class _NavArrow extends StatelessWidget {
  final int direction;
  final bool enabled;
  final VoidCallback onTap;

  const _NavArrow({
    required this.direction,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isFwd = direction == 1;

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: isFwd
              ? (enabled ? cs.primary : cs.surfaceContainerHigh)
              : cs.surfaceContainerHigh,
          shape: BoxShape.circle,
          border: isFwd
              ? null
              : Border.all(
                  color: enabled
                      ? cs.outline
                      : cs.outline.withValues(alpha: 0.3)),
        ),
        child: Icon(
          isFwd
              ? Icons.arrow_forward_rounded
              : Icons.arrow_back_rounded,
          color: isFwd
              ? (enabled
                  ? Colors.white
                  : cs.onSurfaceVariant.withValues(alpha: 0.3))
              : (enabled
                  ? cs.onSurface
                  : cs.onSurfaceVariant.withValues(alpha: 0.3)),
          size: 22,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Empty card placeholder
// ─────────────────────────────────────────────
class _EmptyCardPlaceholder extends StatelessWidget {
  final String collectionId;
  const _EmptyCardPlaceholder({required this.collectionId});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () =>
          context.push('/collections/$collectionId/add'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_circle_outline_rounded,
              size: 44,
              color: cs.primary.withValues(alpha: 0.4)),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No cards yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap + Add Card to create your first flashcard',
            style: TextStyle(
              fontSize: 13,
              color: cs.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Flashcard page — self-managed flip animation
// ─────────────────────────────────────────────
class _FlashCardPage extends ConsumerStatefulWidget {
  final Flashcard card;
  final bool isFocused;
  final ScrollController outerController;
  final VoidCallback onLongPress;

  const _FlashCardPage({
    super.key,
    required this.card,
    required this.isFocused,
    required this.outerController,
    required this.onLongPress,
  });

  @override
  ConsumerState<_FlashCardPage> createState() =>
      _FlashCardPageState();
}

class _FlashCardPageState extends ConsumerState<_FlashCardPage> {
  bool _showBack = false;

  @override
  void didUpdateWidget(covariant _FlashCardPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isFocused && !widget.isFocused && _showBack) {
      setState(() => _showBack = false);
    }
  }

  void _flip() => setState(() => _showBack = !_showBack);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: _flip,
      onLongPress: widget.onLongPress,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale:
                  Tween<double>(begin: 0.95, end: 1.0).animate(animation),
              child: child,
            ),
          );
        },
        child: _showBack
            ? _BackFace(
                key: const ValueKey('back'),
                card: widget.card,
                cs: cs,
                outerController: widget.outerController,
              )
            : _FrontFace(
                key: const ValueKey('front'),
                card: widget.card,
                cs: cs,
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Card options sheet (long press) — redesigned
// ─────────────────────────────────────────────
class _CardOptionsSheet extends StatelessWidget {
  final Flashcard card;
  final FlashcardCollection collection;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CardOptionsSheet({
    required this.card,
    required this.collection,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return AppBottomSheet(
      title: card.title,
      subtitle: 'CARD OPTIONS',
      leadingIcon: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: collection.color,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Icon(collection.iconData,
            color: Colors.white, size: 20),
      ),
      actions: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.sm),
        child: Column(
          children: [
            AppButton(
              label: 'EDIT CARD',
              type: AppButtonType.outline,
              fullWidth: true,
              icon: Icons.edit_outlined,
              height: 50,
              onPressed: onEdit,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: 'DELETE CARD',
              type: AppButtonType.danger,
              fullWidth: true,
              icon: Icons.delete_outline_rounded,
              height: 50,
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Front face — no collection chip
// ─────────────────────────────────────────────
class _FrontFace extends StatelessWidget {
  final Flashcard card;
  final ColorScheme cs;

  const _FrontFace({
    super.key,
    required this.card,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: cs.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Accent top bar
          Container(height: 4, color: cs.primary),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title — centred vertically
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            card.title,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: cs.onSurface,
                                  height: 1.3,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          // Tag chips
                          Consumer(
                            builder: (context, ref, _) {
                              final allTags = ref.watch(tagsProvider);
                              final cardTags = card.tagIds
                                  .map((id) => allTags
                                      .where((t) => t.id == id)
                                      .cast<Tag?>()
                                      .firstOrNull)
                                  .whereType<Tag>()
                                  .toList();
                              if (cardTags.isEmpty) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding:
                                    const EdgeInsets.only(top: 10),
                                child: Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  alignment: WrapAlignment.center,
                                  children: cardTags
                                      .map((tag) => Container(
                                            padding: const EdgeInsets
                                                .symmetric(
                                                horizontal: 8,
                                                vertical: 3),
                                            decoration: BoxDecoration(
                                              color: cs
                                                  .surfaceContainerHigh,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      AppRadius.full),
                                              border: Border.all(
                                                  color: cs.outline),
                                            ),
                                            child: Text(
                                              '#${tag.name}',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight:
                                                    FontWeight.w600,
                                                color:
                                                    cs.onSurfaceVariant,
                                              ),
                                            ),
                                          ))
                                      .toList(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  // "VIEW ANSWER" footer
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color:
                                cs.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color:
                                    cs.primary.withValues(alpha: 0.3)),
                          ),
                          child: Icon(Icons.visibility_rounded,
                              size: 16, color: cs.primary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'VIEW ANSWER',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: cs.onSurfaceVariant
                                .withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Back face — with outer scroll propagation + review buttons
// ─────────────────────────────────────────────
class _BackFace extends StatelessWidget {
  final Flashcard card;
  final ColorScheme cs;
  final ScrollController outerController;

  const _BackFace({
    super.key,
    required this.card,
    required this.cs,
    required this.outerController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
            color: cs.primary.withValues(alpha: 0.3)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                Text(
                  'ANSWER',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: cs.primary.withValues(alpha: 0.6),
                  ),
                ),
                const Spacer(),
                Text(
                  'TAP TO FLIP',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                    color: cs.onSurfaceVariant
                        .withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
          Divider(
              height: 12,
              thickness: 0.5,
              color: cs.primary.withValues(alpha: 0.2)),
          Expanded(
            child: NotificationListener<OverscrollNotification>(
              onNotification: (notification) {
                if (outerController.hasClients) {
                  final newOffset = (outerController.offset +
                          notification.overscroll)
                      .clamp(0.0,
                          outerController.position.maxScrollExtent);
                  outerController.jumpTo(newOffset);
                }
                return true;
              },
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: card.content.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'No content yet.\nTap + Add Card to edit.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: cs.onSurfaceVariant
                                  .withValues(alpha: 0.5),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      )
                    : MarkdownBody(
                        data: card.content,
                        styleSheet: MarkdownStyleSheet.fromTheme(
                                Theme.of(context))
                            .copyWith(
                          p: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: cs.onSurface,
                                height: 1.6,
                              ),
                          code: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                fontFamily: 'monospace',
                                backgroundColor:
                                    cs.surfaceContainer,
                                color: cs.primary,
                              ),
                          blockquoteDecoration: BoxDecoration(
                            color: cs.surfaceContainer,
                            borderRadius: BorderRadius.circular(
                                AppRadius.sm),
                            border: Border(
                              left: BorderSide(
                                  color: cs.primary, width: 3),
                            ),
                          ),
                          blockquotePadding:
                              const EdgeInsets.fromLTRB(
                                  12, 8, 12, 8),
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// TABLE VIEW — search, sort, tag filter, row numbers, detail sheet
// ─────────────────────────────────────────────
class _TableView extends ConsumerStatefulWidget {
  final List<Flashcard> flashcards;
  final FlashcardCollection collection;
  final String collectionId;
  final void Function(Flashcard) onCardTap;
  final void Function(Flashcard) onCardLongPress;

  const _TableView({
    required this.flashcards,
    required this.collection,
    required this.collectionId,
    required this.onCardTap,
    required this.onCardLongPress,
  });

  @override
  ConsumerState<_TableView> createState() => _TableViewState();
}

class _TableViewState extends ConsumerState<_TableView> {
  String? _sortColumn; // 'title' | 'created' | 'modified'
  bool _sortAscending = true;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  Set<String> _selectedTagIds = {};

  @override
  void initState() {
    super.initState();
    _searchController.addListener(
        () => setState(() => _searchQuery = _searchController.text));
  }

  void _onColumnTap(String column) {
    setState(() {
      if (_sortColumn == column) {
        if (_sortAscending) {
          _sortAscending = false;
        } else {
          _sortColumn = null;
          _sortAscending = true;
        }
      } else {
        _sortColumn = column;
        _sortAscending = true;
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showTagFilterSheet(List<Tag> collectionTags, ColorScheme cs) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final sheetCs = Theme.of(ctx).colorScheme;
          return Container(
            decoration: BoxDecoration(
              color: sheetCs.surfaceContainer,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.lg),
              ),
              border: Border(
                top: BorderSide(color: sheetCs.outline),
                left: BorderSide(color: sheetCs.outline),
                right: BorderSide(color: sheetCs.outline),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    24, 12, 24, AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        margin: const EdgeInsets.only(
                            bottom: AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: sheetCs.onSurfaceVariant
                              .withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Text(
                      'Filter by Tag',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: sheetCs.onSurface,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: collectionTags.map((tag) {
                        final isSelected =
                            _selectedTagIds.contains(tag.id);
                        return GestureDetector(
                          onTap: () {
                            setState(() {
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
                            setSheetState(() {});
                          },
                          child: AnimatedContainer(
                            duration:
                                const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? sheetCs.primary
                                      .withValues(alpha: 0.12)
                                  : sheetCs.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(
                                  AppRadius.full),
                              border: Border.all(
                                color: isSelected
                                    ? sheetCs.primary
                                        .withValues(alpha: 0.5)
                                    : sheetCs.outline,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isSelected) ...[
                                  Icon(Icons.check_rounded,
                                      size: 13,
                                      color: sheetCs.primary),
                                  const SizedBox(width: 4),
                                ],
                                Text(
                                  '#${tag.name}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? sheetCs.primary
                                        : sheetCs.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    AppButton(
                      label: 'APPLY',
                      type: AppButtonType.primary,
                      fullWidth: true,
                      height: 50,
                      onPressed: () =>
                          Navigator.of(ctx, rootNavigator: true)
                              .pop(),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<Flashcard> get _displayCards {
    var list = widget.flashcards.where((c) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        if (!c.title.toLowerCase().contains(q) &&
            !c.content.toLowerCase().contains(q)) {
          return false;
        }
      }
      if (_selectedTagIds.isNotEmpty) {
        if (!c.tagIds.any((id) => _selectedTagIds.contains(id))) {
          return false;
        }
      }
      return true;
    }).toList();

    if (_sortColumn != null) {
      list.sort((a, b) {
        int cmp;
        switch (_sortColumn) {
          case 'title':
            cmp = a.title.toLowerCase().compareTo(b.title.toLowerCase());
          case 'created':
            cmp = a.createdAt.compareTo(b.createdAt);
          case 'modified':
            cmp = a.updatedAt.compareTo(b.updatedAt);
          default:
            cmp = 0;
        }
        return _sortAscending ? cmp : -cmp;
      });
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final allTags = ref.watch(tagsProvider);

    // Tags used in this collection's cards
    final usedTagIds =
        widget.flashcards.expand((c) => c.tagIds).toSet();
    final collectionTags =
        allTags.where((t) => usedTagIds.contains(t.id)).toList();

    final display = _displayCards;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row count
            RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurfaceVariant,
                  letterSpacing: 0.5,
                ),
                children: [
                  const TextSpan(text: 'SHOWING '),
                  TextSpan(
                      text: '${display.length}',
                      style: TextStyle(color: cs.primary)),
                  const TextSpan(text: ' ROWS'),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.sm),

            // Search + filter buttons row
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(fontSize: 14, color: cs.onSurface),
                    decoration: InputDecoration(
                      hintText: 'Search cards...',
                      hintStyle: TextStyle(color: cs.onSurfaceVariant),
                      prefixIcon: Icon(Icons.search_rounded,
                          size: 20, color: cs.onSurfaceVariant),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.close_rounded,
                                  size: 18, color: cs.onSurfaceVariant),
                              onPressed: () => _searchController.clear(),
                            )
                          : null,
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                // Filter button with active-count badge
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: _selectedTagIds.isNotEmpty
                            ? cs.primary.withValues(alpha: 0.1)
                            : cs.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: _selectedTagIds.isNotEmpty
                              ? cs.primary.withValues(alpha: 0.4)
                              : cs.outline,
                        ),
                      ),
                      child: IconButton(
                        constraints: const BoxConstraints(
                            minWidth: 40, minHeight: 40),
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          Icons.filter_list_rounded,
                          size: 20,
                          color: _selectedTagIds.isNotEmpty
                              ? cs.primary
                              : cs.onSurfaceVariant,
                        ),
                        onPressed: collectionTags.isEmpty
                            ? null
                            : () => _showTagFilterSheet(
                                collectionTags, cs),
                      ),
                    ),
                    if (_selectedTagIds.isNotEmpty)
                      Positioned(
                        right: -4,
                        top: -4,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: cs.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${_selectedTagIds.length}',
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: AppSpacing.xs),
                // Clear all filters button
                Container(
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: cs.outline),
                  ),
                  child: IconButton(
                    constraints: const BoxConstraints(
                        minWidth: 40, minHeight: 40),
                    padding: EdgeInsets.zero,
                    icon: Icon(Icons.close_rounded,
                        size: 20, color: cs.onSurfaceVariant),
                    onPressed: () {
                      setState(() {
                        _selectedTagIds = {};
                        _searchController.clear();
                      });
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            // Table
            if (display.isEmpty)
              Container(
                height: 100,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: cs.surfaceContainer,
                  borderRadius:
                      BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: cs.outline),
                ),
                child: Text(
                  _searchQuery.isEmpty && _selectedTagIds.isEmpty
                      ? 'No cards yet.'
                      : 'No cards match the current filter.',
                  style: TextStyle(
                      fontSize: 13, color: cs.onSurfaceVariant),
                ),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ClipRRect(
                  borderRadius:
                      BorderRadius.circular(AppRadius.md),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: cs.outline),
                      borderRadius:
                          BorderRadius.circular(AppRadius.md),
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        // Header
                        Container(
                          color: cs.surfaceContainerHigh,
                          child: Row(
                            children: [
                              _TH(text: '#', width: 44, cs: cs),
                              _SortableHeader(
                                text: 'TITLE',
                                width: 150,
                                columnKey: 'title',
                                sortColumn: _sortColumn,
                                sortAscending: _sortAscending,
                                onTap: _onColumnTap,
                                cs: cs,
                              ),
                              _TH(
                                  text: 'CONTENT',
                                  width: 200,
                                  cs: cs),
                              _SortableHeader(
                                text: 'CREATED',
                                width: 100,
                                columnKey: 'created',
                                sortColumn: _sortColumn,
                                sortAscending: _sortAscending,
                                onTap: _onColumnTap,
                                cs: cs,
                              ),
                              _SortableHeader(
                                text: 'MODIFIED',
                                width: 100,
                                columnKey: 'modified',
                                sortColumn: _sortColumn,
                                sortAscending: _sortAscending,
                                onTap: _onColumnTap,
                                cs: cs,
                              ),
                              _TH(text: 'TAGS', width: 130, cs: cs),
                            ],
                          ),
                        ),
                        Container(
                            height: 1,
                            color: cs.outline
                                .withValues(alpha: 0.5)),

                        // Data rows
                        ...display.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final card = entry.value;
                          return _TableDataRow(
                            index: idx + 1,
                            card: card,
                            allTags: allTags,
                            cs: cs,
                            isLast: idx == display.length - 1,
                            onTap: () =>
                                widget.onCardTap(card),
                            onLongPress: () =>
                                widget.onCardLongPress(card),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Sortable column header cell
// ─────────────────────────────────────────────
class _SortableHeader extends StatelessWidget {
  final String text;
  final double width;
  final String columnKey;
  final String? sortColumn;
  final bool sortAscending;
  final void Function(String) onTap;
  final ColorScheme cs;

  const _SortableHeader({
    required this.text,
    required this.width,
    required this.columnKey,
    required this.sortColumn,
    required this.sortAscending,
    required this.onTap,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = sortColumn == columnKey;
    return GestureDetector(
      onTap: () => onTap(columnKey),
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: isActive ? cs.primary : cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 3),
            Icon(
              isActive
                  ? (sortAscending
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded)
                  : Icons.unfold_more_rounded,
              size: 12,
              color: isActive
                  ? cs.primary
                  : cs.onSurfaceVariant.withValues(alpha: 0.35),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Table header cell
// ─────────────────────────────────────────────
class _TH extends StatelessWidget {
  final String text;
  final double width;
  final ColorScheme cs;

  const _TH({required this.text, required this.width, required this.cs});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 10),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: cs.onSurfaceVariant,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Table data row
// ─────────────────────────────────────────────
class _TableDataRow extends StatelessWidget {
  final int index;
  final Flashcard card;
  final List<Tag> allTags;
  final ColorScheme cs;
  final bool isLast;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _TableDataRow({
    required this.index,
    required this.card,
    required this.allTags,
    required this.cs,
    required this.isLast,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainer,
          border: isLast
              ? null
              : Border(
                  bottom: BorderSide(
                      color: cs.outline.withValues(alpha: 0.5),
                      width: 0.5)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 44,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 14),
                child: Text(
                  '$index',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color:
                          cs.onSurfaceVariant.withValues(alpha: 0.6)),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            SizedBox(
              width: 150,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 14),
                child: Text(
                  card.title,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            SizedBox(
              width: 200,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 14),
                child: Text(
                  card.content.isEmpty
                      ? '—'
                      : stripMarkdown(card.content),
                  style: TextStyle(
                      fontSize: 12, color: cs.onSurfaceVariant),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            SizedBox(
              width: 100,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 14),
                child: Text(
                  formatDate(card.createdAt),
                  style: TextStyle(
                      fontSize: 12, color: cs.onSurfaceVariant),
                ),
              ),
            ),
            SizedBox(
              width: 100,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 14),
                child: Text(
                  formatDate(card.updatedAt),
                  style: TextStyle(
                      fontSize: 12, color: cs.onSurfaceVariant),
                ),
              ),
            ),
            SizedBox(
              width: 130,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                child: card.tagIds.isEmpty
                    ? Text(
                        '—',
                        style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurfaceVariant
                                .withValues(alpha: 0.4)),
                      )
                    : Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: card.tagIds
                            .map((id) => allTags
                                .where((t) => t.id == id)
                                .cast<Tag?>()
                                .firstOrNull)
                            .whereType<Tag>()
                            .map((tag) => Container(
                                  padding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2),
                                  decoration: BoxDecoration(
                                    color: cs.surfaceContainerHigh,
                                    borderRadius:
                                        BorderRadius.circular(
                                            AppRadius.full),
                                    border: Border.all(
                                        color: cs.outline),
                                  ),
                                  child: Text(
                                    '#${tag.name}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Card detail bottom sheet
// ─────────────────────────────────────────────
class _CardDetailSheet extends StatelessWidget {
  final Flashcard card;
  final FlashcardCollection collection;
  final VoidCallback onEdit;
  final Future<void> Function() onDeleteConfirm;

  const _CardDetailSheet({
    required this.card,
    required this.collection,
    required this.onEdit,
    required this.onDeleteConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AppBottomSheet(
      title: card.title,
      leadingIcon: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: collection.color,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Icon(collection.iconData,
            color: Colors.white, size: 20),
      ),
      actions: Row(
        children: [
          Expanded(
            child: AppButton(
              label: 'EDIT',
              type: AppButtonType.outline,
              icon: Icons.edit_outlined,
              height: 48,
              onPressed: onEdit,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: AppButton(
              label: 'DELETE',
              type: AppButtonType.danger,
              icon: Icons.delete_outline_rounded,
              height: 48,
              onPressed: () async {
                Navigator.of(context, rootNavigator: true).pop();
                await onDeleteConfirm();
              },
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ANSWER',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: cs.outline),
            ),
            child: card.content.isEmpty
                ? Text(
                    'No answer content yet.',
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                      fontSize: 13,
                    ),
                  )
                : MarkdownBody(
                    data: card.content,
                    styleSheet:
                        MarkdownStyleSheet.fromTheme(Theme.of(context))
                            .copyWith(
                      p: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(
                            color: cs.onSurface,
                            height: 1.6,
                          ),
                      code: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                            fontFamily: 'monospace',
                            backgroundColor: cs.surfaceContainer,
                            color: cs.primary,
                          ),
                      blockquoteDecoration: BoxDecoration(
                        color: cs.surfaceContainer,
                        borderRadius:
                            BorderRadius.circular(AppRadius.sm),
                        border: Border(
                          left:
                              BorderSide(color: cs.primary, width: 3),
                        ),
                      ),
                      blockquotePadding:
                          const EdgeInsets.fromLTRB(12, 8, 12, 8),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
