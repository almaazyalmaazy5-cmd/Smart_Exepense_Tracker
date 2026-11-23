import 'package:intl/intl.dart';

// ============================================================================
// ملف تنسيق الأرقام والعملات والتواريخ (Formatters)
// ----------------------------------------------------------------------------
// مسؤول عن عرض المبالغ مع الفواصل والعملة، وعرض التاريخ والوقت بصيغة عربية واضحة.
// ============================================================================

class Formatters {
  /// أسماء الأشهر الميلادية بالعربية لعرض عناوين الأيام والتقارير بوضوح
  static const List<String> arabicMonths = [
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ];

  /// تنسيق عنوان اليوم لتجميع العمليات في شاشة سجل العمليات
  /// مثال: "اليوم - 20 نوفمبر 2026" أو "أمس - 19 نوفمبر 2026"
  static String formatArabicDayHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final checkDate = DateTime(date.year, date.month, date.day);

    final monthName = arabicMonths[date.month - 1];
    final datePart = '${date.day} $monthName ${date.year}';

    if (checkDate == today) return 'اليوم - $datePart';
    if (checkDate == yesterday) return 'أمس - $datePart';
    return datePart;
  }

  /// تنسيق المبلغ المالي (مثال: 25,000 ر.ي أو 145.50 $)
  static String formatCurrency(double amount, {String symbol = r'$'}) {
    final bool isWhole = amount.truncateToDouble() == amount;
    final formattedNumber = NumberFormat(isWhole ? '#,##0' : '#,##0.00').format(amount);
    return '$formattedNumber $symbol';
  }

  /// تنسيق الرقم فقط بدون رمز العملة (مثال: 25,000)
  static String formatNumberOnly(double amount) {
    final bool isWhole = amount.truncateToDouble() == amount;
    return NumberFormat(isWhole ? '#,##0' : '#,##0.00').format(amount);
  }

  /// تنسيق الوقت بصيغة عربية (مثال: 09:30 م أو 08:00 ص)
  static String formatTimeArabic(DateTime date) {
    final hour12 = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'م' : 'ص';
    return '${hour12.toString().padLeft(2, '0')}:$minute $period';
  }

  /// تنسيق التاريخ والوقت بشكل ذكي (اليوم / أمس / تاريخ كامل)
  static String formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final checkDate = DateTime(date.year, date.month, date.day);

    if (checkDate == today) {
      return 'اليوم • ${formatTimeArabic(date)}';
    } else if (checkDate == yesterday) {
      return 'أمس • ${formatTimeArabic(date)}';
    } else {
      final month = date.month.toString().padLeft(2, '0');
      final day = date.day.toString().padLeft(2, '0');
      return '${date.year}/$month/$day • ${formatTimeArabic(date)}';
    }
  }

  /// تنسيق مختصر للتاريخ (اليوم / أمس / يوم/شهر) لبطاقة آخر العمليات
  static String formatRelativeDay(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final checkDate = DateTime(date.year, date.month, date.day);

    if (checkDate == today) return 'اليوم';
    if (checkDate == yesterday) return 'أمس';
    return '${date.day}/${date.month}/${date.year}';
  }

  static String formatShortDate(DateTime date) {
    return DateFormat('d MMM').format(date);
  }

  static String formatMonthYear(DateTime date) {
    return DateFormat('MMMM yyyy').format(date);
  }
}
