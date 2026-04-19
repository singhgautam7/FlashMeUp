import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/collection.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_bar_widget.dart';
import '../../../shared/widgets/app_button.dart';

// ─────────────────────────────────────────────
// Icon & color palettes
// ─────────────────────────────────────────────
const List<Color> _kColors = [
  Color(0xFF6366F1), // Indigo (default)
  Color(0xFF8B5CF6), // Violet
  Color(0xFFEC4899), // Pink
  Color(0xFFEF4444), // Red
  Color(0xFFF97316), // Orange
  Color(0xFFEAB308), // Amber
  Color(0xFF22C55E), // Green
  Color(0xFF10B981), // Emerald
  Color(0xFF14B8A6), // Teal
  Color(0xFF06B6D4), // Cyan
  Color(0xFF3B82F6), // Blue
  Color(0xFF64748B), // Slate
];

const List<IconData> _kIcons = [
  Icons.auto_stories_rounded,
  Icons.library_books_rounded,
  Icons.school_rounded,
  Icons.psychology_rounded,
  Icons.science_rounded,
  Icons.biotech_rounded,
  Icons.calculate_rounded,
  Icons.functions_rounded,
  Icons.language_rounded,
  Icons.translate_rounded,
  Icons.spellcheck_rounded,
  Icons.history_edu_rounded,
  Icons.public_rounded,
  Icons.map_rounded,
  Icons.palette_rounded,
  Icons.music_note_rounded,
  Icons.theater_comedy_rounded,
  Icons.brush_rounded,
  Icons.camera_alt_rounded,
  Icons.computer_rounded,
  Icons.code_rounded,
  Icons.memory_rounded,
  Icons.developer_mode_rounded,
  Icons.fitness_center_rounded,
  Icons.restaurant_rounded,
  Icons.travel_explore_rounded,
  Icons.sports_soccer_rounded,
  Icons.local_hospital_rounded,
  Icons.medical_services_rounded,
  Icons.eco_rounded,
  Icons.business_rounded,
  Icons.account_balance_rounded,
  Icons.gavel_rounded,
  Icons.lightbulb_rounded,
  Icons.bolt_rounded,
  Icons.star_rounded,
  Icons.favorite_rounded,
  Icons.emoji_events_rounded,
  Icons.rocket_launch_rounded,
  Icons.book_rounded,
];

class AddEditCollectionScreen extends ConsumerStatefulWidget {
  final String? collectionId; // null = add mode

  const AddEditCollectionScreen({super.key, this.collectionId});

  @override
  ConsumerState<AddEditCollectionScreen> createState() =>
      _AddEditCollectionScreenState();
}

