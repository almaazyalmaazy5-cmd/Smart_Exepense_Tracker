import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../providers/expense_provider.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  TransactionType _selectedType = TransactionType.expense;
  late Map<String, dynamic> _selectedCategory;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _selectedCategory = AppConstants.defaultExpenseCategories.first;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onTypeChanged(TransactionType type) {
    setState(() {
      _selectedType = type;
      _selectedCategory = type == TransactionType.expense
          ? AppConstants.defaultExpenseCategories.first
          : AppConstants.defaultIncomeCategories.first;
    });
  }

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

  void _saveTransaction() {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء إدخال مبلغ صحيح أكبر من الصفر'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final provider = Provider.of<ExpenseProvider>(context, listen: false);

    provider.addTransaction(
      title: _titleController.text.trim(),
      amount: amount,
      type: _selectedType,
      categoryId: _selectedCategory['id'] as String,
      categoryName: _selectedCategory['name'] as String,
      categoryIconCode: _selectedCategory['iconCode'] as int,
      categoryColorHex: _selectedCategory['colorHex'] as int,
      date: _selectedDate,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _selectedType == TransactionType.expense
              ? 'تم تسجيل المصروف بنجاح ✅'
              : 'تم تسجيل الدخل بنجاح ✅',
        ),
        backgroundColor: _selectedType == TransactionType.expense
            ? Colors.red.shade700
            : Colors.green.shade700,
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isExpense = _selectedType == TransactionType.expense;
    final categories = isExpense
        ? AppConstants.defaultExpenseCategories
        : AppConstants.defaultIncomeCategories;

    return Scaffold(
      appBar: AppBar(
        title: Text(isExpense ? 'إضافة مصروف جديد' : 'إضافة دخل جديد'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // 1. Transaction Type Selector (Expense vs Income)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _onTypeChanged(TransactionType.expense),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isExpense
                              ? Colors.red.shade600
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.arrow_upward,
                              color: isExpense ? Colors.white : Colors.grey,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'مصروف',
                              style: TextStyle(
                                color: isExpense ? Colors.white : Colors.grey,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _onTypeChanged(TransactionType.income),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !isExpense
                              ? Colors.green.shade600
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.arrow_downward,
                              color: !isExpense ? Colors.white : Colors.grey,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'دخل',
                              style: TextStyle(
                                color: !isExpense ? Colors.white : Colors.grey,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 2. Amount Input
            Text(
              'المبلغ',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: '0.00',
                prefixIcon: Icon(
                  Icons.attach_money,
                  color: isExpense ? Colors.red : Colors.green,
                ),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'الرجاء إدخال المبلغ';
                }
                if (double.tryParse(val.trim()) == null) {
                  return 'أدخل رقماً صالحاً';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // 3. Title Input
            Text(
              'الوصف / البند',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: isExpense
                    ? 'مثال: غداء عمل، وقود، تسوق...'
                    : 'مثال: راتب شهري، أرباح مشروع...',
                prefixIcon: const Icon(Icons.edit_outlined),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'الرجاء إدخال وصف المعاملة';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // 4. Category Selector
            Text(
              'التصنيف',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: categories.map((cat) {
                final isSelected = _selectedCategory['id'] == cat['id'];
                final color = Color(cat['colorHex'] as int);

                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedCategory = cat;
                    });
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color
                          : (isDark
                              ? const Color(0xFF1E293B)
                              : Colors.white),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? color
                            : (isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFCBD5E1)),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          IconData(cat['iconCode'] as int,
                              fontFamily: 'MaterialIcons'),
                          color: isSelected ? Colors.white : color,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          cat['name'] as String,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? Colors.white
                                : (isDark ? Colors.white70 : Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // 5. Date Picker
            Text(
              'التاريخ',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFCBD5E1),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      '${_selectedDate.year}/${_selectedDate.month}/${_selectedDate.day}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.arrow_forward_ios, size: 14),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 6. Notes Input
            Text(
              'ملاحظات إضافية (اختياري)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'أي تفاصيل أخرى ترغب في تذكرها...',
                prefixIcon: Icon(Icons.notes),
              ),
            ),
            const SizedBox(height: 32),

            // 7. Submit Button
            ElevatedButton(
              onPressed: _saveTransaction,
              style: ElevatedButton.styleFrom(
                backgroundColor: isExpense
                    ? Colors.red.shade600
                    : Colors.green.shade600,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                isExpense ? 'حفظ المصروف' : 'حفظ الدخل',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
