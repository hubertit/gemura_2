import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gemura/core/theme/app_theme.dart';
import 'package:gemura/features/customers/presentation/providers/customer_provider.dart';
import 'package:gemura/features/customers/domain/models/customer.dart';

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
  DateTime _saleDate = DateTime.now();
  TimeOfDay _saleTime = TimeOfDay.now();

  final List<String> _statuses = [
    'Accepted',
    'Rejected',
  ];

  final List<String> _rejectionReasons = [
    'Poor Quality',
    'Wrong Quantity',
    'Late Delivery',
    'Contamination',
    'Temperature Issues',
    'Other',
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

  void _submitForm() {
    if (_formKey.currentState!.validate() && _selectedCustomer != null) {
      // TODO: Save sale record to database
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sale recorded successfully!'),
          backgroundColor: AppTheme.snackbarSuccessColor,
        ),
      );
      Navigator.of(context).pop();
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
    final customers = ref.watch(customerProvider);

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
              // Sale Information
              _buildSectionTitle('Sale Information'),
              const SizedBox(height: AppTheme.spacing12),
              
              // Customer Selection
              InkWell(
                onTap: () => _showCustomerSelectionDialog(customers),
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
                                    '${_selectedCustomer!.buyingPricePerLiter.toStringAsFixed(0)} Frw/L',
                                    style: AppTheme.bodySmall.copyWith(
                                      color: AppTheme.textSecondaryColor,
                                      fontSize: 12,
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
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  items: _statuses.map((status) {
                    return DropdownMenuItem<String>(
                      value: status,
                      child: Text(status, style: AppTheme.bodySmall),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedStatus = value!),
                  style: AppTheme.bodySmall,
                  dropdownColor: AppTheme.surfaceColor,
                ),
              ),
              const SizedBox(height: AppTheme.spacing12),

              // Rejection Reason (only show if rejected)
              if (_selectedStatus == 'Rejected')
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
                    border: Border.all(color: AppTheme.thinBorderColor, width: AppTheme.thinBorderWidth),
                  ),
                  child: DropdownButtonFormField<String>(
                    value: _selectedRejectionReason,
                    decoration: const InputDecoration(
                      hintText: 'Rejection Reason',
                      prefixIcon: Icon(Icons.cancel),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    items: _rejectionReasons.map((reason) {
                      return DropdownMenuItem<String>(
                        value: reason,
                        child: Text(reason, style: AppTheme.bodySmall),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => _selectedRejectionReason = value),
                    style: AppTheme.bodySmall,
                    dropdownColor: AppTheme.surfaceColor,
                  ),
                ),
              if (_selectedStatus == 'Rejected') const SizedBox(height: AppTheme.spacing12),
              const SizedBox(height: AppTheme.spacing16),

              // Date and Time
              _buildSectionTitle('Date & Time'),
              const SizedBox(height: AppTheme.spacing12),

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
              _buildSectionTitle('Additional Information'),
              const SizedBox(height: AppTheme.spacing12),

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
              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
                  ),
                ),
                child: const Text(
                  'Record Sale',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
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
    final totalValue = quantity * _selectedCustomer!.buyingPricePerLiter;

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
          _buildSummaryRow('Quantity', '${quantity.toStringAsFixed(1)}L'),
          _buildSummaryRow('Price per Liter', '${_selectedCustomer!.buyingPricePerLiter.toStringAsFixed(0)} Frw'),
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTheme.titleMedium.copyWith(
        color: AppTheme.textPrimaryColor,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  void _showCustomerSelectionDialog(List<Customer> customers) {
    final searchController = TextEditingController();
    List<Customer> filteredCustomers = customers;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.business, color: AppTheme.primaryColor),
                const SizedBox(width: AppTheme.spacing8),
                const Text('Select Customer'),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Search field
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Search customers...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                        borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
                      ),
                    ),
                    onChanged: (value) {
                      setDialogState(() {
                        if (value.isEmpty) {
                          filteredCustomers = customers;
                        } else {
                          final query = value.toLowerCase();
                          filteredCustomers = customers.where((customer) {
                            return customer.name.toLowerCase().contains(query) ||
                                customer.phone.toLowerCase().contains(query) ||
                                customer.location.toLowerCase().contains(query);
                          }).toList();
                        }
                      });
                    },
                  ),
                  const SizedBox(height: AppTheme.spacing16),
                  // Customer list
                  SizedBox(
                    height: 300,
                    child: filteredCustomers.isEmpty
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
                                      '${customer.buyingPricePerLiter.toStringAsFixed(0)} Frw/L',
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
                          ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ],
          );
        },
      ),
    );
  }
} 