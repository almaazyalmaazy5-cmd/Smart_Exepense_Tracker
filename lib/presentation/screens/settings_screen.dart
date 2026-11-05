import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../providers/expense_provider.dart';
import '../providers/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _showCurrencyPicker(BuildContext context, String currentSymbol) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey.withAlpha(50),
                    child: Text(
                      curr['symbol']!,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final expenseProv = Provider.of<ExpenseProvider>(context);
    final themeProv = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات ومعلومات التطبيق'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Section 1: Preferences
          const Text(
            'تفضيلات الواجهة والعملة',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.attach_money, color: Colors.teal),
                  title: const Text('العملة الحالية'),
                  subtitle: Text('الرمز الحالي: ${expenseProv.currencySymbol}'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () => _showCurrencyPicker(context, expenseProv.currencySymbol),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: Icon(
                    themeProv.isDark ? Icons.dark_mode : Icons.light_mode,
                    color: Colors.amber,
                  ),
                  title: const Text('الوضع الليلي (Dark Mode)'),
                  subtitle: const Text('تبديل مظهر التطبيق'),
                  value: themeProv.isDark,
                  onChanged: (_) => themeProv.toggleTheme(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section 2: Developer & Architecture Info
          const Text(
            'حول المشروع والمطور',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.teal.withAlpha(40),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.code, color: Colors.teal, size: 28),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppConstants.appName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'الإصدار 1.0.0 • مبني بـ Flutter & Clean Architecture',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),
                const Text(
                  'المميزات الهندسية للـ CV:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 8),
                _buildCheckItem('Clean Architecture (Data, Domain, Presentation Layers)'),
                _buildCheckItem('State Management: Provider & ChangeNotifier'),
                _buildCheckItem('Offline-First Architecture with Local Persistence'),
                _buildCheckItem('Interactive Data Visualizations with fl_chart'),
                _buildCheckItem('AI/Smart Financial Insights Engine'),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  static Widget _buildCheckItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.teal, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12.5, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}
