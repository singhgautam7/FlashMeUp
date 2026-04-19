import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/collection.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_bar_widget.dart';
import '../../../shared/widgets/app_bottom_sheet.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/fmu_fab.dart';
import '../../../shared/widgets/page_header.dart';
import '../../import_export/widgets/import_export_sheet.dart';

class CollectionsScreen extends ConsumerWidget {
  const CollectionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collections = ref.watch(collectionsProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AppBarWidget(actions: const []),
      ),
      body: collections.isEmpty
          ? EmptyState(
              icon: Icons.library_books_outlined,
              title: 'No Collections Yet',
              body:
                  'Create your first collection to start organising your flashcards.',
              actionLabel: 'ADD COLLECTION',
              onAction: () => context.push('/collections/new'),
            )
          : CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(
                  child: PageHeader(
                    title: 'Collections',
                    description: 'Curation of your knowledge assets',
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final col = collections[index];
                        return Padding(
                          padding: const EdgeInsets.only(
                              bottom: AppSpacing.md),
                          child: _CollectionCard(
                            collection: col,
                            onTap: () =>
                                context.push('/collections/${col.id}'),
                            onLongPress: () =>
                                _showOptions(context, ref, col),
                          ),
                        );
                      },
                      childCount: collections.length,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
      floatingActionButton: FmuFab(
        label: 'Add Collection',
        icon: Icons.add_rounded,
        onPressed: () => context.push('/collections/new'),
      ),
    );
  }

  void _showOptions(BuildContext context, WidgetRef ref,
      FlashcardCollection collection) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => UncontrolledProviderScope(
        container: ProviderScope.containerOf(context),
        child: _CollectionOptionsSheet(collection: collection),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Collection card — clean, no 3-dot / arrow
// ─────────────────────────────────────────────
class _CollectionCard extends ConsumerWidget {
  final FlashcardCollection collection;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _CollectionCard({
    required this.collection,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final cardCount = ref
        .watch(flashcardsProvider)
        .where((f) => f.collectionId == collection.id)
        .length;
    final accentColor = collection.color;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: cs.surfaceContainer,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: cs.outline),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon badge
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(
                collection.iconData,
                size: 22,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Title + description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    collection.title,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                          color: cs.onSurface,
                        ),
                  ),
                  if (collection.description != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      collection.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                            fontSize: 12,
                            color: cs.onSurfaceVariant,
                          ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  // Card count chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Text(
                      '$cardCount ${cardCount == 1 ? 'CARD' : 'CARDS'}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: accentColor,
                        letterSpacing: 0.5,
                      ),
                    ),
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

// ─────────────────────────────────────────────
// Options bottom sheet (shown on long press)
// ─────────────────────────────────────────────
class _CollectionOptionsSheet extends ConsumerWidget {
  final FlashcardCollection collection;

  const _CollectionOptionsSheet({required this.collection});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    return AppBottomSheet(
      title: collection.title,
      subtitle: 'Choose an action',
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _OptionTile(
            icon: Icons.edit_outlined,
            label: 'Edit Collection',
            onTap: () {
              Navigator.of(context).pop();
              context
                  .push('/collections/${collection.id}/edit');
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          _OptionTile(
            icon: Icons.swap_vert_rounded,
            label: 'Import / Export',
            onTap: () {
              Navigator.of(context).pop();
              ImportExportSheet.show(context);
            },
          ),
          const SizedBox(height: AppSpacing.md),
          _OptionTile(
            icon: Icons.delete_outline_rounded,
            label: 'Delete Collection',
            color: cs.error,
            onTap: () => _confirmDelete(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref) async {
    final cs = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(color: cs.outline),
        ),
        backgroundColor: cs.surfaceContainer,
        title: const Text('Delete Collection?'),
        content: Text(
          '"${collection.title}" and all its flashcards will be permanently deleted.',
        ),
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
    if (confirmed == true && context.mounted) {
      ref
          .read(collectionsProvider.notifier)
          .delete(collection.id);
      ref
          .read(flashcardsProvider.notifier)
          .deleteByCollection(collection.id);
      if (context.mounted) Navigator.of(context).pop();
    }
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _OptionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tileColor = color ?? cs.onSurface;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: 14),
        decoration: BoxDecoration(
          color: color != null
              ? cs.errorContainer.withValues(alpha: 0.4)
              : cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: color != null
                ? cs.error.withValues(alpha: 0.3)
                : cs.outline,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: tileColor),
            const SizedBox(width: AppSpacing.md),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: tileColor,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: tileColor.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }
}
