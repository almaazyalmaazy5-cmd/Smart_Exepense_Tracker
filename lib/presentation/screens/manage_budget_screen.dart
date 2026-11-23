import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../providers/budget_provider.dart';
import '../providers/theme_provider.dart';

// ============================================================================
// واجهة إدارة الميزانية الشاملة (ManageBudgetScreen)
// ----------------------------------------------------------------------------
// الميزات المنفذة:
//   [1] تسجيل السقف الكلي مع عملة افتراضية ر.ي وقائمة منسدلة لتغيير العملة بسهم صغير.
//   [2] دعم تسجيل الميزانية الكلية بعملة والتصنيفات بعملة أخرى مع حساب فارق الصرف تلقائياً
//       (أو بدون فارق صرف إذا كانت العملتان متساويتين).
//   [3] سهم رجوع في أعلى الواجهة وزر رجوع الهاتف مع نافذة تأكيد الخروج دون حفظ
//       (نفس معايير التطبيقات العالمية: حفظ / خروج دون حفظ / إلغاء).
// ============================================================================

class ManageBudgetScreen extends StatefulWidget {
  const ManageBudgetScreen({super.key});

  @override
  State<ManageBudgetScreen> createState() => _ManageBudgetScreenState();
}

class _ManageBudgetScreenState extends State<ManageBudgetScreen> {
  late final TextEditingController _monthlyController;
  final Map<String, TextEditingController> _categoryControllers = {};

  late String _selectedBudgetCurrency;
  late String _selectedCategoryCurrency;

  // القيم الأولية لتتبع هل قام المستخدم بأي تعديل
  late final String _initialMonthly;
  late final String _initialBudgetCurrency;
  late final String _initialCategoryCurrency;
  final Map<String, String> _initialCategoryValues = {};

  String? _monthlyError;

