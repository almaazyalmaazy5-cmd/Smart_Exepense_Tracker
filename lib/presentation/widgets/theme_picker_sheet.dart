import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../providers/theme_provider.dart';

// ============================================================================
// نافذة تخصيص المظهر والألوان (ThemePickerSheet)
// ----------------------------------------------------------------------------
// تسمح للمستخدم بالتبديل بين الوضع النهاري (Light) والوضع الداكن (Dark)
// واختيار لون التطبيق المفضّل بضغطة واحدة.
// ============================================================================

class ThemePickerSheet extends StatelessWidget {
  const ThemePickerSheet({super.key});

  /// دالة مساعدة لفتح نافذة الألوان من أي شاشة في التطبيق
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const ThemePickerSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDark;
    final selectedKey = themeProvider.themeColorKey;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ========== [1] شريط السحب العلوي ==========
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha(110),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ========== [2] العنوان ==========
          const Text(
            'تخصيص مظهر وألوان التطبيق',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'اختر الوضع المريح لعينيك واللون الذي يناسبك',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
          const SizedBox(height: 18),

          // ========== [3] اختيار الوضع: النهاري (Light) أو الداكن (Dark) ==========
          const Text(
            'وضع العرض',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildModeOption(
                  context: context,
                  title: 'الوضع النهاري (Light)',
                  icon: Icons.light_mode_rounded,
                  isSelected: !isDark,
                  primaryColor: themeProvider.selectedColor.primary,
                  onTap: () => themeProvider.setDarkMode(false),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildModeOption(
                  context: context,
                  title: 'الوضع الداكن (Dark)',
                  icon: Icons.dark_mode_rounded,
                  isSelected: isDark,
                  primaryColor: themeProvider.selectedColor.primaryLight,
                  onTap: () => themeProvider.setDarkMode(true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),

          // ========== [4] اختيار اللون الرئيسي للتطبيق ==========
          const Text(
            'اللون الرئيسي للتطبيق',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: AppTheme.colorOptions.map((option) {
              final isSelected = option.key == selectedKey;
              return InkWell(
                onTap: () => themeProvider.setThemeColor(option.key),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? option.primary.withAlpha(isDark ? 70 : 30)
                        : (isDark ? const Color(0xFF1E293B) : Colors.grey.shade100),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? option.primary
                          : (isDark ? const Color(0xFF334155) : Colors.grey.shade300),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: option.primary,
                          shape: BoxShape.circle,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white, size: 14)
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        option.nameAr,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildModeOption({
    required BuildContext context,
    required String title,
    required IconData icon,
    required bool isSelected,
    required Color primaryColor,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withAlpha(isDark ? 65 : 28)
              : (isDark ? const Color(0xFF1E293B) : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? primaryColor
                : (isDark ? const Color(0xFF334155) : Colors.grey.shade300),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? primaryColor : Colors.grey,
              size: 26,
            ),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

