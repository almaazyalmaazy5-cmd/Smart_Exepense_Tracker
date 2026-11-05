import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'data/datasources/local_storage_service.dart';
import 'data/repositories/expense_repository_impl.dart';
import 'domain/repositories/expense_repository.dart';
import 'presentation/providers/budget_provider.dart';
import 'presentation/providers/expense_provider.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/screens/main_navigation_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final LocalStorageService storageService = LocalStorageService();
  final ExpenseRepository repository =
      ExpenseRepositoryImpl(storageService: storageService);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ExpenseProvider(repository: repository),
        ),
        ChangeNotifierProvider(
          create: (_) => BudgetProvider(repository: repository),
        ),
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(repository: repository),
        ),
      ],
      child: const SmartExpenseApp(),
    ),
  );
}

class SmartExpenseApp extends StatelessWidget {
  const SmartExpenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Smart Expense Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      builder: (context, child) {
        // Enforce Arabic RTL layout for clean readability
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
      home: const MainNavigationScreen(),
    );
  }
}
