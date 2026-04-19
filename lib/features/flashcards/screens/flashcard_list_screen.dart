import 'dart:math' show pi;

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/collection.dart';
import '../../../core/models/flashcard.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/markdown_utils.dart';
import '../../../shared/widgets/app_bar_widget.dart';
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
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
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

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AppBarWidget(
          showBack: true,
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
        slivers: [
          SliverToBoxAdapter(
            child: PageHeader(
              label: 'Collection',
              title: collection.title,
            ),
          ),

          // ── Controls row ──────────────────────────
          SliverPadding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg),
            sliver: SliverToBoxAdapter(
              child: _ViewToggle(
                viewMode: _viewMode,
                onToggle: (v) => setState(() => _viewMode = v),
              ),
            ),
          ),

          const SliverToBoxAdapter(
              child: SizedBox(height: AppSpacing.md)),

          // ── Main content ──────────────────────────
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
              ),
            )
          else
            _TableView(
              flashcards: flashcards,
              collectionId: widget.collectionId,
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
      floatingActionButton: FmuFab(
        label: 'Add Card',
        icon: Icons.add_rounded,
        onPressed: () => context
            .push('/collections/${widget.collectionId}/add'),
      ),
    );
  }

  void _startQuiz(BuildContext context, List<Flashcard> cards) {
    if (cards.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Add some cards first to start a quiz!'),
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
// CARD SECTION — PageView + nav + tags
// ─────────────────────────────────────────────
class _CardSection extends StatelessWidget {
  final List<Flashcard> flashcards;
  final FlashcardCollection collection;
  final PageController pageController;
  final int currentPage;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onNavigate;
  final String collectionId;

  const _CardSection({
    required this.flashcards,
    required this.collection,
    required this.pageController,
    required this.currentPage,
    required this.onPageChanged,
    required this.onNavigate,
    required this.collectionId,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final total = flashcards.length;
    final displayNum = currentPage + 1; // 1-indexed for display

    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card count — ALL CAPS, accent numbers
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
                      style: TextStyle(color: collection.color),
                    ),
                    const TextSpan(text: ' OF '),
                    TextSpan(
                      text: '$total',
                      style: TextStyle(color: collection.color),
                    ),
                    const TextSpan(text: ' CARDS'),
                  ],
                ),
              ),
            ),

          // PageView
          SizedBox(
            height: 380,
            child: total == 0
                ? _EmptyCardPlaceholder(
                    collectionId: collectionId)
                : PageView.builder(
                    controller: pageController,
                    itemCount: total,
                    onPageChanged: onPageChanged,
                    itemBuilder: (ctx, index) {
                      final card = flashcards[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4),
                        child: _FlashCardPage(
                          key: ValueKey(card.id),
                          card: card,
                          collection: collection,
                        ),
                      );
                    },
                  ),
          ),

          // Navigation arrows row
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

          // DECK TAGS section
          const SizedBox(height: AppSpacing.xl),
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
          Text(
            'No tags assigned yet.',
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurfaceVariant.withValues(alpha: 0.55),
              fontStyle: FontStyle.italic,
            ),
          ),
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
// Empty card placeholder — full width, no bg
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
  final FlashcardCollection collection;

  const _FlashCardPage({
    super.key,
    required this.card,
    required this.collection,
  });

  @override
  ConsumerState<_FlashCardPage> createState() =>
      _FlashCardPageState();
}

