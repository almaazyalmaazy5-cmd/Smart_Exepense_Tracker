import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/budget_model.dart';
import '../../domain/repositories/expense_repository.dart';

// ============================================================================
// مزوّد حالة الميزانية الشهرية والفرعية (BudgetProvider)
// ----------------------------------------------------------------------------
// يدير السقف الشهري الكلي + الميزانيات الفرعية لكل تصنيف (الطعام، المواصلات...)
// ويدعم العملة المخصصة وفارق الصرف ونسب الاستهلاك وحالات التنبيه.
// ============================================================================

class BudgetProvider extends ChangeNotifier {
  final ExpenseRepository _repository;
  BudgetModel _budget = BudgetModel(
    monthlyLimit: 250000.0,
    currency: 'ر.ي',
    categoryCurrency: 'ر.ي',
    exchangeRate: 1.0,
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
  String get currency => _budget.currency;
  String get categoryCurrency => _budget.categoryCurrency;
  double get exchangeRate => _budget.exchangeRate;
  bool get areCurrenciesEqual => _budget.areCurrenciesEqual;
  double get monthlyLimitInCategoriesCurrency =>
      _budget.monthlyLimitInCategoriesCurrency;
  Map<String, double> get categoryLimits => _budget.categoryLimits;
  double get alertThreshold => _budget.alertThreshold;

  /// إرجاع الميزانية المخصصة لتصنيف معين (0 إذا لم يُحدد بعد)
  double getCategoryLimit(String categoryId) {
    return _budget.categoryLimits[categoryId] ?? 0.0;
  }

  /// إرجاع السقف الكلي محسوباً بأي عملة مستهدفة (للمقارنة العادلة مع المصروفات)
  double monthlyLimitIn(String targetCurrency) {
    if (_budget.currency == targetCurrency) {
      return _budget.monthlyLimit;
    }
    if (_budget.categoryCurrency == targetCurrency) {
      return _budget.monthlyLimitInCategoriesCurrency;
    }
    final rate = AppConstants.getDefaultExchangeRate(_budget.currency, targetCurrency);
    return _budget.monthlyLimit * rate;
  }

  /// إرجاع السقف الفعّال الموازي لعملة تسجيل المصروفات
  double effectiveTotalLimit(String? expenseCurrency) {
    if (expenseCurrency == null || expenseCurrency == _budget.currency) {
      return _budget.monthlyLimit;
    }
    if (expenseCurrency == _budget.categoryCurrency) {
      return _budget.monthlyLimitInCategoriesCurrency;
    }
    return monthlyLimitIn(expenseCurrency);
  }

  Future<void> loadBudget() async {
    _isLoading = true;
    notifyListeners();

    _budget = await _repository.getBudget();

    _isLoading = false;
    notifyListeners();
  }

  /// تحديث السقف الشهري الكلي
  Future<void> updateMonthlyLimit(double limit, {String? currency}) async {
    _budget = _budget.copyWith(
      monthlyLimit: limit,
      currency: currency ?? _budget.currency,
    );
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

  /// تحديث الميزانية الكلية وجميع الميزانيات الفرعية وفارق الصرف دفعة واحدة
  Future<void> updateAllBudgets({
    required double monthlyLimit,
    String? currency,
    String? categoryCurrency,
    double? exchangeRate,
    required Map<String, double> categoryLimits,
  }) async {
    final cleaned = <String, double>{};
    categoryLimits.forEach((key, value) {
      if (value > 0) cleaned[key] = value;
    });

    final effCurrency = currency ?? _budget.currency;
    final effCatCurrency = categoryCurrency ?? _budget.categoryCurrency;
    final effRate = effCurrency == effCatCurrency
        ? 1.0
        : (exchangeRate ?? _budget.exchangeRate);

    _budget = _budget.copyWith(
      monthlyLimit: monthlyLimit,
      currency: effCurrency,
      categoryCurrency: effCatCurrency,
      exchangeRate: effRate,
      categoryLimits: cleaned,
    );
    await _repository.updateBudget(_budget);
    notifyListeners();
  }

  // ========== حسابات الميزانية الشهرية الكلية مع دعم فارق الصرف ==========
  double calculateUsagePercentage(double totalSpent, {String? expenseCurrency}) {
    final limit = effectiveTotalLimit(expenseCurrency);
    if (limit <= 0) return 0.0;
    return (totalSpent / limit).clamp(0.0, 1.0);
  }

  double remainingBudget(double totalSpent, {String? expenseCurrency}) {
    final limit = effectiveTotalLimit(expenseCurrency);
    return limit - totalSpent;
  }

  bool isOverBudget(double totalSpent, {String? expenseCurrency}) {
    final limit = effectiveTotalLimit(expenseCurrency);
    return limit > 0 && totalSpent > limit;
  }

  bool isNearLimit(double totalSpent, {String? expenseCurrency}) {
    final limit = effectiveTotalLimit(expenseCurrency);
    if (limit <= 0) return false;
    final ratio = totalSpent / limit;
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
