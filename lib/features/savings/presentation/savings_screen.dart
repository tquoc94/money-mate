import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:qlct/core/theme/app_theme.dart';
import 'package:qlct/core/utils/thousands_formatter.dart';
import 'package:qlct/features/savings/data/models/savings_goal_model.dart';
import 'package:qlct/features/savings/data/repositories/savings_repository.dart';
import 'package:qlct/features/savings/providers/savings_providers.dart';
import 'package:qlct/l10n/app_localizations.dart';

class SavingsScreen extends ConsumerStatefulWidget {
  const SavingsScreen({super.key});

  @override
  ConsumerState<SavingsScreen> createState() => _SavingsScreenState();
}

class _SavingsScreenState extends ConsumerState<SavingsScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final goalsAsync = ref.watch(savingsGoalsProvider);
    final currFmt = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return Scaffold(
      appBar: AppBar(title: Text(l10n.savingsGoals)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddGoalDialog(context, l10n),
        child: const Icon(Icons.add_rounded),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
              decoration: InputDecoration(
                hintText: l10n.savingsGoalSearch,
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: isDark ? AppColors.cardDark : Colors.grey.shade100,
              ),
              style: GoogleFonts.nunito(fontSize: 14),
            ),
          ),
          const Gap(8),
          Expanded(
            child: goalsAsync.when(
              data: (goals) {
                final filtered = _searchQuery.isEmpty
                    ? goals
                    : goals
                          .where(
                            (g) => g.name.toLowerCase().contains(_searchQuery),
                          )
                          .toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.savings_rounded,
                          size: 64,
                          color: AppColors.primary.withValues(alpha: 0.3),
                        ),
                        const Gap(12),
                        Text(
                          _searchQuery.isEmpty
                              ? l10n.noSavingsGoals
                              : l10n.notFound,
                          style: GoogleFonts.nunito(
                            fontSize: 16,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                        if (_searchQuery.isEmpty) ...[
                          const Gap(4),
                          Text(
                            l10n.noSavingsGoalsHint,
                            style: GoogleFonts.nunito(
                              fontSize: 13,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) => _buildGoalCard(
                    context,
                    filtered[i],
                    currFmt,
                    isDark,
                    i,
                    l10n,
                  ),
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

  Widget _buildGoalCard(
    BuildContext context,
    SavingsGoalModel goal,
    NumberFormat fmt,
    bool isDark,
    int index,
    AppLocalizations l10n,
  ) {
    final pct = goal.percentage.clamp(0.0, 1.0);
    final statusColor = goal.isCompleted ? AppColors.primary : AppColors.info;

    return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.cardLight,
            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            boxShadow: AppShadows.cardShadow(isDark),
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
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      goal.isCompleted
                          ? Icons.check_circle_rounded
                          : Icons.savings_rounded,
                      color: statusColor,
                      size: 20,
                    ),
                  ),
                  const Gap(12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          goal.name,
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${fmt.format(goal.currentAmount)} / ${fmt.format(goal.targetAmount)}',
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
                  if (!goal.isCompleted)
                    IconButton(
                      icon: const Icon(
                        Icons.add_circle_rounded,
                        color: AppColors.primary,
                      ),
                      onPressed: () => _showDepositDialog(context, goal, l10n),
                    ),
                  IconButton(
                    icon: const Icon(Icons.edit_rounded, size: 18),
                    tooltip: l10n.editGoal,
                    onPressed: () => _showEditGoalDialog(context, goal, l10n),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      size: 20,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                    onPressed: () => deleteSavingsGoal(goal.id),
                  ),
                ],
              ),
              const Gap(12),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 8,
                        backgroundColor: isDark
                            ? AppColors.dividerDark
                            : AppColors.dividerLight,
                        color: statusColor,
                      ),
                    ),
                  ),
                  const Gap(8),
                  Text(
                    '${(pct * 100).toInt()}%',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
              if (!goal.isCompleted) ...[
                const Gap(6),
                Text(
                  l10n.remainingAmount(fmt.format(goal.remaining)),
                  style: GoogleFonts.nunito(fontSize: 12, color: statusColor),
                ),
              ],
              if (goal.isCompleted)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    l10n.goalReached,
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
        )
        .animate()
        .fadeIn(delay: (index * 80).ms, duration: 300.ms)
        .slideY(begin: 0.05, end: 0);
  }

  void _showAddGoalDialog(BuildContext context, AppLocalizations l10n) {
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController();

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
              l10n.addGoal,
              style: GoogleFonts.beVietnamPro(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Gap(16),
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: l10n.goalName,
                hintText: l10n.goalNameHint,
              ),
            ),
            const Gap(12),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [ThousandsSeparatorFormatter()],
              decoration: InputDecoration(
                labelText: l10n.targetAmount,
                suffixText: '₫',
              ),
            ),
            const Gap(16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  final name = nameCtrl.text.trim();
                  final amount = ThousandsSeparatorFormatter.parse(
                    amountCtrl.text,
                  );
                  if (name.isEmpty || amount <= 0) return;
                  addSavingsGoal(
                    SavingsGoalModel(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: name,
                      targetAmount: amount,
                      createdAt: DateTime.now(),
                    ),
                  );
                  Navigator.pop(ctx);
                },
                child: Text(l10n.createGoal),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDepositDialog(
    BuildContext context,
    SavingsGoalModel goal,
    AppLocalizations l10n,
  ) {
    final ctrl = TextEditingController();
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
              l10n.depositTo(goal.name),
              style: GoogleFonts.beVietnamPro(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Gap(16),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              inputFormatters: [ThousandsSeparatorFormatter()],
              decoration: InputDecoration(
                labelText: l10n.depositAmount,
                suffixText: '₫',
              ),
              autofocus: true,
            ),
            const Gap(16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  final amount = ThousandsSeparatorFormatter.parse(ctrl.text);
                  if (amount <= 0) return;
                  addToSavings(goal.id, amount);
                  Navigator.pop(ctx);
                },
                child: Text(l10n.deposit),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditGoalDialog(
    BuildContext context,
    SavingsGoalModel goal,
    AppLocalizations l10n,
  ) {
    final nameCtrl = TextEditingController(text: goal.name);
    final amountCtrl = TextEditingController(
      text: ThousandsSeparatorFormatter.format(goal.targetAmount),
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
              l10n.editGoal,
              style: GoogleFonts.beVietnamPro(
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Gap(16),
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(labelText: l10n.goalName),
            ),
            const Gap(10),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [ThousandsSeparatorFormatter()],
              decoration: InputDecoration(
                labelText: l10n.targetAmount,
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
                      final name = nameCtrl.text.trim();
                      final amount = ThousandsSeparatorFormatter.parse(
                        amountCtrl.text,
                      );
                      if (name.isEmpty || amount <= 0) return;
                      updateSavingsGoal(goal.id, name, amount);
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
