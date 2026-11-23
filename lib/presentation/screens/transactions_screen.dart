import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/category_model.dart';
import '../../data/models/transaction_model.dart';
import '../providers/expense_provider.dart';
import '../providers/theme_provider.dart';
import 'add_transaction_screen.dart';

// ============================================================================
// الواجهة الثالثة: سجل العمليات (TransactionsScreen)
// ----------------------------------------------------------------------------
// مطابقة للتصميم في الصورة وتتكوّن من 5 أقسام واضحة:
//   [1] شريط البحث النصي (بحث بالعنوان أو التصنيف أو الملاحظات)
//   [2] أزرار التصفية حسب النوع (الكل | دخل | مصروف)
//   [3] قائمتا التصفية المنسدلتان (كل التصنيفات | كل الوقت)
//   [4] تجميع العمليات تلقائياً حسب الأيام (اليوم - أمس - التاريخ)
//   [5] بطاقة العملية مع الوقت وقائمة الثلاث نقاط (عرض / تعديل / حذف)
// ============================================================================

enum _TypeFilter { all, income, expense }

enum _TimeFilter { allTime, today, last7Days, thisMonth, lastMonth }

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  _TypeFilter _selectedType = _TypeFilter.all;
  String _selectedCategoryId = 'all';
  _TimeFilter _selectedTime = _TimeFilter.allTime;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// التصنيفات المتاحة في القائمة المنسدلة بناءً على النوع المختار
  List<CategoryModel> get _availableCategories {
    switch (_selectedType) {
      case _TypeFilter.income:
        return AppConstants.incomeCategories;
      case _TypeFilter.expense:
        return AppConstants.expenseCategories;
      case _TypeFilter.all:
        return AppConstants.allCategories;
    }
  }

  /// التحقق هل يوجد أي فلتر نشط لعرض زر "إعادة تعيين"
  bool get _hasActiveFilters =>
      _searchQuery.isNotEmpty ||
      _selectedType != _TypeFilter.all ||
      _selectedCategoryId != 'all' ||
      _selectedTime != _TimeFilter.allTime;

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _selectedType = _TypeFilter.all;
      _selectedCategoryId = 'all';
      _selectedTime = _TimeFilter.allTime;
    });
  }

  /// تطبيق جميع الفلاتر (البحث + النوع + التصنيف + الوقت) على قائمة العمليات
  List<TransactionModel> _applyFilters(List<TransactionModel> all) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final query = _searchQuery.trim().toLowerCase();

    return all.where((tx) {
      // 1. فلتر النوع
      if (_selectedType == _TypeFilter.income && !tx.isIncome) return false;
      if (_selectedType == _TypeFilter.expense && !tx.isExpense) return false;

      // 2. فلتر التصنيف
      if (_selectedCategoryId != 'all' && tx.categoryId != _selectedCategoryId) {
        return false;
      }

      // 3. فلتر الوقت
      switch (_selectedTime) {
        case _TimeFilter.allTime:
          break;
        case _TimeFilter.today:
          final txDay = DateTime(tx.date.year, tx.date.month, tx.date.day);
          if (txDay != todayStart) return false;
          break;
        case _TimeFilter.last7Days:
          final weekAgo = todayStart.subtract(const Duration(days: 6));
          if (tx.date.isBefore(weekAgo)) return false;
          break;
        case _TimeFilter.thisMonth:
          if (tx.date.year != now.year || tx.date.month != now.month) {
            return false;
          }
          break;
        case _TimeFilter.lastMonth:
          final lastMonthDate = DateTime(now.year, now.month - 1, 1);
          if (tx.date.year != lastMonthDate.year ||
              tx.date.month != lastMonthDate.month) {
            return false;
          }
          break;
      }

      // 4. فلتر البحث النصي
      if (query.isNotEmpty) {
        final inTitle = tx.title.toLowerCase().contains(query);
        final inCategory = tx.categoryName.toLowerCase().contains(query);
        final inNotes = (tx.notes ?? '').toLowerCase().contains(query);
        if (!inTitle && !inCategory && !inNotes) return false;
      }

      return true;
    }).toList();
  }

  /// تجميع العمليات حسب اليوم (مع الحفاظ على الترتيب من الأحدث إلى الأقدم)
  Map<String, List<TransactionModel>> _groupByDay(List<TransactionModel> list) {
    final Map<String, List<TransactionModel>> grouped = {};
    for (final tx in list) {
      final header = Formatters.formatArabicDayHeader(tx.date);
      grouped.putIfAbsent(header, () => []).add(tx);
    }
    return grouped;
  }

  /// حوار تأكيد حذف عملية
  Future<void> _confirmDelete(
    BuildContext context,
    TransactionModel tx,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف عملية "${tx.title}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.expenseColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await Provider.of<ExpenseProvider>(context, listen: false)
          .deleteTransaction(tx.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حذف العملية بنجاح')),
      );
    }
  }

  /// فتح تفاصيل العملية في نافذة سفلية
  void _showDetailsSheet(
    BuildContext context,
    TransactionModel tx,
    String currency,
  ) {
    final categoryColor = Color(tx.categoryColorHex);
    final paymentMethod = AppConstants.getPaymentMethod(tx.paymentMethod);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha(110),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: categoryColor.withAlpha(35),
                  child: Icon(
                    AppConstants.getCategoryIcon(tx.categoryId),
                    color: categoryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tx.title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${tx.categoryName} • ${Formatters.formatDate(tx.date)}',
                        style: const TextStyle(fontSize: 12.5, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${tx.isExpense ? '-' : '+'} ${Formatters.formatCurrency(tx.amount, symbol: currency)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: tx.isExpense
                        ? AppTheme.expenseColor
                        : AppTheme.incomeColor,
                  ),
                ),
              ],
            ),
            if (paymentMethod != null) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(paymentMethod.icon, size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    'طريقة الدفع: ${paymentMethod.nameAr}',
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
            if (tx.notes != null && tx.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 6),
              const Text(
                'الملاحظات:',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(tx.notes!, style: const TextStyle(fontSize: 14)),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('تعديل'),
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              AddTransactionScreen(transactionToEdit: tx),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.expenseColor,
                      side: const BorderSide(color: AppTheme.expenseColor),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('حذف'),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _confirmDelete(context, tx);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _timeFilterLabel(_TimeFilter filter) {
    switch (filter) {
      case _TimeFilter.allTime:
        return 'كل الوقت';
      case _TimeFilter.today:
        return 'اليوم';
      case _TimeFilter.last7Days:
        return 'آخر 7 أيام';
      case _TimeFilter.thisMonth:
        return 'هذا الشهر';
      case _TimeFilter.lastMonth:
        return 'الشهر الماضي';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Provider.of<ThemeProvider>(context).selectedColor.primary;

    return Consumer<ExpenseProvider>(
      builder: (context, provider, child) {
        final filtered = _applyFilters(provider.transactions);
        final grouped = _groupByDay(filtered);
        final dayHeaders = grouped.keys.toList();
        final currency = provider.currencySymbol;

        // التأكد أن التصنيف المختار ما زال ضمن القائمة المتاحة
        final categoryIds = _availableCategories.map((c) => c.id).toSet();
        final safeCategoryValue =
            (_selectedCategoryId == 'all' || categoryIds.contains(_selectedCategoryId))
                ? _selectedCategoryId
                : 'all';

        return Scaffold(
          appBar: AppBar(
            title: const Text('سجل العمليات'),
            actions: [
              if (_hasActiveFilters)
                IconButton(
                  tooltip: 'إعادة تعيين الفلاتر',
                  icon: const Icon(Icons.filter_alt_off_outlined),
                  onPressed: _resetFilters,
                ),
            ],
          ),
          body: Column(
            children: [
              // ==============================================================
              // منطقة البحث والفلاتر العلوية
              // ==============================================================
              Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(isDark ? 30 : 10),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // ========== [1] شريط البحث ==========
                    TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: InputDecoration(
                        hintText: 'ابحث عن عملية...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded, size: 20),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: isDark
                            ? const Color(0xFF0F172A)
                            : const Color(0xFFF3F4F6),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ========== [2] أزرار التصفية بالنوع (الكل | دخل | مصروف) ==========
                    Row(
                      children: [
                        Expanded(
                          child: _buildTypeChip(
                            label: 'الكل',
                            isSelected: _selectedType == _TypeFilter.all,
                            activeColor: primaryColor,
                            isDark: isDark,
                            onTap: () => setState(() {
                              _selectedType = _TypeFilter.all;
                              _selectedCategoryId = 'all';
                            }),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildTypeChip(
                            label: 'دخل',
                            isSelected: _selectedType == _TypeFilter.income,
                            activeColor: AppTheme.incomeColor,
                            isDark: isDark,
                            onTap: () => setState(() {
                              _selectedType = _TypeFilter.income;
                              _selectedCategoryId = 'all';
                            }),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildTypeChip(
                            label: 'مصروف',
                            isSelected: _selectedType == _TypeFilter.expense,
                            activeColor: AppTheme.expenseColor,
                            isDark: isDark,
                            onTap: () => setState(() {
                              _selectedType = _TypeFilter.expense;
                              _selectedCategoryId = 'all';
                            }),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // ========== [3] قائمتا التصفية المنسدلتان (التصنيف + الوقت) ==========
                    Row(
                      children: [
                        Icon(
                          Icons.filter_alt_outlined,
                          size: 20,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                        const SizedBox(width: 8),
                        // قائمة التصنيفات
                        Expanded(
                          child: _buildDropdownContainer(
                            isDark: isDark,
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: safeCategoryValue,
                                isExpanded: true,
                                isDense: true,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                                items: [
                                  const DropdownMenuItem(
                                    value: 'all',
                                    child: Text('كل التصنيفات'),
                                  ),
                                  ..._availableCategories.map(
                                    (cat) => DropdownMenuItem(
                                      value: cat.id,
                                      child: Text(
                                        cat.name,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _selectedCategoryId = val);
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // قائمة الوقت
                        Expanded(
                          child: _buildDropdownContainer(
                            isDark: isDark,
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<_TimeFilter>(
                                value: _selectedTime,
                                isExpanded: true,
                                isDense: true,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                                items: _TimeFilter.values
                                    .map(
                                      (f) => DropdownMenuItem(
                                        value: f,
                                        child: Text(_timeFilterLabel(f)),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _selectedTime = val);
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ==============================================================
              // [4] قائمة العمليات المجمّعة حسب الأيام
              // ==============================================================
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off_rounded,
                                size: 64,
                                color: isDark
                                    ? Colors.white24
                                    : Colors.grey.shade400,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'لا توجد عمليات مطابقة للبحث أو التصفية',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              if (_hasActiveFilters) ...[
                                const SizedBox(height: 12),
                                TextButton.icon(
                                  onPressed: _resetFilters,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('عرض كل العمليات'),
                                ),
                              ],
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 95),
                        itemCount: dayHeaders.length,
                        itemBuilder: (context, groupIndex) {
                          final dayTitle = dayHeaders[groupIndex];
                          final dayTransactions = grouped[dayTitle]!;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // عنوان اليوم (مثال: اليوم - 20 نوفمبر 2026)
                              Padding(
                                padding:
                                    const EdgeInsets.only(top: 8, bottom: 8, right: 4),
                                child: Text(
                                  dayTitle,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? Colors.white70
                                        : const Color(0xFF374151),
                                  ),
                                ),
                              ),

                              // بطاقة تضم عمليات هذا اليوم
                              Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF1E293B)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withAlpha(isDark ? 30 : 10),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: List.generate(
                                    dayTransactions.length,
                                    (index) {
                                      final tx = dayTransactions[index];
                                      final isLast =
                                          index == dayTransactions.length - 1;
                                      return Column(
                                        children: [
                                          _buildTransactionItem(
                                            context: context,
                                            tx: tx,
                                            currency: currency,
                                            isDark: isDark,
                                          ),
                                          if (!isLast)
                                            Divider(
                                              height: 1,
                                              indent: 68,
                                              endIndent: 16,
                                              color: isDark
                                                  ? const Color(0xFF334155)
                                                  : const Color(0xFFF1F5F9),
                                            ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==========================================================================
  // [5] صف العملية الواحدة مع الوقت وقائمة الثلاث نقاط (عرض / تعديل / حذف)
  // ==========================================================================
  Widget _buildTransactionItem({
    required BuildContext context,
    required TransactionModel tx,
    required String currency,
    required bool isDark,
  }) {
    final categoryColor = Color(tx.categoryColorHex);
    final isExpense = tx.isExpense;
    final paymentMethod = AppConstants.getPaymentMethod(tx.paymentMethod);

    return InkWell(
      onTap: () => _showDetailsSheet(context, tx, currency),
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            // أيقونة التصنيف الدائرية
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: categoryColor.withAlpha(isDark ? 55 : 35),
                shape: BoxShape.circle,
              ),
              child: Icon(
                AppConstants.getCategoryIcon(tx.categoryId),
                color: categoryColor,
                size: 21,
              ),
            ),
            const SizedBox(width: 12),

            // اسم العملية + المبلغ + طريقة الدفع إن وجدت
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        '${isExpense ? '-' : '+'} ${Formatters.formatCurrency(tx.amount, symbol: currency)}',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: isExpense
                              ? AppTheme.expenseColor
                              : AppTheme.incomeColor,
                        ),
                      ),
                      if (paymentMethod != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          '• ${paymentMethod.nameAr}',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark ? Colors.white54 : Colors.black45,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // الوقت (مثال: 09:30 م)
            Text(
              Formatters.formatTimeArabic(tx.date),
              style: TextStyle(
                fontSize: 11.5,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            ),

            // قائمة الثلاث نقاط (تعديل / حذف / تفاصيل)
            PopupMenuButton<String>(
              padding: EdgeInsets.zero,
              icon: Icon(
                Icons.more_vert_rounded,
                size: 20,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
              onSelected: (action) {
                if (action == 'details') {
                  _showDetailsSheet(context, tx, currency);
                } else if (action == 'edit') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          AddTransactionScreen(transactionToEdit: tx),
                    ),
                  );
                } else if (action == 'delete') {
                  _confirmDelete(context, tx);
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'details',
                  child: Row(
                    children: [
                      Icon(Icons.visibility_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('عرض التفاصيل'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('تعديل'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('حذف', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeChip({
    required String label,
    required bool isSelected,
    required Color activeColor,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 9),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor
              : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF3F4F6)),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white70 : Colors.black87),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownContainer({
    required bool isDark,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}
