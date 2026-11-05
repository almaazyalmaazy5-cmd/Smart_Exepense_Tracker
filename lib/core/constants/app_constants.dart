import 'package:flutter/material.dart';

enum TransactionType { expense, income }

class AppConstants {
  static const String appName = 'Smart Expense Tracker';
  static const String appVersion = '1.0.0';

  // Supported Currencies
  static const List<Map<String, String>> currencies = [
    {'code': 'USD', 'symbol': r'$', 'name': 'US Dollar'},
    {'code': 'SAR', 'symbol': 'ر.س', 'name': 'Saudi Riyal'},
    {'code': 'YER', 'symbol': 'ر.ي', 'name': 'Yemeni Rial'},
    {'code': 'AED', 'symbol': 'د.إ', 'name': 'UAE Dirham'},
    {'code': 'EGP', 'symbol': 'ج.م', 'name': 'Egyptian Pound'},
    {'code': 'EUR', 'symbol': '€', 'name': 'Euro'},
  ];

  // Default Categories with Icons and Colors (using final so .codePoint can be accessed)
  static final List<Map<String, dynamic>> defaultExpenseCategories = [
    {
      'id': 'food',
      'name': 'طعام ومطاعم',
      'nameEn': 'Food & Dining',
      'iconCode': Icons.restaurant.codePoint,
      'colorHex': 0xFFFF5722, // Deep Orange
    },
    {
      'id': 'transport',
      'name': 'مواصلات ونقل',
      'nameEn': 'Transportation',
      'iconCode': Icons.directions_car.codePoint,
      'colorHex': 0xFF2196F3, // Blue
    },
    {
      'id': 'shopping',
      'name': 'تسوق وملابس',
      'nameEn': 'Shopping',
      'iconCode': Icons.shopping_bag.codePoint,
      'colorHex': 0xFF9C27B0, // Purple
    },
    {
      'id': 'bills',
      'name': 'فواتير وخدمات',
      'nameEn': 'Bills & Utilities',
      'iconCode': Icons.receipt_long.codePoint,
      'colorHex': 0xFFE91E63, // Pink
    },
    {
      'id': 'housing',
      'name': 'سكن وإيجار',
      'nameEn': 'Housing & Rent',
      'iconCode': Icons.home.codePoint,
      'colorHex': 0xFF795548, // Brown
    },
    {
      'id': 'health',
      'name': 'صحة وأدوية',
      'nameEn': 'Health & Medical',
      'iconCode': Icons.local_hospital.codePoint,
      'colorHex': 0xFF009688, // Teal
    },
    {
      'id': 'entertainment',
      'name': 'ترفيه وأنشطة',
      'nameEn': 'Entertainment',
      'iconCode': Icons.movie.codePoint,
      'colorHex': 0xFFFF9800, // Orange
    },
    {
      'id': 'education',
      'name': 'تعليم ودورات',
      'nameEn': 'Education',
      'iconCode': Icons.school.codePoint,
      'colorHex': 0xFF3F51B5, // Indigo
    },
    {
      'id': 'other_expense',
      'name': 'أخرى',
      'nameEn': 'Other',
      'iconCode': Icons.more_horiz.codePoint,
      'colorHex': 0xFF607D8B, // Blue Grey
    },
  ];

  static final List<Map<String, dynamic>> defaultIncomeCategories = [
    {
      'id': 'salary',
      'name': 'راتب شهري',
      'nameEn': 'Salary',
      'iconCode': Icons.account_balance_wallet.codePoint,
      'colorHex': 0xFF4CAF50, // Green
    },
    {
      'id': 'freelance',
      'name': 'عمل حر / مشاريع',
      'nameEn': 'Freelance',
      'iconCode': Icons.laptop_mac.codePoint,
      'colorHex': 0xFF00BCD4, // Cyan
    },
    {
      'id': 'investment',
      'name': 'استثمارات وأرباح',
      'nameEn': 'Investment',
      'iconCode': Icons.trending_up.codePoint,
      'colorHex': 0xFF8BC34A, // Light Green
    },
    {
      'id': 'gift',
      'name': 'مكافآت وهدايا',
      'nameEn': 'Gift / Bonus',
      'iconCode': Icons.card_giftcard.codePoint,
      'colorHex': 0xFFFFC107, // Amber
    },
    {
      'id': 'other_income',
      'name': 'دخل إضافي',
      'nameEn': 'Other Income',
      'iconCode': Icons.attach_money.codePoint,
      'colorHex': 0xFF607D8B, // Blue Grey
    },
  ];
}
