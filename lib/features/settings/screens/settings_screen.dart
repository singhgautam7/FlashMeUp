import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_bar_widget.dart';
import '../../../shared/widgets/settings_widgets.dart';
import '../../import_export/import_export_service.dart';
import '../../import_export/widgets/import_export_sheet.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      backgroundColor: cs.surface,
      body: CustomScrollView(
        slivers: [
          // AppBar — brand, no back (root tab)
          SliverToBoxAdapter(
            child: AppBarWidget(actions: const []),
          ),

          // Page header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'App\nSettings',
                    style:
                        Theme.of(context).textTheme.displaySmall?.copyWith(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: cs.onSurface,
                              height: 1.15,
                              letterSpacing: -0.5,
                            ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Customize your FlashMeUp experience.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 13,
                          color: cs.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── APPEARANCE ──────────────────────────────
                const SectionLabel(label: 'APPEARANCE'),
                const SizedBox(height: AppSpacing.sm),
                SettingsCard(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const SquircleIcon(
                                icon: Icons.palette_outlined,
                                size: 18,
                                padding: 8,
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Text(
                                'Theme',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: cs.onSurface,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          SettingsCardSelector<ThemeMode>(
                            options: const [
                              SelectorOption(
                                value: ThemeMode.light,
                                label: 'LIGHT',
                                icon: Icons.light_mode_outlined,
                              ),
                              SelectorOption(
                                value: ThemeMode.dark,
                                label: 'DARK',
                                icon: Icons.dark_mode_outlined,
                              ),
                              SelectorOption(
                                value: ThemeMode.system,
                                label: 'SYSTEM',
                                icon: Icons.settings_brightness_outlined,
                              ),
                            ],
                            selectedValue: themeMode,
                            onSelected: (val) {
                              ref
                                  .read(themeModeProvider.notifier)
                                  .setMode(val);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.xl),

                // // ── STUDY PREFERENCES ────────────────────────
                // const SectionLabel(label: 'STUDY PREFERENCES'),
                // const SizedBox(height: AppSpacing.sm),
                // SettingsCard(
                //   children: [
                //     SettingsTile(
                //       icon: Icons.repeat_rounded,
                //       label: 'Spaced Repetition',
                //       subtitle: 'SuperMemo-2 algorithm',
                //       trailing: Switch(
                //         value: true,
                //         onChanged: (_) {},
                //       ),
                //     ),
                //     Divider(height: 1, color: cs.outline),
                //     SettingsTile(
                //       icon: Icons.shuffle_rounded,
                //       label: 'Shuffle Cards',
                //       subtitle: 'Randomize review order',
                //       trailing: Switch(
                //         value: false,
                //         onChanged: (_) {},
                //       ),
                //     ),
                //     Divider(height: 1, color: cs.outline),
                //     SettingsTile(
                //       icon: Icons.timer_outlined,
                //       label: 'Daily Goal',
                //       subtitle: 'Cards per session',
                //       onTap: () {},
                //       trailing: Row(
                //         mainAxisSize: MainAxisSize.min,
                //         children: [
                //           Text(
                //             '20 cards',
                //             style: TextStyle(
                //               fontSize: 14,
                //               color: cs.onSurfaceVariant,
                //             ),
                //           ),
                //           const SizedBox(width: AppSpacing.sm),
                //           Icon(
                //             Icons.chevron_right_rounded,
                //             size: 20,
                //             color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                //           ),
                //         ],
                //       ),
                //     ),
                //   ],
                // ),

                // const SizedBox(height: AppSpacing.xl),

                // ── DATA ────────────────────────────────────
                const SectionLabel(label: 'DATA'),
                const SizedBox(height: AppSpacing.sm),
                SettingsCard(
                  children: [
                    // Generate Mock Data (top, prominent)
                    SettingsTile(
                      icon: Icons.auto_awesome_rounded,
                      label: 'Generate Mock Data',
                      subtitle: 'Populate with sample collections & cards',
                      onTap: () => _showMockDataConfirmation(context),
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    Divider(height: 1, color: cs.outline),
                    SettingsTile(
                      icon: Icons.upload_file_rounded,
                      label: 'Import/Export Data',
                      subtitle: 'Add/Share cards from a JSON backup',
                      onTap: () => _showImportSheet(context),
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    Divider(height: 1, color: cs.outline),
                    // SettingsTile(
                    //   icon: Icons.download_rounded,
                    //   label: 'Export Data',
                    //   subtitle: 'Backup all collections as JSON',
                    //   onTap: () => _showExportSheet(context),
                    //   trailing: Icon(
                    //     Icons.chevron_right_rounded,
                    //     size: 20,
                    //     color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                    //   ),
                    // ),
                    // Divider(height: 1, color: cs.outline),
                    SettingsTile(
                      icon: Icons.delete_outline_rounded,
                      label: 'Clear All Data',
                      subtitle: 'Permanently delete everything',
                      onTap: () => _showClearConfirmation(context),
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.xl),

                // ── ABOUT ───────────────────────────────────
                const SectionLabel(label: 'ABOUT'),
                const SizedBox(height: AppSpacing.sm),
                SettingsCard(
                  children: [
                    SettingsTile(
                      icon: Icons.flash_on_rounded,
                      label: 'FlashMeUp',
                      subtitle: 'Your offline-first flashcard app',
                      trailing: Icon(
                        Icons.favorite_rounded,
                        size: 16,
                        color: cs.error,
                      ),
                    ),
                    Divider(height: 1, color: cs.outline),
                    SettingsTile(
                      icon: Icons.info_outline_rounded,
                      label: 'App Version',
                      trailing: Text(
                        'v1.0.0',
                        style: TextStyle(
                          fontSize: 14,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.xxl),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Export
  // ─────────────────────────────────────────────
  Future<void> _showExportSheet(BuildContext context) async {
    final cs = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(color: cs.outline),
        ),
        backgroundColor: cs.surfaceContainer,
        title: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.download_rounded, color: cs.primary, size: 20),
          const SizedBox(width: 10),
          const Text('Export Data'),
        ]),
        content: Text(
          'This will export all your collections, cards, and tags as a JSON file.',
          style: TextStyle(color: cs.onSurface, fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Export & Share')),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ImportExportService.exportFile(
        collections: ref.read(collectionsProvider),
        flashcards: ref.read(flashcardsProvider),
        tags: ref.read(tagsProvider),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  // ─────────────────────────────────────────────
  // Import
  // ─────────────────────────────────────────────
  void _showImportSheet(BuildContext context) {
    ImportExportSheet.show(context);
  }

  // ─────────────────────────────────────────────
  // Mock Data Confirmation
  // ─────────────────────────────────────────────
  void _showMockDataConfirmation(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        insetPadding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(color: cs.outline),
        ),
        backgroundColor: cs.surfaceContainer,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome_rounded,
                color: cs.primary, size: 22),
            const SizedBox(width: 10),
            const Flexible(
                child: Text('Generate Mock Data',
                    overflow: TextOverflow.ellipsis)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This will delete all your existing collections and flashcards, '
                'then populate the app with sample data including:',
                style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 14,
                    height: 1.5),
              ),
              const SizedBox(height: 12),
              _bulletItem(context, 'Vocabulary Essentials (5 cards)'),
              _bulletItem(
                  context, 'Neuroanatomy Fundamentals (3 cards)'),
              _bulletItem(context, 'Spanish Basics (4 cards)'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cs.errorContainer,
                  borderRadius:
                      BorderRadius.circular(AppRadius.sm),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_rounded,
                        size: 16, color: cs.onErrorContainer),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'All existing data will be permanently deleted.',
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onErrorContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              generateMockData(ref);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content:
                      Text('✓ Mock data generated successfully'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Icons.auto_awesome_rounded, size: 16),
            label: const Text('Generate'),
          ),
        ],
      ),
    );
  }

  Widget _bulletItem(BuildContext context, String text) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(Icons.circle, size: 6, color: cs.primary),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
                fontSize: 13,
                color: cs.onSurface,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Clear All Data Confirmation
  // ─────────────────────────────────────────────
  void _showClearConfirmation(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(color: cs.outline),
        ),
        backgroundColor: cs.surfaceContainer,
        title: const Text('Clear All Data?'),
        content: Text(
          'This will permanently delete all collections and flashcards. '
          'There is no way to undo this action.',
          style: TextStyle(color: cs.onSurface, fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(collectionsProvider.notifier).clear();
              ref.read(flashcardsProvider.notifier).clear();
              ref.read(tagsProvider.notifier).clear();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All data cleared.'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: FilledButton.styleFrom(
                backgroundColor: cs.error),
            child: const Text('Clear Everything'),
          ),
        ],
      ),
    );
  }
}