  @override
  void initState() {
    super.initState();
    final budgetProv = Provider.of<BudgetProvider>(context, listen: false);

    _selectedBudgetCurrency = budgetProv.currency;
    _selectedCategoryCurrency = budgetProv.categoryCurrency;

    final initialMonthlyVal = budgetProv.monthlyLimit > 0
        ? (budgetProv.monthlyLimit.truncateToDouble() == budgetProv.monthlyLimit
              ? budgetProv.monthlyLimit.toStringAsFixed(0)
              : budgetProv.monthlyLimit.toStringAsFixed(2))
        : '';
    _monthlyController = TextEditingController(text: initialMonthlyVal);
    _initialMonthly = initialMonthlyVal;
    _initialBudgetCurrency = _selectedBudgetCurrency;
    _initialCategoryCurrency = _selectedCategoryCurrency;

    for (final cat in AppConstants.expenseCategories) {
      final lim = budgetProv.getCategoryLimit(cat.id);
      final catVal = lim > 0
          ? (lim.truncateToDouble() == lim
                ? lim.toStringAsFixed(0)
                : lim.toStringAsFixed(2))
          : '';
      _categoryControllers[cat.id] = TextEditingController(text: catVal);
      _initialCategoryValues[cat.id] = catVal;

      _categoryControllers[cat.id]!.addListener(() {
        if (mounted) setState(() {});
      });
    }

    _monthlyController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _monthlyController.dispose();
    for (final c in _categoryControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  /// فحص هل هناك أي تغييرات غير محفوظة قام بها المستخدم
  bool _hasUnsavedChanges() {
    if (_monthlyController.text.trim() != _initialMonthly) return true;
    if (_selectedBudgetCurrency != _initialBudgetCurrency) return true;
    if (_selectedCategoryCurrency != _initialCategoryCurrency) return true;

    for (final entry in _categoryControllers.entries) {
      final initialVal = _initialCategoryValues[entry.key] ?? '';
      if (entry.value.text.trim() != initialVal) return true;
    }
    return false;
  }

  /// إظهار نافذة تأكيد الخروج دون حفظ وفق المعايير العالمية
  Future<String?> _showUnsavedChangesDialog(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withAlpha(35),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: AppTheme.warningColor,
                size: 26,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'تعديلات غير محفوظة',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          'لديك تعديلات لم تقم بحفظها في إعدادات الميزانية. هل تريد حفظ التغييرات الآن أم الخروج وتجاهلها؟',
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(
            children: [
              // إلغاء (البقاء في الواجهة)
              TextButton(
                onPressed: () => Navigator.pop(ctx, 'cancel'),
                child: const Text('إلغاء'),
              ),
              const Spacer(),
              // خروج دون حفظ
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.expenseColor,
                  side: const BorderSide(color: AppTheme.expenseColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.pop(ctx, 'discard'),
                child: const Text('خروج دون حفظ'),
              ),
              const SizedBox(width: 8),
              // حفظ التعديلات
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.pop(ctx, 'save'),
                child: const Text('حفظ'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// معالجة الرجوع (من سهم الـ AppBar أو زر رجوع الهاتف)
  Future<void> _handleBack() async {
    if (!_hasUnsavedChanges()) {
      Navigator.of(context).pop();
      return;
    }

    final action = await _showUnsavedChangesDialog(context);
    if (!mounted) return;

    if (action == 'save') {
      await _saveAll();
    } else if (action == 'discard') {
      Navigator.of(context).pop();
    }
    // إذا كان 'cancel' يبقى في الشاشة
  }

  /// إظهار قائمة منسدلة منبثقة لاختيار العملة
  Future<void> _showCurrencyMenu({
    required BuildContext context,
    required String currentCurrency,
    required ValueChanged<String> onSelected,
  }) async {
    final primaryColor = Provider.of<ThemeProvider>(
      context,
      listen: false,
    ).selectedColor.primary;

    final selected = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 50,
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha(110),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                'اختر العملة',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            const Divider(),
            ...AppConstants.currencies.map((c) {
              final isCurrent = c['symbol'] == currentCurrency;
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: isCurrent
                      ? primaryColor
                      : Colors.grey.withAlpha(40),
                  child: Text(
                    c['symbol']!,
                    style: TextStyle(
                      color: isCurrent ? Colors.white : null,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                title: Text(
                  c['name']!,
                  style: TextStyle(
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                trailing: Text(
                  c['code']!,
                  style: const TextStyle(color: Colors.grey),
                ),
                onTap: () => Navigator.pop(ctx, c['symbol']),
              );
            }),
          ],
        ),
      ),
    );

    if (selected != null && mounted) {
      onSelected(selected);
    }
  }

  /// تغيير عملة الميزانية الكلية وتحديث سعر الصرف تلقائياً
  void _onBudgetCurrencyChanged(String newCurrency) {
    setState(() {
      _selectedBudgetCurrency = newCurrency;
    });
  }

  /// تغيير عملة التصنيفات وتحديث سعر الصرف تلقائياً
  void _onCategoryCurrencyChanged(String newCurrency) {
    setState(() {
      _selectedCategoryCurrency = newCurrency;
    });
  }

  /// حفظ كافة التعديلات في مزوّد الميزانية وقاعدة البيانات المحلية
  Future<void> _saveAll() async {
    setState(() {
      _monthlyError = null;
    });

    final monthlyText = _monthlyController.text.trim();
    final monthly = double.tryParse(monthlyText);
    if (monthly == null || monthly <= 0) {
      setState(() {
        _monthlyError = 'الرجاء إدخال مبلغ صحيح أكبر من الصفر للميزانية الكلية';
      });
      return;
    }

    final double rate = _selectedBudgetCurrency == _selectedCategoryCurrency
        ? 1.0
        : AppConstants.getDefaultExchangeRate(
            _selectedBudgetCurrency,
            _selectedCategoryCurrency,
          );

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
      currency: _selectedBudgetCurrency,
      categoryCurrency: _selectedCategoryCurrency,
      exchangeRate: rate,
      categoryLimits: updatedCats,
    );

    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم حفظ إعدادات الميزانية بنجاح ✅'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = Provider.of<ThemeProvider>(
      context,
    ).selectedColor.primary;

    final areCurrenciesEqual =
        _selectedBudgetCurrency == _selectedCategoryCurrency;
    final rawMonthly = double.tryParse(_monthlyController.text.trim()) ?? 0.0;
    final double rawRate = areCurrenciesEqual
        ? 1.0
        : AppConstants.getDefaultExchangeRate(
            _selectedBudgetCurrency,
            _selectedCategoryCurrency,
          );

    // الميزانية الكلية محسوبة بعملة التصنيفات
    final double convertedMonthlyToCategories =
        areCurrenciesEqual ? rawMonthly : (rawMonthly * rawRate);
    // مجموع ما خصصه المستخدم للتصنيفات
    double totalAllocatedToCats = 0.0;
    for (final c in _categoryControllers.values) {
      final val = double.tryParse(c.text.trim());
      if (val != null && val > 0) {
        totalAllocatedToCats += val;
      }
    }

    final double remainingToAllocate =
        convertedMonthlyToCategories - totalAllocatedToCats;
    final bool isOverAllocated =
        convertedMonthlyToCategories > 0 && remainingToAllocate < 0;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إدارة الميزانية'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: 'رجوع',
            onPressed: _handleBack,
          ),
          actions: [
            TextButton.icon(
              onPressed: _saveAll,
              icon: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 20,
              ),
              label: const Text(
                'حفظ',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            // ================================================================
            // [1] بطاقة السقف الكلي واختيار العملة بسهم منسدل
            // ================================================================
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(isDark ? 35 : 10),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: primaryColor.withAlpha(30),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.account_balance_wallet_rounded,
                          color: primaryColor,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'الميزانية الكلية للشهر',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // زر السهم المنسدل لاختيار عملة الميزانية الكلية
                      _buildCurrencyDropdownSelector(
                        label: 'عملة الميزانية',
                        currencySymbol: _selectedBudgetCurrency,
                        primaryColor: primaryColor,
                        onTap: () => _showCurrencyMenu(
                          context: context,
                          currentCurrency: _selectedBudgetCurrency,
                          onSelected: _onBudgetCurrencyChanged,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // حقل إدخال المبلغ الكلي
                  TextField(
                    controller: _monthlyController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                    decoration: InputDecoration(
                      labelText: 'المبلغ الإجمالي',
                      hintText: 'مثال: 250000',
                      prefixIcon: const Icon(Icons.attach_money_rounded),
                      suffixIcon: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _selectedBudgetCurrency,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                            const SizedBox(width: 2),
                            InkWell(
                              onTap: () => _showCurrencyMenu(
                                context: context,
                                currentCurrency: _selectedBudgetCurrency,
                                onSelected: _onBudgetCurrencyChanged,
                              ),
                              child: const Icon(
                                Icons.arrow_drop_down_rounded,
                                size: 24,
                              ),
                            ),
                          ],
                        ),
                      ),
                      errorText: _monthlyError,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ================================================================
            // [2] قسم عملة التصنيفات + حساب فارق الصرف (إذا اختلفتا)
            // ================================================================
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(isDark ? 35 : 10),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.tune_rounded,
                            color: primaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'عملة ميزانيات التصنيفات',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      // سهم منسدل لاختيار عملة التصنيفات
                      _buildCurrencyDropdownSelector(
                        label: 'عملة الفئات',
                        currencySymbol: _selectedCategoryCurrency,
                        primaryColor: primaryColor,
                        onTap: () => _showCurrencyMenu(
                          context: context,
                          currentCurrency: _selectedCategoryCurrency,
                          onSelected: _onCategoryCurrencyChanged,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // إذا كانت العملتان متساويتين: لا يتم احتساب أي فارق صرف
                  if (areCurrenciesEqual) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withAlpha(isDark ? 40 : 25),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.withAlpha(100)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_outline_rounded,
                            color: Colors.green,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'العملتان متطابقتان ($_selectedBudgetCurrency)؛ يتم احتساب الميزانية بنسبة 1:1 دون أي فارق صرف.',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: isDark
                                    ? Colors.green.shade200
                                    : Colors.green.shade900,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // إذا اختلفت العملتان: حساب فارق الصرف تلقائياً
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.warningColor.withAlpha(
                          isDark ? 40 : 22,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppTheme.warningColor.withAlpha(110),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.currency_exchange_rounded,
                                color: AppTheme.warningColor,
                                size: 21,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'حساب فارق الصرف التلقائي',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.warningColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'الميزانية الكلية مسجلة بـ ($_selectedBudgetCurrency) والتصنيفات بـ ($_selectedCategoryCurrency). تم احتساب سعر الصرف تلقائياً:',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // بطاقة عرض سعر الصرف المحسوب تلقائياً
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.black26
                                  : Colors.white.withAlpha(200),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.warningColor.withAlpha(80),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.auto_mode_rounded,
                                  size: 20,
                                  color: AppTheme.warningColor,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '1 $_selectedBudgetCurrency = ${Formatters.formatNumberOnly(rawRate)} $_selectedCategoryCurrency',
                                  style: const TextStyle(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.warningColor.withAlpha(30),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'محسوب تلقائياً',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.warningColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),

                          // قيمة التحويل الإجمالية الناتجة عن فارق الصرف
                          if (rawMonthly > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.black26
                                    : Colors.white.withAlpha(180),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'السقف الكلي يعادل: ${Formatters.formatCurrency(convertedMonthlyToCategories, symbol: _selectedCategoryCurrency)}',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],

                  // ملخص التوزيع والمتبقي
                  if (rawMonthly > 0) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF0F172A)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'المخصص للتصنيفات:',
                                style: TextStyle(fontSize: 12.5),
                              ),
                              Text(
                                Formatters.formatCurrency(
                                  totalAllocatedToCats,
                                  symbol: _selectedCategoryCurrency,
                                ),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                isOverAllocated
                                    ? 'تجاوز في التوزيع:'
                                    : 'المتبقي للتوزيع:',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: isOverAllocated
                                      ? AppTheme.expenseColor
                                      : null,
                                  fontWeight: isOverAllocated
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              Text(
                                Formatters.formatCurrency(
                                  remainingToAllocate.abs(),
                                  symbol: _selectedCategoryCurrency,
                                ),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isOverAllocated
                                      ? AppTheme.expenseColor
                                      : Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ================================================================
            // [3] تقسيم الميزانية على التصنيفات (اختياري)
            // ================================================================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'تقسيم الميزانية على التصنيفات',
                  style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold),
                ),
                Text(
                  'العملة: $_selectedCategoryCurrency',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : Colors.black54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            ...AppConstants.expenseCategories.map((cat) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(isDark ? 25 : 6),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: cat.color.withAlpha(isDark ? 55 : 30),
                        child: Icon(cat.icon, color: cat.color, size: 20),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 95,
                        child: Text(
                          cat.name,
                          style: const TextStyle(
                            fontSize: 14,
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
                            suffixText: _selectedCategoryCurrency,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 20),

            // ================================================================
            // [4] زر الحفظ العريض
            // ================================================================
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _saveAll,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 3,
                ),
                icon: const Icon(Icons.save_rounded),
                label: const Text(
                  'حفظ إعدادات الميزانية',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// أداة لعرض العملة المختارة مع سهم منسدل صغير بجانبها
  Widget _buildCurrencyDropdownSelector({
    required String label,
    required String currencySymbol,
    required Color primaryColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: primaryColor.withAlpha(22),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: primaryColor.withAlpha(80)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              currencySymbol,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down_rounded, size: 22, color: primaryColor),
          ],
        ),
      ),
    );
  }
}
