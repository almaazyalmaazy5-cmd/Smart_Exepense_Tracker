import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/transaction_model.dart';
import '../../domain/repositories/expense_repository.dart';

class ExpenseProvider extends ChangeNotifier {
  final ExpenseRepository _repository;
  final Uuid _uuid = const Uuid();

  List<TransactionModel> _transactions = [];
  bool _isLoading = true;
  String _currencySymbol = r'$';
  String _selectedCategoryFilter = 'all';

  ExpenseProvider({required ExpenseRepository repository})
      : _repository = repository {
    loadData();
  }

  List<TransactionModel> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String get currencySymbol => _currencySymbol;
  String get selectedCategoryFilter => _selectedCategoryFilter;

  // Filtered transactions
  List<TransactionModel> get filteredTransactions {
    if (_selectedCategoryFilter == 'all') {
      return _transactions;
    }
    return _transactions
        .where((t) => t.categoryId == _selectedCategoryFilter)
        .toList();
  }

  // Financial Summaries
  double get totalIncome {
    return _transactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get totalExpense {
    return _transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get currentBalance => totalIncome - totalExpense;

  // Current Month Total Expense
  double get currentMonthExpense {
    final now = DateTime.now();
    return _transactions
        .where((t) =>
            t.type == TransactionType.expense &&
            t.date.year == now.year &&
            t.date.month == now.month)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  // Category breakdown for charts
  Map<String, Map<String, dynamic>> get categoryExpenseBreakdown {
    final Map<String, Map<String, dynamic>> map = {};
    final expenseList = _transactions.where((t) => t.isExpense).toList();
    final double total = totalExpense;

    for (final tx in expenseList) {
      if (!map.containsKey(tx.categoryId)) {
        map[tx.categoryId] = {
          'name': tx.categoryName,
          'amount': 0.0,
          'color': Color(tx.categoryColorHex),
          'icon': IconData(tx.categoryIconCode, fontFamily: 'MaterialIcons'),
        };
      }
      map[tx.categoryId]!['amount'] =
          (map[tx.categoryId]!['amount'] as double) + tx.amount;
    }

    // Add percentage
    for (final entry in map.entries) {
      final double amt = entry.value['amount'] as double;
      entry.value['percentage'] = total > 0 ? (amt / total) * 100 : 0.0;
    }

    return map;
  }

  // Dynamic Smart Advice Generator (Smart Insights)
  List<String> get smartInsights {
    final List<String> insights = [];
    if (_transactions.isEmpty) {
      insights.add('أهلاً بك! ابدأ بتسجيل أول عملية لمعرفة تحليل مصاريفك.');
      return insights;
    }

    final double income = totalIncome;
    final double expense = totalExpense;

    // Savings rate check
    if (income > 0) {
      final double savingsRate = ((income - expense) / income) * 100;
      if (savingsRate >= 30) {
        insights.add(
            'رائع جداً! معدل ادخارك الحالي ${savingsRate.toStringAsFixed(0)}% وهو معدل استثماري ممتاز.');
      } else if (savingsRate > 0 && savingsRate < 15) {
        insights.add(
            'تنبيه مالي: نسبة التوفير لديك منخفضة (${savingsRate.toStringAsFixed(0)}%). حاول تقليل المصاريف الكمالية.');
      } else if (savingsRate <= 0) {
        insights.add(
            'تحذير: نفقاتك تجاوزت إجمالي دخلك! راجع ميزانيتك الشهرية فوراً لتجنب الديون.');
      }
    }

    // Top Category Analysis
    final breakdown = categoryExpenseBreakdown;
    if (breakdown.isNotEmpty) {
      final sortedEntries = breakdown.entries.toList()
        ..sort((a, b) => (b.value['amount'] as double)
            .compareTo(a.value['amount'] as double));

      final topCategory = sortedEntries.first;
      final double topPercent = topCategory.value['percentage'] as double;
      if (topPercent >= 35) {
        insights.add(
            'أكبر استهلاك لميزانيتك يذهب إلى "${topCategory.value['name']}" بنسبة ${topPercent.toStringAsFixed(0)}%. وضع حد شهري لهذا البند سيوفر لك مبالغ جيدة.');
      }
    }

    if (insights.isEmpty) {
      insights.add(
          'أمورك المالية مستقرة ومتوازنة. استمر في تدوين فواتيرك بانتظام!');
    }

    return insights;
  }

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    final result = await _repository.getAllTransactions();
    _transactions = List<TransactionModel>.from(result);
    _currencySymbol = await _repository.getCurrency();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addTransaction({
    required String title,
    required double amount,
    required TransactionType type,
    required String categoryId,
    required String categoryName,
    required int categoryIconCode,
    required int categoryColorHex,
    required DateTime date,
    String? notes,
  }) async {
    final newTransaction = TransactionModel(
      id: _uuid.v4(),
      title: title,
      amount: amount,
      type: type,
      categoryId: categoryId,
      categoryName: categoryName,
      categoryIconCode: categoryIconCode,
      categoryColorHex: categoryColorHex,
      date: date,
      notes: notes,
    );

    await _repository.addTransaction(newTransaction);
    _transactions.insert(0, newTransaction);
    notifyListeners();
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    await _repository.updateTransaction(transaction);
    final index = _transactions.indexWhere((t) => t.id == transaction.id);
    if (index != -1) {
      _transactions[index] = transaction;
      notifyListeners();
    }
  }

  Future<void> deleteTransaction(String id) async {
    await _repository.deleteTransaction(id);
    _transactions.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  Future<void> setCurrency(String symbol) async {
    _currencySymbol = symbol;
    await _repository.setCurrency(symbol);
    notifyListeners();
  }

  void setFilter(String categoryId) {
    _selectedCategoryFilter = categoryId;
    notifyListeners();
  }
}
