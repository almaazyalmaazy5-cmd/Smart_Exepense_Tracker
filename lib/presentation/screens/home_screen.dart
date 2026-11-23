import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/transaction_model.dart';
import '../providers/budget_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/theme_provider.dart';
import 'add_transaction_screen.dart';
import 'budget_screen.dart';

// ============================================================================
// الواجهة الأولى: الصفحة الرئيسية (Dashboard / HomeScreen)
// ----------------------------------------------------------------------------
// تتكون هذه الشاشة من 4 أقسام واضحة مطابقة للتصميم:
//   [1] الهيدر العلوي بلون التطبيق + أيقونة الإعدادات وأيقونة التنبيهات الذكية
//   [2] البطاقات الثلاث المتجاورة (إجمالي الرصيد | إجمالي الدخل | إجمالي المصروفات)
//   [3] بطاقة الميزانية الشهرية مع شريط التقدم (بالضغط عليها تفتح شاشة الميزانية)
//   [4] قسم آخر العمليات مع زر "عرض الكل"
// ============================================================================

class HomeScreen extends StatelessWidget {
  /// دالة اختيارية للانتقال إلى تبويب "العمليات" عند الضغط على "عرض الكل"
  final VoidCallback? onViewAllTransactions;

  /// دالة اختيارية للانتقال إلى تبويب "الإعدادات" عند الضغط على أيقونة الترس
  final VoidCallback? onOpenSettings;

  const HomeScreen({
    super.key,
    this.onViewAllTransactions,
    this.onOpenSettings,
  });

