import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/tag.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_bar_widget.dart';
import '../../../shared/widgets/app_bottom_sheet.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/fmu_fab.dart';
import '../../../shared/widgets/page_header.dart';

class TagsScreen extends ConsumerStatefulWidget {
  const TagsScreen({super.key});

  @override
  ConsumerState<TagsScreen> createState() => _TagsScreenState();
}

class _TagsScreenState extends ConsumerState<TagsScreen> {
  void _showAddTagSheet() {
    final cs = Theme.of(context).colorScheme;
    final controller = TextEditingController();
    String? error;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: StatefulBuilder(
          builder: (ctx, setSheetState) => Container(
            decoration: BoxDecoration(
              color: cs.surfaceContainer,
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.lg)),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: cs.onSurfaceVariant
                              .withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Text(
                      'New Tag',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tags are lowercase and unique. Use them to label cards across collections.',
                      style: TextStyle(
                          fontSize: 12, color: cs.onSurfaceVariant),
                    ),
                    const SizedBox(height: 16),
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
                          setSheetState(() => error = null);
                        }
                      },
                      onSubmitted: (_) => _saveTag(
                          controller, setSheetState, ctx,
                          (e) => error = e),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () => _saveTag(
                                controller, setSheetState, ctx,
                                (e) => error = e),
                            child: const Text('Add Tag'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _saveTag(
    TextEditingController controller,
    StateSetter setSheetState,
    BuildContext ctx,
    void Function(String?) setError,
  ) {
    final tags = ref.read(tagsProvider);
    final name = controller.text.trim().toLowerCase();
    if (name.isEmpty) return;
    if (tags.any((t) => t.name == name)) {
      setSheetState(() => setError('Tag "$name" already exists'));
      return;
    }
    ref.read(tagsProvider.notifier).add(Tag(name: name));
    Navigator.pop(ctx);
  }

  void _showTagDetailSheet(BuildContext context, Tag tag, int cardCount) {
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AppBottomSheet(
        title: '#${tag.name}',
        leadingIcon: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: cs.primary,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Center(
            child: Text(
              '#',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
        ),
        actions: Column(
          children: [
            AppButton(
              label: 'RENAME TAG',
              type: AppButtonType.outline,
              fullWidth: true,
              icon: Icons.edit_outlined,
              height: 50,
              onPressed: () {
                Navigator.of(context, rootNavigator: true).pop();
                _showRenameSheet(context, tag);
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: 'DELETE TAG',
              type: AppButtonType.danger,
              fullWidth: true,
              icon: Icons.delete_outline_rounded,
              height: 50,
              onPressed: () {
                Navigator.of(context, rootNavigator: true).pop();
                _showDeleteConfirmation(context, tag);
              },
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DetailRow(
              icon: Icons.style_outlined,
              label: 'Cards',
              value: '$cardCount card${cardCount == 1 ? '' : 's'}',
              cs: cs,
            ),
            const SizedBox(height: AppSpacing.sm),
            _DetailRow(
              icon: Icons.calendar_today_outlined,
              label: 'Created',
              value: _formatDate(tag.createdAt),
              cs: cs,
            ),
          ],
        ),
      ),
    );
  }

  void _showRenameSheet(BuildContext context, Tag tag) {
    final cs = Theme.of(context).colorScheme;
    final controller = TextEditingController(text: tag.name);
    String? error;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: StatefulBuilder(
          builder: (ctx, setSheetState) => Container(
            decoration: BoxDecoration(
              color: cs.surfaceContainer,
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.lg)),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: cs.onSurfaceVariant
                              .withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Text(
                      'Rename Tag',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: controller,
                      autofocus: true,
                      textCapitalization: TextCapitalization.none,
                      style: TextStyle(color: cs.onSurface),
                      decoration: InputDecoration(
                        hintText: 'New tag name',
                        hintStyle:
                            TextStyle(color: cs.onSurfaceVariant),
                        prefixText: '# ',
                        errorText: error,
                      ),
                      onChanged: (_) {
                        if (error != null) {
                          setSheetState(() => error = null);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () {
                              final tags = ref.read(tagsProvider);
                              final name = controller.text
                                  .trim()
                                  .toLowerCase();
                              if (name.isEmpty) return;
                              if (name != tag.name &&
                                  tags.any((t) => t.name == name)) {
                                setSheetState(() => error =
                                    'Tag "$name" already exists');
                                return;
                              }
                              ref
                                  .read(tagsProvider.notifier)
                                  .rename(tag.id, name);
                              Navigator.pop(ctx);
                            },
                            child: const Text('Rename'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Tag tag) {
    final cs = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(color: cs.outline),
        ),
        backgroundColor: cs.surfaceContainer,
        title: const Text('Delete Tag?'),
        content: Text(
          '"#${tag.name}" will be removed from all cards.',
          style: TextStyle(color: cs.onSurface, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(tagsProvider.notifier).delete(tag.id);
            },
            style: FilledButton.styleFrom(
                backgroundColor: cs.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tags = ref.watch(tagsProvider);
    final flashcards = ref.watch(flashcardsProvider);

    Map<String, int> tagCardCounts = {};
    for (final card in flashcards) {
      for (final tagId in card.tagIds) {
        tagCardCounts[tagId] = (tagCardCounts[tagId] ?? 0) + 1;
      }
    }

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AppBarWidget(actions: const []),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: PageHeader(
              label: 'LIBRARY',
              title: 'Tags',
              description: 'Organise cards across collections with tags',
            ),
          ),
          if (tags.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        borderRadius:
                            BorderRadius.circular(AppRadius.lg),
                      ),
                      child: Icon(Icons.label_outline_rounded,
                          color: cs.primary, size: 32),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'No tags yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xxl),
                      child: Text(
                        'Tap + to create your first tag. Add them to cards while editing.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: cs.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Text(
                    '${tags.length} TAG${tags.length == 1 ? '' : 'S'}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ...tags.map((tag) {
                    final count = tagCardCounts[tag.id] ?? 0;
                    return Padding(
                      padding:
                          const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _TagRow(
                        tag: tag,
                        cardCount: count,
                        onTap: () => _showTagDetailSheet(
                            context, tag, count),
                      ),
                    );
                  }),
                  const SizedBox(height: 120),
                ]),
              ),
            ),
        ],
      ),
      floatingActionButton: FmuFab(
        label: 'Add Tag',
        icon: Icons.add_rounded,
        onPressed: _showAddTagSheet,
      ),
    );
  }
}

class _TagRow extends StatelessWidget {
  final Tag tag;
  final int cardCount;
  final VoidCallback onTap;

  const _TagRow({
    required this.tag,
    required this.cardCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: cs.surfaceContainer,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: cs.outline),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: cs.primary,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Center(
                child: Text(
                  '#',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '#${tag.name}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                  Text(
                    '$cardCount card${cardCount == 1 ? '' : 's'}',
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: cs.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ColorScheme cs;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: cs.onSurfaceVariant),
        const SizedBox(width: AppSpacing.sm),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: cs.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
        ),
      ],
    );
  }
}
