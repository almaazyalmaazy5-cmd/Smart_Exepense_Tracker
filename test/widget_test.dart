import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/core/constants/app_constants.dart';
import 'package:smart_expense_tracker/data/models/budget_model.dart';
import 'package:smart_expense_tracker/data/models/transaction_model.dart';
import 'package:smart_expense_tracker/domain/repositories/expense_repository.dart';
import 'package:smart_expense_tracker/presentation/providers/expense_provider.dart';
import 'package:smart_expense_tracker/presentation/providers/budget_provider.dart';

// In-Memory Mock Repository for testing
class MockExpenseRepository implements ExpenseRepository {
  List<TransactionModel> items = [];
  BudgetModel budget = BudgetModel(monthlyLimit: 1000.0, month: 1, year: 2026);
  String currency = r'$';
  bool isDark = false;

  @override
  Future<List<TransactionModel>> getAllTransactions() async =>
      List<TransactionModel>.from(items);

  @override
  Future<void> addTransaction(TransactionModel tx) async =>
      items.insert(0, tx);

  @override
  Future<void> updateTransaction(TransactionModel tx) async {
    final idx = items.indexWhere((i) => i.id == tx.id);
    if (idx != -1) items[idx] = tx;
  }

  @override
  Future<void> deleteTransaction(String id) async =>
      items.removeWhere((i) => i.id == id);

  @override
  Future<BudgetModel> getBudget() async => budget;

  @override
  Future<void> updateBudget(BudgetModel b) async => budget = b;

  @override
  Future<String> getCurrency() async => currency;

  @override
  Future<void> setCurrency(String c) async => currency = c;

  @override
  Future<bool> isDarkTheme() async => isDark;

  @override
  Future<void> setDarkTheme(bool dark) async => isDark = dark;
}

void main() {
  group('ExpenseProvider Unit Tests', () {
    late MockExpenseRepository mockRepo;
    late ExpenseProvider expenseProvider;

    setUp(() async {
      mockRepo = MockExpenseRepository();
      expenseProvider = ExpenseProvider(repository: mockRepo);
      await expenseProvider.loadData();
    });

    test('Initial balance should be zero when no transactions exist', () {
      expect(expenseProvider.totalIncome, 0.0);
      expect(expenseProvider.totalExpense, 0.0);
      expect(expenseProvider.currentBalance, 0.0);
    });

    test('Adding income and expense correctly computes balance', () async {
      await expenseProvider.addTransaction(
        title: 'Salary',
        amount: 2000.0,
        type: TransactionType.income,
        categoryId: 'salary',
        categoryName: 'Salary',
        categoryIconCode: 0xe040,
        categoryColorHex: 0xFF4CAF50,
        date: DateTime.now(),
      );

      await expenseProvider.addTransaction(
        title: 'Groceries',
        amount: 500.0,
        type: TransactionType.expense,
        categoryId: 'food',
        categoryName: 'Food',
        categoryIconCode: 0xe532,
        categoryColorHex: 0xFFFF5722,
        date: DateTime.now(),
      );

      expect(expenseProvider.totalIncome, 2000.0);
      expect(expenseProvider.totalExpense, 500.0);
      expect(expenseProvider.currentBalance, 1500.0);
    });

    test('Deleting a transaction updates balance correctly', () async {
      await expenseProvider.addTransaction(
        title: 'Coffee',
        amount: 5.0,
        type: TransactionType.expense,
        categoryId: 'food',
        categoryName: 'Food',
        categoryIconCode: 0xe532,
        categoryColorHex: 0xFFFF5722,
        date: DateTime.now(),
      );

      final id = expenseProvider.transactions.first.id;
      expect(expenseProvider.transactions.length, 1);

      await expenseProvider.deleteTransaction(id);
      expect(expenseProvider.transactions.length, 0);
      expect(expenseProvider.totalExpense, 0.0);
    });
  });

  group('BudgetProvider Unit Tests', () {
    late MockExpenseRepository mockRepo;
    late BudgetProvider budgetProvider;

    setUp(() {
      mockRepo = MockExpenseRepository();
      budgetProvider = BudgetProvider(repository: mockRepo);
    });

    test('Usage percentage and remaining budget calculation', () {
      // Limit is 1000.0
      expect(budgetProvider.calculateUsagePercentage(500.0), 0.5);
      expect(budgetProvider.remainingBudget(500.0), 500.0);
      expect(budgetProvider.isOverBudget(500.0), false);
      expect(budgetProvider.isNearLimit(500.0), false);

      // Over budget
      expect(budgetProvider.isOverBudget(1200.0), true);

      // Near limit (>= 80%)
      expect(budgetProvider.isNearLimit(850.0), true);
    });
  });
}
