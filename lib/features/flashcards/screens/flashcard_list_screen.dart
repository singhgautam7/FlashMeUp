


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
  bool _showHint = false; // eye: show brief back-text on front face

  late final PageController _pageController;
  int _currentPage = 0; // 0 = info card, 1..N = cards
  bool _isFlipped = false;

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

  void _goToPage(int page, List<Flashcard> cards) {
    final maxPage = cards.length; // 0 = info, 1..N = cards
    if (page < 0 || page > maxPage) return;
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
                if (value == 'edit') {
                  context.push(
                      '/collections/${widget.collectionId}/edit');
                } else if (value == 'quiz') {
                  _startQuiz(context, flashcards);
                } else if (value == 'import_export') {
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
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  _ViewToggle(
                    viewMode: _viewMode,
                    onToggle: (v) => setState(() => _viewMode = v),
                  ),
                  const Spacer(),
                  Tooltip(
                    message: _showHint
                        ? 'Hide back preview'
                        : 'Show back preview',
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _showHint = !_showHint),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _showHint
                              ? cs.primary.withValues(alpha: 0.1)
                              : Colors.transparent,
                          borderRadius:
                              BorderRadius.circular(AppRadius.md),
                          border: _showHint
                              ? Border.all(
                                  color: cs.primary
                                      .withValues(alpha: 0.4))
                              : null,
                        ),
                        child: Icon(
                          _showHint
                              ? Icons.visibility_rounded
                              : Icons.visibility_off_outlined,
                          size: 18,
                          color: _showHint
                              ? cs.primary
                              : cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),

          // ── Main content ──────────────────────────
          if (_viewMode == _ViewMode.card)
            SliverToBoxAdapter(
              child: _CardSection(
                flashcards: flashcards,
                collection: collection,
                pageController: _pageController,
                currentPage: _currentPage,
                isFlipped: _isFlipped,
                showHint: _showHint,
                onPageChanged: (i) => setState(() {
                  _currentPage = i;
                  _isFlipped = false;
                }),
                onFlip: () =>
                    setState(() => _isFlipped = !_isFlipped),
                onNavigate: (page) => _goToPage(page, flashcards),
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
        onPressed: () =>
            context.push('/collections/${widget.collectionId}/add'),
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
    // Jump to first real card
    _pageController.jumpToPage(1);
    setState(() {
      _currentPage = 1;
      _isFlipped = false;
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
                ? Border.all(color: cs.primary.withValues(alpha: 0.4))
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 14,
                  color:
                      selected ? cs.primary : cs.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color:
                      selected ? cs.primary : cs.onSurfaceVariant,
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
  final bool isFlipped;
  final bool showHint;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onFlip;
  final ValueChanged<int> onNavigate;
  final String collectionId;

  const _CardSection({
    required this.flashcards,
    required this.collection,
    required this.pageController,
    required this.currentPage,
    required this.isFlipped,
    required this.showHint,
    required this.onPageChanged,
    required this.onFlip,
    required this.onNavigate,
    required this.collectionId,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final total = flashcards.length;
    // pageCount: 1 info card + N flashcards
    final pageCount = total + 1;
    // display index (0-based): currentPage 0 → display "–", 1..N → "N"
    final displayNum = currentPage == 0 ? 0 : currentPage;

    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card count label
          if (total > 0)
            Padding(
              padding:
                  const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text(
                currentPage == 0
                    ? 'Showing $total cards'
                    : 'Showing $displayNum of $total cards',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurfaceVariant,
                  letterSpacing: 0.2,
                ),
              ),
            ),

          // PageView
          SizedBox(
            height: 380,
            child: total == 0
                ? _EmptyCardPlaceholder(collectionId: collectionId)
                : PageView.builder(
                    controller: pageController,
                    itemCount: pageCount,
                    onPageChanged: onPageChanged,
                    itemBuilder: (ctx, index) {
                      if (index == 0) {
                        return const Padding(
                          padding:
                              EdgeInsets.symmetric(horizontal: 4),
                          child: _InfoCard(),
                        );
                      }
                      final card = flashcards[index - 1];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4),
                        child: _FlashCardPage(
                          card: card,
                          collection: collection,
                          isFlipped: isFlipped &&
                              currentPage == index,
                          showHint: showHint,
                          onFlip: onFlip,
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
                // Left arrow
                _NavArrow(
                  direction: -1,
                  enabled: currentPage > 0,
                  onTap: () => onNavigate(currentPage - 1),
                ),
                const Spacer(),
                // Counter
                Text(
                  currentPage == 0
                      ? '– / $total'
                      : '$displayNum / $total',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                const Spacer(),
                // Right arrow
                _NavArrow(
                  direction: 1,
                  enabled: currentPage < total,
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
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: 10),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: cs.outline),
            ),
            child: Text(
              'No tags assigned yet',
              style: TextStyle(
                fontSize: 12,
                color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                fontStyle: FontStyle.italic,
              ),
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
  final int direction; // -1 left, +1 right
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

    if (isFwd) {
      return GestureDetector(
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: enabled ? cs.primary : cs.surfaceContainerHigh,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.arrow_forward_rounded,
            color: enabled
                ? Colors.white
                : cs.onSurfaceVariant.withValues(alpha: 0.3),
            size: 22,
          ),
        ),
      );
    }
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: enabled
                ? cs.outline
                : cs.outline.withValues(alpha: 0.3),
          ),
          color: cs.surfaceContainerHigh,
        ),
        child: Icon(
          Icons.arrow_back_rounded,
          color: enabled
              ? cs.onSurface
              : cs.onSurfaceVariant.withValues(alpha: 0.3),
          size: 22,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Info card (page 0)
// ─────────────────────────────────────────────
class _InfoCard extends StatelessWidget {
  const _InfoCard();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
            color: cs.outline.withValues(alpha: 0.5), width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.touch_app_rounded,
            size: 52,
            color: cs.onSurfaceVariant.withValues(alpha: 0.35),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'TAP TO REVEAL ANSWER',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: cs.onSurfaceVariant.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Swipe left or right to navigate cards',
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurfaceVariant.withValues(alpha: 0.4),
            ),
          ),
        ],
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
      onTap: () => context.push('/collections/$collectionId/add'),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: cs.primary.withValues(alpha: 0.3),
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline_rounded,
                size: 40,
                color: cs.primary.withValues(alpha: 0.5)),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Add your first flashcard',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: cs.primary.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Individual flashcard page
// ─────────────────────────────────────────────
class _FlashCardPage extends ConsumerWidget {
  final Flashcard card;
  final FlashcardCollection collection;
  final bool isFlipped;
  final bool showHint;
  final VoidCallback onFlip;

  const _FlashCardPage({
    required this.card,
    required this.collection,
    required this.isFlipped,
    required this.showHint,
    required this.onFlip,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onFlip,
      onLongPress: () => _showCardOptions(context, ref),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 320),
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.04),
              end: Offset.zero,
            ).animate(CurvedAnimation(
                parent: animation, curve: Curves.easeOut)),
            child: child,
          ),
        ),
        child: isFlipped
            ? KeyedSubtree(
                key: const ValueKey('back'),
                child: _BackFace(card: card, cs: cs),
              )
            : KeyedSubtree(
                key: const ValueKey('front'),
                child: _FrontFace(
                    card: card,
                    collection: collection,
                    cs: cs,
                    showHint: showHint),
              ),
      ),
    );
  }

  void _showCardOptions(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => UncontrolledProviderScope(
        container: ProviderScope.containerOf(context),
        child: Container(
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
                ListTile(
                  leading: Icon(Icons.edit_outlined, color: cs.primary),
                  title: const Text('Edit Card'),
                  onTap: () {
                    Navigator.pop(context);
                    context.push(
                        '/collections/${card.collectionId}/card/${card.id}');
                  },
                ),
                ListTile(
                  leading:
                      Icon(Icons.delete_outline_rounded, color: cs.error),
                  title: Text('Delete Card',
                      style: TextStyle(color: cs.error)),
                  onTap: () {
                    Navigator.pop(context);
                    ref
                        .read(flashcardsProvider.notifier)
                        .delete(card.id);
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Front face
// ─────────────────────────────────────────────
class _FrontFace extends StatelessWidget {
  final Flashcard card;
  final FlashcardCollection collection;
  final ColorScheme cs;
  final bool showHint;

  const _FrontFace({
    required this.card,
    required this.collection,
    required this.cs,
    required this.showHint,
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
      child: Column(
        children: [
          // Top accent bar
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.lg)),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: collection chip + bookmark icon
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.12),
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
                      Icon(Icons.bookmark_border_rounded,
                          size: 18,
                          color: cs.onSurfaceVariant
                              .withValues(alpha: 0.4)),
                    ],
                  ),

                  // Title — centered vertically in remaining space
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

                  // Hint text (back preview)
                  if (showHint && card.content.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        stripMarkdown(card.content),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant
                              .withValues(alpha: 0.6),
                          fontStyle: FontStyle.italic,
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
                            color: accentColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color:
                                    accentColor.withValues(alpha: 0.3)),
                          ),
                          child: Icon(Icons.visibility_rounded,
                              size: 16, color: accentColor),
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
        border: Border.all(color: cs.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
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
                    color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
          Divider(
              height: 12,
              thickness: 0.5,
              color: cs.primary.withValues(alpha: 0.2)),
          // Scrollable markdown content
          Expanded(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: card.content.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'No content added yet.\nTap to edit.',
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

  const _TableView({required this.flashcards, required this.collectionId});

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
      return SliverPadding(
        padding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        sliver: SliverToBoxAdapter(
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
        padding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: cs.outline),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: DataTable(
            headingRowColor:
                WidgetStateProperty.all(cs.surfaceContainerHigh),
            dataRowColor:
                WidgetStateProperty.all(cs.surfaceContainer),
            columnSpacing: 20,
            horizontalMargin: 16,
            headingRowHeight: 44,
            dataRowMinHeight: 52,
            dataRowMaxHeight: 72,
            border: TableBorder(
              horizontalInside:
                  BorderSide(color: cs.outline, width: 0.5),
            ),
            columns: [
              DataColumn(label: Text('TITLE', style: headerStyle)),
              DataColumn(
                  label: Text('CONTENT', style: headerStyle)),
              DataColumn(
                  label: Text('CREATED', style: headerStyle)),
              DataColumn(
                  label: Text('MODIFIED', style: headerStyle)),
              DataColumn(
                  label: Text('ACTIONS', style: headerStyle)),
            ],
            rows: flashcards.map((card) {
              return DataRow(cells: [
                DataCell(SizedBox(
                  width: 140,
                  child: Text(card.title,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                          fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2),
                )),
                DataCell(SizedBox(
                  width: 220,
                  child: Text(
                    card.content.isEmpty
                        ? '—'
                        : stripMarkdown(card.content),
                    style: TextStyle(
                        fontSize: 12, color: cs.onSurfaceVariant),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                )),
                DataCell(Text(formatDate(card.createdAt),
                    style: TextStyle(
                        fontSize: 12, color: cs.onSurfaceVariant))),
                DataCell(Text(formatDate(card.updatedAt),
                    style: TextStyle(
                        fontSize: 12, color: cs.onSurfaceVariant))),
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
                      onPressed: () => ref
                          .read(flashcardsProvider.notifier)
                          .delete(card.id),
                      icon: Icon(Icons.delete_outline_rounded,
                          size: 16, color: cs.error),
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
    );
  }
}
