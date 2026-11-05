import 'package:flutter/material.dart';
import '../../data/models/budget_model.dart';
import '../../domain/repositories/expense_repository.dart';

class BudgetProvider extends ChangeNotifier {
  final ExpenseRepository _repository;
  BudgetModel _budget = BudgetModel(
    monthlyLimit: 2500.0,
    month: DateTime.now().month,
    year: DateTime.now().year,
  );
  bool _isLoading = true;

  BudgetProvider({required ExpenseRepository repository})
      : _repository = repository {
    loadBudget();
  }

  BudgetModel get budget => _budget;
  bool get isLoading => _isLoading;
  double get monthlyLimit => _budget.monthlyLimit;

  Future<void> loadBudget() async {
    _isLoading = true;
    notifyListeners();

    _budget = await _repository.getBudget();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateMonthlyLimit(double limit) async {
    _budget = _budget.copyWith(monthlyLimit: limit);
    await _repository.updateBudget(_budget);
    notifyListeners();
  }

  double calculateUsagePercentage(double totalSpent) {
    if (_budget.monthlyLimit <= 0) return 0.0;
    return (totalSpent / _budget.monthlyLimit).clamp(0.0, 1.0);
  }

  double remainingBudget(double totalSpent) {
    return _budget.monthlyLimit - totalSpent;
  }

  bool isOverBudget(double totalSpent) {
    return totalSpent > _budget.monthlyLimit;
  }

  bool isNearLimit(double totalSpent) {
    if (_budget.monthlyLimit <= 0) return false;
    final ratio = totalSpent / _budget.monthlyLimit;
    return ratio >= _budget.alertThreshold && ratio <= 1.0;
  }
}
