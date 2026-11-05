import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/formatters.dart';
import '../providers/budget_provider.dart';
import '../providers/expense_provider.dart';

class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

  void _showSetBudgetDialog(BuildContext context, double currentLimit) {
    final controller = TextEditingController(text: currentLimit.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تعديل الميزانية الشهرية'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('حدد سقف الإنفاق الأقصى لهذا الشهر:'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.account_balance_wallet),
                hintText: 'مثال: 2500',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(controller.text.trim());
              if (val != null && val > 0) {
                Provider.of<BudgetProvider>(context, listen: false)
                    .updateMonthlyLimit(val);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم تحديث الميزانية الشهرية بنجاح ✅'),
                  ),
                );
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Consumer2<BudgetProvider, ExpenseProvider>(
      builder: (context, budgetProv, expenseProv, child) {
        final limit = budgetProv.monthlyLimit;
        final currentSpent = expenseProv.currentMonthExpense;
        final currency = expenseProv.currencySymbol;
        final usagePercent = budgetProv.calculateUsagePercentage(currentSpent);
        final remaining = budgetProv.remainingBudget(currentSpent);
        final isOver = budgetProv.isOverBudget(currentSpent);
        final isNear = budgetProv.isNearLimit(currentSpent);

        Color statusColor = Colors.green;
        String statusText = 'ميزانيتك في المنطقة الآمنة ومستقرة 👍';
        if (isOver) {
          statusColor = Colors.red;
          statusText = 'تنبيه عاجل: لقد تجاوزت سقف الميزانية المحددة! ⚠️';
        } else if (isNear) {
          statusColor = Colors.orange;
          statusText = 'تحذير: اقتربت جداً من استنزاف كامل الميزانية (أكثر من 80%) ⏳';
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('الميزانية الذكية وتنبيهات الاستهلاك'),
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // 1. Main Budget Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: statusColor.withAlpha(isDark ? 100 : 70),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withAlpha(isDark ? 30 : 15),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'الميزانية المخصصة للشهر',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          tooltip: 'تعديل سقف الميزانية',
                          onPressed: () => _showSetBudgetDialog(context, limit),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      Formatters.formatCurrency(limit, symbol: currency),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Progress Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: usagePercent,
                        minHeight: 14,
                        backgroundColor: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0),
                        valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Stats Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('المصروف الحالي',
                                style: TextStyle(fontSize: 12, color: Colors.grey)),
                            Text(
                              Formatters.formatCurrency(currentSpent, symbol: currency),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(isOver ? 'قيمة العجز' : 'المتبقي',
                                style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            Text(
                              Formatters.formatCurrency(remaining.abs(), symbol: currency),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isOver ? Colors.red : Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 2. Alert Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(isDark ? 40 : 25),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: statusColor.withAlpha(80)),
                ),
                child: Row(
                  children: [
                    Icon(
                      isOver
                          ? Icons.warning_rounded
                          : (isNear ? Icons.access_time_filled : Icons.check_circle),
                      color: statusColor,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 3. Smart Budgeting Tips
              const Text(
                'نصائح هندسة الميزانية (قاعدة 50/30/20)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildRuleCard(
                title: '50% للاحتياجات الأساسية',
                subtitle: 'الإيجار، الفواتير، الغذاء، والمواصلات الأساسية.',
                color: Colors.blue,
                isDark: isDark,
              ),
              const SizedBox(height: 10),
              _buildRuleCard(
                title: '30% للرغبات والأنشطة الترفيهية',
                subtitle: 'المطاعم، التسوق، والأنشطة الشخصية.',
                color: Colors.purple,
                isDark: isDark,
              ),
              const SizedBox(height: 10),
              _buildRuleCard(
                title: '20% للادخار والاستثمار',
                subtitle: 'صندوق الطوارئ، والاستثمار للمستقبل.',
                color: Colors.teal,
                isDark: isDark,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRuleCard({
    required String title,
    required String subtitle,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
