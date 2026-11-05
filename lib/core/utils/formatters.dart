import 'package:intl/intl.dart';

class Formatters {
  static String formatCurrency(double amount, {String symbol = r'$'}) {
    final formatter = NumberFormat.currency(
      symbol: '$symbol ',
      decimalDigits: amount.truncateToDouble() == amount ? 0 : 2,
    );
    return formatter.format(amount);
  }

  static String formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final checkDate = DateTime(date.year, date.month, date.day);

    if (checkDate == today) {
      return 'اليوم (${DateFormat('hh:mm a').format(date)})';
    } else if (checkDate == yesterday) {
      return 'أمس (${DateFormat('hh:mm a').format(date)})';
    } else {
      return DateFormat('yyyy/MM/dd • hh:mm a').format(date);
    }
  }

  static String formatShortDate(DateTime date) {
    return DateFormat('d MMM').format(date);
  }

  static String formatMonthYear(DateTime date) {
    return DateFormat('MMMM yyyy').format(date);
  }
}
