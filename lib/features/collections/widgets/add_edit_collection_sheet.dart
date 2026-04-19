import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/collection.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_bottom_sheet.dart';
import '../../../shared/widgets/app_button.dart';

/// Bottom sheet for adding or editing a collection.
/// Call [AddEditCollectionSheet.show] to display it.
class AddEditCollectionSheet extends ConsumerStatefulWidget {
  final FlashcardCollection? collection; // null = add mode

  const AddEditCollectionSheet({super.key, this.collection});

  /// Show the sheet. Wraps in ProviderScope so providers are accessible.
  static void show(BuildContext context, {FlashcardCollection? collection}) {
    final container = ProviderScope.containerOf(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => UncontrolledProviderScope(
        container: container,
        child: AddEditCollectionSheet(collection: collection),
      ),
    );
  }

  @override
  ConsumerState<AddEditCollectionSheet> createState() =>
      _AddEditCollectionSheetState();
}

class _AddEditCollectionSheetState
    extends ConsumerState<AddEditCollectionSheet> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _nameFocus = FocusNode();
  bool _isLoading = false;

  bool get _isEdit => widget.collection != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _nameController.text = widget.collection!.title;
      _descController.text = widget.collection!.description ?? '';
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _nameFocus.requestFocus();
    });
    _nameController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isLoading = true);
    final desc = _descController.text.trim();

    if (_isEdit) {
      final updated = widget.collection!.copyWith(
        title: name,
        description: desc.isEmpty ? null : desc,
        clearDescription: desc.isEmpty,
      );
      ref.read(collectionsProvider.notifier).update(updated);
    } else {
      ref.read(collectionsProvider.notifier).add(
        FlashcardCollection(
          title: name,
          description: desc.isEmpty ? null : desc,
        ),
      );
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: AppBottomSheet(
        title: _isEdit ? 'Edit Collection' : 'New Collection',
        subtitle: _isEdit
            ? 'Update the name and description.'
            : 'Give your collection a name and optional description.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              focusNode: _nameFocus,
              textCapitalization: TextCapitalization.sentences,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              decoration: const InputDecoration(
                labelText: 'Collection Name *',
                hintText: 'e.g. Vocabulary Essentials',
              ),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _descController,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'Briefly describe what this collection covers',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: _isEdit ? 'SAVE CHANGES' : 'CREATE COLLECTION',
              type: AppButtonType.primary,
              fullWidth: true,
              height: 52,
              isLoading: _isLoading,
              onPressed:
                  _nameController.text.trim().isEmpty ? null : _save,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: 'CANCEL',
              type: AppButtonType.ghost,
              fullWidth: true,
              height: 40,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
