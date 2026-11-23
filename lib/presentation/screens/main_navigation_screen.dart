import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import 'add_transaction_screen.dart';
import 'analytics_screen.dart';
import 'home_screen.dart';
import 'settings_screen.dart';
import 'transactions_screen.dart';

// ============================================================================
// شاشة التنقل السفلية الرئيسية (MainNavigationScreen)
// ----------------------------------------------------------------------------
// مطابقة للتصميم في الصورة:
//   - 4 تبويبات: الرئيسية | التقارير | العمليات | الإعدادات
//   - زر (+) دائري بارز في المنتصف لإضافة عملية جديدة من أي شاشة
//   - شاشة الميزانية يمكن فتحها مباشرة بالضغط على بطاقة الميزانية في الرئيسية
// ============================================================================

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  void _selectTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Provider.of<ThemeProvider>(context).selectedColor.primary;

    final List<Widget> screens = [
      HomeScreen(
        onViewAllTransactions: () => _selectTab(2), // الانتقال لتبويب العمليات
        onOpenSettings: () => _selectTab(3), // الانتقال لتبويب الإعدادات
      ),
      const AnalyticsScreen(),
      const TransactionsScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),

      // ========== [1] زر (+) الدائري المركزي لإضافة عملية ==========
      floatingActionButton: FloatingActionButton(
        heroTag: 'center_add_transaction_fab',
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 6,
        shape: const CircleBorder(),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddTransactionScreen(),
            ),
          );
        },
        child: const Icon(Icons.add_rounded, size: 32),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // ========== [2] شريط التنقل السفلي بفتحة دائرية في المنتصف ==========
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        elevation: 10,
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        height: 68,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              index: 0,
              icon: Icons.home_outlined,
              activeIcon: Icons.home_rounded,
              label: 'الرئيسية',
              primaryColor: primaryColor,
            ),
            _buildNavItem(
              index: 1,
              icon: Icons.bar_chart_outlined,
              activeIcon: Icons.bar_chart_rounded,
              label: 'التقارير',
              primaryColor: primaryColor,
            ),
            // مسافة فارغة للزر المركزي (+)
            const SizedBox(width: 48),
            _buildNavItem(
              index: 2,
              icon: Icons.receipt_long_outlined,
              activeIcon: Icons.receipt_long_rounded,
              label: 'العمليات',
              primaryColor: primaryColor,
            ),
            _buildNavItem(
              index: 3,
              icon: Icons.settings_outlined,
              activeIcon: Icons.settings_rounded,
              label: 'الإعدادات',
              primaryColor: primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  /// بناء عنصر واحد داخل شريط التنقل السفلي
  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required Color primaryColor,
  }) {
    final isSelected = _currentIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDark ? Theme.of(context).colorScheme.primary : primaryColor;
    final inactiveColor = isDark ? Colors.white54 : Colors.grey.shade600;

    return Expanded(
      child: InkWell(
        onTap: () => _selectTab(index),
        borderRadius: BorderRadius.circular(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? activeColor : inactiveColor,
              size: 24,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
