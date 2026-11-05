import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../providers/expense_provider.dart';
import '../widgets/summary_card.dart';
import '../widgets/smart_insight_banner.dart';
import '../widgets/transaction_tile.dart';
import 'add_transaction_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Consumer<ExpenseProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final transactions = provider.filteredTransactions;

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'لوحة التحكم المالية',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  'تابع مصاريفك ونمِّ مدخراتك بذكاء',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'تحديث البيانات',
                onPressed: () => provider.loadData(),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () => provider.loadData(),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                // 1. Balance Summary Card
                SummaryCard(
                  balance: provider.currentBalance,
                  income: provider.totalIncome,
                  expense: provider.totalExpense,
                  currency: provider.currencySymbol,
                ),
                const SizedBox(height: 16),

                // 2. AI Smart Insight Banner
                SmartInsightBanner(insights: provider.smartInsights),
                const SizedBox(height: 20),

                // 3. Category Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(
                        context: context,
                        label: 'الكل (${provider.transactions.length})',
                        isSelected: provider.selectedCategoryFilter == 'all',
                        onSelected: () => provider.setFilter('all'),
                      ),
                      ...AppConstants.defaultExpenseCategories.map((cat) {
                        final isSelected =
                            provider.selectedCategoryFilter == cat['id'];
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _buildFilterChip(
                            context: context,
                            label: cat['name'] as String,
                            isSelected: isSelected,
                            onSelected: () =>
                                provider.setFilter(cat['id'] as String),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // 4. Transactions Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'سجل المعاملات',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      '${transactions.length} حركة',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // 5. Transactions List or Empty State
                if (transactions.isEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 30),
                    padding: const EdgeInsets.all(32),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 64,
                          color: isDark ? Colors.white24 : Colors.grey.shade400,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'لا توجد معاملات مسجلة في هذا التصنيف',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'اضغط على زر (+) في الأسفل لإضافة مصروف أو دخل جديد',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white38 : Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else
                  ...transactions.map((tx) {
                    return TransactionTile(
                      transaction: tx,
                      currency: provider.currencySymbol,
                      onDelete: () => provider.deleteTransaction(tx.id),
                    );
                  }),
                const SizedBox(height: 80), // Space for floating button
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            heroTag: 'add_expense_fab',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddTransactionScreen(),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('إضافة معاملة'),
          ),
        );
      },
    );
  }

  Widget _buildFilterChip({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      labelStyle: TextStyle(
        fontSize: 12.5,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected
            ? Colors.white
            : (isDark ? Colors.white70 : Colors.black87),
      ),
      selectedColor: theme.colorScheme.primary,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected
              ? Colors.transparent
              : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
        ),
      ),
    );
  }
}
