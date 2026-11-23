import 'package:flutter/material.dart';

// ============================================================================
// ملف الألوان والمظهر العام للتطبيق (AppTheme)
// ----------------------------------------------------------------------------
// لتغيير لون التطبيق الافتراضي أو إضافة لون جديد، عدّل قائمة [colorOptions]
// هنا فقط، وسيتغير اللون تلقائياً في جميع شاشات التطبيق.
// ============================================================================

/// نموذج يمثل خيار لون رئيسي يمكن للمستخدم اختياره من الإعدادات أو الشاشة الرئيسية
class AppColorOption {
  final String key;
  final String nameAr;
  final String nameEn;
  final Color primary;
  final Color primaryLight;
  final Color primaryDark;

  const AppColorOption({
    required this.key,
    required this.nameAr,
    required this.nameEn,
    required this.primary,
    required this.primaryLight,
    required this.primaryDark,
  });
}

class AppTheme {
  // ========== [1] الألوان الثابتة للدخل والمصروفات ==========
  static const Color expenseColor = Color(0xFFDC2626); // أحمر للمصروفات
  static const Color incomeColor = Color(0xFF15803D); // أخضر للدخل
  static const Color warningColor = Color(0xFFF59E0B); // برتقالي للتحذير (80%+)

  // ألوان افتراضية (للتوافق مع بقية الملفات)
  static const Color primaryColor = Color(0xFF0E6B3C); // الأخضر الداكن (لون التصميم)
  static const Color primaryLight = Color(0xFF198754);

  // ========== [2] قائمة الألوان التي يمكن للمستخدم الاختيار منها ==========
  static const List<AppColorOption> colorOptions = [
    AppColorOption(
      key: 'emerald_green',
      nameAr: 'الأخضر الداكن (الافتراضي)',
      nameEn: 'Dark Green',
      primary: Color(0xFF0E6B3C),
      primaryLight: Color(0xFF1B8A52),
      primaryDark: Color(0xFF084C29),
    ),
    AppColorOption(
      key: 'modern_teal',
      nameAr: 'التركوازي الحديث',
      nameEn: 'Modern Teal',
      primary: Color(0xFF0F766E),
      primaryLight: Color(0xFF14B8A6),
      primaryDark: Color(0xFF115E59),
    ),
    AppColorOption(
      key: 'ocean_blue',
      nameAr: 'الأزرق الملكي',
      nameEn: 'Ocean Blue',
      primary: Color(0xFF1D4ED8),
      primaryLight: Color(0xFF3B82F6),
      primaryDark: Color(0xFF1E3A8A),
    ),
    AppColorOption(
      key: 'royal_purple',
      nameAr: 'البنفسجي الفاخر',
      nameEn: 'Royal Purple',
      primary: Color(0xFF6D28D9),
      primaryLight: Color(0xFF8B5CF6),
      primaryDark: Color(0xFF4C1D95),
    ),
    AppColorOption(
      key: 'warm_orange',
      nameAr: 'البرتقالي الدافئ',
      nameEn: 'Warm Orange',
      primary: Color(0xFFC2410C),
      primaryLight: Color(0xFFF97316),
      primaryDark: Color(0xFF9A3412),
    ),
    AppColorOption(
      key: 'crimson_rose',
      nameAr: 'العنابي الأنيق',
      nameEn: 'Crimson Rose',
      primary: Color(0xFFBE123C),
      primaryLight: Color(0xFFF43F5E),
      primaryDark: Color(0xFF881337),
    ),
  ];

  /// إرجاع خيار اللون حسب المفتاح المحفوظ (الافتراضي: الأخضر الداكن)
  static AppColorOption getColorOption(String key) {
    return colorOptions.firstWhere(
      (option) => option.key == key,
      orElse: () => colorOptions.first,
    );
  }

  // ========== [3] الوضع النهاري (Light Theme) ==========
  static ThemeData lightTheme(AppColorOption colorOption) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: colorOption.primary,
        brightness: Brightness.light,
        primary: colorOption.primary,
        secondary: colorOption.primaryLight,
        surface: Colors.white,
        surfaceContainerHighest: const Color(0xFFE5E7EB),
      ),
      // خلفية رمادية فاتحة جداً حسب الهوية البصرية
      scaffoldBackgroundColor: const Color(0xFFF4F6F8),
      fontFamily: 'Roboto',
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: colorOption.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        elevation: 1.5,
        shadowColor: Colors.black.withAlpha(18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        color: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorOption.primary, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          backgroundColor: colorOption.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // ========== [4] الوضع الداكن (Dark Theme) ==========
  static ThemeData darkTheme(AppColorOption colorOption) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: colorOption.primary,
        brightness: Brightness.dark,
        primary: colorOption.primaryLight,
        secondary: colorOption.primary,
        surface: const Color(0xFF1E293B),
        surfaceContainerHighest: const Color(0xFF334155),
      ),
      scaffoldBackgroundColor: const Color(0xFF0F172A),
      fontFamily: 'Roboto',
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: colorOption.primaryDark,
        foregroundColor: Colors.white,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shadowColor: Colors.black.withAlpha(50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        color: const Color(0xFF1E293B),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1E293B),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF475569)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF334155)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorOption.primaryLight, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          backgroundColor: colorOption.primaryLight,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
