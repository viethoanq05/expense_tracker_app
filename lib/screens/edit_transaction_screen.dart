import 'package:expense_tracker_app/models/category_record.dart';
import 'package:expense_tracker_app/models/transaction_record.dart';
import 'package:expense_tracker_app/services/repository_registry.dart';
import 'package:flutter/material.dart';

class EditTransactionScreen extends StatefulWidget {
  const EditTransactionScreen({super.key, required this.transaction});

  final TransactionRecord transaction;

  @override
  State<EditTransactionScreen> createState() => _EditTransactionScreenState();
}

class _EditTransactionScreenState extends State<EditTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _noteController;

  late TransactionType _type;
  late DateTime _date;
  String? _selectedCategory;

  bool _isLoadingCategories = true;
  bool _isSaving = false;
  List<CategoryRecord> _allCategories = [];

  @override
  void initState() {
    super.initState();
    final tx = widget.transaction;
    _titleController = TextEditingController(text: tx.title);
    _amountController = TextEditingController(
      text: tx.amount.toStringAsFixed(0),
    );
    _noteController = TextEditingController(text: tx.note ?? '');

    _type = tx.type;
    _date = tx.date;
    _selectedCategory = tx.category;

    _loadCategories();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await RepositoryRegistry.expenseRepository
          .getCategories();
      if (!mounted) return;
      setState(() {
        _allCategories = categories;
        _isLoadingCategories = false;

        // Ensure selected category is valid for current type
        _validateCategorySelection();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingCategories = false;
      });
    }
  }

  void _validateCategorySelection() {
    if (_allCategories.isEmpty) return;

    final validCategories = _allCategories
        .where((c) => c.type == _type)
        .toList();
    if (!validCategories.any((c) => c.name == _selectedCategory)) {
      _selectedCategory = validCategories.isNotEmpty
          ? validCategories.first.name
          : null;
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_date),
      );
      if (time != null && mounted) {
        setState(() {
          _date = DateTime(
            picked.year,
            picked.month,
            picked.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _selectedCategory == null) return;

    setState(() => _isSaving = true);

    try {
      final updatedTx = widget.transaction.copyWith(
        title: _titleController.text.trim(),
        amount: double.parse(_amountController.text.trim()),
        note: _noteController.text.trim(),
        type: _type,
        date: _date,
        category: _selectedCategory,
      );

      await RepositoryRegistry.expenseRepository.updateTransaction(updatedTx);

      if (!mounted) return;
      Navigator.of(context).pop(true); // Return true indicating success
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update: $e')));
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Transaction'),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check_rounded),
              tooltip: 'Save',
              onPressed: _save,
            ),
        ],
      ),
      body: _isLoadingCategories
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SegmentedButton<TransactionType>(
                      segments: const [
                        ButtonSegment(
                          value: TransactionType.expense,
                          label: Text('Expense'),
                          icon: Icon(Icons.trending_down_rounded),
                        ),
                        ButtonSegment(
                          value: TransactionType.income,
                          label: Text('Income'),
                          icon: Icon(Icons.trending_up_rounded),
                        ),
                      ],
                      selected: {_type},
                      onSelectionChanged: (Set<TransactionType> newSelection) {
                        setState(() {
                          _type = newSelection.first;
                          _validateCategorySelection();
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _amountController,
                      decoration: const InputDecoration(
                        labelText: 'Amount (VND)',
                        prefixIcon: Icon(Icons.attach_money_rounded),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter an amount';
                        }
                        if (double.tryParse(value.trim()) == null) {
                          return 'Invalid amount';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title / Content',
                        prefixIcon: Icon(Icons.title_rounded),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        prefixIcon: Icon(Icons.category_rounded),
                        border: OutlineInputBorder(),
                      ),
                      items: _allCategories
                          .where((c) => c.type == _type)
                          .map(
                            (c) => DropdownMenuItem(
                              value: c.name,
                              child: Text(c.name),
                            ),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _selectedCategory = val),
                      validator: (value) =>
                          value == null ? 'Please select a category' : null,
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_today_rounded),
                      title: const Text('Date & Time'),
                      subtitle: Text(
                        '${_date.day.toString().padLeft(2, '0')}/${_date.month.toString().padLeft(2, '0')}/${_date.year} '
                        '${_date.hour.toString().padLeft(2, '0')}:${_date.minute.toString().padLeft(2, '0')}',
                      ),
                      trailing: const Icon(Icons.edit_rounded, size: 20),
                      onTap: _selectDate,
                    ),
                    const Divider(height: 24),
                    TextFormField(
                      controller: _noteController,
                      decoration: const InputDecoration(
                        labelText: 'Note (Optional)',
                        prefixIcon: Icon(Icons.notes_rounded),
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 32),
                    FilledButton(
                      onPressed: _isSaving ? null : _save,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Save Changes',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
