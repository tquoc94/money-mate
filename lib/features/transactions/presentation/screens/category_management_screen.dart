import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qlct/core/theme/app_theme.dart';
import 'package:qlct/features/transactions/data/models/category_model.dart';
import 'package:qlct/features/transactions/data/repositories/category_repository.dart';
import 'package:qlct/features/transactions/providers/transaction_providers.dart';
import 'package:qlct/l10n/app_localizations.dart';

class CategoryManagementScreen extends ConsumerWidget {
  const CategoryManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.categoryManagement),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showCategoryDialog(context, ref, l10n),
          ),
        ],
      ),
      body: categoriesAsync.when(
        data: (categories) {
          final expenseCats = categories.where((c) => c.isExpense).toList();
          final incomeCats = categories.where((c) => c.isIncome).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimens.spacingMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(
                  context,
                  l10n.expenseSection,
                  Icons.arrow_upward_rounded,
                  AppColors.expense,
                  isDark,
                ),
                const Gap(8),
                ...expenseCats.asMap().entries.map(
                  (e) => _buildCategoryTile(
                    context,
                    ref,
                    e.value,
                    isDark,
                    l10n,
                  ).animate().fadeIn(delay: (e.key * 50).ms, duration: 200.ms),
                ),
                const Gap(20),
                _buildSectionHeader(
                  context,
                  l10n.incomeSection,
                  Icons.arrow_downward_rounded,
                  AppColors.income,
                  isDark,
                ),
                const Gap(8),
                ...incomeCats.asMap().entries.map(
                  (e) => _buildCategoryTile(
                    context,
                    ref,
                    e.value,
                    isDark,
                    l10n,
                  ).animate().fadeIn(delay: (e.key * 50).ms, duration: 200.ms),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const Gap(8),
        Text(
          title,
          style: GoogleFonts.beVietnamPro(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryTile(
    BuildContext context,
    WidgetRef ref,
    CategoryModel cat,
    bool isDark,
    AppLocalizations l10n,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: Dismissible(
        key: Key(cat.id),
        direction: cat.isDefault
            ? DismissDirection.none
            : DismissDirection.endToStart,
        confirmDismiss: (_) async {
          if (cat.isDefault) return false;
          return await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(l10n.deleteCategoryTitle),
              content: Text(l10n.deleteCategoryConfirm(cat.name)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(l10n.cancel),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.expense,
                  ),
                  child: Text(l10n.delete),
                ),
              ],
            ),
          );
        },
        onDismissed: (_) => deleteCategory(cat.id),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: AppColors.expense,
            borderRadius: BorderRadius.circular(AppDimens.radiusSm),
          ),
          child: const Icon(Icons.delete_rounded, color: Colors.white),
        ),
        child: InkWell(
          onTap: cat.isDefault
              ? null
              : () => _showCategoryDialog(context, ref, l10n, existing: cat),
          borderRadius: BorderRadius.circular(AppDimens.radiusSm),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : AppColors.cardLight,
              borderRadius: BorderRadius.circular(AppDimens.radiusSm),
              border: Border.all(
                color: (isDark ? AppColors.dividerDark : AppColors.dividerLight)
                    .withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: cat.colorValue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(cat.iconData, color: cat.colorValue, size: 20),
                ),
                const Gap(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        CategoryModel.localizedName(cat.id, l10n),
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      if (cat.isDefault)
                        Text(
                          l10n.defaultCategory,
                          style: GoogleFonts.nunito(
                            fontSize: 11,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                    ],
                  ),
                ),
                if (!cat.isDefault)
                  Icon(
                    Icons.edit_rounded,
                    size: 18,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showCategoryDialog(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n, {
    CategoryModel? existing,
  }) async {
    final nameController = TextEditingController(text: existing?.name ?? '');
    String selectedIcon = existing?.icon ?? 'food';
    String selectedColor = existing?.color ?? '#F97316';
    String selectedType = existing?.type ?? 'expense';

    final availableIcons = CategoryModel.defaultCategories
        .map((c) => c.icon)
        .toSet()
        .toList();

    final availableColors = [
      '#F97316',
      '#3B82F6',
      '#8B5CF6',
      '#EC4899',
      '#14B8A6',
      '#EF4444',
      '#6366F1',
      '#F59E0B',
      '#10B981',
      '#F43F5E',
      '#0EA5E9',
      '#84CC16',
      '#A855F7',
      '#D946EF',
      '#06B6D4',
    ];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      existing != null
                          ? l10n.editCategoryTitle
                          : l10n.addCategoryTitle,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Gap(16),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                      ),
                      child: Row(
                        children: ['expense', 'income'].map((t) {
                          final isActive = t == selectedType;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () =>
                                  setModalState(() => selectedType = t),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? (t == 'expense'
                                            ? AppColors.expense
                                            : AppColors.income)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(
                                    AppDimens.radiusXs,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    t == 'expense'
                                        ? l10n.expenseSection
                                        : l10n.incomeSection,
                                    style: GoogleFonts.beVietnamPro(
                                      fontWeight: FontWeight.w600,
                                      color: isActive ? Colors.white : null,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const Gap(16),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        hintText: l10n.categoryNameHint,
                        prefixIcon: const Icon(Icons.label_rounded),
                      ),
                    ),
                    const Gap(16),
                    Text(
                      l10n.selectIcon,
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Gap(8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: availableIcons.map((iconKey) {
                        final isSelected = iconKey == selectedIcon;
                        final iconData = CategoryModel.defaultCategories
                            .firstWhere((c) => c.icon == iconKey)
                            .iconData;
                        return GestureDetector(
                          onTap: () =>
                              setModalState(() => selectedIcon = iconKey),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Color(
                                      int.parse(
                                        selectedColor.replaceFirst('#', '0xFF'),
                                      ),
                                    ).withValues(alpha: 0.15)
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? Color(
                                        int.parse(
                                          selectedColor.replaceFirst(
                                            '#',
                                            '0xFF',
                                          ),
                                        ),
                                      )
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              iconData,
                              size: 20,
                              color: Color(
                                int.parse(
                                  selectedColor.replaceFirst('#', '0xFF'),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const Gap(16),
                    Text(
                      l10n.selectColor,
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Gap(8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: availableColors.map((hex) {
                        final color = Color(
                          int.parse(hex.replaceFirst('#', '0xFF')),
                        );
                        final isSelected = hex == selectedColor;
                        return GestureDetector(
                          onTap: () => setModalState(() => selectedColor = hex),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.transparent,
                                width: 3,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: color.withValues(alpha: 0.4),
                                        blurRadius: 8,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 18,
                                  )
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                    const Gap(20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          if (nameController.text.trim().isEmpty) return;
                          final id =
                              existing?.id ??
                              'custom_${DateTime.now().millisecondsSinceEpoch}';
                          final cat = CategoryModel(
                            id: id,
                            name: nameController.text.trim(),
                            icon: selectedIcon,
                            color: selectedColor,
                            type: selectedType,
                            isDefault: false,
                          );
                          addCategory(cat);
                          Navigator.pop(ctx);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          l10n.save,
                          style: GoogleFonts.beVietnamPro(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
