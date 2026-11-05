import '../../domain/repositories/expense_repository.dart';
import '../datasources/local_storage_service.dart';
import '../models/transaction_model.dart';
import '../models/budget_model.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  final LocalStorageService _storageService;

  ExpenseRepositoryImpl({LocalStorageService? storageService})
      : _storageService = storageService ?? LocalStorageService();

  @override
  Future<List<TransactionModel>> getAllTransactions() async {
    return await _storageService.getTransactions();
  }

  @override
  Future<void> addTransaction(TransactionModel transaction) async {
    final list = await _storageService.getTransactions();
    list.insert(0, transaction);
    await _storageService.saveTransactions(list);
  }

  @override
  Future<void> updateTransaction(TransactionModel transaction) async {
    final list = await _storageService.getTransactions();
    final index = list.indexWhere((item) => item.id == transaction.id);
    if (index != -1) {
      list[index] = transaction;
      await _storageService.saveTransactions(list);
    }
  }

  @override
  Future<void> deleteTransaction(String id) async {
    final list = await _storageService.getTransactions();
    list.removeWhere((item) => item.id == id);
    await _storageService.saveTransactions(list);
  }

  @override
  Future<BudgetModel> getBudget() async {
    return await _storageService.getBudget();
  }

  @override
  Future<void> updateBudget(BudgetModel budget) async {
    await _storageService.saveBudget(budget);
  }

  @override
  Future<String> getCurrency() async {
    return await _storageService.getCurrencySymbol();
  }

  @override
  Future<void> setCurrency(String symbol) async {
    await _storageService.saveCurrencySymbol(symbol);
  }

  @override
  Future<bool> isDarkTheme() async {
    return await _storageService.getIsDarkTheme();
  }

  @override
  Future<void> setDarkTheme(bool isDark) async {
    await _storageService.saveIsDarkTheme(isDark);
  }
}
