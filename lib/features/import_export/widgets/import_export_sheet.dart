import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../import_export_service.dart';

class ImportExportSheet extends ConsumerStatefulWidget {
  const ImportExportSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ImportExportSheet(),
    );
  }

  @override
  ConsumerState<ImportExportSheet> createState() =>
      _ImportExportSheetState();
}

class _ImportExportSheetState
    extends ConsumerState<ImportExportSheet> {
  bool _isExporting = false;
  bool _isSharingTemplate = false;
  bool _isImporting = false;

  Future<void> _export() async {
    setState(() => _isExporting = true);
    try {
      final collections = ref.read(collectionsProvider);
      final flashcards = ref.read(flashcardsProvider);
      final tags = ref.read(tagsProvider);
      await ImportExportService.exportFile(
        collections: collections,
        flashcards: flashcards,
        tags: tags,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _shareTemplate() async {
    setState(() => _isSharingTemplate = true);
    try {
      await ImportExportService.shareTemplate();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSharingTemplate = false);
    }
  }

  Future<void> _import() async {
    setState(() => _isImporting = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result == null || result.files.single.path == null) {
        setState(() => _isImporting = false);
        return;
      }
      final file = File(result.files.single.path!);
      final json = await file.readAsString();
      final data = ImportExportService.importFromJson(json);

      if (!mounted) return;

      // Show merge confirmation
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) {
          final cs = Theme.of(ctx).colorScheme;
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              side: BorderSide(color: cs.outline),
            ),
            backgroundColor: cs.surfaceContainer,
            title: const Text('Import Data'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Found in file:',
                  style: TextStyle(
                      fontSize: 12, color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 8),
                _bulletItem(ctx,
                    '${data.collections.length} collections'),
                _bulletItem(ctx,
                    '${data.flashcards.length} cards'),
                _bulletItem(ctx, '${data.tags.length} tags'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer
                        .withValues(alpha: 0.5),
                    borderRadius:
                        BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    'Existing data will be merged. Items with the same ID are skipped.',
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Import'),
              ),
            ],
          );
        },
      );

      if (confirmed != true || !mounted) {
        setState(() => _isImporting = false);
        return;
      }

      // Merge: add items with IDs not already present
      final existingCollectionIds =
          ref.read(collectionsProvider).map((c) => c.id).toSet();
      final existingCardIds =
          ref.read(flashcardsProvider).map((f) => f.id).toSet();
      final existingTagIds =
          ref.read(tagsProvider).map((t) => t.id).toSet();

      final newCollections = data.collections
          .where((c) => !existingCollectionIds.contains(c.id))
          .toList();
      final newCards = data.flashcards
          .where((f) => !existingCardIds.contains(f.id))
          .toList();
      final newTags = data.tags
          .where((t) => !existingTagIds.contains(t.id))
          .toList();

      for (final c in newCollections) {
        ref.read(collectionsProvider.notifier).add(c);
      }
      for (final f in newCards) {
        ref.read(flashcardsProvider.notifier).add(f);
      }
      for (final t in newTags) {
        ref.read(tagsProvider.notifier).add(t);
      }

      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✓ Imported ${newCollections.length} collections, ${newCards.length} cards, ${newTags.length} tags',
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isImporting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Import failed: invalid file format')),
        );
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  Widget _bulletItem(BuildContext context, String text) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(children: [
        Icon(Icons.circle, size: 5, color: cs.primary),
        const SizedBox(width: 8),
        Text(text,
            style: TextStyle(
                fontSize: 13,
                color: cs.onSurface,
                fontWeight: FontWeight.w500)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.lg),
        ),
        border: Border(
          top: BorderSide(color: cs.outline),
          left: BorderSide(color: cs.outline),
          right: BorderSide(color: cs.outline),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Text(
                'Import / Export',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Back up or restore all your collections, cards, and tags.',
                style: TextStyle(
                  fontSize: 13,
                  color: cs.onSurfaceVariant,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Export section
              Text(
                'EXPORT',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppButton(
                label: 'EXPORT & SHARE',
                type: AppButtonType.primary,
                fullWidth: true,
                icon: Icons.share_rounded,
                height: 50,
                isLoading: _isExporting,
                onPressed: _isExporting ? null : _export,
              ),

              const SizedBox(height: AppSpacing.xl),

              // Import section
              Text(
                'IMPORT',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppButton(
                label: 'DOWNLOAD TEMPLATE',
                type: AppButtonType.outline,
                fullWidth: true,
                icon: Icons.file_download_outlined,
                height: 50,
                isLoading: _isSharingTemplate,
                onPressed: _isSharingTemplate ? null : _shareTemplate,
              ),
              const SizedBox(height: AppSpacing.sm),
              AppButton(
                label: 'CHOOSE JSON FILE',
                type: AppButtonType.primary,
                fullWidth: true,
                icon: Icons.upload_file_rounded,
                height: 50,
                isLoading: _isImporting,
                onPressed: _isImporting ? null : _import,
              ),

              const SizedBox(height: AppSpacing.lg),
              Center(
                child: AppButton(
                  label: 'CLOSE',
                  type: AppButtonType.ghost,
                  onPressed: () =>
                      Navigator.of(context, rootNavigator: true).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