  /// عرض نافذة التنبيهات والنصائح الذكية عند الضغط على أيقونة الجرس
  void _showSmartInsightsDialog(BuildContext context, List<String> insights) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.auto_awesome, color: primaryColor),
            const SizedBox(width: 8),
            const Text('التحليل والتنبيهات الذكية', style: TextStyle(fontSize: 17)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: insights.map((tip) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle, size: 18, color: primaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tip,
                      style: const TextStyle(fontSize: 13.5, height: 1.45),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  /// عرض تفاصيل عملية معينة (بما في ذلك الملاحظات) عند النقر عليها
  void _showTransactionDetails(
    BuildContext context,
    TransactionModel tx,
    String currency,
  ) {
    final isExpense = tx.isExpense;
    final categoryColor = Color(tx.categoryColorHex);

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
                    size: 24,
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
                  '${isExpense ? '-' : '+'}${Formatters.formatCurrency(tx.amount, symbol: currency)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: isExpense ? AppTheme.expenseColor : AppTheme.incomeColor,
                  ),
                ),
              ],
            ),
            if (tx.paymentMethod != null) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(
                    AppConstants.getPaymentMethod(tx.paymentMethod)?.icon ??
                        Icons.payments_outlined,
                    size: 18,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'طريقة الدفع: ${AppConstants.getPaymentMethod(tx.paymentMethod)?.nameAr ?? tx.paymentMethod}',
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
            if (tx.notes != null && tx.notes!.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Divider(),
              const SizedBox(height: 8),
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
                // زر تعديل العملية
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.edit_outlined, size: 19),
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
                // زر حذف العملية
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.delete_outline, size: 19),
                    label: const Text('حذف'),
                    onPressed: () {
                      Navigator.pop(ctx);
                      Provider.of<ExpenseProvider>(context, listen: false)
                          .deleteTransaction(tx.id);
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorOption = Provider.of<ThemeProvider>(context).selectedColor;

    return Consumer2<ExpenseProvider, BudgetProvider>(
      builder: (context, expenseProv, budgetProv, child) {
        if (expenseProv.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final currency = expenseProv.currencySymbol;
        final recentList = expenseProv.recentTransactions;

        // حسابات الميزانية الشهرية للبطاقة مع مراعاة العملة وفارق الصرف
        final monthlyLimit = budgetProv.monthlyLimit;
        final currentMonthSpent = expenseProv.currentMonthExpense;
        final remaining = budgetProv.remainingBudget(
          currentMonthSpent,
          expenseCurrency: currency,
        );
        final usageRatio = budgetProv.calculateUsagePercentage(
          currentMonthSpent,
          expenseCurrency: currency,
        );
        final usagePercentText = '${(usageRatio * 100).toStringAsFixed(0)}%';
        final isOverBudget = budgetProv.isOverBudget(
          currentMonthSpent,
          expenseCurrency: currency,
        );
        final isNearBudget = budgetProv.isNearLimit(
          currentMonthSpent,
          expenseCurrency: currency,
        );

        final Color budgetBarColor = isOverBudget
            ? AppTheme.expenseColor
            : (isNearBudget ? AppTheme.warningColor : colorOption.primary);

        return Scaffold(
          body: RefreshIndicator(
            onRefresh: () async {
              await expenseProv.loadData();
              await budgetProv.loadBudget();
            },
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // ==========================================================
                // [1] الهيدر العلوي الأخضر + البطاقات الثلاث المتداخلة
                // ==========================================================
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // خلفية الهيدر العلوي بلون التطبيق المختار
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.fromLTRB(
                        18,
                        MediaQuery.of(context).padding.top + 12,
                        18,
                        72, // مساحة إضافية لتداخل البطاقات الثلاث
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            colorOption.primaryDark,
                            colorOption.primary,
                            colorOption.primaryLight,
                          ],
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                        ),
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(28),
                        ),
                      ),
                      child: Column(
                        children: [
                          // صف الأيقونات العلوي (تغيير الألوان والمظهر + التنبيهات)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // زر التنبيهات والتحليل الذكي
                              IconButton(
                                tooltip: 'التنبيهات الذكية',
                                onPressed: () => _showSmartInsightsDialog(
                                  context,
                                  expenseProv.generateSmartInsights(
                                    monthlyBudgetLimit:
                                        budgetProv.monthlyLimitIn(currency),
                                  ),
                                ),
                                icon: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    const Icon(
                                      Icons.notifications_none_rounded,
                                      color: Colors.white,
                                      size: 26,
                                    ),
                                    if (isOverBudget || isNearBudget)
                                      Positioned(
                                        top: -1,
                                        right: -1,
                                        child: Container(
                                          width: 10,
                                          height: 10,
                                          decoration: const BoxDecoration(
                                            color: Colors.redAccent,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              // زر الانتقال إلى شاشة الإعدادات (مطابق للصورة)
                              IconButton(
                                tooltip: 'الإعدادات',
                                onPressed: onOpenSettings,
                                icon: const Icon(
                                  Icons.settings_outlined,
                                  color: Colors.white,
                                  size: 25,
                                ),
                              ),
                            ],
                          ),

                          // شعار واسم التطبيق والسطر التعريفي
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(32),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.bar_chart_rounded,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            AppConstants.appName,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            AppConstants.appTagline,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ========================================================
                    // [2] البطاقات الثلاث المتداخلة (الرصيد | الدخل | المصروفات)
                    // ========================================================
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: -48,
                      child: Row(
                        children: [
                          // بطاقة 1: إجمالي الرصيد
                          Expanded(
                            child: _buildSummaryMiniCard(
                              title: 'إجمالي الرصيد',
                              amount: expenseProv.currentBalance,
                              currency: currency,
                              icon: Icons.account_balance_wallet_rounded,
                              iconColor: colorOption.primary,
                              backgroundColor: isDark
                                  ? const Color(0xFF1A2E26)
                                  : const Color(0xFFE6F4EA),
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(width: 10),
                          // بطاقة 2: إجمالي الدخل
                          Expanded(
                            child: _buildSummaryMiniCard(
                              title: 'إجمالي الدخل',
                              amount: expenseProv.totalIncome,
                              currency: currency,
                              icon: Icons.arrow_upward_rounded,
                              iconColor: AppTheme.incomeColor,
                              backgroundColor: isDark
                                  ? const Color(0xFF172D23)
                                  : const Color(0xFFECFDF5),
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(width: 10),
                          // بطاقة 3: إجمالي المصروفات
                          Expanded(
                            child: _buildSummaryMiniCard(
                              title: 'إجمالي المصروفات',
                              amount: expenseProv.totalExpense,
                              currency: currency,
                              icon: Icons.arrow_downward_rounded,
                              iconColor: AppTheme.expenseColor,
                              backgroundColor: isDark
                                  ? const Color(0xFF331D22)
                                  : const Color(0xFFFEECEC),
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // مسافة تعويضية لارتفاع البطاقات المتداخلة
                const SizedBox(height: 64),

                // ==========================================================
                // [3] بطاقة الميزانية الشهرية (تفتح شاشة الميزانية عند النقر)
                // ==========================================================
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const BudgetScreen()),
                      );
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(isDark ? 35 : 12),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // صف العنوان + أيقونة التقويم
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_month_rounded,
                                    color: colorOption.primary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'الميزانية الشهرية',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    Formatters.formatCurrency(
                                      monthlyLimit,
                                      symbol: budgetProv.currency,
                                    ),
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: colorOption.primary,
                                    ),
                                  ),
                                  if (!budgetProv.areCurrenciesEqual)
                                    Text(
                                      '≈ ${Formatters.formatCurrency(budgetProv.monthlyLimitInCategoriesCurrency, symbol: budgetProv.categoryCurrency)}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? Colors.white60
                                            : Colors.black54,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // صف المصروف والمتبقي
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'المصروف: ${Formatters.formatCurrency(currentMonthSpent, symbol: currency)}',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: isDark ? Colors.white70 : Colors.black54,
                                ),
                              ),
                              Text(
                                isOverBudget
                                    ? 'العجز: ${Formatters.formatCurrency(remaining.abs(), symbol: currency)}'
                                    : 'المتبقي: ${Formatters.formatCurrency(remaining, symbol: currency)}',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: isOverBudget
                                      ? AppTheme.expenseColor
                                      : (isDark ? Colors.white70 : Colors.black87),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // شريط التقدم + النسبة المئوية
                          Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: LinearProgressIndicator(
                                    value: usageRatio,
                                    minHeight: 10,
                                    backgroundColor: isDark
                                        ? const Color(0xFF334155)
                                        : const Color(0xFFE5E7EB),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      budgetBarColor,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                usagePercentText,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: budgetBarColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 22),

                // ==========================================================
                // [4] قسم آخر العمليات + زر "عرض الكل"
                // ==========================================================
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'آخر العمليات',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: onViewAllTransactions,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        icon: const Text(
                          'عرض الكل',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        label: const Icon(Icons.arrow_forward_rounded, size: 16),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),

                // قائمة آخر 5 معاملات أو حالة فارغة
                if (recentList.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 32,
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 56,
                          color: isDark ? Colors.white24 : Colors.grey.shade400,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'لا توجد عمليات مسجلة بعد',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'اضغط على زر (+) في الأسفل لتسجيل أول عملية',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: isDark ? Colors.white54 : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
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
                        children: List.generate(recentList.length, (index) {
                          final tx = recentList[index];
                          final isLast = index == recentList.length - 1;
                          return Column(
                            children: [
                              _buildRecentTransactionRow(
                                context: context,
                                tx: tx,
                                currency: currency,
                                isDark: isDark,
                              ),
                              if (!isLast)
                                Divider(
                                  height: 1,
                                  indent: 70,
                                  endIndent: 16,
                                  color: isDark
                                      ? const Color(0xFF334155)
                                      : const Color(0xFFF1F5F9),
                                ),
                            ],
                          );
                        }),
                      ),
                    ),
                  ),

                // مسافة سفلية لتجنب تداخل المحتوى مع الشريط السفلي وزر (+)
                const SizedBox(height: 95),
              ],
            ),
          ),
        );
      },
    );
  }

  /// عنصر البطاقة المصغّرة للرصيد / الدخل / المصروفات
  Widget _buildSummaryMiniCard({
    required String title,
    required double amount,
    required String currency,
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.white,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 45 : 18),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 8),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              Formatters.formatNumberOnly(amount),
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ),
          Text(
            currency,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  /// صف العملية الواحدة داخل بطاقة "آخر العمليات"
  Widget _buildRecentTransactionRow({
    required BuildContext context,
    required TransactionModel tx,
    required String currency,
    required bool isDark,
  }) {
    final isExpense = tx.isExpense;
    final categoryColor = Color(tx.categoryColorHex);

    return InkWell(
      onTap: () => _showTransactionDetails(context, tx, currency),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // أيقونة التصنيف الدائرية الملونة
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
            // اسم العملية واليوم
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
                  Text(
                    '• ${Formatters.formatRelativeDay(tx.date)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // المبلغ باللون الأحمر للمصروف والأخضر للدخل
            Text(
              '${isExpense ? '-' : '+'} ${Formatters.formatCurrency(tx.amount, symbol: currency)}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: isExpense ? AppTheme.expenseColor : AppTheme.incomeColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
