import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:qlct/core/theme/app_theme.dart';
import 'package:qlct/core/utils/thousands_formatter.dart';
import 'package:qlct/features/reminders/data/models/reminder_model.dart';
import 'package:qlct/features/reminders/data/repositories/reminder_repository.dart';
import 'package:qlct/features/reminders/providers/reminder_providers.dart';
import 'package:qlct/core/services/notification_service.dart';
import 'package:qlct/l10n/app_localizations.dart';

class ReminderScreen extends ConsumerStatefulWidget {
  const ReminderScreen({super.key});

  @override
  ConsumerState<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends ConsumerState<ReminderScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final remindersAsync = ref.watch(remindersProvider);
    final currFmt = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return Scaffold(
      appBar: AppBar(title: Text(l10n.paymentReminders)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddReminderDialog(context, l10n),
        child: const Icon(Icons.add_rounded),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
              decoration: InputDecoration(
                hintText: l10n.paymentReminderSearch,
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
            child: remindersAsync.when(
              data: (reminders) {
                final filtered = _searchQuery.isEmpty
                    ? reminders
                    : reminders
                          .where(
                            (r) => r.title.toLowerCase().contains(_searchQuery),
                          )
                          .toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_none_rounded,
                          size: 64,
                          color: AppColors.warning.withValues(alpha: 0.3),
                        ),
                        const Gap(12),
                        Text(
                          _searchQuery.isEmpty
                              ? l10n.noReminders
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
                            l10n.noRemindersHint,
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
                  itemBuilder: (context, i) {
                    final r = filtered[i];
                    final isDueSoon = r.isDueSoon;
                    final isOverdue = r.isOverdue;
                    final statusColor = isOverdue
                        ? AppColors.expense
                        : isDueSoon
                        ? AppColors.warning
                        : AppColors.primary;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.cardDark
                            : AppColors.cardLight,
                        borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                        boxShadow: AppShadows.cardShadow(isDark),
                        border: (isDueSoon || isOverdue)
                            ? Border.all(
                                color: statusColor.withValues(alpha: 0.3),
                              )
                            : null,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              isOverdue
                                  ? Icons.warning_amber_rounded
                                  : Icons.notifications_active_rounded,
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
                                  r.title,
                                  style: GoogleFonts.beVietnamPro(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  currFmt.format(r.amount),
                                  style: GoogleFonts.beVietnamPro(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: statusColor,
                                  ),
                                ),
                                Text(
                                  l10n.monthlyOnDay(r.dueDay),
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
                          if (isDueSoon || isOverdue)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isOverdue
                                    ? l10n.overdueLabel
                                    : l10n.dueSoonLabel,
                                style: GoogleFonts.nunito(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: statusColor,
                                ),
                              ),
                            ),
                          const Gap(4),
                          IconButton(
                            icon: const Icon(Icons.edit_rounded, size: 18),
                            tooltip: l10n.edit,
                            onPressed: () =>
                                _showEditReminderDialog(context, r, l10n),
                          ),
                          Switch(
                            value: r.isActive,
                            onChanged: (newValue) async {
                              await toggleReminder(r);
                              if (newValue) {
                                await NotificationService.scheduleMonthlyReminder(
                                  r,
                                );
                              } else {
                                await NotificationService.cancelReminder(r.id);
                              }
                            },
                            activeTrackColor: AppColors.primary,
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.delete_outline_rounded,
                              size: 20,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                            onPressed: () async {
                              await deleteReminder(r.id);
                              await NotificationService.cancelReminder(r.id);
                            },
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: (i * 60).ms, duration: 250.ms);
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

  void _showAddReminderDialog(BuildContext context, AppLocalizations l10n) {
    final titleCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final dayCtrl = TextEditingController();

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
              l10n.addReminder,
              style: GoogleFonts.beVietnamPro(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Gap(16),
            TextField(
              controller: titleCtrl,
              decoration: InputDecoration(
                labelText: l10n.billName,
                hintText: l10n.billNameHint,
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
              controller: dayCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.paymentDay,
                hintText: l10n.paymentDayHint,
              ),
            ),
            const Gap(16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  final title = titleCtrl.text.trim();
                  final amount = ThousandsSeparatorFormatter.parse(
                    amountCtrl.text,
                  );
                  final day = int.tryParse(dayCtrl.text) ?? 0;
                  if (title.isEmpty || amount <= 0 || day < 1 || day > 31)
                    return;
                  final reminder = ReminderModel(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: title,
                    amount: amount,
                    dueDay: day,
                    createdAt: DateTime.now(),
                  );
                  await addReminder(reminder);
                  await NotificationService.scheduleMonthlyReminder(reminder);
                  Navigator.pop(ctx);
                },
                child: Text(l10n.addReminder),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditReminderDialog(
    BuildContext context,
    ReminderModel r,
    AppLocalizations l10n,
  ) {
    final titleCtrl = TextEditingController(text: r.title);
    final amountCtrl = TextEditingController(
      text: ThousandsSeparatorFormatter.format(r.amount),
    );
    final dayCtrl = TextEditingController(text: r.dueDay.toString());
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
              l10n.editReminder,
              style: GoogleFonts.beVietnamPro(
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Gap(16),
            TextField(
              controller: titleCtrl,
              decoration: InputDecoration(labelText: l10n.billName),
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
              controller: dayCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: l10n.paymentDay),
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
                    onPressed: () async {
                      final title = titleCtrl.text.trim();
                      final amount = ThousandsSeparatorFormatter.parse(
                        amountCtrl.text,
                      );
                      final day = int.tryParse(dayCtrl.text) ?? 0;
                      if (title.isEmpty || amount <= 0 || day < 1 || day > 31)
                        return;
                      await updateReminder(
                        r.id,
                        title: title,
                        amount: amount,
                        dueDay: day,
                      );
                      if (r.isActive) {
                        await NotificationService.cancelReminder(r.id);
                        await NotificationService.scheduleMonthlyReminder(
                          ReminderModel(
                            id: r.id,
                            title: title,
                            amount: amount,
                            dueDay: day,
                            createdAt: r.createdAt,
                          ),
                        );
                      }
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
