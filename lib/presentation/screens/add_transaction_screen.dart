import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/category_model.dart';
import '../../data/models/transaction_model.dart';
import '../providers/expense_provider.dart';
import '../providers/theme_provider.dart';

// ============================================================================
// الواجهة الثانية: إضافة وتعديل عملية (AddTransactionScreen)
// ----------------------------------------------------------------------------
// مطابقة لتصميم الصورة وتعمل بوضعين:
//   - وضع الإضافة: عند فتحها بدون معاملة (من زر +)
//   - وضع التعديل: عند تمرير [transactionToEdit] لتعديل عملية موجودة
//
// أقسام الشاشة:
//   [1] اختيار نوع العملية (دخل / مصروف)
//   [2] إدخال المبلغ
//   [3] اسم / وصف العملية (اختياري - يأخذ اسم التصنيف تلقائياً إذا تُرك فارغاً)
//   [4] شبكة التصنيفات (Grid من 3 أعمدة بالأيقونات)
//   [5] اختيار التاريخ
//   [6] اختيار طريقة الدفع (نقداً / تحويل بنكي / محفظة إلكترونية)
//   [7] ملاحظات إضافية (اختياري)
//   [8] زر حفظ العملية
// ============================================================================

class AddTransactionScreen extends StatefulWidget {
  /// إذا تم تمرير عملية هنا، تفتح الشاشة في وضع "تعديل عملية"
  final TransactionModel? transactionToEdit;

  const AddTransactionScreen({super.key, this.transactionToEdit});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();

  late TransactionType _selectedType;
  late CategoryModel _selectedCategory;
  late DateTime _selectedDate;
  String _selectedPaymentMethod = 'cash';
  bool _isSaving = false;

  bool get _isEditing => widget.transactionToEdit != null;

  @override
  void initState() {
    super.initState();
    final editingTx = widget.transactionToEdit;

    if (editingTx != null) {
      // تعبئة البيانات في حالة تعديل عملية قائمة
      _selectedType = editingTx.type;
      _amountController.text = editingTx.amount.truncateToDouble() == editingTx.amount
          ? editingTx.amount.toStringAsFixed(0)
          : editingTx.amount.toStringAsFixed(2);
      _titleController.text = editingTx.title;
      _notesController.text = editingTx.notes ?? '';
      _selectedDate = editingTx.date;
      _selectedPaymentMethod = editingTx.paymentMethod ?? 'cash';

      final list = _currentCategories;
      _selectedCategory = list.firstWhere(
        (cat) => cat.id == editingTx.categoryId,
        orElse: () => list.first,
      );
    } else {
      // قيم افتراضية عند إضافة عملية جديدة
      _selectedType = TransactionType.expense;
      _selectedCategory = AppConstants.expenseCategories.first;
      _selectedDate = DateTime.now();
      _selectedPaymentMethod = 'cash';
    }
  }

  List<CategoryModel> get _currentCategories =>
      _selectedType == TransactionType.expense
          ? AppConstants.expenseCategories
          : AppConstants.incomeCategories;

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// تبديل نوع العملية (دخل / مصروف) وتحديث التصنيف الافتراضي
  void _onTypeChanged(TransactionType type) {
    if (_selectedType == type) return;
    setState(() {
      _selectedType = type;
      _selectedCategory = _currentCategories.first;
    });
  }

