import 'package:flutter/material.dart';
import '../../data/models/category_model.dart';

// ============================================================================
// ملف الثوابت والتصنيفات وطرق الدفع والعملات (AppConstants)
// ----------------------------------------------------------------------------
// لتعديل اسم التطبيق، إضافة عملة، إضافة تصنيف، أو تعديل طرق الدفع: عدّل هنا فقط.
// ============================================================================

enum TransactionType { expense, income }

/// نموذج بسيط لطريقة الدفع (نقداً / تحويل بنكي / محفظة إلكترونية)
class PaymentMethodOption {
  final String id;
  final String nameAr;
  final String nameEn;
  final IconData icon;

  const PaymentMethodOption({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.icon,
  });
}

class AppConstants {
  // ========== [1] معلومات التطبيق الأساسية ==========
  static const String appName = 'Smart Expense Tracker';
  static const String appTagline = 'تحكم في أموالك .. لمستقبل أفضل';
  static const String appVersion = '1.0.0';

  // ========== [2] العملات المدعومة ==========
  static const List<Map<String, String>> currencies = [
    {'code': 'YER', 'symbol': 'ر.ي', 'name': 'ريال يمني'},
    {'code': 'SAR', 'symbol': 'ر.س', 'name': 'ريال سعودي'},
    {'code': 'USD', 'symbol': r'$', 'name': 'دولار أمريكي'},
    {'code': 'AED', 'symbol': 'د.إ', 'name': 'درهم إماراتي'},
    {'code': 'EGP', 'symbol': 'ج.م', 'name': 'جنيه مصري'},
    {'code': 'EUR', 'symbol': '€', 'name': 'يورو'},
  ];

  // ========== [3] طرق الدفع المتاحة (اختياري في شاشة إضافة عملية) ==========
  static const List<PaymentMethodOption> paymentMethods = [
    PaymentMethodOption(
      id: 'cash',
      nameAr: 'نقداً',
      nameEn: 'Cash',
      icon: Icons.payments_outlined,
    ),
    PaymentMethodOption(
      id: 'bank_transfer',
      nameAr: 'تحويل بنكي',
      nameEn: 'Bank Transfer',
      icon: Icons.account_balance_outlined,
    ),
    PaymentMethodOption(
      id: 'e_wallet',
      nameAr: 'محفظة إلكترونية',
      nameEn: 'E-Wallet',
      icon: Icons.smartphone_outlined,
    ),
  ];

  /// إرجاع طريقة الدفع حسب المعرّف (أو null إن لم تُحدد)
  static PaymentMethodOption? getPaymentMethod(String? id) {
    if (id == null || id.isEmpty) return null;
    for (final method in paymentMethods) {
      if (method.id == id) return method;
    }
    return null;
  }

  // ========== [4] خريطة الأيقونات الثابتة (مهمة لنجاح بناء Release) ==========
  static const Map<String, IconData> categoryIcons = {
    'food': Icons.restaurant,
    'transport': Icons.directions_car,
    'shopping': Icons.shopping_cart,
    'bills': Icons.receipt_long,
    'housing': Icons.home,
    'health': Icons.favorite,
    'entertainment': Icons.movie,
    'education': Icons.school,
    'other_expense': Icons.more_horiz,
    'salary': Icons.work,
    'freelance': Icons.laptop_mac,
    'investment': Icons.trending_up,
    'gift': Icons.card_giftcard,
    'other_income': Icons.attach_money,
  };

  /// دالة آمنة لإرجاع أيقونة التصنيف بدون كسر ميزة تقليم الأيقونات في Flutter
  static IconData getCategoryIcon(String categoryId) {
    return categoryIcons[categoryId] ?? Icons.category_outlined;
  }

  // ========== [5] تصنيفات المصروفات الافتراضية (باستخدام CategoryModel) ==========
  static const List<CategoryModel> expenseCategories = [
    CategoryModel(
      id: 'food',
      name: 'الطعام',
      nameEn: 'Food & Dining',
      icon: Icons.restaurant,
      color: Color(0xFFE53935),
      isExpense: true,
    ),
    CategoryModel(
      id: 'transport',
      name: 'المواصلات',
      nameEn: 'Transportation',
      icon: Icons.directions_car,
      color: Color(0xFF1E88E5),
      isExpense: true,
    ),
    CategoryModel(
      id: 'shopping',
      name: 'التسوق',
      nameEn: 'Shopping',
      icon: Icons.shopping_cart,
      color: Color(0xFFFB8C00),
      isExpense: true,
    ),
    CategoryModel(
      id: 'bills',
      name: 'الفواتير',
      nameEn: 'Bills & Utilities',
      icon: Icons.receipt_long,
      color: Color(0xFF8E24AA),
      isExpense: true,
    ),
    CategoryModel(
      id: 'health',
      name: 'الصحة',
      nameEn: 'Health & Medical',
      icon: Icons.favorite,
      color: Color(0xFF00897B),
      isExpense: true,
    ),
    CategoryModel(
      id: 'education',
      name: 'التعليم',
      nameEn: 'Education',
      icon: Icons.school,
      color: Color(0xFF3949AB),
      isExpense: true,
    ),
    CategoryModel(
      id: 'housing',
      name: 'السكن',
      nameEn: 'Housing & Rent',
      icon: Icons.home,
      color: Color(0xFF6D4C41),
      isExpense: true,
    ),
    CategoryModel(
      id: 'other_expense',
      name: 'أخرى',
      nameEn: 'Other',
      icon: Icons.more_horiz,
      color: Color(0xFF546E7A),
      isExpense: true,
    ),
  ];

  // ========== [6] تصنيفات الدخل الافتراضية (باستخدام CategoryModel) ==========
  static const List<CategoryModel> incomeCategories = [
    CategoryModel(
      id: 'salary',
      name: 'الراتب',
      nameEn: 'Salary',
      icon: Icons.work,
      color: Color(0xFF15803D),
      isExpense: false,
    ),
    CategoryModel(
      id: 'freelance',
      name: 'أعمال إضافية',
      nameEn: 'Freelance',
      icon: Icons.laptop_mac,
      color: Color(0xFF0284C7),
      isExpense: false,
    ),
    CategoryModel(
      id: 'investment',
      name: 'استثمارات',
      nameEn: 'Investment',
      icon: Icons.trending_up,
      color: Color(0xFF65A30D),
      isExpense: false,
    ),
    CategoryModel(
      id: 'gift',
      name: 'مكافآت وهدايا',
      nameEn: 'Gift / Bonus',
      icon: Icons.card_giftcard,
      color: Color(0xFFD97706),
      isExpense: false,
    ),
    CategoryModel(
      id: 'other_income',
      name: 'دخل إضافي',
      nameEn: 'Other Income',
      icon: Icons.attach_money,
      color: Color(0xFF546E7A),
      isExpense: false,
    ),
  ];

  /// إرجاع جميع التصنيفات (مصروفات + دخل)
  static List<CategoryModel> get allCategories => [
        ...expenseCategories,
        ...incomeCategories,
      ];

  /// البحث عن تصنيف بالمعرّف
  static CategoryModel? findCategoryById(String id) {
    for (final cat in allCategories) {
      if (cat.id == id) return cat;
    }
    return null;
  }

  // للتوافق مع أي كود قديم يستخدم القوائم بصيغة Map
  static List<Map<String, dynamic>> get defaultExpenseCategories =>
      expenseCategories.map((c) => c.toMap()).toList();

  static List<Map<String, dynamic>> get defaultIncomeCategories =>
      incomeCategories.map((c) => c.toMap()).toList();
}
