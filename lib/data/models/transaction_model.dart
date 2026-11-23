import '../../core/constants/app_constants.dart';

// ============================================================================
// نموذج المعاملة المالية (TransactionModel)
// ----------------------------------------------------------------------------
// يمثّل كل عملية دخل أو مصروف مع تصنيفها، تاريخها، طريقة الدفع، والملاحظات.
// ============================================================================

class TransactionModel {
  final String id;
  final String title;
  final double amount;
  final TransactionType type;
  final String categoryId;
  final String categoryName;
  final int categoryIconCode;
  final int categoryColorHex;
  final DateTime date;
  final String? paymentMethod; // 'cash' | 'bank_transfer' | 'e_wallet'
  final String? notes;

  TransactionModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.categoryName,
    required this.categoryIconCode,
    required this.categoryColorHex,
    required this.date,
    this.paymentMethod,
    this.notes,
  });

  bool get isExpense => type == TransactionType.expense;
  bool get isIncome => type == TransactionType.income;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'type': type.name,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'categoryIconCode': categoryIconCode,
      'categoryColorHex': categoryColorHex,
      'date': date.toIso8601String(),
      'paymentMethod': paymentMethod,
      'notes': notes,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as String,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      type: TransactionType.values.byName(map['type'] as String),
      categoryId: map['categoryId'] as String,
      categoryName: map['categoryName'] as String,
      categoryIconCode: map['categoryIconCode'] as int,
      categoryColorHex: map['categoryColorHex'] as int,
      date: DateTime.parse(map['date'] as String),
      paymentMethod: map['paymentMethod'] as String?,
      notes: map['notes'] as String?,
    );
  }

  TransactionModel copyWith({
    String? id,
    String? title,
    double? amount,
    TransactionType? type,
    String? categoryId,
    String? categoryName,
    int? categoryIconCode,
    int? categoryColorHex,
    DateTime? date,
    String? paymentMethod,
    String? notes,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      categoryIconCode: categoryIconCode ?? this.categoryIconCode,
      categoryColorHex: categoryColorHex ?? this.categoryColorHex,
      date: date ?? this.date,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
    );
  }
}
