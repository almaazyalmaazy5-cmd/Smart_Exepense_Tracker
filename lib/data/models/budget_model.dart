class BudgetModel {
  final double monthlyLimit;
  final String currency; // عملة الميزانية الكلية (الافتراضية: ر.ي)
  final String categoryCurrency; // عملة ميزانية التصنيفات (الافتراضية: ر.ي)
  final double exchangeRate; // سعر صرف 1 وحدة من عملة الميزانية الكلية إلى عملة التصنيفات
  final int month;
  final int year;
  final Map<String, double> categoryLimits;
  final double alertThreshold; // Default 0.8 (80%)

  BudgetModel({
    required this.monthlyLimit,
    this.currency = 'ر.ي',
    this.categoryCurrency = 'ر.ي',
    this.exchangeRate = 1.0,
    required this.month,
    required this.year,
    this.categoryLimits = const {},
    this.alertThreshold = 0.80,
  });

  /// هل العملتان متطابقتان تماماً
  bool get areCurrenciesEqual => currency == categoryCurrency;

  /// السقف الكلي محسوباً بعملة التصنيفات بعد احتساب فارق الصرف
  double get monthlyLimitInCategoriesCurrency {
    if (areCurrenciesEqual || exchangeRate <= 0) {
      return monthlyLimit;
    }
    return monthlyLimit * exchangeRate;
  }

  /// تحويل أي مبلغ من عملة التصنيفات إلى عملة الميزانية الكلية
  double convertFromCategoriesToBudget(double amountInCategories) {
    if (areCurrenciesEqual || exchangeRate <= 0) {
      return amountInCategories;
    }
    return amountInCategories / exchangeRate;
  }

  /// تحويل أي مبلغ من عملة الميزانية الكلية إلى عملة التصنيفات
  double convertFromBudgetToCategories(double amountInBudget) {
    if (areCurrenciesEqual || exchangeRate <= 0) {
      return amountInBudget;
    }
    return amountInBudget * exchangeRate;
  }

  Map<String, dynamic> toMap() {
    return {
      'monthlyLimit': monthlyLimit,
      'currency': currency,
      'categoryCurrency': categoryCurrency,
      'exchangeRate': exchangeRate,
      'month': month,
      'year': year,
      'categoryLimits': categoryLimits,
      'alertThreshold': alertThreshold,
    };
  }

  factory BudgetModel.fromMap(Map<String, dynamic> map) {
    return BudgetModel(
      monthlyLimit: (map['monthlyLimit'] as num?)?.toDouble() ?? 250000.0,
      currency: map['currency'] as String? ?? 'ر.ي',
      categoryCurrency: map['categoryCurrency'] as String? ?? 'ر.ي',
      exchangeRate: (map['exchangeRate'] as num?)?.toDouble() ?? 1.0,
      month: map['month'] as int? ?? DateTime.now().month,
      year: map['year'] as int? ?? DateTime.now().year,
      categoryLimits: (map['categoryLimits'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, (v as num).toDouble()),
          ) ??
          {},
      alertThreshold: (map['alertThreshold'] as num?)?.toDouble() ?? 0.80,
    );
  }

  BudgetModel copyWith({
    double? monthlyLimit,
    String? currency,
    String? categoryCurrency,
    double? exchangeRate,
    int? month,
    int? year,
    Map<String, double>? categoryLimits,
    double? alertThreshold,
  }) {
    return BudgetModel(
      monthlyLimit: monthlyLimit ?? this.monthlyLimit,
      currency: currency ?? this.currency,
      categoryCurrency: categoryCurrency ?? this.categoryCurrency,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      month: month ?? this.month,
      year: year ?? this.year,
      categoryLimits: categoryLimits ?? this.categoryLimits,
      alertThreshold: alertThreshold ?? this.alertThreshold,
    );
  }
}
