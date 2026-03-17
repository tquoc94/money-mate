import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:qlct/core/theme/app_theme.dart';
import 'package:qlct/core/utils/thousands_formatter.dart';
import 'package:qlct/features/budget/data/models/budget_model.dart';
import 'package:qlct/features/budget/data/repositories/budget_repository.dart';
import 'package:qlct/features/budget/providers/budget_providers.dart';
import 'package:qlct/features/transactions/data/models/category_model.dart';
import 'package:qlct/l10n/app_localizations.dart';

class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final budgetsAsync = ref.watch(budgetsProvider);
    final progress = ref.watch(budgetProgressProvider);
    final currFmt = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final selected = ref.watch(selectedBudgetMonthProvider);
    final now = DateTime.now();
    final isCurrentMonth =
        selected.month == now.month && selected.year == now.year;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.budget),
        actions: [
          if (isCurrentMonth)
            IconButton(
              icon: const Icon(Icons.add_rounded),
              onPressed: () =>
                  _showAddBudgetDialog(context, ref, selected, l10n),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildMonthSelector(context, ref, selected, isDark),
          Expanded(
            child: budgetsAsync.when(
              data: (budgets) {
                if (budgets.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.savings_rounded,
                          size: 64,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                        const Gap(16),
                        Text(
                          l10n.noBudgets,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const Gap(8),
                        Text(
                          l10n.noBudgetsHint,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(AppDimens.spacingMd),
                  itemCount: budgets.length,
                  itemBuilder: (context, index) {
                    final budget = budgets[index];
                    final prog = progress[budget.categoryId];
                    final spent = prog?['spent'] ?? 0;
                    final pct = prog?['percentage'] ?? 0;
                    final cat = CategoryModel.defaultCategories.firstWhere(
                      (c) => c.id == budget.categoryId,
                      orElse: () => CategoryModel.defaultCategories.first,
                    );

                    final isOverBudget = pct > 1.0;
                    final isWarning = pct > 0.8 && pct <= 1.0;

                    return Dismissible(
                      key: Key(budget.docId),
                      direction: DismissDirection.endToStart,
                      onDismissed: (_) => deleteBudget(budget.docId),
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: AppColors.expense,
                          borderRadius: BorderRadius.circular(
                            AppDimens.radiusSm,
                          ),
                        ),
                        child: const Icon(
                          Icons.delete_rounded,
                          color: Colors.white,
                        ),
                      ),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.cardDark
                              : AppColors.cardLight,
                          borderRadius: BorderRadius.circular(
                            AppDimens.radiusMd,
                          ),
                          border: Border.all(
                            color: isOverBudget
                                ? AppColors.expense.withValues(alpha: 0.5)
                                : (isDark
                                          ? AppColors.dividerDark
                                          : AppColors.dividerLight)
                                      .withValues(alpha: 0.5),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: cat.colorValue.withValues(
                                      alpha: 0.12,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    cat.iconData,
                                    color: cat.colorValue,
                                    size: 20,
                                  ),
                                ),
                                const Gap(12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        CategoryModel.localizedName(
                                          cat.id,
                                          l10n,
                                        ),
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleSmall,
                                      ),
                                      Text(
                                        '${currFmt.format(spent)} / ${currFmt.format(budget.limit)}',
                                        style: GoogleFonts.nunito(
                                          fontSize: 12,
                                          color: isDark
                                              ? AppColors.textSecondaryDark
                                              : AppColors.textSecondaryLight,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit_rounded,
                                    size: 17,
                                  ),
                                  tooltip: l10n.editLimit,
                                  onPressed: () => _showEditBudgetDialog(
                                    context,
                                    budget,
                                    l10n,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 32,
                                    minHeight: 32,
                                  ),
                                  padding: EdgeInsets.zero,
                                ),
                                IconButton(
                                  icon: Icon(
                                    budget.isPinned
                                        ? Icons.push_pin_rounded
                                        : Icons.push_pin_outlined,
                                    color: budget.isPinned
                                        ? AppColors.primary
                                        : (isDark
                                              ? AppColors.textSecondaryDark
                                              : AppColors.textSecondaryLight),
                                    size: 18,
                                  ),
                                  tooltip: budget.isPinned
                                      ? l10n.unpin
                                      : l10n.pinToHome,
                                  onPressed: () => toggleBudgetPin(budget),
                                  constraints: const BoxConstraints(
                                    minWidth: 32,
                                    minHeight: 32,
                                  ),
                                  padding: EdgeInsets.zero,
                                ),
                                if (isOverBudget)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.expense.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      l10n.overBudget,
                                      style: GoogleFonts.beVietnamPro(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.expense,
                                      ),
                                    ),
                                  )
                                else if (isWarning)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${(pct * 100).toInt()}%',
                                      style: GoogleFonts.beVietnamPro(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.orange,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const Gap(12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: pct.clamp(0.0, 1.0),
                                minHeight: 8,
                                backgroundColor: isDark
                                    ? AppColors.dividerDark
                                    : AppColors.dividerLight,
                                color: isOverBudget
                                    ? AppColors.expense
                                    : isWarning
                                    ? Colors.orange
                                    : AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(
                      delay: (index * 80).ms,
                      duration: 300.ms,
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector(
    BuildContext context,
    WidgetRef ref,
    DateTime selected,
    bool isDark,
  ) {
    final monthLabel = 'T${selected.month}/${selected.year}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        border: Border(
          bottom: BorderSide(
            color: (isDark ? AppColors.dividerDark : AppColors.dividerLight)
                .withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: () {
              final prev = DateTime(selected.year, selected.month - 1);
              ref.read(selectedBudgetMonthProvider.notifier).state = prev;
            },
          ),
          Text(
            monthLabel,
            style: GoogleFonts.beVietnamPro(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: () {
              final now = DateTime.now();
              if (selected.year < now.year ||
                  (selected.year == now.year && selected.month < now.month)) {
                final next = DateTime(selected.year, selected.month + 1);
                ref.read(selectedBudgetMonthProvider.notifier).state = next;
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showAddBudgetDialog(
    BuildContext context,
    WidgetRef ref,
    DateTime now,
    AppLocalizations l10n,
  ) async {
    final amountController = TextEditingController();
    CategoryModel? selectedCat;

    final expenseCats = CategoryModel.defaultCategories
        .where((c) => c.isExpense)
        .toList();

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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.addBudget,
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Gap(16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: expenseCats.map((cat) {
                      final isSelected = selectedCat?.id == cat.id;
                      return GestureDetector(
                        onTap: () => setModalState(() => selectedCat = cat),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? cat.colorValue.withValues(alpha: 0.15)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? cat.colorValue
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                cat.iconData,
                                color: cat.colorValue,
                                size: 16,
                              ),
                              const Gap(6),
                              Text(
                                CategoryModel.localizedName(cat.id, l10n),
                                style: GoogleFonts.nunito(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const Gap(16),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [ThousandsSeparatorFormatter()],
                    decoration: InputDecoration(
                      hintText: l10n.budgetLimit,
                      suffixText: '₫',
                      suffixStyle: GoogleFonts.beVietnamPro(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Gap(16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        if (selectedCat == null ||
                            amountController.text.isEmpty)
                          return;
                        final limit = ThousandsSeparatorFormatter.parse(
                          amountController.text,
                        );
                        if (limit <= 0) return;
                        final budget = BudgetModel(
                          categoryId: selectedCat!.id,
                          categoryName: selectedCat!.name,
                          limit: limit,
                          month: now.month,
                          year: now.year,
                        );
                        setBudget(budget);
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
            );
          },
        );
      },
    );
  }

  void _showEditBudgetDialog(
    BuildContext context,
    BudgetModel budget,
    AppLocalizations l10n,
  ) {
    final ctrl = TextEditingController(
      text: ThousandsSeparatorFormatter.format(budget.limit),
    );
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${l10n.editLimit}: ${budget.categoryName}',
              style: GoogleFonts.beVietnamPro(
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Gap(16),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              inputFormatters: [ThousandsSeparatorFormatter()],
              autofocus: true,
              decoration: InputDecoration(
                labelText: l10n.newBudgetLimit,
                suffixText: '₫',
              ),
            ),
            const Gap(16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(l10n.cancel),
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      final newLimit = ThousandsSeparatorFormatter.parse(
                        ctrl.text,
                      );
                      if (newLimit <= 0) return;
                      updateBudgetLimit(budget.docId, newLimit);
                      Navigator.pop(ctx);
                    },
                    child: Text(l10n.save),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
