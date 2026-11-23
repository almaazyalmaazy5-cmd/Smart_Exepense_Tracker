import 'package:flutter/material.dart';
import '../../data/models/budget_model.dart';
import '../../domain/repositories/expense_repository.dart';

// ============================================================================
// مزوّد حالة الميزانية الشهرية والفرعية (BudgetProvider)
// ----------------------------------------------------------------------------
// يدير السقف الشهري الكلي + الميزانيات الفرعية لكل تصنيف (الطعام، المواصلات...)
// ويحسب نسب الاستهلاك وحالات التنبيه (آمن / تحذير ≥ 80% / تجاوز > 100%).
// ============================================================================

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
  Map<String, double> get categoryLimits => _budget.categoryLimits;
  double get alertThreshold => _budget.alertThreshold;

  /// إرجاع الميزانية المخصصة لتصنيف معين (0 إذا لم يُحدد بعد)
  double getCategoryLimit(String categoryId) {
    return _budget.categoryLimits[categoryId] ?? 0.0;
  }

  Future<void> loadBudget() async {
    _isLoading = true;
    notifyListeners();

    _budget = await _repository.getBudget();

    _isLoading = false;
    notifyListeners();
  }

  /// تحديث السقف الشهري الكلي
  Future<void> updateMonthlyLimit(double limit) async {
    _budget = _budget.copyWith(monthlyLimit: limit);
    await _repository.updateBudget(_budget);
    notifyListeners();
  }

  /// تحديث ميزانية تصنيف فرعي واحد
  Future<void> updateCategoryLimit(String categoryId, double limit) async {
    final updated = Map<String, double>.from(_budget.categoryLimits);
    if (limit <= 0) {
      updated.remove(categoryId);
    } else {
      updated[categoryId] = limit;
    }
    _budget = _budget.copyWith(categoryLimits: updated);
    await _repository.updateBudget(_budget);
    notifyListeners();
  }

  /// تحديث الميزانية الكلية وجميع الميزانيات الفرعية دفعة واحدة (من نافذة إدارة الميزانية)
  Future<void> updateAllBudgets({
    required double monthlyLimit,
    required Map<String, double> categoryLimits,
  }) async {
    final cleaned = <String, double>{};
    categoryLimits.forEach((key, value) {
      if (value > 0) cleaned[key] = value;
    });

    _budget = _budget.copyWith(
      monthlyLimit: monthlyLimit,
      categoryLimits: cleaned,
    );
    await _repository.updateBudget(_budget);
    notifyListeners();
  }

  // ========== حسابات الميزانية الشهرية الكلية ==========
  double calculateUsagePercentage(double totalSpent) {
    if (_budget.monthlyLimit <= 0) return 0.0;
    return (totalSpent / _budget.monthlyLimit).clamp(0.0, 1.0);
  }

  double remainingBudget(double totalSpent) {
    return _budget.monthlyLimit - totalSpent;
  }

  bool isOverBudget(double totalSpent) {
    return _budget.monthlyLimit > 0 && totalSpent > _budget.monthlyLimit;
  }

  bool isNearLimit(double totalSpent) {
    if (_budget.monthlyLimit <= 0) return false;
    final ratio = totalSpent / _budget.monthlyLimit;
    return ratio >= _budget.alertThreshold && ratio <= 1.0;
  }

  // ========== حسابات ميزانية كل تصنيف فرعي ==========
  double categoryUsageRatio(String categoryId, double spent) {
    final limit = getCategoryLimit(categoryId);
    if (limit <= 0) return 0.0;
    return (spent / limit).clamp(0.0, 1.0);
  }

  bool isCategoryOverBudget(String categoryId, double spent) {
    final limit = getCategoryLimit(categoryId);
    return limit > 0 && spent > limit;
  }

  bool isCategoryNearLimit(String categoryId, double spent) {
    final limit = getCategoryLimit(categoryId);
    if (limit <= 0) return false;
    final ratio = spent / limit;
    return ratio >= _budget.alertThreshold && ratio <= 1.0;
  }
}
