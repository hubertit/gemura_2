import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/savings_provider.dart';
import '../../domain/models/savings_goal.dart';

class CreateSavingsGoalScreen extends ConsumerStatefulWidget {
  const CreateSavingsGoalScreen({super.key});

  @override
  ConsumerState<CreateSavingsGoalScreen> createState() => _CreateSavingsGoalScreenState();
}

class _CreateSavingsGoalScreenState extends ConsumerState<CreateSavingsGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _targetAmountController = TextEditingController();
  final _targetDateController = TextEditingController();
  
  DateTime? _selectedDate;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _targetAmountController.dispose();
    _targetDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Savings Goal'),
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimaryColor),
        titleTextStyle: AppTheme.titleMedium.copyWith(
          color: AppTheme.textPrimaryColor,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: AppTheme.backgroundColor,
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.spacing16),
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(AppTheme.borderRadius16),
                border: Border.all(
                    color: AppTheme.thinBorderColor, 
                    width: AppTheme.thinBorderWidth),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.savings,
                      size: 48,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(height: AppTheme.spacing12),
                                         Text(
                       'Create New Savings Goal',
                       style: AppTheme.bodyMedium.copyWith(
                         fontWeight: FontWeight.w600,
                         color: AppTheme.textPrimaryColor,
                       ),
                     ),
                    const SizedBox(height: AppTheme.spacing8),
                    Text(
                      'Set a target amount and date to start saving towards your goal.',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: AppTheme.spacing24),
            
            // Goal Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Goal Name',
                hintText: 'e.g., Vacation Fund, Emergency Fund',
                prefixIcon: Icon(Icons.flag),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a goal name';
                }
                return null;
              },
            ),
            
            const SizedBox(height: AppTheme.spacing16),
            
            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'Describe your savings goal',
                prefixIcon: Icon(Icons.description),
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            
            const SizedBox(height: AppTheme.spacing16),
            
            // Target Amount
            TextFormField(
              controller: _targetAmountController,
              decoration: const InputDecoration(
                labelText: 'Target Amount',
                hintText: 'Enter your target amount',
                                        prefixIcon: Icon(Icons.monetization_on),
                        prefixText: 'RWF ',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a target amount';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount <= 0) {
                  return 'Please enter a valid amount';
                }
                return null;
              },
            ),
            
            const SizedBox(height: AppTheme.spacing16),
            
            // Target Date
            TextFormField(
              controller: _targetDateController,
              decoration: const InputDecoration(
                labelText: 'Target Date',
                hintText: 'Select your target date',
                prefixIcon: Icon(Icons.calendar_today),
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.date_range),
              ),
              readOnly: true,
              onTap: () => _selectDate(context),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please select a target date';
                }
                if (_selectedDate != null && _selectedDate!.isBefore(DateTime.now())) {
                  return 'Target date cannot be in the past';
                }
                return null;
              },
            ),
            
            const SizedBox(height: AppTheme.spacing32),
            
            // Create Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createGoal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Create Savings Goal',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)), // 5 years from now
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _targetDateController.text = DateFormat('MMM dd, yyyy').format(picked);
      });
    }
  }

  void _createGoal() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final goal = SavingsGoal(
        id: 'SAVINGS-${DateTime.now().millisecondsSinceEpoch}',
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        currentAmount: 0,
        targetAmount: double.parse(_targetAmountController.text),
        currency: 'RWF',
        targetDate: _selectedDate!,
        createdAt: DateTime.now(),
        contributors: ['You'],
      );
      
      ref.read(savingsProvider.notifier).addSavingsGoal(goal);
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          AppTheme.successSnackBar(
            message: 'Savings goal "${goal.name}" created successfully!',
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppTheme.errorSnackBar(
            message: 'Failed to create savings goal. Please try again.',
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
} 