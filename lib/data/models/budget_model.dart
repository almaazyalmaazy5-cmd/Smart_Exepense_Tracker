class BudgetModel {
  final double monthlyLimit;
  final int month;
  final int year;
  final Map<String, double> categoryLimits;
  final double alertThreshold; // Default 0.8 (80%)

  BudgetModel({
    required this.monthlyLimit,
    required this.month,
    required this.year,
    this.categoryLimits = const {},
    this.alertThreshold = 0.80,
  });

  Map<String, dynamic> toMap() {
    return {
      'monthlyLimit': monthlyLimit,
      'month': month,
      'year': year,
      'categoryLimits': categoryLimits,
      'alertThreshold': alertThreshold,
    };
  }

  factory BudgetModel.fromMap(Map<String, dynamic> map) {
    return BudgetModel(
      monthlyLimit: (map['monthlyLimit'] as num?)?.toDouble() ?? 2000.0,
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
    int? month,
    int? year,
    Map<String, double>? categoryLimits,
    double? alertThreshold,
  }) {
    return BudgetModel(
      monthlyLimit: monthlyLimit ?? this.monthlyLimit,
      month: month ?? this.month,
      year: year ?? this.year,
      categoryLimits: categoryLimits ?? this.categoryLimits,
      alertThreshold: alertThreshold ?? this.alertThreshold,
    );
  }
}
