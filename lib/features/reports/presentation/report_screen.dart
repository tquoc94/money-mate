import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:qlct/core/theme/app_theme.dart';
import 'package:qlct/features/reports/providers/report_providers.dart';
import 'package:qlct/features/transactions/data/models/category_model.dart';
import 'package:qlct/l10n/app_localizations.dart';

class ReportScreen extends ConsumerWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final period = ref.watch(reportPeriodProvider);
    final summary = ref.watch(reportSummaryProvider);
    final txnAsync = ref.watch(reportTransactionsProvider);
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final selected = ref.watch(selectedReportMonthProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.reports)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimens.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMonthSelector(
              context,
              ref,
              selected,
              isDark,
            ).animate().fadeIn(duration: 200.ms),
            const Gap(12),
            _buildPeriodSelector(
              context,
              ref,
              period,
              l10n,
              isDark,
            ).animate().fadeIn(duration: 300.ms),
            const Gap(16),
            _buildSummaryCards(context, summary, currencyFormat, l10n, isDark)
                .animate()
                .fadeIn(delay: 100.ms, duration: 400.ms)
                .slideY(begin: 0.05, end: 0),
            const Gap(20),
            Text(
              l10n.byCategory,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Gap(12),
            txnAsync.when(
              data: (txns) {
                final catExpenses =
                    summary['categoryExpenses'] as Map<String, double>? ?? {};
                if (catExpenses.isEmpty) {
                  return _buildEmptyChart(context, l10n, isDark);
                }
                return _buildPieChart(context, catExpenses, isDark)
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 500.ms)
                    .scale(
                      begin: const Offset(0.9, 0.9),
                      end: const Offset(1, 1),
                    );
              },
              loading: () => const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
            const Gap(20),
            Text(l10n.byTime, style: Theme.of(context).textTheme.titleMedium),
            const Gap(12),
            txnAsync.when(
              data: (txns) {
                final dailyData =
                    summary['dailyData'] as Map<String, Map<String, double>>? ??
                    {};
                if (dailyData.isEmpty) {
                  return _buildEmptyChart(context, l10n, isDark);
                }
                return _buildBarChart(context, dailyData, isDark)
                    .animate()
                    .fadeIn(delay: 300.ms, duration: 500.ms)
                    .slideY(begin: 0.05, end: 0);
              },
              loading: () => const SizedBox(height: 200),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
            const Gap(20),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector(
    BuildContext context,
    WidgetRef ref,
    ReportPeriod period,
    AppLocalizations l10n,
    bool isDark,
  ) {
    final labels = {
      ReportPeriod.week: l10n.week,
      ReportPeriod.month: l10n.month,
      ReportPeriod.year: l10n.year,
    };

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(AppDimens.radiusSm),
      ),
      child: Row(
        children: ReportPeriod.values.map((p) {
          final isActive = p == period;
          return Expanded(
            child: GestureDetector(
              onTap: () => ref.read(reportPeriodProvider.notifier).state = p,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppDimens.radiusXs),
                ),
                child: Center(
                  child: Text(
                    labels[p]!,
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 14,
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
    );
  }

  Widget _buildSummaryCards(
    BuildContext context,
    Map<String, dynamic> summary,
    NumberFormat fmt,
    AppLocalizations l10n,
    bool isDark,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            label: l10n.totalExpense,
            value: fmt.format(summary['totalExpense'] ?? 0),
            icon: Icons.arrow_upward_rounded,
            color: AppColors.expense,
            isDark: isDark,
          ),
        ),
        const Gap(12),
        Expanded(
          child: _buildStatCard(
            context,
            label: l10n.averagePerDay,
            value: fmt.format(summary['avgPerDay'] ?? 0),
            icon: Icons.calendar_today_rounded,
            color: AppColors.primary,
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        border: Border.all(
          color: (isDark ? AppColors.dividerDark : AppColors.dividerLight)
              .withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const Gap(10),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const Gap(4),
          Text(
            value,
            style: GoogleFonts.beVietnamPro(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChart(
    BuildContext context,
    AppLocalizations l10n,
    bool isDark,
  ) {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        border: Border.all(
          color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart_rounded,
              size: 40,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
            const Gap(8),
            Text(
              l10n.noTransactions,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart(
    BuildContext context,
    Map<String, double> categoryExpenses,
    bool isDark,
  ) {
    final total = categoryExpenses.values.fold(0.0, (a, b) => a + b);
    final entries = categoryExpenses.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    final colors = <Color>[];
    for (final entry in entries) {
      final cat = CategoryModel.defaultCategories.firstWhere(
        (c) => c.name == entry.key,
        orElse: () => CategoryModel.defaultCategories.first,
      );
      colors.add(cat.colorValue);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        border: Border.all(
          color: (isDark ? AppColors.dividerDark : AppColors.dividerLight)
              .withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: entries.asMap().entries.map((e) {
                  final pct = (e.value.value / total * 100);
                  return PieChartSectionData(
                    color: colors[e.key],
                    value: e.value.value,
                    title: '${pct.toStringAsFixed(0)}%',
                    radius: 50,
                    titleStyle: GoogleFonts.beVietnamPro(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const Gap(16),
          ...entries.asMap().entries.map((e) {
            final pct = (e.value.value / total * 100).toStringAsFixed(1);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: colors[e.key],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const Gap(8),
                  Expanded(
                    child: Text(
                      e.value.key,
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    currencyFormat.format(e.value.value),
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Gap(8),
                  SizedBox(
                    width: 40,
                    child: Text(
                      '$pct%',
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBarChart(
    BuildContext context,
    Map<String, Map<String, double>> dailyData,
    bool isDark,
  ) {
    final entries = dailyData.entries.toList();
    final maxEntries = entries.length > 7
        ? entries.sublist(entries.length - 7)
        : entries;

    double maxY = 0;
    for (final e in maxEntries) {
      final inc = e.value['income'] ?? 0;
      final exp = e.value['expense'] ?? 0;
      if (inc > maxY) maxY = inc;
      if (exp > maxY) maxY = exp;
    }
    maxY = maxY == 0 ? 100 : maxY * 1.2;

    return Container(
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        border: Border.all(
          color: (isDark ? AppColors.dividerDark : AppColors.dividerLight)
              .withValues(alpha: 0.5),
        ),
      ),
      child: BarChart(
        BarChartData(
          maxY: maxY,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final fmt = NumberFormat.compact(locale: 'vi');
                return BarTooltipItem(
                  fmt.format(rod.toY),
                  GoogleFonts.nunito(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= maxEntries.length)
                    return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      maxEntries[idx].key,
                      style: GoogleFonts.nunito(fontSize: 10),
                    ),
                  );
                },
                reservedSize: 28,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 42,
                getTitlesWidget: (value, meta) {
                  final fmt = NumberFormat.compact(locale: 'vi');
                  return Text(
                    fmt.format(value),
                    style: GoogleFonts.nunito(fontSize: 10),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 4,
            getDrawingHorizontalLine: (value) => FlLine(
              color: (isDark ? AppColors.dividerDark : AppColors.dividerLight)
                  .withValues(alpha: 0.5),
              strokeWidth: 1,
            ),
          ),
          barGroups: maxEntries.asMap().entries.map((e) {
            final inc = e.value.value['income'] ?? 0;
            final exp = e.value.value['expense'] ?? 0;
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: inc,
                  color: AppColors.income,
                  width: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                BarChartRodData(
                  toY: exp,
                  color: AppColors.expense,
                  width: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
              barsSpace: 4,
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMonthSelector(
    BuildContext context,
    WidgetRef ref,
    DateTime selected,
    bool isDark,
  ) {
    final monthLabel = 'Tháng ${selected.month}/${selected.year}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(AppDimens.radiusSm),
        border: Border.all(
          color: (isDark ? AppColors.dividerDark : AppColors.dividerLight)
              .withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: () {
              final prev = DateTime(selected.year, selected.month - 1);
              ref.read(selectedReportMonthProvider.notifier).state = prev;
            },
          ),
          Text(
            monthLabel,
            style: GoogleFonts.beVietnamPro(
              fontSize: 15,
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
                ref.read(selectedReportMonthProvider.notifier).state = next;
              }
            },
          ),
        ],
      ),
    );
  }
}
