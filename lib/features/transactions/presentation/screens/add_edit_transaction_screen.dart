import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:qlct/core/theme/app_theme.dart';
import 'package:qlct/core/utils/thousands_formatter.dart';
import 'package:qlct/features/transactions/data/models/transaction_model.dart';
import 'package:qlct/features/transactions/data/models/category_model.dart';
import 'package:qlct/features/transactions/data/repositories/transaction_repository.dart';
import 'package:qlct/features/transactions/providers/transaction_providers.dart';
import 'package:qlct/features/budget/providers/budget_providers.dart';
import 'package:qlct/l10n/app_localizations.dart';

class AddEditTransactionScreen extends ConsumerStatefulWidget {
  final String? transactionId;
  const AddEditTransactionScreen({super.key, this.transactionId});

  @override
  ConsumerState<AddEditTransactionScreen> createState() =>
      _AddEditTransactionScreenState();
}

class _AddEditTransactionScreenState
    extends ConsumerState<AddEditTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  String _type = 'expense';
  CategoryModel? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  TransactionModel? _existingTxn;

  bool get _isEditing => widget.transactionId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) _loadTransaction();
  }

  Future<void> _loadTransaction() async {
    final txn = await getTransaction(widget.transactionId!);
    if (txn == null || !mounted) return;
    setState(() {
      _existingTxn = txn;
      _amountController.text = ThousandsSeparatorFormatter.format(txn.amount);
      _noteController.text = txn.note;
      _type = txn.type;
      _selectedDate = txn.date;
      _selectedCategory = CategoryModel.defaultCategories.firstWhere(
        (c) => c.id == txn.categoryId,
        orElse: () => CategoryModel.defaultCategories.first,
      );
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) return;

    setState(() => _isLoading = true);
    try {
      final now = DateTime.now();
      final txn = TransactionModel(
        id: _existingTxn?.id ?? '',
        amount: double.parse(_amountController.text.replaceAll('.', '')),
        type: _type,
        categoryId: _selectedCategory!.id,
        categoryName: _selectedCategory!.name,
        note: _noteController.text.trim(),
        date: _selectedDate,
        createdAt: _existingTxn?.createdAt ?? now,
        updatedAt: now,
      );

      if (_isEditing) {
        await updateTransaction(txn);
      } else {
        await addTransaction(txn);
      }

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing ? l10n.transactionUpdated : l10n.transactionAdded,
            ),
            backgroundColor: AppColors.primary,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.expense,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allCategories =
        ref.watch(categoriesStreamProvider).valueOrNull ??
        CategoryModel.defaultCategories;
    final categories = _type == 'expense'
        ? allCategories.where((c) => c.isExpense).toList()
        : allCategories.where((c) => c.isIncome).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? l10n.editTransaction : l10n.addTransaction),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimens.spacingMd),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTypeToggle(l10n, isDark),
              const Gap(20),
              _buildAmountField(l10n, isDark),
              const Gap(16),
              Text(
                l10n.selectCategory,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const Gap(8),
              _buildCategoryGrid(categories, isDark),
              if (_type == 'expense' && _selectedCategory != null)
                _buildJarBalance(ref, isDark, l10n),
              const Gap(16),
              _buildDatePicker(l10n, isDark),
              const Gap(16),
              _buildNoteField(l10n),
              const Gap(24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          l10n.save,
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeToggle(AppLocalizations l10n, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(AppDimens.radiusSm),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() {
                _type = 'expense';
                _selectedCategory = null;
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _type == 'expense'
                      ? AppColors.expense
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppDimens.radiusXs),
                ),
                child: Center(
                  child: Text(
                    l10n.expense,
                    style: GoogleFonts.beVietnamPro(
                      fontWeight: FontWeight.w600,
                      color: _type == 'expense' ? Colors.white : null,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() {
                _type = 'income';
                _selectedCategory = null;
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _type == 'income'
                      ? AppColors.income
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppDimens.radiusXs),
                ),
                child: Center(
                  child: Text(
                    l10n.income,
                    style: GoogleFonts.beVietnamPro(
                      fontWeight: FontWeight.w600,
                      color: _type == 'income' ? Colors.white : null,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountField(AppLocalizations l10n, bool isDark) {
    return TextFormField(
      controller: _amountController,
      keyboardType: TextInputType.number,
      inputFormatters: [ThousandsSeparatorFormatter()],
      style: GoogleFonts.beVietnamPro(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: _type == 'expense' ? AppColors.expense : AppColors.income,
      ),
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        hintText: '0',
        hintStyle: GoogleFonts.beVietnamPro(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: isDark
              ? AppColors.textSecondaryDark
              : AppColors.textSecondaryLight,
        ),
        suffixText: '₫',
        suffixStyle: GoogleFonts.beVietnamPro(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: isDark
              ? AppColors.textSecondaryDark
              : AppColors.textSecondaryLight,
        ),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return l10n.amountRequired;
        return null;
      },
    );
  }

  Widget _buildCategoryGrid(List<CategoryModel> categories, bool isDark) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.85,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final cat = categories[index];
        final isSelected = _selectedCategory?.id == cat.id;
        return GestureDetector(
          onTap: () => setState(() => _selectedCategory = cat),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? cat.colorValue.withValues(alpha: 0.15)
                  : (isDark ? AppColors.cardDark : AppColors.cardLight),
              borderRadius: BorderRadius.circular(AppDimens.radiusSm),
              border: Border.all(
                color: isSelected ? cat.colorValue : Colors.transparent,
                width: 2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: cat.colorValue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(cat.iconData, color: cat.colorValue, size: 20),
                ),
                const Gap(4),
                Text(
                  cat.name,
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDatePicker(AppLocalizations l10n, bool isDark) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 1)),
        );
        if (picked != null) setState(() => _selectedDate = picked);
      },
      borderRadius: BorderRadius.circular(AppDimens.radiusSm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(
            color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
          ),
          borderRadius: BorderRadius.circular(AppDimens.radiusSm),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 20,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
            const Gap(12),
            Text(
              DateFormat('dd/MM/yyyy').format(_selectedDate),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteField(AppLocalizations l10n) {
    return TextFormField(
      controller: _noteController,
      maxLines: 2,
      decoration: InputDecoration(
        hintText: l10n.enterNote,
        prefixIcon: const Icon(Icons.note_alt_rounded),
      ),
    );
  }

  Widget _buildJarBalance(WidgetRef ref, bool isDark, AppLocalizations l10n) {
    final progress = ref.watch(budgetProgressProvider);
    final p = progress[_selectedCategory!.id];
    final currFmt = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    if (p == null) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: 14,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
            const Gap(4),
            Text(
              l10n.noBudgetForCategory,
              style: GoogleFonts.nunito(
                fontSize: 12,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      );
    }

    final limit = p['limit'] ?? 0;
    final spent = p['spent'] ?? 0;
    final inputAmount = ThousandsSeparatorFormatter.parse(
      _amountController.text,
    );
    final afterSpend = limit - spent - (_isEditing ? 0 : inputAmount);
    final isOver = afterSpend < 0;
    final isWarning = afterSpend >= 0 && afterSpend < limit * 0.2;
    final statusColor = isOver
        ? AppColors.expense
        : isWarning
        ? Colors.orange
        : AppColors.primary;

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: statusColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: statusColor.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.savings_rounded, size: 16, color: statusColor),
            const Gap(6),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text:
                          '${CategoryModel.localizedName(_selectedCategory!.id, l10n)}: ',
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextSpan(
                      text: isOver
                          ? l10n.jarOver(currFmt.format(-afterSpend))
                          : l10n.jarRemaining(currFmt.format(afterSpend)),
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
