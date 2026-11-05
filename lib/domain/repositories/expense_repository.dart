import '../../data/models/transaction_model.dart';
import '../../data/models/budget_model.dart';

abstract class ExpenseRepository {
  Future<List<TransactionModel>> getAllTransactions();
  Future<void> addTransaction(TransactionModel transaction);
  Future<void> updateTransaction(TransactionModel transaction);
  Future<void> deleteTransaction(String id);
  Future<BudgetModel> getBudget();
  Future<void> updateBudget(BudgetModel budget);
  Future<String> getCurrency();
  Future<void> setCurrency(String symbol);
  Future<bool> isDarkTheme();
  Future<void> setDarkTheme(bool isDark);
}
