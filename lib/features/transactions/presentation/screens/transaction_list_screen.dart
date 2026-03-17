import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:qlct/core/theme/app_theme.dart';
import 'package:qlct/features/transactions/providers/transaction_providers.dart';
import 'package:qlct/features/transactions/data/models/transaction_model.dart';
import 'package:qlct/features/transactions/data/models/category_model.dart';
import 'package:qlct/features/transactions/data/repositories/transaction_repository.dart';
import 'package:qlct/l10n/app_localizations.dart';

class TransactionListScreen extends ConsumerStatefulWidget {
  const TransactionListScreen({super.key});

  @override
  ConsumerState<TransactionListScreen> createState() =>
      _TransactionListScreenState();
}

class _TransactionListScreenState extends ConsumerState<TransactionListScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final txnAsync = ref.watch(transactionsStreamProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.transactions)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Tìm giao dịch...',
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
            child: txnAsync.when(
              data: (txns) {
                final filtered = _searchQuery.isEmpty
                    ? txns
                    : txns
                          .where(
                            (t) =>
                                t.categoryName.toLowerCase().contains(
                                  _searchQuery,
                                ) ||
                                t.note.toLowerCase().contains(_searchQuery) ||
                                t.amount.toString().contains(_searchQuery),
                          )
                          .toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_rounded,
                          size: 64,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                        const Gap(16),
                        Text(
                          _searchQuery.isEmpty
                              ? l10n.noTransactions
                              : 'Không tìm thấy',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  );
                }

                final grouped = _groupByDate(filtered);
                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(transactionsStreamProvider),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppDimens.spacingMd),
                    itemCount: grouped.length,
                    itemBuilder: (context, index) {
                      final entry = grouped.entries.elementAt(index);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (index > 0) const Gap(12),
                          _buildDateHeader(context, entry.key, isDark),
                          const Gap(8),
                          ...entry.value.asMap().entries.map((e) {
                            return _buildTxnTile(
                              context,
                              ref,
                              e.value,
                              isDark,
                              l10n,
                            ).animate().fadeIn(
                              delay: (e.key * 60).ms,
                              duration: 300.ms,
                            );
                          }),
                        ],
                      );
                    },
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

  Map<String, List<TransactionModel>> _groupByDate(
    List<TransactionModel> txns,
  ) {
    final map = <String, List<TransactionModel>>{};
    for (final txn in txns) {
      final key = DateFormat('yyyy-MM-dd').format(txn.date);
      map.putIfAbsent(key, () => []).add(txn);
    }
    return map;
  }

  Widget _buildDateHeader(BuildContext context, String dateStr, bool isDark) {
    final date = DateTime.parse(dateStr);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateDay = DateTime(date.year, date.month, date.day);

    String label;
    if (dateDay == today) {
      label = 'Hôm nay';
    } else if (dateDay == today.subtract(const Duration(days: 1))) {
      label = 'Hôm qua';
    } else {
      label = DateFormat('EEEE, dd/MM', 'vi').format(date);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        label,
        style: GoogleFonts.beVietnamPro(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isDark
              ? AppColors.textSecondaryDark
              : AppColors.textSecondaryLight,
        ),
      ),
    );
  }

  Widget _buildTxnTile(
    BuildContext context,
    WidgetRef ref,
    TransactionModel txn,
    bool isDark,
    AppLocalizations l10n,
  ) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final cat = CategoryModel.defaultCategories.firstWhere(
      (c) => c.id == txn.categoryId,
      orElse: () => CategoryModel.defaultCategories.first,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Slidable(
        endActionPane: ActionPane(
          motion: const BehindMotion(),
          children: [
            SlidableAction(
              onPressed: (_) => context.push('/transaction/edit/${txn.id}'),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: Icons.edit_rounded,
              label: l10n.edit,
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(12),
              ),
            ),
            SlidableAction(
              onPressed: (_) async {
                await deleteTransaction(txn.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.transactionDeleted)),
                  );
                }
              },
              backgroundColor: AppColors.expense,
              foregroundColor: Colors.white,
              icon: Icons.delete_rounded,
              label: l10n.delete,
              borderRadius: const BorderRadius.horizontal(
                right: Radius.circular(12),
              ),
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.cardLight,
            borderRadius: BorderRadius.circular(AppDimens.radiusSm),
            boxShadow: AppShadows.cardShadow(isDark),
          ),
          child: InkWell(
            onTap: () => context.push('/transaction/edit/${txn.id}'),
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
        ),
      ),
    );
  }
}
