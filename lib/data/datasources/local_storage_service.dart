import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../models/transaction_model.dart';
import '../models/budget_model.dart';

class LocalStorageService {
  static const String _transactionsKey = 'app_transactions_v1';
  static const String _budgetKey = 'app_budget_v1';
  static const String _currencyKey = 'app_currency_symbol';
  static const String _themeKey = 'app_is_dark_theme';
  static const String _themeColorKey = 'app_theme_color_key';
  static const String _languageKey = 'app_language_code';

  Future<List<TransactionModel>> getTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_transactionsKey);
    if (data == null || data.isEmpty) {
      // Provide clean default sample data for first launch demonstration
      return _getInitialSeedTransactions();
    }
    try {
      final List<dynamic> decoded = jsonDecode(data) as List<dynamic>;
      return decoded
          .map((item) => TransactionModel.fromMap(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveTransactions(List<TransactionModel> transactions) async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> rawList =
        transactions.map((tx) => tx.toMap()).toList();
    await prefs.setString(_transactionsKey, jsonEncode(rawList));
  }

  Future<BudgetModel> getBudget() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_budgetKey);
    if (data == null || data.isEmpty) {
      final now = DateTime.now();
      return BudgetModel(
        monthlyLimit: 250000.0,
        currency: 'ر.ي',
        categoryCurrency: 'ر.ي',
        exchangeRate: 1.0,
        month: now.month,
        year: now.year,
        categoryLimits: const {
          'food': 60000.0,
          'transport': 30000.0,
          'shopping': 40000.0,
          'bills': 50000.0,
        },
      );
    }
    try {
      final Map<String, dynamic> decoded = jsonDecode(data) as Map<String, dynamic>;
      return BudgetModel.fromMap(decoded);
    } catch (e) {
      final now = DateTime.now();
      return BudgetModel(
        monthlyLimit: 250000.0,
        currency: 'ر.ي',
        categoryCurrency: 'ر.ي',
        exchangeRate: 1.0,
        month: now.month,
        year: now.year,
      );
    }
  }

  Future<void> saveBudget(BudgetModel budget) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_budgetKey, jsonEncode(budget.toMap()));
  }

  Future<String> getCurrencySymbol() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currencyKey) ?? 'ر.ي';
  }

  Future<void> saveCurrencySymbol(String symbol) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currencyKey, symbol);
  }

  Future<bool> getIsDarkTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_themeKey) ?? false;
  }

  Future<void> saveIsDarkTheme(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, isDark);
  }

  Future<String> getThemeColorKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_themeColorKey) ?? 'emerald_green';
  }

  Future<void> saveThemeColorKey(String colorKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeColorKey, colorKey);
  }

  Future<String> getLanguageCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_languageKey) ?? 'ar';
  }

  Future<void> saveLanguageCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, code);
  }

  List<TransactionModel> _getInitialSeedTransactions() {
    final now = DateTime.now();
    return [
      TransactionModel(
        id: 'seed-1',
        title: 'راتب هذا الشهر',
        amount: 3200.0,
        type: TransactionType.income,
        categoryId: 'salary',
        categoryName: 'راتب شهري',
        categoryIconCode: 0xe040, // Icons.account_balance_wallet
        categoryColorHex: 0xFF4CAF50,
        date: now.subtract(const Duration(days: 3)),
        notes: 'تم استلام الراتب الأساسي',
      ),
      TransactionModel(
        id: 'seed-2',
        title: 'تسوق وتموينات السوبرماركت',
        amount: 145.50,
        type: TransactionType.expense,
        categoryId: 'food',
        categoryName: 'طعام ومطاعم',
        categoryIconCode: 0xe532, // Icons.restaurant
        categoryColorHex: 0xFFFF5722,
        date: now.subtract(const Duration(days: 2)),
        notes: 'مشتريات خضروات ومواد غذائية',
      ),
      TransactionModel(
        id: 'seed-3',
        title: 'مشروع برمجي مستقل',
        amount: 650.0,
        type: TransactionType.income,
        categoryId: 'freelance',
        categoryName: 'عمل حر / مشاريع',
        categoryIconCode: 0xe378, // Icons.laptop_mac
        categoryColorHex: 0xFF00BCD4,
        date: now.subtract(const Duration(days: 1)),
        notes: 'دفعة أولى لتطبيق فلاتر',
      ),
      TransactionModel(
        id: 'seed-4',
        title: 'فاتورة الكهرباء والإنترنت',
        amount: 85.0,
        type: TransactionType.expense,
        categoryId: 'bills',
        categoryName: 'فواتير وخدمات',
        categoryIconCode: 0xe506, // Icons.receipt_long
        categoryColorHex: 0xFFE91E63,
        date: now.subtract(const Duration(hours: 5)),
        notes: 'سداد فواتير الشهر',
      ),
      TransactionModel(
        id: 'seed-5',
        title: 'وقود ومواصلات',
        amount: 40.0,
        type: TransactionType.expense,
        categoryId: 'transport',
        categoryName: 'مواصلات ونقل',
        categoryIconCode: 0xe1d7, // Icons.directions_car
        categoryColorHex: 0xFF2196F3,
        date: now,
        notes: 'بنزين سيارة',
      ),
    ];
  }
}
