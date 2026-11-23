import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/category_model.dart';
import '../providers/budget_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/theme_provider.dart';
import 'analytics_screen.dart';
import 'manage_budget_screen.dart';

// ============================================================================
// الواجهة الرابعة: الميزانية الشهرية (BudgetScreen)
// ----------------------------------------------------------------------------
// مطابقة للتصميم وتتكوّن من 3 أقسام رئيسية واضحة:
//   [1] بطاقة الميزانية الكلية المحددة مع عملتها وفارق الصرف + شريط التقدم + المتبقي
//   [2] تفاصيل الميزانية حسب التصنيف (مع عملة التصنيفات وشريط التقدم وتنبيه 80%)
//   [3] زر "إدارة الميزانية" في الأسفل لفتح واجهة إدارة الميزانية الشاملة
// ============================================================================

class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

  /// فتح واجهة إدارة الميزانية (الكلية + العملات + فارق الصرف + الفئات)
  void _openManageBudgetSheet(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ManageBudgetScreen()),
    );
  }

  /// فتح حوار سريع لتعديل ميزانية تصنيف واحد عند النقر على بطاقته
  void _openSingleCategoryDialog(
    BuildContext context,
    CategoryModel category,
    double currentLimit,
  ) {
    showDialog(
      context: context,
      builder: (_) => _SingleCategoryBudgetDialog(
        category: category,
        currentLimit: currentLimit,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Provider.of<ThemeProvider>(context).selectedColor.primary;

    return Consumer2<BudgetProvider, ExpenseProvider>(
      builder: (context, budgetProv, expenseProv, child) {
        final limit = budgetProv.monthlyLimit;
        final budgetCurrency = budgetProv.currency;
        final categoryCurrency = budgetProv.categoryCurrency;
        final expenseCurrency = expenseProv.currencySymbol;

        final currentSpent = expenseProv.currentMonthExpense;
        final spentByCategory = expenseProv.currentMonthExpenseByCategory;

        final usageRatio = budgetProv.calculateUsagePercentage(
          currentSpent,
          expenseCurrency: expenseCurrency,
        );
        final effectiveLimit = budgetProv.effectiveTotalLimit(expenseCurrency);
        final rawPercent =
            effectiveLimit > 0 ? (currentSpent / effectiveLimit) * 100 : 0.0;
        final remaining = budgetProv.remainingBudget(
          currentSpent,
          expenseCurrency: expenseCurrency,
        );
        final isOver = budgetProv.isOverBudget(
          currentSpent,
          expenseCurrency: expenseCurrency,
        );
        final isNear = budgetProv.isNearLimit(
          currentSpent,
          expenseCurrency: expenseCurrency,
        );

        final Color mainBarColor = isOver
            ? AppTheme.expenseColor
            : (isNear ? AppTheme.warningColor : primaryColor);

        // جمع التنبيهات النشطة على مستوى التصنيفات (≥ 80%)
        final List<String> categoryAlerts = [];
        for (final cat in AppConstants.expenseCategories) {
          final catSpent = spentByCategory[cat.id] ?? 0.0;
          if (budgetProv.isCategoryOverBudget(cat.id, catSpent)) {
            categoryAlerts.add('تجاوزت ميزانية "${cat.name}"!');
          } else if (budgetProv.isCategoryNearLimit(cat.id, catSpent)) {
            categoryAlerts.add('اقتربت من 80% في ميزانية "${cat.name}".');
          }
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('الميزانية الشهرية'),
            actions: [
              IconButton(
                tooltip: 'الإحصائيات',
                icon: const Icon(Icons.bar_chart_rounded),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
                  );
                },
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                  children: [
                    // ========================================================
                    // [1] بطاقة الميزانية الشهرية الكلية
                    // ========================================================
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(isDark ? 35 : 12),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // صف العنوان + أيقونة الهدف (Target)
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppTheme.expenseColor.withAlpha(28),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.track_changes_rounded,
                                  color: AppTheme.expenseColor,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'الميزانية المحددة',
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        color: isDark
                                            ? Colors.white60
                                            : Colors.black54,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      Formatters.formatCurrency(
                                        limit,
                                        symbol: budgetCurrency,
                                      ),
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    // إذا كانت هناك عملتان مختلفتان (حساب فارق الصرف)
                                    if (!budgetProv.areCurrenciesEqual) ...[
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: primaryColor.withAlpha(25),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'تعادل: ${Formatters.formatCurrency(budgetProv.monthlyLimitInCategoriesCurrency, symbol: categoryCurrency)} • (1 $budgetCurrency = ${Formatters.formatNumberOnly(budgetProv.exchangeRate)} $categoryCurrency)',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600,
                                            color: primaryColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),

                          // شريط التقدم الكلي
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: usageRatio,
                              minHeight: 12,
                              backgroundColor: isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFE5E7EB),
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(mainBarColor),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // المتبقي + نسبة الإنفاق
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                isOver
                                    ? 'العجز: ${Formatters.formatCurrency(remaining.abs(), symbol: expenseCurrency)}'
                                    : 'المتبقي: ${Formatters.formatCurrency(remaining, symbol: expenseCurrency)}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isOver
                                      ? AppTheme.expenseColor
                                      : (isDark ? Colors.white70 : Colors.black87),
                                ),
                              ),
                              Text(
                                'تم إنفاق ${rawPercent.toStringAsFixed(0)}%',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: mainBarColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // شريط التنبيه الذكي (يظهر عند تجاوز 80% كلياً أو في أي تصنيف)
                    if (isOver || isNear || categoryAlerts.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: (isOver
                                  ? AppTheme.expenseColor
                                  : AppTheme.warningColor)
                              .withAlpha(isDark ? 45 : 26),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: (isOver
                                    ? AppTheme.expenseColor
                                    : AppTheme.warningColor)
                                .withAlpha(110),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              isOver
                                  ? Icons.warning_amber_rounded
                                  : Icons.notifications_active_outlined,
                              color: isOver
                                  ? AppTheme.expenseColor
                                  : AppTheme.warningColor,
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                isOver
                                    ? 'تنبيه: لقد تجاوزت سقف الميزانية الشهرية المحددة!'
                                    : (isNear
                                        ? 'تحذير: استهلكت أكثر من 80% من ميزانيتك الشهرية.'
                                        : categoryAlerts.join(' • ')),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isOver
                                      ? AppTheme.expenseColor
                                      : (isDark
                                          ? Colors.amber.shade200
                                          : const Color(0xFFB45309)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 22),

                    // ========================================================
                    // [2] تفاصيل الميزانية حسب التصنيف
                    // ========================================================
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'تفاصيل الميزانية حسب التصنيف',
                          style: TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'العملة: $categoryCurrency',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white54 : Colors.black45,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    ...AppConstants.expenseCategories.map((cat) {
                      final catLimit = budgetProv.getCategoryLimit(cat.id);
                      final catSpent = spentByCategory[cat.id] ?? 0.0;
                      final ratio = budgetProv.categoryUsageRatio(cat.id, catSpent);
                      final catPercent =
                          catLimit > 0 ? (catSpent / catLimit) * 100 : 0.0;
                      final catOver =
                          budgetProv.isCategoryOverBudget(cat.id, catSpent);
                      final catNear =
                          budgetProv.isCategoryNearLimit(cat.id, catSpent);

                      final Color progressColor = catOver
                          ? AppTheme.expenseColor
                          : (catNear ? AppTheme.warningColor : cat.color);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () =>
                              _openSingleCategoryDialog(context, cat, catLimit),
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1E293B)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: (catOver || catNear)
                                  ? Border.all(
                                      color: progressColor.withAlpha(130),
                                      width: 1.3,
                                    )
                                  : null,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(isDark ? 30 : 8),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    // أيقونة التصنيف
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: cat.color
                                            .withAlpha(isDark ? 55 : 32),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        cat.icon,
                                        color: cat.color,
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 12),

                                    // اسم التصنيف والميزانية المخصصة له
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                cat.name,
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              if (catOver || catNear) ...[
                                                const SizedBox(width: 6),
                                                Icon(
                                                  Icons.warning_rounded,
                                                  size: 16,
                                                  color: progressColor,
                                                ),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            catLimit > 0
                                                ? 'المخصص: ${Formatters.formatCurrency(catLimit, symbol: categoryCurrency)}'
                                                : 'لم يتم تحديد ميزانية (اضغط للتحديد)',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isDark
                                                  ? Colors.white54
                                                  : Colors.black54,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // المبلغ المصروف والنسبة المئوية
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          Formatters.formatCurrency(
                                            catSpent,
                                            symbol: expenseCurrency,
                                          ),
                                          style: TextStyle(
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.w800,
                                            color: catOver
                                                ? AppTheme.expenseColor
                                                : null,
                                          ),
                                        ),
                                        if (catLimit > 0)
                                          Text(
                                            '${catPercent.toStringAsFixed(0)}%',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: progressColor,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                                if (catLimit > 0) ...[
                                  const SizedBox(height: 10),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: LinearProgressIndicator(
                                      value: ratio,
                                      minHeight: 8,
                                      backgroundColor: isDark
                                          ? const Color(0xFF334155)
                                          : const Color(0xFFE5E7EB),
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        progressColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),

              // ==============================================================
              // [3] زر "إدارة الميزانية" العريض في الأسفل
              // ==============================================================
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () => _openManageBudgetSheet(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.settings_outlined),
                      label: const Text(
                        'إدارة الميزانية',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================================
// نافذة تعديل ميزانية تصنيف واحد بسرعة
// ============================================================================
class _SingleCategoryBudgetDialog extends StatefulWidget {
  final CategoryModel category;
  final double currentLimit;

  const _SingleCategoryBudgetDialog({
    required this.category,
    required this.currentLimit,
  });

  @override
  State<_SingleCategoryBudgetDialog> createState() =>
      _SingleCategoryBudgetDialogState();
}

class _SingleCategoryBudgetDialogState
    extends State<_SingleCategoryBudgetDialog> {
  late final TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.currentLimit > 0
          ? (widget.currentLimit.truncateToDouble() == widget.currentLimit
              ? widget.currentLimit.toStringAsFixed(0)
              : widget.currentLimit.toStringAsFixed(2))
          : '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final text = _controller.text.trim();
    final value = text.isEmpty ? 0.0 : double.tryParse(text);
    if (value == null || value < 0) {
      setState(() => _errorText = 'الرجاء إدخال رقم صالح (أو 0 للإلغاء)');
      return;
    }

    await Provider.of<BudgetProvider>(context, listen: false)
        .updateCategoryLimit(widget.category.id, value);
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تم تحديث ميزانية "${widget.category.name}" ✅')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoryCurrency =
        Provider.of<BudgetProvider>(context).categoryCurrency;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(widget.category.icon, color: widget.category.color),
          const SizedBox(width: 8),
          Text('ميزانية ${widget.category.name}'),
        ],
      ),
      content: TextField(
        controller: _controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        autofocus: true,
        decoration: InputDecoration(
          hintText: 'مثال: 10000 (أو 0 للإزالة)',
          suffixText: categoryCurrency,
          errorText: _errorText,
          prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text('حفظ'),
        ),
      ],
    );
  }
}

