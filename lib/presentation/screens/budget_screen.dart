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

// ============================================================================
// الواجهة الرابعة: الميزانية الشهرية (BudgetScreen)
// ----------------------------------------------------------------------------
// مطابقة للتصميم في الصورة وتتكوّن من 3 أقسام رئيسية واضحة:
//   [1] بطاقة الميزانية الكلية المحددة + شريط التقدم + المتبقي ونسبة الإنفاق
//   [2] تفاصيل الميزانية حسب التصنيف (مع شريط تقدم وتنبيه 80% لكل تصنيف)
//   [3] زر "إدارة الميزانية" في الأسفل لتعديل الميزانية الكلية وميزانيات الفئات
// ============================================================================

class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

  /// فتح نافذة إدارة الميزانية (الكلية + جميع التصنيفات الفرعية)
  void _openManageBudgetSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _ManageBudgetSheet(),
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
        final currentSpent = expenseProv.currentMonthExpense;
        final spentByCategory = expenseProv.currentMonthExpenseByCategory;
        final currency = expenseProv.currencySymbol;

        final usageRatio = budgetProv.calculateUsagePercentage(currentSpent);
        final rawPercent = limit > 0 ? (currentSpent / limit) * 100 : 0.0;
        final remaining = budgetProv.remainingBudget(currentSpent);
        final isOver = budgetProv.isOverBudget(currentSpent);
        final isNear = budgetProv.isNearLimit(currentSpent);

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
                                        symbol: currency,
                                      ),
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
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
                                    ? 'العجز: ${Formatters.formatCurrency(remaining.abs(), symbol: currency)}'
                                    : 'المتبقي: ${Formatters.formatCurrency(remaining, symbol: currency)}',
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
                          'اضغط لتعديل الفئة',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark ? Colors.white54 : Colors.black45,
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
                                                ? 'المخصص: ${Formatters.formatCurrency(catLimit, symbol: currency)}'
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
                                            symbol: currency,
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
              // [3] زر "إدارة الميزانية" العريض في الأسفل (مطابق للصورة)
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
// نافذة تعديل ميزانية تصنيف واحد بسرعة (مع dispose صحيح للـ Controller)
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
          ? widget.currentLimit.toStringAsFixed(0)
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

// ============================================================================
// نافذة "إدارة الميزانية" الشاملة (الميزانية الكلية + جميع التصنيفات)
// ============================================================================
class _ManageBudgetSheet extends StatefulWidget {
  const _ManageBudgetSheet();

  @override
  State<_ManageBudgetSheet> createState() => _ManageBudgetSheetState();
}

class _ManageBudgetSheetState extends State<_ManageBudgetSheet> {
  late final TextEditingController _monthlyController;
  final Map<String, TextEditingController> _categoryControllers = {};
  String? _errorText;

  @override
  void initState() {
    super.initState();
    final budgetProv = Provider.of<BudgetProvider>(context, listen: false);
    _monthlyController = TextEditingController(
      text: budgetProv.monthlyLimit.toStringAsFixed(0),
    );
    for (final cat in AppConstants.expenseCategories) {
      final lim = budgetProv.getCategoryLimit(cat.id);
      _categoryControllers[cat.id] = TextEditingController(
        text: lim > 0 ? lim.toStringAsFixed(0) : '',
      );
    }
  }

  @override
  void dispose() {
    _monthlyController.dispose();
    for (final c in _categoryControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _saveAll() async {
    final monthly = double.tryParse(_monthlyController.text.trim());
    if (monthly == null || monthly <= 0) {
      setState(() => _errorText = 'أدخل قيمة صحيحة أكبر من الصفر للميزانية الشهرية');
      return;
    }

    final Map<String, double> updatedCats = {};
    for (final entry in _categoryControllers.entries) {
      final raw = entry.value.text.trim();
      if (raw.isEmpty) continue;
      final parsed = double.tryParse(raw);
      if (parsed != null && parsed > 0) {
        updatedCats[entry.key] = parsed;
      }
    }

    await Provider.of<BudgetProvider>(context, listen: false).updateAllBudgets(
      monthlyLimit: monthly,
      categoryLimits: updatedCats,
    );

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم حفظ إعدادات الميزانية بنجاح ✅')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = Provider.of<ExpenseProvider>(context).currencySymbol;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 14, 20, bottomInset + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha(110),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'إدارة الميزانية الشهرية',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),

            // الميزانية الكلية
            const Text(
              'السقف الشهري الكلي',
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _monthlyController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: 'مثال: 50000',
                suffixText: currency,
                errorText: _errorText,
                prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
              ),
            ),
            const SizedBox(height: 18),

            // ميزانيات الفئات
            const Text(
              'تقسيم الميزانية على التصنيفات (اختياري)',
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ...AppConstants.expenseCategories.map((cat) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Icon(cat.icon, color: cat.color, size: 22),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 90,
                      child: Text(
                        cat.name,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _categoryControllers[cat.id],
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          hintText: 'بدون حد',
                          isDense: true,
                          suffixText: currency,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _saveAll,
                icon: const Icon(Icons.save_outlined),
                label: const Text('حفظ الميزانية'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
