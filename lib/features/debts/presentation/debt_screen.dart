import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:qlct/core/theme/app_theme.dart';
import 'package:qlct/core/utils/thousands_formatter.dart';
import 'package:qlct/features/debts/data/models/debt_model.dart';
import 'package:qlct/features/debts/data/repositories/debt_repository.dart';
import 'package:qlct/features/debts/providers/debt_providers.dart';
import 'package:qlct/l10n/app_localizations.dart';

class DebtScreen extends ConsumerStatefulWidget {
  const DebtScreen({super.key});

  @override
  ConsumerState<DebtScreen> createState() => _DebtScreenState();
}

class _DebtScreenState extends ConsumerState<DebtScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final debtsAsync = ref.watch(debtsProvider);
    final currFmt = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final totalOwed = ref.watch(totalOwedToMeProvider);
    final totalBorrowed = ref.watch(totalIBorrowedProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.debtLedger),
          bottom: TabBar(
            labelStyle: GoogleFonts.nunito(
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
            unselectedLabelStyle: GoogleFonts.nunito(fontSize: 14),
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            tabs: [
              Tab(text: '${l10n.lend} (${currFmt.format(totalOwed)})'),
              Tab(text: '${l10n.borrow} (${currFmt.format(totalBorrowed)})'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddDebtDialog(context, l10n),
          child: const Icon(Icons.add_rounded),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: TextField(
                onChanged: (v) =>
                    setState(() => _searchQuery = v.toLowerCase()),
                decoration: InputDecoration(
                  hintText: l10n.searchByName,
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
              child: debtsAsync.when(
                data: (debts) {
                  final filtered = _searchQuery.isEmpty
                      ? debts
                      : debts
                            .where(
                              (d) =>
                                  d.personName.toLowerCase().contains(
                                    _searchQuery,
                                  ) ||
                                  (d.note?.toLowerCase().contains(
                                        _searchQuery,
                                      ) ??
                                      false),
                            )
                            .toList();

                  final owedToMe = filtered.where((d) => d.isOwedToMe).toList();
                  final iBorrowed = filtered
                      .where((d) => !d.isOwedToMe)
                      .toList();
                  return TabBarView(
                    children: [
                      _buildDebtList(
                        context,
                        owedToMe,
                        currFmt,
                        isDark,
                        true,
                        l10n,
                      ),
                      _buildDebtList(
                        context,
                        iBorrowed,
                        currFmt,
                        isDark,
                        false,
                        l10n,
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDebtList(
    BuildContext context,
    List<DebtModel> debts,
    NumberFormat fmt,
    bool isDark,
    bool isOwedToMe,
    AppLocalizations l10n,
  ) {
    if (debts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.handshake_rounded,
              size: 64,
              color: AppColors.primary.withValues(alpha: 0.3),
            ),
            const Gap(12),
            Text(
              isOwedToMe ? l10n.nobodyOwesYou : l10n.youDontOweAnyone,
              style: GoogleFonts.nunito(
                fontSize: 16,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: debts.length,
      itemBuilder: (context, i) {
        final debt = debts[i];
        final isOverdue = debt.isOverdue;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.cardLight,
            borderRadius: BorderRadius.circular(AppDimens.radiusSm),
            boxShadow: AppShadows.cardShadow(isDark),
            border: isOverdue
                ? Border.all(color: AppColors.expense.withValues(alpha: 0.3))
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color:
                      (debt.isPaid
                              ? AppColors.primary
                              : isOverdue
                              ? AppColors.expense
                              : AppColors.info)
                          .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  debt.isPaid
                      ? Icons.check_circle_rounded
                      : Icons.person_rounded,
                  color: debt.isPaid
                      ? AppColors.primary
                      : isOverdue
                      ? AppColors.expense
                      : AppColors.info,
                  size: 20,
                ),
              ),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      debt.personName,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        decoration: debt.isPaid
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    Text(
                      fmt.format(debt.amount),
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: debt.isPaid
                            ? AppColors.textSecondaryLight
                            : isOwedToMe
                            ? AppColors.income
                            : AppColors.expense,
                      ),
                    ),
                    if (debt.note != null && debt.note!.isNotEmpty)
                      Text(
                        debt.note!,
                        style: GoogleFonts.nunito(
                          fontSize: 11,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    if (debt.dueDate != null)
                      Text(
                        l10n.dueDate(
                          DateFormat('dd/MM/yyyy').format(debt.dueDate!),
                        ),
                        style: GoogleFonts.nunito(
                          fontSize: 11,
                          color: isOverdue
                              ? AppColors.expense
                              : (isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight),
                        ),
                      ),
                  ],
                ),
              ),
              if (!debt.isPaid)
                IconButton(
                  icon: const Icon(
                    Icons.check_rounded,
                    color: AppColors.primary,
                  ),
                  tooltip: l10n.markPaid,
                  onPressed: () => toggleDebtPaid(debt),
                ),
              IconButton(
                icon: const Icon(Icons.edit_rounded, size: 18),
                tooltip: l10n.edit,
                onPressed: () => _showEditDebtDialog(context, debt, l10n),
              ),
              IconButton(
                icon: Icon(
                  Icons.delete_outline_rounded,
                  size: 20,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
                onPressed: () => deleteDebt(debt.id),
              ),
            ],
          ),
        ).animate().fadeIn(delay: (i * 60).ms, duration: 250.ms);
      },
    );
  }

  void _showAddDebtDialog(BuildContext context, AppLocalizations l10n) {
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    bool isOwedToMe = true;
    DateTime? dueDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
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
                l10n.addDebt,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Gap(16),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: Text(l10n.lend),
                      selected: isOwedToMe,
                      selectedColor: AppColors.primary.withValues(alpha: 0.15),
                      onSelected: (_) => setSheetState(() => isOwedToMe = true),
                    ),
                  ),
                  const Gap(8),
                  Expanded(
                    child: ChoiceChip(
                      label: Text(l10n.borrow),
                      selected: !isOwedToMe,
                      selectedColor: AppColors.expense.withValues(alpha: 0.15),
                      onSelected: (_) =>
                          setSheetState(() => isOwedToMe = false),
                    ),
                  ),
                ],
              ),
              const Gap(12),
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: l10n.personName,
                  hintText: l10n.personNameHint,
                ),
              ),
              const Gap(10),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [ThousandsSeparatorFormatter()],
                decoration: InputDecoration(
                  labelText: l10n.amount,
                  suffixText: '₫',
                ),
              ),
              const Gap(10),
              TextField(
                controller: noteCtrl,
                decoration: InputDecoration(labelText: l10n.noteOptional),
              ),
              const Gap(10),
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: DateTime.now().add(const Duration(days: 7)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) setSheetState(() => dueDate = picked);
                },
                icon: const Icon(Icons.calendar_today_rounded, size: 16),
                label: Text(
                  dueDate != null
                      ? l10n.dueDate(DateFormat('dd/MM/yyyy').format(dueDate!))
                      : l10n.selectDueDate,
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
                    addDebt(
                      DebtModel(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        personName: name,
                        amount: amount,
                        isOwedToMe: isOwedToMe,
                        note: noteCtrl.text.trim().isEmpty
                            ? null
                            : noteCtrl.text.trim(),
                        dueDate: dueDate,
                        createdAt: DateTime.now(),
                      ),
                    );
                    Navigator.pop(ctx);
                  },
                  child: Text(l10n.add),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditDebtDialog(
    BuildContext context,
    DebtModel debt,
    AppLocalizations l10n,
  ) {
    final nameCtrl = TextEditingController(text: debt.personName);
    final amountCtrl = TextEditingController(
      text: ThousandsSeparatorFormatter.format(debt.amount),
    );
    final noteCtrl = TextEditingController(text: debt.note ?? '');
    DateTime? dueDate = debt.dueDate;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
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
                l10n.editDebt,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Gap(16),
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(labelText: l10n.personName),
              ),
              const Gap(10),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [ThousandsSeparatorFormatter()],
                decoration: InputDecoration(
                  labelText: l10n.amount,
                  suffixText: '₫',
                ),
              ),
              const Gap(10),
              TextField(
                controller: noteCtrl,
                decoration: InputDecoration(labelText: l10n.note),
              ),
              const Gap(10),
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate:
                        dueDate ?? DateTime.now().add(const Duration(days: 7)),
                    firstDate: DateTime.now().subtract(
                      const Duration(days: 365),
                    ),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) setSheetState(() => dueDate = picked);
                },
                icon: const Icon(Icons.calendar_today_rounded, size: 16),
                label: Text(
                  dueDate != null
                      ? l10n.dueDate(DateFormat('dd/MM/yyyy').format(dueDate!))
                      : l10n.selectDueDate,
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
                        updateDebt(
                          debt.id,
                          personName: name,
                          amount: amount,
                          note: noteCtrl.text.trim().isEmpty
                              ? null
                              : noteCtrl.text.trim(),
                          dueDate: dueDate,
                        );
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
      ),
    );
  }
}
