import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:qlct/core/theme/app_theme.dart';
import 'package:qlct/features/auth/providers/auth_providers.dart';
import 'package:qlct/features/transactions/providers/transaction_providers.dart';
import 'package:qlct/features/transactions/data/models/transaction_model.dart';
import 'package:qlct/features/transactions/data/models/category_model.dart';
import 'package:qlct/features/transactions/data/repositories/category_repository.dart';
import 'package:qlct/features/budget/providers/budget_providers.dart';
import 'package:qlct/features/reminders/providers/reminder_providers.dart';
import 'package:qlct/features/savings/providers/savings_providers.dart';
import 'package:qlct/features/debts/providers/debt_providers.dart';
import 'package:qlct/l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fl_chart/fl_chart.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    initDefaultCategories();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(currentUserProvider);
    final summary = ref.watch(monthlySummaryProvider);
    final txnAsync = ref.watch(monthlyTransactionsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final now = DateTime.now();
    String timeOfDay;
    if (now.hour < 12) {
      timeOfDay = l10n.morning;
    } else if (now.hour < 18) {
      timeOfDay = l10n.afternoon;
    } else {
      timeOfDay = l10n.evening;
    }

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(monthlyTransactionsProvider),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppDimens.spacingMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundImage: user?.photoURL != null
                          ? CachedNetworkImageProvider(user!.photoURL!)
                          : null,
                      child: user?.photoURL == null
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    const Gap(12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.greeting(
                              timeOfDay,
                              user?.displayName?.split(' ').first ?? '',
                            ),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            DateFormat('EEEE, dd/MM/yyyy', 'vi').format(now),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ).animate().fadeIn(duration: 400.ms),
                const Gap(20),
                _buildBalanceCard(context, summary, isDark, l10n)
                    .animate()
                    .fadeIn(delay: 100.ms, duration: 400.ms)
                    .slideY(begin: 0.1, end: 0),
                const Gap(16),
                _buildBudgetAlerts(
                  context,
                  ref,
                  isDark,
                ).animate().fadeIn(delay: 150.ms, duration: 300.ms),
                const Gap(12),
                _buildUpcomingReminders(
                  context,
                  ref,
                  isDark,
                ).animate().fadeIn(delay: 180.ms, duration: 300.ms),
                const Gap(12),
                _buildSparkline(
                  context,
                  ref,
                  isDark,
                ).animate().fadeIn(delay: 200.ms, duration: 300.ms),
                const Gap(12),
                _buildQuickSummary(
                  context,
                  ref,
                  isDark,
                ).animate().fadeIn(delay: 220.ms, duration: 300.ms),
                const Gap(20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.recentTransactions,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    TextButton(
                      onPressed: () => context.go('/transactions'),
                      child: Text(l10n.viewAll),
                    ),
                  ],
                ),
                const Gap(8),
                txnAsync.when(
                  data: (txns) {
                    if (txns.isEmpty) {
                      return _buildEmptyState(context, l10n, isDark);
                    }
                    final recent = txns.take(5).toList();
                    return Column(
                      children: recent.asMap().entries.map((entry) {
                        return _buildTransactionTile(
                              context,
                              entry.value,
                              isDark,
                            )
                            .animate()
                            .fadeIn(
                              delay: (200 + entry.key * 80).ms,
                              duration: 300.ms,
                            )
                            .slideX(begin: 0.05, end: 0);
                      }).toList(),
                    );
                  },
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (e, _) => Center(child: Text('Error: $e')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard(
    BuildContext context,
    Map<String, double> summary,
    bool isDark,
    AppLocalizations l10n,
  ) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: isDark
            ? AppGradients.primaryDarkGradient
            : AppGradients.primaryGradient,
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        boxShadow: AppShadows.elevatedShadow(isDark),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        child: Stack(
          children: [
            Positioned(
              top: -30,
              right: -30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            Positioned(
              bottom: -20,
              left: -20,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          l10n.balance,
                          style: GoogleFonts.nunito(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Gap(8),
                  Text(
                    currencyFormat.format(summary['balance'] ?? 0),
                    style: GoogleFonts.beVietnamPro(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Gap(20),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildSummaryItem(
                            icon: Icons.arrow_downward_rounded,
                            label: l10n.totalIncome,
                            amount: currencyFormat.format(
                              summary['income'] ?? 0,
                            ),
                            color: Colors.white,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 36,
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                        Expanded(
                          child: _buildSummaryItem(
                            icon: Icons.arrow_upward_rounded,
                            label: l10n.totalExpense,
                            amount: currencyFormat.format(
                              summary['expense'] ?? 0,
                            ),
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String label,
    required String amount,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const Gap(8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.nunito(
                    color: color.withValues(alpha: 0.8),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  amount,
                  style: GoogleFonts.beVietnamPro(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    AppLocalizations l10n,
    bool isDark,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        border: Border.all(
          color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_rounded,
            size: 48,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
          const Gap(12),
          Text(
            l10n.noTransactions,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const Gap(4),
          Text(
            l10n.noTransactionsHint,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTile(
    BuildContext context,
    TransactionModel txn,
    bool isDark,
  ) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final cat = CategoryModel.defaultCategories.firstWhere(
      (c) => c.id == txn.categoryId,
      orElse: () => CategoryModel.defaultCategories.first,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(AppDimens.radiusSm),
        border: Border.all(
          color: (isDark ? AppColors.dividerDark : AppColors.dividerLight)
              .withValues(alpha: 0.5),
        ),
      ),
      child: InkWell(
        onTap: () => context.push('/transaction/edit/${txn.id}'),
        borderRadius: BorderRadius.circular(AppDimens.radiusSm),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: cat.colorValue.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(cat.iconData, color: cat.colorValue, size: 22),
            ),
            const Gap(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    txn.categoryName,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  if (txn.note.isNotEmpty)
                    Text(
                      txn.note,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            Text(
              '${txn.isExpense ? "-" : "+"}${currencyFormat.format(txn.amount)}',
              style: GoogleFonts.beVietnamPro(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: txn.isExpense ? AppColors.expense : AppColors.income,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetAlerts(BuildContext context, WidgetRef ref, bool isDark) {
    final progress = ref.watch(budgetProgressProvider);
    final allBudgets = ref.watch(budgetsProvider).valueOrNull ?? [];
    final pinnedBudgets = allBudgets.where((b) => b.isPinned).toList();
    final currFmt = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    if (allBudgets.isEmpty) {
      return InkWell(
        onTap: () => context.push('/budget'),
        borderRadius: BorderRadius.circular(AppDimens.radiusSm),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.savings_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const Gap(12),
              Expanded(
                child: Text(
                  'Thiết lập hũ chi tiêu',
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ],
          ),
        ),
      );
    }

    if (pinnedBudgets.isEmpty) {
      return InkWell(
        onTap: () => context.push('/budget'),
        borderRadius: BorderRadius.circular(AppDimens.radiusSm),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(AppDimens.radiusSm),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.push_pin_outlined,
                color: AppColors.primary,
                size: 18,
              ),
              const Gap(8),
              Expanded(
                child: Text(
                  'Ghim hũ để hiện trên trang chủ',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AppColors.primary.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      );
    }

    return InkWell(
      onTap: () => context.push('/budget'),
      borderRadius: BorderRadius.circular(AppDimens.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(14),
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
                const Icon(
                  Icons.savings_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
                const Gap(6),
                Text(
                  'Hũ chi tiêu',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ],
            ),
            const Gap(10),
            Column(
              children: pinnedBudgets.map((b) {
                final p = progress[b.categoryId];
                final remaining = p?['remaining'] ?? b.limit;
                final pct = p?['percentage'] ?? 0;
                final isOver = pct > 1.0;
                final isWarning = pct > 0.8 && pct <= 1.0;

                final cat = CategoryModel.defaultCategories.firstWhere(
                  (c) => c.id == b.categoryId,
                  orElse: () => CategoryModel.defaultCategories.first,
                );

                final statusColor = isOver
                    ? AppColors.expense
                    : isWarning
                    ? Colors.orange
                    : AppColors.primary;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: cat.colorValue.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            cat.iconData,
                            color: cat.colorValue,
                            size: 16,
                          ),
                        ),
                        const Gap(10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                b.categoryName,
                                style: GoogleFonts.nunito(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                isOver
                                    ? 'Vượt ${currFmt.format(-remaining)}'
                                    : 'Còn ${currFmt.format(remaining)}',
                                style: GoogleFonts.beVietnamPro(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: statusColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 60,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: pct.clamp(0.0, 1.0),
                              minHeight: 5,
                              backgroundColor: isDark
                                  ? AppColors.dividerDark
                                  : AppColors.dividerLight,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingReminders(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
  ) {
    final upcoming = ref.watch(upcomingRemindersProvider);
    if (upcoming.isEmpty) return const SizedBox.shrink();

    final currFmt = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppDimens.radiusSm),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.notifications_active_rounded,
                color: AppColors.warning,
                size: 16,
              ),
              const Gap(6),
              Text(
                'Sắp đến hạn',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
          const Gap(8),
          ...upcoming
              .take(3)
              .map(
                (r) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Text(
                        '• ${r.title}',
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        currFmt.format(r.amount),
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: r.isOverdue
                              ? AppColors.expense
                              : AppColors.warning,
                        ),
                      ),
                      const Gap(6),
                      Text(
                        'ngày ${r.dueDay}',
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
              ),
        ],
      ),
    );
  }

  Widget _buildSparkline(BuildContext context, WidgetRef ref, bool isDark) {
    final txnAsync = ref.watch(monthlyTransactionsProvider);
    final txns = txnAsync.valueOrNull ?? [];
    if (txns.isEmpty) return const SizedBox.shrink();

    final now = DateTime.now();
    final dailySpend = <double>[];
    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final total = txns
          .where(
            (t) =>
                !t.isIncome &&
                t.date.day == day.day &&
                t.date.month == day.month,
          )
          .fold(0.0, (sum, t) => sum + t.amount);
      dailySpend.add(total);
    }

    final maxVal = dailySpend.reduce((a, b) => a > b ? a : b);
    if (maxVal == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(AppDimens.radiusSm),
        boxShadow: AppShadows.cardShadow(isDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chi tiêu 7 ngày qua',
            style: GoogleFonts.beVietnamPro(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Gap(12),
          SizedBox(
            height: 60,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                minY: 0,
                maxY: maxVal * 1.2,
                lineBarsData: [
                  LineChartBarData(
                    spots: dailySpend
                        .asMap()
                        .entries
                        .map((e) => FlSpot(e.key.toDouble(), e.value))
                        .toList(),
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                        radius: 3,
                        color: AppColors.primary,
                        strokeWidth: 1.5,
                        strokeColor: Colors.white,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primary.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickSummary(BuildContext context, WidgetRef ref, bool isDark) {
    final goals = ref.watch(savingsGoalsProvider).valueOrNull ?? [];
    final totalOwed = ref.watch(totalOwedToMeProvider);
    final totalBorrowed = ref.watch(totalIBorrowedProvider);
    final reminders = ref.watch(remindersProvider).valueOrNull ?? [];
    final activeReminders = reminders.where((r) => r.isActive).length;
    final currFmt = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );

    final totalSaved = goals.fold(0.0, (sum, g) => sum + g.currentAmount);
    final netDebt = totalOwed - totalBorrowed;

    return Row(
      children: [
        Expanded(
          child: _buildSummaryChip(
            context,
            isDark,
            icon: Icons.savings_rounded,
            color: AppColors.info,
            title: 'Tiết kiệm',
            value: currFmt.format(totalSaved),
            onTap: () => context.push('/savings'),
          ),
        ),
        const Gap(8),
        Expanded(
          child: _buildSummaryChip(
            context,
            isDark,
            icon: Icons.handshake_rounded,
            color: netDebt >= 0 ? AppColors.primary : AppColors.expense,
            title: netDebt >= 0 ? 'Được nợ' : 'Đang nợ',
            value: currFmt.format(netDebt.abs()),
            onTap: () => context.push('/debts'),
          ),
        ),
        const Gap(8),
        Expanded(
          child: _buildSummaryChip(
            context,
            isDark,
            icon: Icons.notifications_active_rounded,
            color: AppColors.warning,
            title: 'Nhắc nhở',
            value: '$activeReminders bill',
            onTap: () => context.push('/reminders'),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryChip(
    BuildContext context,
    bool isDark, {
    required IconData icon,
    required Color color,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimens.radiusSm),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(AppDimens.radiusSm),
          boxShadow: AppShadows.cardShadow(isDark),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const Gap(4),
            Text(
              title,
              style: GoogleFonts.nunito(
                fontSize: 10,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
            const Gap(2),
            Text(
              value,
              style: GoogleFonts.beVietnamPro(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
