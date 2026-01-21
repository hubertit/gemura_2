import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gemura/core/theme/app_theme.dart';
import 'package:gemura/features/customers/presentation/providers/customers_provider.dart';
import 'package:gemura/shared/models/customer.dart';
import 'package:gemura/features/sales/presentation/providers/sales_provider.dart';
import 'package:gemura/features/collection/presentation/providers/collections_provider.dart';

class RecordSaleScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? preFilledData;
  
  const RecordSaleScreen({super.key, this.preFilledData});

  @override
  ConsumerState<RecordSaleScreen> createState() => _RecordSaleScreenState();
}

class _RecordSaleScreenState extends ConsumerState<RecordSaleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _notesController = TextEditingController();
  
  Customer? _selectedCustomer;
  String _selectedStatus = 'Accepted';
  String? _selectedRejectionReason;
  String _paymentStatus = 'unpaid';
  DateTime _saleDate = DateTime.now();
  TimeOfDay _saleTime = TimeOfDay.now();

  final List<String> _statuses = [
    'Accepted',
    'Rejected',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.preFilledData != null) {
      final data = widget.preFilledData!;
      _quantityController.text = data['quantity']?.toString() ?? '';
      _notesController.text = data['notes'] ?? '';
      // TODO: Set selected customer based on pre-filled data
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate() && _selectedCustomer != null) {
      final salesNotifier = ref.read(salesNotifierProvider.notifier);
      
      // Prefer UUID over code - ensure at least one is provided
      final customerAccountId = _selectedCustomer!.accountId;
      final customerAccountCode = (customerAccountId == null || customerAccountId.isEmpty) 
          ? _selectedCustomer!.accountCode 
          : null;
      
      // Validate that at least one identifier is available
      if (customerAccountId == null && (customerAccountCode == null || customerAccountCode.isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Customer account information is missing. Please select a valid customer.'),
            backgroundColor: AppTheme.snackbarErrorColor,
          ),
        );
        return;
      }
      
      await salesNotifier.recordSale(
        customerAccountId: customerAccountId,
        customerAccountCode: customerAccountCode,
        quantity: double.parse(_quantityController.text),
        status: _selectedStatus,
        saleAt: DateTime(
          _saleDate.year,
          _saleDate.month,
          _saleDate.day,
          _saleTime.hour,
          _saleTime.minute,
        ),
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        paymentStatus: _paymentStatus,
      );
    } else if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a customer'),
          backgroundColor: AppTheme.snackbarErrorColor,
        ),
      );
    }
  }

  void _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _saleDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _saleDate) {
      setState(() {
        _saleDate = picked;
      });
    }
  }

  void _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _saleTime,
    );
    if (picked != null && picked != _saleTime) {
      setState(() {
        _saleTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customersNotifierProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Record Sale'),
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimaryColor),
        titleTextStyle: AppTheme.titleMedium.copyWith(color: AppTheme.textPrimaryColor),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacing16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Customer Selection
              InkWell(
                onTap: () => _showCustomerSelectionDialog(customersAsync),
                child: Container(
                  padding: const EdgeInsets.all(AppTheme.spacing12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
                    border: Border.all(color: AppTheme.thinBorderColor, width: AppTheme.thinBorderWidth),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.business, color: AppTheme.textSecondaryColor),
                      const SizedBox(width: AppTheme.spacing12),
                      Expanded(
                        child: _selectedCustomer == null
                            ? Text(
                                'Select Customer',
                                style: AppTheme.bodySmall.copyWith(
                                  color: AppTheme.textHintColor,
                                ),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selectedCustomer!.name,
                                    style: AppTheme.bodySmall.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '${_selectedCustomer!.pricePerLiter.toStringAsFixed(0)} Frw/L',
                                    style: AppTheme.bodySmall.copyWith(
                                      color: AppTheme.textSecondaryColor,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    'Account: ${_selectedCustomer!.accountCode}',
                                    style: AppTheme.bodySmall.copyWith(
                                      color: AppTheme.textSecondaryColor,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                      const Icon(Icons.arrow_drop_down, color: AppTheme.textSecondaryColor),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacing12),

              // Quantity
              TextFormField(
                controller: _quantityController,
                style: AppTheme.bodySmall,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'Quantity (Liters)',
                  prefixIcon: Icon(Icons.local_shipping),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter quantity';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  if (double.parse(value) <= 0) {
                    return 'Quantity must be greater than 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.spacing12),

              // Status
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
                  border: Border.all(color: AppTheme.thinBorderColor, width: AppTheme.thinBorderWidth),
                ),
                child: DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  decoration: const InputDecoration(
                    hintText: 'Status',
                    prefixIcon: Icon(Icons.check_circle),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 16),
                  ),
                  items: _statuses.map((status) {
                    return DropdownMenuItem<String>(
                      value: status,
                      child: Text(
                        status,
                        style: AppTheme.bodySmall,
                        textAlign: TextAlign.left,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedStatus = value!),
                  style: AppTheme.bodySmall,
                  dropdownColor: AppTheme.surfaceColor,
                  alignment: AlignmentDirectional.centerStart,
                  iconSize: 24,
                ),
              ),
              const SizedBox(height: AppTheme.spacing12),

              // Rejection Reason (only show if rejected)
              if (_selectedStatus == 'Rejected')
                Consumer(
                  builder: (context, ref, child) {
                    final rejectionReasonsAsync = ref.watch(rejectionReasonsProvider);
                    return rejectionReasonsAsync.when(
                      data: (reasons) => Container(
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceColor,
                          borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
                          border: Border.all(color: AppTheme.thinBorderColor, width: AppTheme.thinBorderWidth),
                        ),
                        child: DropdownButtonFormField<String>(
                          value: _selectedRejectionReason,
                          decoration: InputDecoration(
                            hintText: 'Rejection Reason',
                            hintStyle: AppTheme.hintText,
                            prefixIcon: const Icon(Icons.cancel),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 16),
                          ),
                          items: reasons.map((reason) {
                            return DropdownMenuItem<String>(
                              value: reason['name'] as String,
                              child: Text(
                                reason['name'] as String,
                                style: AppTheme.bodySmall,
                                textAlign: TextAlign.left,
                              ),
                            );
                          }).toList(),
                          onChanged: (value) => setState(() => _selectedRejectionReason = value),
                          style: AppTheme.bodySmall,
                          dropdownColor: AppTheme.surfaceColor,
                          alignment: AlignmentDirectional.centerStart,
                          iconSize: 24,
                        ),
                      ),
                      loading: () => Container(
                        padding: const EdgeInsets.all(AppTheme.spacing16),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceColor,
                          borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
                          border: Border.all(color: AppTheme.thinBorderColor, width: AppTheme.thinBorderWidth),
                        ),
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      error: (error, stack) => Container(
                        padding: const EdgeInsets.all(AppTheme.spacing16),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceColor,
                          borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
                          border: Border.all(color: AppTheme.errorColor, width: AppTheme.thinBorderWidth),
                        ),
                        child: Text(
                          'Failed to load rejection reasons',
                          style: AppTheme.bodySmall.copyWith(color: AppTheme.errorColor),
                        ),
                      ),
                    );
                  },
                ),
              if (_selectedStatus == 'Rejected') const SizedBox(height: AppTheme.spacing12),
              const SizedBox(height: AppTheme.spacing12),

              // Payment Status
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
                  border: Border.all(color: AppTheme.thinBorderColor, width: AppTheme.thinBorderWidth),
                ),
                child: DropdownButtonFormField<String>(
                  value: _paymentStatus,
                  decoration: const InputDecoration(
                    hintText: 'Payment Status',
                    prefixIcon: Icon(Icons.payment),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 16),
                  ),
                  items: ['paid', 'unpaid'].map((status) {
                    return DropdownMenuItem<String>(
                      value: status,
                      child: Text(
                        status == 'paid' ? 'Paid' : 'Unpaid',
                        style: AppTheme.bodySmall,
                        textAlign: TextAlign.left,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _paymentStatus = value!),
                  style: AppTheme.bodySmall,
                  dropdownColor: AppTheme.surfaceColor,
                  alignment: AlignmentDirectional.centerStart,
                  iconSize: 24,
                ),
              ),
              const SizedBox(height: AppTheme.spacing16),

              // Date and Time
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _selectDate,
                      child: Container(
                        padding: const EdgeInsets.all(AppTheme.spacing12),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceColor,
                          borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
                          border: Border.all(color: AppTheme.thinBorderColor, width: AppTheme.thinBorderWidth),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 16, color: AppTheme.textSecondaryColor),
                            const SizedBox(width: AppTheme.spacing8),
                            Text(
                              '${_saleDate.day}/${_saleDate.month}/${_saleDate.year}',
                              style: AppTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing12),
                  Expanded(
                    child: InkWell(
                      onTap: _selectTime,
                      child: Container(
                        padding: const EdgeInsets.all(AppTheme.spacing12),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceColor,
                          borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
                          border: Border.all(color: AppTheme.thinBorderColor, width: AppTheme.thinBorderWidth),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time, size: 16, color: AppTheme.textSecondaryColor),
                            const SizedBox(width: AppTheme.spacing8),
                            Text(
                              _saleTime.format(context),
                              style: AppTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacing16),

              // Notes
              TextFormField(
                controller: _notesController,
                style: AppTheme.bodySmall,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Notes (optional)',
                  prefixIcon: Icon(Icons.note),
                ),
              ),
              const SizedBox(height: AppTheme.spacing24),

              // Summary Card
              if (_selectedCustomer != null && _quantityController.text.isNotEmpty) ...[
                _buildSummaryCard(),
                const SizedBox(height: AppTheme.spacing24),
              ],

              // Submit Button
              Consumer(
                builder: (context, ref, child) {
                  final salesState = ref.watch(salesNotifierProvider);
                  
                  // Show success message and navigate back
                  if (salesState.isSuccess) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Sale recorded successfully!'),
                          backgroundColor: AppTheme.snackbarSuccessColor,
                        ),
                      );
                      ref.read(salesNotifierProvider.notifier).resetState();
                      Navigator.of(context).pop();
                    });
                  }
                  
                  // Show error message
                  if (salesState.error != null) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(salesState.error!),
                          backgroundColor: AppTheme.snackbarErrorColor,
                        ),
                      );
                      ref.read(salesNotifierProvider.notifier).resetState();
                    });
                  }
                  
                  return ElevatedButton(
                    onPressed: salesState.isLoading ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
                      ),
                    ),
                    child: salesState.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Record Sale',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    if (_selectedCustomer == null || _quantityController.text.isEmpty) {
      return const SizedBox.shrink();
    }

    final quantity = double.tryParse(_quantityController.text) ?? 0;
    final totalValue = quantity * _selectedCustomer!.pricePerLiter;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: AppTheme.successColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
        border: Border.all(color: AppTheme.successColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sale Summary',
            style: AppTheme.titleMedium.copyWith(
              color: AppTheme.successColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spacing12),
          _buildSummaryRow('Customer', _selectedCustomer!.name),
          _buildSummaryRow('Account Code', _selectedCustomer!.accountCode),
          _buildSummaryRow('Quantity', '${quantity.toStringAsFixed(1)}L'),
          _buildSummaryRow('Price per Liter', '${_selectedCustomer!.pricePerLiter.toStringAsFixed(0)} Frw'),
          _buildSummaryRow('Total Revenue', '${totalValue.toStringAsFixed(0)} Frw'),
          _buildSummaryRow('Status', _selectedStatus),
          if (_selectedStatus == 'Rejected' && _selectedRejectionReason != null)
            _buildSummaryRow('Rejection Reason', _selectedRejectionReason!),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacing4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.textSecondaryColor,
            ),
          ),
          Text(
            value,
            style: AppTheme.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
        ],
      ),
    );
  }

  void _showCustomerSelectionDialog(AsyncValue<List<Customer>> customersAsync) {
    final searchController = TextEditingController();
    List<Customer> filteredCustomers = [];
    
    // Initialize filtered customers from async value
    customersAsync.when(
      data: (customers) => filteredCustomers = customers,
      loading: () => filteredCustomers = [],
      error: (error, stack) => filteredCustomers = [],
    );

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            backgroundColor: AppTheme.surfaceColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.borderRadius16),
            ),
            child: Container(
              padding: const EdgeInsets.all(AppTheme.spacing16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  Row(
                    children: [
                      Icon(Icons.business, color: AppTheme.primaryColor, size: 20),
                      const SizedBox(width: AppTheme.spacing8),
                      Text(
                        'Select Customer',
                        style: AppTheme.titleMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.close, color: AppTheme.textSecondaryColor),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacing12),
                  // Search field
                  TextField(
                    controller: searchController,
                    style: AppTheme.bodySmall,
                    decoration: InputDecoration(
                      hintText: 'Search by name, phone, or address...',
                      hintStyle: AppTheme.hintText,
                      prefixIcon: Icon(Icons.search, size: 18, color: AppTheme.textSecondaryColor),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                        borderSide: BorderSide(color: AppTheme.primaryColor, width: 1),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacing12,
                        vertical: AppTheme.spacing8,
                      ),
                    ),
                    onChanged: (value) {
                      setDialogState(() {
                        customersAsync.when(
                          data: (customers) {
                            if (value.isEmpty) {
                              filteredCustomers = customers;
                            } else {
                              final query = value.toLowerCase();
                              filteredCustomers = customers.where((customer) {
                                return customer.name.toLowerCase().contains(query) ||
                                    customer.phone.toLowerCase().contains(query) ||
                                    (customer.address?.toLowerCase().contains(query) ?? false);
                              }).toList();
                            }
                          },
                          loading: () => filteredCustomers = [],
                          error: (error, stack) => filteredCustomers = [],
                        );
                      });
                    },
                  ),
                  const SizedBox(height: AppTheme.spacing16),
                  // Customer list
                  SizedBox(
                    height: 300,
                    child: customersAsync.when(
                      loading: () => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      error: (error, stack) => Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 48, color: AppTheme.textSecondaryColor),
                            const SizedBox(height: AppTheme.spacing8),
                            Text(
                              'Failed to load customers',
                              style: AppTheme.bodySmall.copyWith(
                                color: AppTheme.textSecondaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      data: (customers) {
                        // Initialize filtered customers if empty
                        if (filteredCustomers.isEmpty) {
                          filteredCustomers = customers;
                        }
                        
                        return filteredCustomers.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.search_off, size: 48, color: AppTheme.textSecondaryColor),
                                    const SizedBox(height: AppTheme.spacing8),
                                    Text(
                                      'No customers found',
                                      style: AppTheme.bodySmall.copyWith(
                                        color: AppTheme.textSecondaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                itemCount: filteredCustomers.length,
                                itemBuilder: (context, index) {
                                  final customer = filteredCustomers[index];
                                  return ListTile(
                                    leading: CircleAvatar(
                                      radius: 20,
                                      backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                                      child: Text(
                                        customer.name.isNotEmpty ? customer.name[0].toUpperCase() : 'C',
                                        style: TextStyle(
                                          color: AppTheme.primaryColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      customer.name,
                                      style: AppTheme.bodySmall.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          customer.phone,
                                          style: AppTheme.bodySmall.copyWith(
                                            color: AppTheme.textSecondaryColor,
                                            fontSize: 12,
                                          ),
                                        ),
                                        Text(
                                          '${customer.pricePerLiter.toStringAsFixed(0)} Frw/L',
                                          style: AppTheme.bodySmall.copyWith(
                                            color: AppTheme.primaryColor,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                          ),
                                        ),
                                        
                                      ],
                                    ),
                                    onTap: () {
                                      setState(() {
                                        _selectedCustomer = customer;
                                      });
                                      Navigator.of(context).pop();
                                    },
                                  );
                                },
                              );
                      },
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing16),
                  // Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          'Cancel',
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
} 