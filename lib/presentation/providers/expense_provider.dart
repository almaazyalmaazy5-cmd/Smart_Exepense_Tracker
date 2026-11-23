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
  String _currencySymbol = 'ر.ي';
  String _selectedCategoryFilter = 'all';

  ExpenseProvider({required ExpenseRepository repository})
      : _repository = repository {
    loadData();
  }

  List<TransactionModel> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String get currencySymbol => _currencySymbol;
  String get selectedCategoryFilter => _selectedCategoryFilter;

  /// أحدث 5 معاملات لعرضها في الصفحة الرئيسية (Dashboard)
  List<TransactionModel> get recentTransactions =>
      _transactions.take(5).toList();

  /// ترتيب المعاملات تلقائياً من الأحدث إلى الأقدم حسب التاريخ
  void _sortByDateDescending() {
    _transactions.sort((a, b) => b.date.compareTo(a.date));
  }

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

  /// مصروفات الشهر الحالي مجمّعة حسب معرّف التصنيف (لشاشة الميزانية الفرعية)
  Map<String, double> get currentMonthExpenseByCategory {
    final now = DateTime.now();
    final Map<String, double> map = {};
    for (final tx in _transactions) {
      if (tx.isExpense &&
          tx.date.year == now.year &&
          tx.date.month == now.month) {
        map[tx.categoryId] = (map[tx.categoryId] ?? 0.0) + tx.amount;
      }
    }
    return map;
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
          'icon': AppConstants.getCategoryIcon(tx.categoryId),
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

  /// مصروفات الشهر الماضي الإجمالية (للمقارنة في التحليلات الذكية)
  double get lastMonthExpense {
    final now = DateTime.now();
    final lastMonth = DateTime(now.year, now.month - 1, 1);
    return _transactions
        .where((t) =>
            t.isExpense &&
            t.date.year == lastMonth.year &&
            t.date.month == lastMonth.month)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  /// إرجاع قائمة العمليات لفترة محددة (عدد الأشهر: 0 = هذا الشهر، 1 = الشهر الماضي، 3 = آخر 3 أشهر)
  List<TransactionModel> transactionsForPeriod(String periodKey) {
    final now = DateTime.now();
    if (periodKey == 'this_month') {
      return _transactions
          .where((t) => t.date.year == now.year && t.date.month == now.month)
          .toList();
    } else if (periodKey == 'last_month') {
      final last = DateTime(now.year, now.month - 1, 1);
      return _transactions
          .where((t) => t.date.year == last.year && t.date.month == last.month)
          .toList();
    } else {
      // آخر 3 أشهر (الشهر الحالي + الشهرين السابقين)
      final start = DateTime(now.year, now.month - 2, 1);
      return _transactions.where((t) => !t.date.isBefore(start)).toList();
    }
  }

  /// توزيع المصروفات حسب التصنيف لقائمة عمليات محددة (مرتّب تنازلياً من الأعلى للأقل)
  List<Map<String, dynamic>> buildSortedCategoryBreakdown(
    List<TransactionModel> source,
  ) {
    final Map<String, Map<String, dynamic>> map = {};
    final expenseList = source.where((t) => t.isExpense).toList();
    final double total = expenseList.fold(0.0, (sum, t) => sum + t.amount);

    for (final tx in expenseList) {
      if (!map.containsKey(tx.categoryId)) {
        map[tx.categoryId] = {
          'id': tx.categoryId,
          'name': tx.categoryName,
          'amount': 0.0,
          'color': Color(tx.categoryColorHex),
          'icon': AppConstants.getCategoryIcon(tx.categoryId),
        };
      }
      map[tx.categoryId]!['amount'] =
          (map[tx.categoryId]!['amount'] as double) + tx.amount;
    }

    final list = map.values.map((entry) {
      final double amt = entry['amount'] as double;
      return {
        ...entry,
        'percentage': total > 0 ? (amt / total) * 100 : 0.0,
      };
    }).toList();

    list.sort(
      (a, b) => (b['amount'] as double).compareTo(a['amount'] as double),
    );
    return list;
  }

  /// التحليل المالي الذكي المطوّر (يعمل محلياً بالحسابات دون إنترنت)
  List<String> generateSmartInsights({double? monthlyBudgetLimit}) {
    final List<String> insights = [];
    if (_transactions.isEmpty) {
      insights.add('أهلاً بك! ابدأ بتسجيل أول عملية لعرض تحليلاتك المالية الذكية.');
      return insights;
    }

    final now = DateTime.now();
    final thisMonthExp = currentMonthExpense;
    final prevMonthExp = lastMonthExpense;

    // 1. مقارنة مصروفات هذا الشهر بالشهر الماضي
    if (prevMonthExp > 0 && thisMonthExp > 0) {
      final diffPercent = ((thisMonthExp - prevMonthExp) / prevMonthExp) * 100;
      if (diffPercent >= 5) {
        insights.add(
          'مصروفاتك هذا الشهر أعلى من الشهر الماضي بنسبة ${diffPercent.toStringAsFixed(0)}%.',
        );
      } else if (diffPercent <= -5) {
        insights.add(
          'أحسنت! مصروفاتك هذا الشهر أقل من الشهر الماضي بنسبة ${diffPercent.abs().toStringAsFixed(0)}%.',
        );
      }
    }

    // 2. أكثر تصنيف استهلاكاً للمال
    final breakdown = buildSortedCategoryBreakdown(
      transactionsForPeriod('this_month'),
    );
    final effectiveBreakdown =
        breakdown.isNotEmpty ? breakdown : buildSortedCategoryBreakdown(_transactions);
    if (effectiveBreakdown.isNotEmpty) {
      final top = effectiveBreakdown.first;
      final topName = top['name'] as String;
      final topPct = (top['percentage'] as double).toStringAsFixed(0);
      insights.add('أكثر تصنيف أنفقت عليه هو "$topName" بنسبة $topPct%.');
    }

    // 3. تحليل الميزانية الشهرية والتوقّع اليومي (Burn Rate Forecast)
    if (monthlyBudgetLimit != null && monthlyBudgetLimit > 0) {
      final remainingPct =
          ((monthlyBudgetLimit - thisMonthExp) / monthlyBudgetLimit) * 100;
      if (thisMonthExp > monthlyBudgetLimit) {
        insights.add('تنبيه عاجل: لقد تجاوزت ميزانيتك الشهرية المحددة!');
      } else {
        insights.add(
          'بقي لديك ${remainingPct.clamp(0, 100).toStringAsFixed(0)}% من ميزانيتك الشهرية.',
        );

        final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
        if (now.day >= 3 && thisMonthExp > 0) {
          final projected = (thisMonthExp / now.day) * daysInMonth;
          if (projected > monthlyBudgetLimit) {
            insights.add(
              'إذا استمر معدل إنفاقك الحالي، فقد تتجاوز ميزانيتك المحددة قبل نهاية الشهر.',
            );
          }
        }
      }
    }

    // 4. معدل الادخار الكلي
    final double income = totalIncome;
    final double expense = totalExpense;
    if (income > 0) {
      final double savingsRate = ((income - expense) / income) * 100;
      if (savingsRate >= 30) {
        insights.add(
          'ممتاز! معدل ادخارك الإجمالي ${savingsRate.toStringAsFixed(0)}% وهو معدل صحي جداً.',
        );
      } else if (savingsRate <= 0) {
        insights.add(
          'تحذير: إجمالي مصروفاتك تجاوز دخلك، راجع نفقاتك لتجنّب العجز.',
        );
      }
    }

    if (insights.isEmpty) {
      insights.add('أمورك المالية مستقرة ومتوازنة. استمر في تدوين عملياتك بانتظام!');
    }
    return insights;
  }

  // Dynamic Smart Advice Generator (Smart Insights) - للتوافق السريع
  List<String> get smartInsights => generateSmartInsights();

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    final result = await _repository.getAllTransactions();
    _transactions = List<TransactionModel>.from(result);
    _sortByDateDescending();
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
    String? paymentMethod,
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
      paymentMethod: paymentMethod,
      notes: notes,
    );

    await _repository.addTransaction(newTransaction);
    _transactions.insert(0, newTransaction);
    _sortByDateDescending();
    notifyListeners();
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    await _repository.updateTransaction(transaction);
    final index = _transactions.indexWhere((t) => t.id == transaction.id);
    if (index != -1) {
      _transactions[index] = transaction;
      _sortByDateDescending();
      notifyListeners();
    }
  }

  Future<void> deleteTransaction(String id) async {
    await _repository.deleteTransaction(id);
    _transactions.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  /// مسح جميع العمليات (للبدء ببيانات نظيفة بدون العمليات التجريبية)
  Future<void> clearAllTransactions() async {
    await _repository.saveAllTransactions([]);
    _transactions = [];
    notifyListeners();
  }

  /// استبدال جميع العمليات (عند استعادة نسخة احتياطية JSON)
  Future<void> replaceAllTransactions(List<TransactionModel> items) async {
    final sorted = List<TransactionModel>.from(items)
      ..sort((a, b) => b.date.compareTo(a.date));
    await _repository.saveAllTransactions(sorted);
    _transactions = sorted;
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
