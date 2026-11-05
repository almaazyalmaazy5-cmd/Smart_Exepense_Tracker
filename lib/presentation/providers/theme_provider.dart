import 'package:flutter/material.dart';
import '../../domain/repositories/expense_repository.dart';

class ThemeProvider extends ChangeNotifier {
  final ExpenseRepository _repository;
  bool _isDark = false;

  ThemeProvider({required ExpenseRepository repository})
      : _repository = repository {
    _loadTheme();
  }

  bool get isDark => _isDark;
  ThemeMode get themeMode => _isDark ? ThemeMode.dark : ThemeMode.light;

  Future<void> _loadTheme() async {
    _isDark = await _repository.isDarkTheme();
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDark = !_isDark;
    await _repository.setDarkTheme(_isDark);
    notifyListeners();
  }
}