  /// فتح منتقي التاريخ
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedDate.hour,
          _selectedDate.minute,
        );
      });
    }
  }

  /// حفظ العملية الجديدة أو حفظ تعديلات العملية القائمة
  Future<void> _saveTransaction() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء إدخال مبلغ صحيح أكبر من الصفر'),
          backgroundColor: AppTheme.expenseColor,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final provider = Provider.of<ExpenseProvider>(context, listen: false);
      // إذا ترك المستخدم حقل الوصف فارغاً، نستخدم اسم التصنيف تلقائياً لسرعة الإدخال
      final finalTitle = _titleController.text.trim().isEmpty
          ? _selectedCategory.name
          : _titleController.text.trim();
      final finalNotes = _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim();

      if (_isEditing) {
        final updated = widget.transactionToEdit!.copyWith(
          title: finalTitle,
          amount: amount,
          type: _selectedType,
          categoryId: _selectedCategory.id,
          categoryName: _selectedCategory.name,
          categoryIconCode: _selectedCategory.icon.codePoint,
          categoryColorHex: _selectedCategory.color.toARGB32(),
          date: _selectedDate,
          paymentMethod: _selectedPaymentMethod,
          notes: finalNotes,
        );
        await provider.updateTransaction(updated);
      } else {
        await provider.addTransaction(
          title: finalTitle,
          amount: amount,
          type: _selectedType,
          categoryId: _selectedCategory.id,
          categoryName: _selectedCategory.name,
          categoryIconCode: _selectedCategory.icon.codePoint,
          categoryColorHex: _selectedCategory.color.toARGB32(),
          date: _selectedDate,
          paymentMethod: _selectedPaymentMethod,
          notes: finalNotes,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'تم تعديل العملية بنجاح ✅'
                : (_selectedType == TransactionType.expense
                    ? 'تم تسجيل المصروف بنجاح ✅'
                    : 'تم تسجيل الدخل بنجاح ✅'),
          ),
          backgroundColor: _selectedType == TransactionType.expense
              ? AppTheme.expenseColor
              : AppTheme.incomeColor,
        ),
      );
      Navigator.pop(context);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = Provider.of<ThemeProvider>(context).selectedColor.primary;
    final currency = Provider.of<ExpenseProvider>(context).currencySymbol;
    final isExpense = _selectedType == TransactionType.expense;
    final categories = _currentCategories;

    final formattedDate =
        '${_selectedDate.year}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.day.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'تعديل العملية' : 'إضافة عملية'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
          children: [
            // ==========================================================
            // [1] اختيار نوع العملية: دخل / مصروف
            // ==========================================================
            Row(
              children: [
                Expanded(
                  child: _buildTypeButton(
                    label: 'دخل',
                    icon: Icons.arrow_upward_rounded,
                    isSelected: !isExpense,
                    activeColor: primaryColor,
                    isDark: isDark,
                    onTap: () => _onTypeChanged(TransactionType.income),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTypeButton(
                    label: 'مصروف',
                    icon: Icons.arrow_downward_rounded,
                    isSelected: isExpense,
                    activeColor: AppTheme.expenseColor,
                    isDark: isDark,
                    onTap: () => _onTypeChanged(TransactionType.expense),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ==========================================================
            // [2] حقل إدخال المبلغ
            // ==========================================================
            _buildSectionLabel('المبلغ', isDark),
            const SizedBox(height: 8),
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.left,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: '0.00',
                prefixIcon: Icon(
                  Icons.account_balance_wallet_outlined,
                  color: isExpense ? AppTheme.expenseColor : primaryColor,
                ),
                suffixText: currency,
                suffixStyle: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'الرجاء إدخال المبلغ';
                }
                final parsed = double.tryParse(val.trim());
                if (parsed == null || parsed <= 0) {
                  return 'أدخل مبلغاً صحيحاً أكبر من الصفر';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // ==========================================================
            // [3] اسم / وصف العملية (اختياري - يملأ تلقائياً باسم التصنيف)
            // ==========================================================
            _buildSectionLabel('اسم العملية (اختياري)', isDark),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: isExpense
                    ? 'مثال: مطعم ومشروبات، وقود... (أو اتركه فارغاً)'
                    : 'مثال: راتب شهري، مشروع مستقل...',
                prefixIcon: const Icon(Icons.edit_outlined),
              ),
            ),
            const SizedBox(height: 20),

            // ==========================================================
            // [4] شبكة التصنيفات (Grid من 3 أعمدة بالأيقونات)
            // ==========================================================
            _buildSectionLabel('التصنيف', isDark),
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: categories.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.15,
              ),
              itemBuilder: (context, index) {
                final cat = categories[index];
                final isSelected = _selectedCategory.id == cat.id;

                return InkWell(
                  onTap: () => setState(() => _selectedCategory = cat),
                  borderRadius: BorderRadius.circular(16),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? primaryColor.withAlpha(isDark ? 70 : 32)
                          : (isDark ? const Color(0xFF1E293B) : Colors.white),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? primaryColor
                            : (isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFE5E7EB)),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          cat.icon,
                          size: 26,
                          color: isSelected
                              ? primaryColor
                              : (isDark ? Colors.white70 : const Color(0xFF334155)),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          cat.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected
                                ? (isDark ? Colors.white : primaryColor)
                                : (isDark ? Colors.white70 : Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            // ==========================================================
            // [5] اختيار التاريخ
            // ==========================================================
            _buildSectionLabel('التاريخ', isDark),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE5E7EB),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_month_outlined,
                          color: primaryColor,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          formattedDate,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const Icon(Icons.chevron_left_rounded, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ==========================================================
            // [6] اختيار طريقة الدفع (نقداً / تحويل بنكي / محفظة إلكترونية)
            // ==========================================================
            _buildSectionLabel('طريقة الدفع (اختياري)', isDark),
            const SizedBox(height: 10),
            Row(
              children: AppConstants.paymentMethods.map((method) {
                final isSelected = _selectedPaymentMethod == method.id;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: InkWell(
                      onTap: () =>
                          setState(() => _selectedPaymentMethod = method.id),
                      borderRadius: BorderRadius.circular(14),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? primaryColor.withAlpha(isDark ? 70 : 30)
                              : (isDark
                                  ? const Color(0xFF1E293B)
                                  : Colors.white),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? primaryColor
                                : (isDark
                                    ? const Color(0xFF334155)
                                    : const Color(0xFFE5E7EB)),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              method.icon,
                              size: 22,
                              color: isSelected ? primaryColor : Colors.grey,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              method.nameAr,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isSelected
                                    ? (isDark ? Colors.white : primaryColor)
                                    : (isDark ? Colors.white70 : Colors.black87),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // ==========================================================
            // [7] ملاحظات إضافية (اختياري)
            // ==========================================================
            _buildSectionLabel('ملاحظات (اختياري)', isDark),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'أضف ملاحظة هنا ...',
                prefixIcon: Icon(Icons.notes_rounded),
              ),
            ),
            const SizedBox(height: 28),

            // ==========================================================
            // [8] زر حفظ العملية
            // ==========================================================
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveTransaction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(
                  _isEditing ? 'حفظ التعديلات' : 'حفظ العملية',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text, bool isDark) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white70 : const Color(0xFF1F2937),
      ),
    );
  }

  Widget _buildTypeButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color activeColor,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 19,
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.white70 : Colors.black87),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white70 : Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