class _AddEditCollectionScreenState
    extends ConsumerState<AddEditCollectionScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _nameFocus = FocusNode();
  bool _saving = false;

  late int _selectedColorValue;
  late int _selectedIconCodePoint;

  bool get _isEdit => widget.collectionId != null;

  FlashcardCollection? get _existing {
    if (!_isEdit) return null;
    return ref
        .read(collectionsProvider)
        .where((c) => c.id == widget.collectionId)
        .cast<FlashcardCollection?>()
        .firstOrNull;
  }

  @override
  void initState() {
    super.initState();
    final ex = _existing;
    _nameController.text = ex?.title ?? '';
    _descController.text = ex?.description ?? '';
    _selectedColorValue =
        ex?.colorValue ?? _kColors[0].toARGB32();
    _selectedIconCodePoint =
        ex?.iconCodePoint ?? _kIcons[0].codePoint;

    _nameController.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => _nameFocus.requestFocus());
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
    setState(() => _saving = true);
    final desc = _descController.text.trim();

    if (_isEdit && _existing != null) {
      ref.read(collectionsProvider.notifier).update(
            _existing!.copyWith(
              title: name,
              description: desc.isEmpty ? null : desc,
              clearDescription: desc.isEmpty,
              iconCodePoint: _selectedIconCodePoint,
              colorValue: _selectedColorValue,
            ),
          );
    } else {
      ref.read(collectionsProvider.notifier).add(
            FlashcardCollection(
              title: name,
              description: desc.isEmpty ? null : desc,
              iconCodePoint: _selectedIconCodePoint,
              colorValue: _selectedColorValue,
            ),
          );
    }
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accentColor = Color(_selectedColorValue);

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AppBarWidget(showBack: true),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.only(bottom: AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg, 8, AppSpacing.lg, 24),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isEdit
                              ? 'Edit\nCollection'
                              : 'New\nCollection',
                          style: Theme.of(context)
                              .textTheme
                              .displaySmall
                              ?.copyWith(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: cs.onSurface,
                                height: 1.15,
                                letterSpacing: -0.5,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _isEdit
                              ? 'Update the name, icon and appearance.'
                              : 'Give your new collection a name, icon, and color.',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                fontSize: 13,
                                color: cs.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),

                  // ── Preview tile ───────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg),
                    child: Container(
                      padding:
                          const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                            color:
                                accentColor.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: accentColor,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.md),
                            ),
                            child: Icon(
                              IconData(_selectedIconCodePoint,
                                  fontFamily: 'MaterialIcons'),
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _nameController.text.trim().isEmpty
                                      ? 'Collection name...'
                                      : _nameController.text.trim(),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color:
                                        _nameController.text.isEmpty
                                            ? cs.onSurfaceVariant
                                            : cs.onSurface,
                                  ),
                                ),
                                Text(
                                  'Preview',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: accentColor,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // ── Name field ─────────────────────────
                  _Section(
                    label: 'COLLECTION NAME',
                    child: TextField(
                      controller: _nameController,
                      focusNode: _nameFocus,
                      textCapitalization:
                          TextCapitalization.sentences,
                      style: TextStyle(color: cs.onSurface),
                      decoration: const InputDecoration(
                        hintText:
                            'e.g. Vocabulary Essentials',
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // ── Description field ──────────────────
                  _Section(
                    label: 'DESCRIPTION (OPTIONAL)',
                    child: TextField(
                      controller: _descController,
                      maxLines: 3,
                      textCapitalization:
                          TextCapitalization.sentences,
                      style: TextStyle(color: cs.onSurface),
                      decoration: const InputDecoration(
                        hintText:
                            'Briefly describe what this covers',
                        alignLabelWithHint: true,
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // ── Color picker ──────────────────────────
                  _Section(
                    label: 'ACCENT COLOR',
                    hint: 'Swipe to see more',
                    child: SizedBox(
                      height: 44,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _kColors.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: 10),
                        itemBuilder: (ctx, index) {
                          final color = _kColors[index];
                          final selected =
                              color.toARGB32() ==
                                  _selectedColorValue;
                          return GestureDetector(
                            onTap: () => setState(() =>
                                _selectedColorValue =
                                    color.toARGB32()),
                            child: AnimatedContainer(
                              duration:
                                  const Duration(milliseconds: 200),
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: selected
                                    ? Border.all(
                                        color: cs.onSurface,
                                        width: 2.5)
                                    : Border.all(
                                        color: Colors.transparent,
                                        width: 2.5),
                                boxShadow: selected
                                    ? [
                                        BoxShadow(
                                          color: color.withValues(
                                              alpha: 0.5),
                                          blurRadius: 8,
                                          offset:
                                              const Offset(0, 2),
                                        )
                                      ]
                                    : null,
                              ),
                              child: selected
                                  ? const Icon(
                                      Icons.check_rounded,
                                      color: Colors.white,
                                      size: 18)
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // ── Icon picker — 5-col GridView, 3 rows visible ──
                  _Section(
                    label: 'ICON',
                    hint: 'Scroll to see more icons',
                    child: ClipRRect(
                      borderRadius:
                          BorderRadius.circular(AppRadius.md),
                      child: Container(
                        height: 3 * 58 + 2 * 8 + 16, // 3 rows
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHigh,
                          borderRadius:
                              BorderRadius.circular(AppRadius.md),
                          border:
                              Border.all(color: cs.outline),
                        ),
                        padding: const EdgeInsets.all(8),
                        child: GridView.builder(
                          physics:
                              const ClampingScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 5,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                            childAspectRatio: 1,
                          ),
                          itemCount: _kIcons.length,
                          itemBuilder: (ctx, index) {
                            final icon = _kIcons[index];
                            final selected = icon.codePoint ==
                                _selectedIconCodePoint;
                            return GestureDetector(
                              onTap: () => setState(() =>
                                  _selectedIconCodePoint =
                                      icon.codePoint),
                              child: AnimatedContainer(
                                duration: const Duration(
                                    milliseconds: 150),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? accentColor
                                      : cs.surfaceContainer,
                                  borderRadius:
                                      BorderRadius.circular(
                                          AppRadius.md),
                                  border: Border.all(
                                    color: selected
                                        ? accentColor
                                        : cs.outline
                                            .withValues(alpha: 0.5),
                                  ),
                                ),
                                child: Icon(
                                  icon,
                                  size: 22,
                                  color: selected
                                      ? Colors.white
                                      : cs.onSurfaceVariant,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),

          // ── Fixed bottom action bar ────────────────
          Container(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.md +
                  MediaQuery.of(context).padding.bottom,
            ),
            decoration: BoxDecoration(
              color: cs.surface,
              border: Border(
                  top: BorderSide(
                      color: cs.outline, width: 0.5)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppButton(
                  label: _isEdit
                      ? 'SAVE CHANGES'
                      : 'CREATE COLLECTION',
                  type: AppButtonType.primary,
                  fullWidth: true,
                  height: 52,
                  isLoading: _saving,
                  onPressed: _nameController.text.trim().isEmpty
                      ? null
                      : _save,
                ),
                const SizedBox(height: AppSpacing.sm),
                AppButton(
                  label: 'CANCEL',
                  type: AppButtonType.ghost,
                  fullWidth: true,
                  height: 40,
                  onPressed: () => context.pop(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Helper: labelled section
// ─────────────────────────────────────────────
class _Section extends StatelessWidget {
  final String label;
  final String? hint;
  final Widget child;

  const _Section(
      {required this.label, this.hint, required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
              if (hint != null) ...[
                const Spacer(),
                Text(
                  hint!,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: cs.onSurfaceVariant
                        .withValues(alpha: 0.55),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}
