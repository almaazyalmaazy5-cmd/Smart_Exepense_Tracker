import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/repositories/expense_repository.dart';

// ============================================================================
// مزوّد حالة المظهر والألوان واللغة (ThemeProvider)
// ----------------------------------------------------------------------------
// يدير التبديل بين الوضع النهاري (Light) والداكن (Dark)،
// اختيار لون التطبيق الرئيسي المفضّل، ولغة/اتجاه الواجهة (RTL / LTR).
// ============================================================================

class ThemeProvider extends ChangeNotifier {
  final ExpenseRepository _repository;
  bool _isDark = false;
  String _themeColorKey = 'emerald_green';
  String _languageCode = 'ar';

  ThemeProvider({required ExpenseRepository repository})
      : _repository = repository {
    _loadTheme();
  }

  bool get isDark => _isDark;
  ThemeMode get themeMode => _isDark ? ThemeMode.dark : ThemeMode.light;
  String get themeColorKey => _themeColorKey;
  String get languageCode => _languageCode;
  bool get isArabic => _languageCode == 'ar';
  TextDirection get textDirection =>
      isArabic ? TextDirection.rtl : TextDirection.ltr;

  /// كائن اللون المختار حالياً (الأخضر الداكن، الأزرق، البنفسجي...)
  AppColorOption get selectedColor => AppTheme.getColorOption(_themeColorKey);

  Future<void> _loadTheme() async {
    _isDark = await _repository.isDarkTheme();
    _themeColorKey = await _repository.getThemeColor();
    _languageCode = await _repository.getLanguageCode();
    notifyListeners();
  }

  /// التبديل بين الوضع النهاري والوضع الداكن
  Future<void> toggleTheme() async {
    _isDark = !_isDark;
    await _repository.setDarkTheme(_isDark);
    notifyListeners();
  }

  /// تعيين الوضع الداكن أو النهاري بشكل صريح
  Future<void> setDarkMode(bool isDark) async {
    if (_isDark == isDark) return;
    _isDark = isDark;
    await _repository.setDarkTheme(_isDark);
    notifyListeners();
  }

  /// تغيير لون التطبيق الرئيسي وحفظه
  Future<void> setThemeColor(String colorKey) async {
    if (_themeColorKey == colorKey) return;
    _themeColorKey = colorKey;
    await _repository.setThemeColor(colorKey);
    notifyListeners();
  }

  /// تغيير لغة التطبيق (ar / en) وحفظها
  Future<void> setLanguageCode(String code) async {
    if (_languageCode == code) return;
    _languageCode = code;
    await _repository.setLanguageCode(code);
    notifyListeners();
  }
}
