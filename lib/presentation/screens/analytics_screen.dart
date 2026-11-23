import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/transaction_model.dart';
import '../providers/budget_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/theme_provider.dart';

// ============================================================================
// الواجهة الخامسة: التقارير والإحصائيات (AnalyticsScreen)
// ----------------------------------------------------------------------------
// مطابقة للتصميم في الصورة وتتكوّن من 5 أقسام واضحة:
//   [1] فلتر الفترة الزمنية (هذا الشهر | الشهر الماضي | آخر 3 أشهر)
//   [2] بطاقتا ملخص الفترة (الدخل | المصروفات)
//   [3] المخططان: توزيع المصروفات (دائري) + مقارنة الدخل والمصروفات (أعمدة)
//   [4] التحليلات المالية الذكية (Smart Financial Insights)
//   [5] أكثر التصنيفات استهلاكاً للمال (مرتّبة من الأعلى إلى الأقل)
// ============================================================================

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String _selectedPeriod = 'this_month'; // 'this_month' | 'last_month' | 'last_3_months'
  int _touchedIndex = -1;

  /// تجهيز بيانات مخطط الأعمدة (شهر واحد أو آخر 3 أشهر)
  List<Map<String, dynamic>> _buildMonthlyBarData(
    List<TransactionModel> periodTransactions,
  ) {
    final now = DateTime.now();
    final List<DateTime> monthsToShow = [];

    if (_selectedPeriod == 'this_month') {
      monthsToShow.add(DateTime(now.year, now.month, 1));
    } else if (_selectedPeriod == 'last_month') {
      monthsToShow.add(DateTime(now.year, now.month - 1, 1));
    } else {
      monthsToShow.add(DateTime(now.year, now.month - 2, 1));
      monthsToShow.add(DateTime(now.year, now.month - 1, 1));
      monthsToShow.add(DateTime(now.year, now.month, 1));
    }

    return monthsToShow.map((m) {
      double income = 0.0;
      double expense = 0.0;
      for (final tx in periodTransactions) {
        if (tx.date.year == m.year && tx.date.month == m.month) {
          if (tx.isIncome) {
            income += tx.amount;
          } else {
            expense += tx.amount;
          }
        }
      }
      return {
        'label': Formatters.arabicMonths[m.month - 1],
        'income': income,
        'expense': expense,
      };
    }).toList();
  }

  /// تنسيق مختصر لأرقام المحور العمودي (مثال: 40k أو 500)
  String _compactAxisNumber(double value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(value % 1000 == 0 ? 0 : 1)}k';
    }
    return value.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Provider.of<ThemeProvider>(context).selectedColor.primary;

    return Consumer2<ExpenseProvider, BudgetProvider>(
      builder: (context, expenseProv, budgetProv, child) {
        final periodTransactions =
            expenseProv.transactionsForPeriod(_selectedPeriod);
        final periodIncome = periodTransactions
            .where((t) => t.isIncome)
            .fold(0.0, (sum, t) => sum + t.amount);
        final periodExpense = periodTransactions
            .where((t) => t.isExpense)
            .fold(0.0, (sum, t) => sum + t.amount);

        final breakdown =
            expenseProv.buildSortedCategoryBreakdown(periodTransactions);
        final barData = _buildMonthlyBarData(periodTransactions);
        final currency = expenseProv.currencySymbol;
        final insights = expenseProv.generateSmartInsights(
          monthlyBudgetLimit: budgetProv.monthlyLimitIn(currency),
        );

        // حساب أعلى قيمة لمحور الأعمدة
        double maxBarValue = 0.0;
        for (final item in barData) {
          final inc = item['income'] as double;
          final exp = item['expense'] as double;
          if (inc > maxBarValue) maxBarValue = inc;
          if (exp > maxBarValue) maxBarValue = exp;
        }
        final double chartMaxY = maxBarValue > 0 ? maxBarValue * 1.2 : 100.0;

        // الفئة الملموسة حالياً في المخطط الدائري لعرضها في المركز
        final Map<String, dynamic>? touchedItem =
            (_touchedIndex >= 0 && _touchedIndex < breakdown.length)
                ? breakdown[_touchedIndex]
                : null;

        return Scaffold(
          appBar: AppBar(
            title: const Text('الإحصائيات'),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 95),
            children: [
              // ==============================================================
              // [1] فلتر الفترة الزمنية (هذا الشهر | الشهر الماضي | آخر 3 أشهر)
              // ==============================================================
              Row(
                children: [
                  Expanded(
                    child: _buildPeriodTab(
                      label: 'هذا الشهر',
                      isSelected: _selectedPeriod == 'this_month',
                      primaryColor: primaryColor,
                      isDark: isDark,
                      onTap: () => setState(() {
                        _selectedPeriod = 'this_month';
                        _touchedIndex = -1;
                      }),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildPeriodTab(
                      label: 'الشهر الماضي',
                      isSelected: _selectedPeriod == 'last_month',
                      primaryColor: primaryColor,
                      isDark: isDark,
                      onTap: () => setState(() {
                        _selectedPeriod = 'last_month';
                        _touchedIndex = -1;
                      }),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildPeriodTab(
                      label: 'آخر 3 أشهر',
                      isSelected: _selectedPeriod == 'last_3_months',
                      primaryColor: primaryColor,
                      isDark: isDark,
                      onTap: () => setState(() {
                        _selectedPeriod = 'last_3_months';
                        _touchedIndex = -1;
                      }),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ==============================================================
              // [2] بطاقتا الدخل والمصروفات للفترة المختارة
              // ==============================================================
              Row(
                children: [
                  Expanded(
                    child: _buildPeriodSummaryCard(
                      title: 'الدخل',
                      amount: periodIncome,
                      currency: currency,
                      icon: Icons.arrow_upward_rounded,
                      iconColor: AppTheme.incomeColor,
                      bgColor: isDark
                          ? const Color(0xFF172D23)
                          : const Color(0xFFECFDF5),
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildPeriodSummaryCard(
                      title: 'المصروفات',
                      amount: periodExpense,
                      currency: currency,
                      icon: Icons.arrow_downward_rounded,
                      iconColor: AppTheme.expenseColor,
                      bgColor: isDark
                          ? const Color(0xFF331D22)
                          : const Color(0xFFFEECEC),
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ==============================================================
              // [3] الرسوم البيانية: توزيع المصروفات (دائري) + مقارنة (أعمدة)
              // ==============================================================
              if (periodTransactions.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 40,
                    horizontal: 20,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.pie_chart_outline_rounded,
                        size: 60,
                        color: isDark ? Colors.white24 : Colors.grey.shade400,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'لا توجد عمليات في هذه الفترة',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'جرّب اختيار فترة أخرى أو أضف عمليات جديدة',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: isDark ? Colors.white54 : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                // بطاقة 1: الرسم الدائري لتوزيع المصروفات
                if (breakdown.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(isDark ? 30 : 10),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'توزيع المصروفات حسب التصنيف',
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 200,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              PieChart(
                                PieChartData(
                                  pieTouchData: PieTouchData(
                                    touchCallback: (event, response) {
                                      setState(() {
                                        if (!event.isInterestedForInteractions ||
                                            response == null ||
                                            response.touchedSection == null) {
                                          _touchedIndex = -1;
                                          return;
                                        }
                                        _touchedIndex = response
                                            .touchedSection!.touchedSectionIndex;
                                      });
                                    },
                                  ),
                                  borderData: FlBorderData(show: false),
                                  sectionsSpace: 3,
                                  centerSpaceRadius: 54,
                                  sections: _buildPieSections(breakdown),
                                ),
                              ),
                              // النص المركزي داخل الدائرة
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    touchedItem != null
                                        ? touchedItem['name'] as String
                                        : 'إجمالي الصرف',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: isDark
                                          ? Colors.white60
                                          : Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    touchedItem != null
                                        ? '${(touchedItem['percentage'] as double).toStringAsFixed(0)}%'
                                        : Formatters.formatNumberOnly(
                                            periodExpense,
                                          ),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        // مفتاح الألوان (Legend)
                        Wrap(
                          spacing: 14,
                          runSpacing: 8,
                          children: breakdown.take(6).map((item) {
                            final color = item['color'] as Color;
                            final name = item['name'] as String;
                            final pct = (item['percentage'] as double)
                                .toStringAsFixed(0);
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '$name ($pct%)',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 16),

                // بطاقة 2: مخطط الأعمدة (مقارنة الدخل والمصروفات)
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(isDark ? 30 : 10),
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
                          const Text(
                            'مقارنة الدخل والمصروفات',
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                              _buildLegendDot(AppTheme.incomeColor, 'الدخل'),
                              const SizedBox(width: 10),
                              _buildLegendDot(
                                AppTheme.expenseColor,
                                'المصروفات',
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 190,
                        child: BarChart(
                          BarChartData(
                            maxY: chartMaxY,
                            barTouchData: BarTouchData(enabled: true),
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              getDrawingHorizontalLine: (_) => FlLine(
                                color: isDark
                                    ? const Color(0xFF334155)
                                    : const Color(0xFFE5E7EB),
                                strokeWidth: 1,
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            titlesData: FlTitlesData(
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 42,
                                  getTitlesWidget: (val, _) => Text(
                                    _compactAxisNumber(val),
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      color: isDark
                                          ? Colors.white54
                                          : Colors.black54,
                                    ),
                                  ),
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (val, _) {
                                    final idx = val.toInt();
                                    if (idx < 0 || idx >= barData.length) {
                                      return const SizedBox.shrink();
                                    }
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Text(
                                        barData[idx]['label'] as String,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            barGroups: List.generate(barData.length, (index) {
                              final inc = barData[index]['income'] as double;
                              final exp = barData[index]['expense'] as double;
                              return BarChartGroupData(
                                x: index,
                                barsSpace: 10,
                                barRods: [
                                  BarChartRodData(
                                    toY: inc,
                                    color: AppTheme.incomeColor,
                                    width: barData.length == 1 ? 28 : 16,
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(6),
                                    ),
                                  ),
                                  BarChartRodData(
                                    toY: exp,
                                    color: AppTheme.expenseColor,
                                    width: barData.length == 1 ? 28 : 16,
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(6),
                                    ),
                                  ),
                                ],
                              );
                            }),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 18),

              // ==============================================================
              // [4] التحليلات المالية الذكية (Smart Financial Insights)
              // ==============================================================
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: primaryColor.withAlpha(isDark ? 45 : 22),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: primaryColor.withAlpha(80)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.auto_awesome_rounded,
                          color: primaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'التحليلات المالية الذكية',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ...insights.map(
                      (tip) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.insights_rounded,
                              size: 16,
                              color: primaryColor,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                tip,
                                style: const TextStyle(
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ==============================================================
              // [5] أكثر التصنيفات استهلاكاً للمال (مرتّبة تنازلياً)
              // ==============================================================
              if (breakdown.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text(
                  'أكثر التصنيفات استهلاكاً للمال',
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                ...breakdown.map((data) {
                  final name = data['name'] as String;
                  final amount = data['amount'] as double;
                  final color = data['color'] as Color;
                  final icon = data['icon'] as IconData;
                  final percent = data['percentage'] as double;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor:
                                  color.withAlpha(isDark ? 55 : 32),
                              child: Icon(icon, color: color, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  Formatters.formatCurrency(
                                    amount,
                                    symbol: currency,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  '${percent.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: color,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: percent / 100,
                            minHeight: 7,
                            backgroundColor: isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFE5E7EB),
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        );
      },
    );
  }

  List<PieChartSectionData> _buildPieSections(
    List<Map<String, dynamic>> items,
  ) {
    return List.generate(items.length, (index) {
      final data = items[index];
      final isTouched = index == _touchedIndex;
      final color = data['color'] as Color;
      final percent = data['percentage'] as double;

      return PieChartSectionData(
        color: color,
        value: data['amount'] as double,
        title: percent >= 8 ? '${percent.toStringAsFixed(0)}%' : '',
        radius: isTouched ? 52 : 42,
        titleStyle: TextStyle(
          fontSize: isTouched ? 14 : 11,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    });
  }

  Widget _buildPeriodTab({
    required String label,
    required bool isSelected,
    required Color primaryColor,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 170),
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor
              : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected
                ? primaryColor
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white70 : Colors.black87),
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodSummaryCard({
    required String title,
    required double amount,
    required String currency,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    Formatters.formatCurrency(amount, symbol: currency),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11.5)),
      ],
    );
  }
}
