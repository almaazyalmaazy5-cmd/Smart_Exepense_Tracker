import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/budget_model.dart';
import '../../data/models/transaction_model.dart';
import '../providers/budget_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/theme_picker_sheet.dart';

// ============================================================================
// الواجهة السادسة: الإعدادات (SettingsScreen)
// ----------------------------------------------------------------------------
// مطابقة للتصميم في الصورة وتضم جميع إعدادات التطبيق في مكان واحد:
//   [1] اللغة (العربية / الإنجليزية)
//   [2] الوضع الليلي والنهاري (Dark / Light Mode)
//   [3] ألوان ومظهر التطبيق (اختيار اللون المفضّل)
//   [4] العملة المستخدمة
//   [5] إدارة التصنيفات
//   [6] النسخ الاحتياطي واستعادة البيانات (JSON)
//   [7] تصدير البيانات (Excel / CSV)
//   [8] مسح جميع البيانات + حول التطبيق + زر مشاركة التطبيق
// ============================================================================

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  /// إرجاع اسم العملة العربية المقابل للرمز المختار
  String _currencyNameForSymbol(String symbol) {
    for (final c in AppConstants.currencies) {
      if (c['symbol'] == symbol) return c['name']!;
    }
    return symbol;
  }

  // ========== نافذة اختيار اللغة ==========
  void _showLanguagePicker(BuildContext context, ThemeProvider themeProv) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Text(
                'اختر لغة واتجاه الواجهة',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.language),
              title: const Text('العربية (RTL)'),
              trailing: themeProv.isArabic
                  ? Icon(Icons.check_circle,
                      color: themeProv.selectedColor.primary)
                  : null,
              onTap: () {
                themeProv.setLanguageCode('ar');
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.language),
              title: const Text('English (LTR)'),
              trailing: !themeProv.isArabic
                  ? Icon(Icons.check_circle,
                      color: themeProv.selectedColor.primary)
                  : null,
              onTap: () {
                themeProv.setLanguageCode('en');
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ========== نافذة اختيار العملة ==========
  void _showCurrencyPicker(BuildContext context, String currentSymbol) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor =
        Provider.of<ThemeProvider>(context, listen: false).selectedColor.primary;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Text(
                  'اختر عملة التطبيق',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(),
              ...AppConstants.currencies.map((curr) {
                final isSelected = curr['symbol'] == currentSymbol;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isSelected
                        ? primaryColor
                        : Colors.grey.withAlpha(45),
                    child: Text(
                      curr['symbol']!,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : (isDark ? Colors.white : Colors.black87),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  title: Text(
                    curr['name']!,
                    style: TextStyle(
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  trailing: Text(
                    curr['code']!,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  onTap: () {
                    Provider.of<ExpenseProvider>(context, listen: false)
                        .setCurrency(curr['symbol']!);
                    Navigator.pop(ctx);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  // ========== نافذة عرض وإدارة التصنيفات ==========
  void _showCategoriesOverview(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha(110),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'تصنيفات التطبيق',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),
            const Text(
              'تصنيفات المصروفات',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.expenseColor,
              ),
            ),
            const SizedBox(height: 8),
            ...AppConstants.expenseCategories.map(
              (cat) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: cat.color.withAlpha(isDark ? 55 : 32),
                  child: Icon(cat.icon, color: cat.color, size: 20),
                ),
                title: Text(cat.name),
                subtitle: Text(cat.nameEn, style: const TextStyle(fontSize: 12)),
              ),
            ),
            const Divider(height: 24),
            const Text(
              'تصنيفات الدخل',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.incomeColor,
              ),
            ),
            const SizedBox(height: 8),
            ...AppConstants.incomeCategories.map(
              (cat) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: cat.color.withAlpha(isDark ? 55 : 32),
                  child: Icon(cat.icon, color: cat.color, size: 20),
                ),
                title: Text(cat.name),
                subtitle: Text(cat.nameEn, style: const TextStyle(fontSize: 12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========== نافذة النسخ الاحتياطي والاستعادة (JSON) ==========
  void _showBackupRestoreDialog(BuildContext context) {
    final expenseProv = Provider.of<ExpenseProvider>(context, listen: false);
    final budgetProv = Provider.of<BudgetProvider>(context, listen: false);

    final backupJson = const JsonEncoder.withIndent('  ').convert({
      'app': AppConstants.appName,
      'exportedAt': DateTime.now().toIso8601String(),
      'budget': budgetProv.budget.toMap(),
      'transactions': expenseProv.transactions.map((t) => t.toMap()).toList(),
    });

    showDialog(
      context: context,
      builder: (ctx) => _BackupRestoreDialog(backupJson: backupJson),
    );
  }

  // ========== نافذة تصدير البيانات بصيغة CSV (لـ Excel) ==========
  void _showExportCsvDialog(BuildContext context) {
    final expenseProv = Provider.of<ExpenseProvider>(context, listen: false);
    final buffer = StringBuffer();
    buffer.writeln('التاريخ,النوع,العملية,التصنيف,المبلغ,طريقة الدفع,الملاحظات');

    for (final tx in expenseProv.transactions) {
      final typeLabel = tx.isExpense ? 'مصروف' : 'دخل';
      final payment =
          AppConstants.getPaymentMethod(tx.paymentMethod)?.nameAr ?? '-';
      final safeTitle = tx.title.replaceAll(',', ' ');
      final safeNotes = (tx.notes ?? '').replaceAll(',', ' ').replaceAll('\n', ' ');
      buffer.writeln(
        '${tx.date.toIso8601String()},$typeLabel,$safeTitle,${tx.categoryName},${tx.amount},$payment,$safeNotes',
      );
    }

    final csvText = buffer.toString();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('تصدير البيانات (Excel / CSV)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'تم تجهيز ${expenseProv.transactions.length} عملية بصيغة CSV قابلة للفتح مباشرة في Excel أو Google Sheets.',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              height: 130,
              width: double.maxFinite,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  csvText,
                  style: const TextStyle(fontSize: 11.5, fontFamily: 'monospace'),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إغلاق'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.copy_rounded, size: 18),
            label: const Text('نسخ CSV'),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: csvText));
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تم نسخ ملف CSV إلى الحافظة بنجاح ✅'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ========== نافذة تأكيد مسح جميع البيانات ==========
  Future<void> _confirmClearAllData(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('مسح جميع العمليات'),
        content: const Text(
          'هل أنت متأكد من حذف جميع العمليات المسجلة والبدء من الصفر؟ لا يمكن التراجع عن هذه الخطوة.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.expenseColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('نعم، امسح الكل'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await Provider.of<ExpenseProvider>(context, listen: false)
          .clearAllTransactions();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم مسح جميع العمليات بنجاح')),
      );
    }
  }

  // ========== نافذة حول التطبيق ==========
  void _showAboutAppDialog(BuildContext context, Color primaryColor) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryColor.withAlpha(30),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.bar_chart_rounded, color: primaryColor),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                AppConstants.appName,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('الإصدار: ${AppConstants.appVersion}'),
            SizedBox(height: 8),
            Text(
              'تطبيق ذكي وخفيف لإدارة المصاريف والدخل والميزانية الشهرية، يعمل بدون إنترنت مع تحليلات ورسوم بيانية تفاعلية.',
              style: TextStyle(fontSize: 13.5, height: 1.45),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final expenseProv = Provider.of<ExpenseProvider>(context);
    final themeProv = Provider.of<ThemeProvider>(context);
    final primaryColor = themeProv.selectedColor.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 95),
        children: [
          // ================================================================
          // بطاقة الإعدادات الرئيسية (مطابقة لترتيب الصورة تماماً)
          // ================================================================
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(isDark ? 30 : 10),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                // [1] اللغة
                ListTile(
                  leading: Icon(Icons.language_rounded, color: primaryColor),
                  title: const Text(
                    'اللغة',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        themeProv.isArabic ? 'العربية' : 'English',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.chevron_left_rounded, color: Colors.grey),
                    ],
                  ),
                  onTap: () => _showLanguagePicker(context, themeProv),
                ),
                const Divider(height: 1, indent: 56),

                // [2] الوضع الليلي والنهاري
                SwitchListTile(
                  secondary: Icon(
                    themeProv.isDark
                        ? Icons.dark_mode_rounded
                        : Icons.light_mode_rounded,
                    color: primaryColor,
                  ),
                  title: const Text(
                    'الوضع الليلي',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  value: themeProv.isDark,
                  activeThumbColor: primaryColor,
                  onChanged: (_) => themeProv.toggleTheme(),
                ),
                const Divider(height: 1, indent: 56),

                // [3] ألوان ومظهر التطبيق (طلبك الخاص!)
                ListTile(
                  leading: Icon(Icons.palette_outlined, color: primaryColor),
                  title: const Text(
                    'ألوان ومظهر التطبيق',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    themeProv.selectedColor.nameAr,
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: primaryColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.chevron_left_rounded, color: Colors.grey),
                    ],
                  ),
                  onTap: () => ThemePickerSheet.show(context),
                ),
                const Divider(height: 1, indent: 56),

                // [4] العملة
                ListTile(
                  leading: Icon(Icons.payments_outlined, color: primaryColor),
                  title: const Text(
                    'العملة',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _currencyNameForSymbol(expenseProv.currencySymbol),
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.chevron_left_rounded, color: Colors.grey),
                    ],
                  ),
                  onTap: () =>
                      _showCurrencyPicker(context, expenseProv.currencySymbol),
                ),
                const Divider(height: 1, indent: 56),

                // [5] إدارة التصنيفات
                ListTile(
                  leading: Icon(Icons.grid_view_rounded, color: primaryColor),
                  title: const Text(
                    'إدارة التصنيفات',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  trailing:
                      const Icon(Icons.chevron_left_rounded, color: Colors.grey),
                  onTap: () => _showCategoriesOverview(context),
                ),
                const Divider(height: 1, indent: 56),

                // [6] النسخ الاحتياطي واستعادة البيانات
                ListTile(
                  leading: Icon(Icons.cloud_sync_outlined, color: primaryColor),
                  title: const Text(
                    'النسخ الاحتياطي واستعادة البيانات',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  trailing:
                      const Icon(Icons.chevron_left_rounded, color: Colors.grey),
                  onTap: () => _showBackupRestoreDialog(context),
                ),
                const Divider(height: 1, indent: 56),

                // [7] تصدير البيانات (Excel / CSV)
                ListTile(
                  leading: Icon(Icons.download_rounded, color: primaryColor),
                  title: const Text(
                    'تصدير البيانات (Excel / CSV)',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  trailing:
                      const Icon(Icons.chevron_left_rounded, color: Colors.grey),
                  onTap: () => _showExportCsvDialog(context),
                ),
                const Divider(height: 1, indent: 56),

                // [8] حول التطبيق
                ListTile(
                  leading: Icon(Icons.info_outline_rounded, color: primaryColor),
                  title: const Text(
                    'حول التطبيق',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  trailing:
                      const Icon(Icons.chevron_left_rounded, color: Colors.grey),
                  onTap: () => _showAboutAppDialog(context, primaryColor),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // زر مسح جميع البيانات (اختياري للبدء من الصفر)
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.expenseColor,
              side: BorderSide(color: AppTheme.expenseColor.withAlpha(120)),
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.delete_sweep_outlined),
            label: const Text(
              'مسح جميع العمليات والبدء من جديد',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            onPressed: () => _confirmClearAllData(context),
          ),

          const SizedBox(height: 12),

          // زر مشاركة التطبيق (مطابق لأسفل الصورة)
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(14),
            ),
            child: TextButton.icon(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                foregroundColor: isDark ? Colors.white : const Color(0xFF1F2937),
              ),
              icon: const Icon(Icons.share_outlined, size: 20),
              label: const Text(
                'مشاركة التطبيق',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              onPressed: () async {
                await Clipboard.setData(
                  const ClipboardData(
                    text:
                        'جرّب تطبيق Smart Expense Tracker لإدارة المصاريف والميزانية الشهرية بذكاء وبسهولة!',
                  ),
                );
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم نسخ رسالة مشاركة التطبيق إلى الحافظة ✅'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// نافذة النسخ الاحتياطي والاستعادة (JSON Backup / Restore)
// ============================================================================
class _BackupRestoreDialog extends StatefulWidget {
  final String backupJson;

  const _BackupRestoreDialog({required this.backupJson});

  @override
  State<_BackupRestoreDialog> createState() => _BackupRestoreDialogState();
}

class _BackupRestoreDialogState extends State<_BackupRestoreDialog> {
  final TextEditingController _restoreController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _restoreController.dispose();
    super.dispose();
  }

  Future<void> _restoreFromJson() async {
    final raw = _restoreController.text.trim();
    if (raw.isEmpty) {
      setState(() => _error = 'الرجاء لصق نص النسخة الاحتياطية أولاً');
      return;
    }

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final txListRaw = decoded['transactions'] as List<dynamic>?;
      final budgetRaw = decoded['budget'] as Map<String, dynamic>?;

      if (txListRaw == null) {
        setState(() => _error = 'صيغة النسخة الاحتياطية غير صالحة');
        return;
      }

      final parsedTransactions = txListRaw
          .map((item) => TransactionModel.fromMap(item as Map<String, dynamic>))
          .toList();

      await Provider.of<ExpenseProvider>(context, listen: false)
          .replaceAllTransactions(parsedTransactions);

      if (budgetRaw != null && mounted) {
        final restoredBudget = BudgetModel.fromMap(budgetRaw);
        await Provider.of<BudgetProvider>(context, listen: false)
            .updateAllBudgets(
          monthlyLimit: restoredBudget.monthlyLimit,
          currency: restoredBudget.currency,
          categoryCurrency: restoredBudget.categoryCurrency,
          exchangeRate: restoredBudget.exchangeRate,
          categoryLimits: restoredBudget.categoryLimits,
        );
      }

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تمت استعادة ${parsedTransactions.length} عملية بنجاح ✅',
          ),
        ),
      );
    } catch (_) {
      setState(() => _error = 'تعذّر قراءة النص؛ تأكد أنه نسخة احتياطية JSON صالحة');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('النسخ الاحتياطي والاستعادة'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '1. نسخ بياناتك الحالية احتياطياً (JSON):',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: const Text('نسخ النسخة الاحتياطية'),
                onPressed: () async {
                  await Clipboard.setData(
                    ClipboardData(text: widget.backupJson),
                  );
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم نسخ النسخة الاحتياطية إلى الحافظة ✅'),
                    ),
                  );
                },
              ),
            ),
            const Divider(height: 24),
            const Text(
              '2. استعادة من نسخة احتياطية سابقة:',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _restoreController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'الصق نص JSON هنا...',
                errorText: _error,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إغلاق'),
        ),
        ElevatedButton(
          onPressed: _restoreFromJson,
          child: const Text('استعادة'),
        ),
      ],
    );
  }
}