class _FlashCardPageState extends ConsumerState<_FlashCardPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
  }

  void _flip() {
    if (_ctrl.value < 0.5) {
      _ctrl.forward();
    } else {
      _ctrl.reverse();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _showOptions(BuildContext context) async {
    final cs = Theme.of(context).colorScheme;
    await showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => UncontrolledProviderScope(
        container: ProviderScope.containerOf(context),
        child: _CardOptionsSheet(
            card: widget.card, cs: cs),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: _flip,
      onLongPress: () => _showOptions(context),
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (ctx, _) {
          final angle = _ctrl.value * pi;
          final showBack = angle > pi / 2;

          final Matrix4 matrix = Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(showBack ? angle - pi : angle);

          return Transform(
            alignment: Alignment.center,
            transform: matrix,
            child: showBack
                ? _BackFace(
                    card: widget.card, cs: cs)
                : _FrontFace(
                    card: widget.card,
                    collection: widget.collection,
                    cs: cs,
                  ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Card options sheet (long press)
// ─────────────────────────────────────────────
class _CardOptionsSheet extends ConsumerWidget {
  final Flashcard card;
  final ColorScheme cs;

  const _CardOptionsSheet({required this.card, required this.cs});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: cs.onSurfaceVariant.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 4),
              child: Text(
                card.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            ListTile(
              leading: Icon(Icons.edit_outlined,
                  color: cs.primary),
              title: const Text('Edit Card'),
              onTap: () {
                Navigator.of(context).pop();
                context.push(
                    '/collections/${card.collectionId}/card/${card.id}');
              },
            ),
            ListTile(
              leading: Icon(
                  Icons.delete_outline_rounded, color: cs.error),
              title: Text('Delete Card',
                  style: TextStyle(color: cs.error)),
              onTap: () =>
                  _confirmDelete(context, ref),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref) async {
    Navigator.of(context).pop();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(color: cs.outline),
        ),
        backgroundColor: cs.surfaceContainer,
        title: const Text('Delete Card?'),
        content: Text(
            '"${card.title}" will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
                backgroundColor: cs.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(flashcardsProvider.notifier).delete(card.id);
    }
  }
}

// ─────────────────────────────────────────────
// Front face
// ─────────────────────────────────────────────
class _FrontFace extends StatelessWidget {
  final Flashcard card;
  final FlashcardCollection collection;
  final ColorScheme cs;

  const _FrontFace({
    required this.card,
    required this.collection,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = collection.color;

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
          Container(height: 4, color: accentColor),
          Expanded(
            child: Padding(
              padding:
                  const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  // Top row: collection chip + bookmark
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: accentColor
                              .withValues(alpha: 0.12),
                          borderRadius:
                              BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Text(
                          collection.title.toUpperCase(),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                            color: accentColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.bookmark_border_rounded,
                        size: 18,
                        color: cs.onSurfaceVariant
                            .withValues(alpha: 0.4),
                      ),
                    ],
                  ),

                  // Title — centred vertically
                  Expanded(
                    child: Center(
                      child: Text(
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
                    ),
                  ),

                  // "VIEW SIDE B" footer
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: accentColor
                                .withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: accentColor
                                    .withValues(alpha: 0.3)),
                          ),
                          child: Icon(
                            Icons.visibility_rounded,
                            size: 16,
                            color: accentColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'VIEW SIDE B',
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
// Back face
// ─────────────────────────────────────────────
class _BackFace extends StatelessWidget {
  final Flashcard card;
  final ColorScheme cs;

  const _BackFace({required this.card, required this.cs});

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
            padding:
                const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                Text(
                  'SIDE B',
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
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.fromLTRB(20, 0, 20, 16),
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
                      styleSheet:
                          MarkdownStyleSheet.fromTheme(
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
// TABLE VIEW
// ─────────────────────────────────────────────
class _TableView extends ConsumerWidget {
  final List<Flashcard> flashcards;
  final String collectionId;

  const _TableView(
      {required this.flashcards, required this.collectionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final headerStyle = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.5,
      color: cs.onSurfaceVariant,
    );

    if (flashcards.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg),
          child: Container(
            height: 120,
            alignment: Alignment.center,
            child: Text(
              'No cards yet — tap Add Card to get started.',
              style: TextStyle(
                  color: cs.onSurfaceVariant, fontSize: 13),
            ),
          ),
        ),
      );
    }

    return SliverToBoxAdapter(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: cs.outline),
              borderRadius:
                  BorderRadius.circular(AppRadius.md),
            ),
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                  cs.surfaceContainerHigh),
              dataRowColor: WidgetStateProperty.all(
                  cs.surfaceContainer),
              columnSpacing: 20,
              horizontalMargin: 16,
              headingRowHeight: 44,
              dataRowMinHeight: 52,
              dataRowMaxHeight: 72,
              border: TableBorder(
                horizontalInside: BorderSide(
                    color: cs.outline, width: 0.5),
              ),
              columns: [
                DataColumn(
                    label: Text('TITLE', style: headerStyle)),
                DataColumn(
                    label:
                        Text('CONTENT', style: headerStyle)),
                DataColumn(
                    label:
                        Text('CREATED', style: headerStyle)),
                DataColumn(
                    label:
                        Text('MODIFIED', style: headerStyle)),
                DataColumn(
                    label:
                        Text('ACTIONS', style: headerStyle)),
              ],
              rows: flashcards.map((card) {
                return DataRow(cells: [
                  DataCell(SizedBox(
                    width: 140,
                    child: Text(
                      card.title,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                          fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  )),
                  DataCell(SizedBox(
                    width: 220,
                    child: Text(
                      card.content.isEmpty
                          ? '—'
                          : stripMarkdown(card.content),
                      style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  )),
                  DataCell(Text(formatDate(card.createdAt),
                      style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant))),
                  DataCell(Text(formatDate(card.updatedAt),
                      style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant))),
                  DataCell(Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () => context.push(
                            '/collections/$collectionId/card/${card.id}'),
                        icon: Icon(Icons.edit_outlined,
                            size: 16, color: cs.primary),
                        tooltip: 'Edit',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                            minWidth: 32, minHeight: 32),
                      ),
                      IconButton(
                        onPressed: () =>
                            _confirmDelete(context, ref, card),
                        icon: Icon(
                            Icons.delete_outline_rounded,
                            size: 16,
                            color: cs.error),
                        tooltip: 'Delete',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                            minWidth: 32, minHeight: 32),
                      ),
                    ],
                  )),
                ]);
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context,
      WidgetRef ref, Flashcard card) async {
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
        content: Text(
            '"${card.title}" will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
                backgroundColor: cs.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(flashcardsProvider.notifier).delete(card.id);
    }
  }
}
