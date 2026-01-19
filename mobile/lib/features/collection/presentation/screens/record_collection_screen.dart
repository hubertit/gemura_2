import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gemura/core/theme/app_theme.dart';
import 'package:gemura/features/suppliers/presentation/providers/suppliers_provider.dart';
import 'package:gemura/shared/models/supplier.dart';
import '../providers/collections_provider.dart';

class RecordCollectionScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? preFilledData;
  
  const RecordCollectionScreen({super.key, this.preFilledData});

  @override
  ConsumerState<RecordCollectionScreen> createState() => _RecordCollectionScreenState();
}

class _RecordCollectionScreenState extends ConsumerState<RecordCollectionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _notesController = TextEditingController();
  
  Supplier? _selectedSupplier;
  String _selectedStatus = 'Accepted';
  String? _selectedRejectionReason;
  DateTime _collectionDate = DateTime.now();
  TimeOfDay _collectionTime = TimeOfDay.now();
  bool _isSubmitting = false;

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
      // TODO: Set selected supplier based on pre-filled data
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate() && _selectedSupplier != null) {
      setState(() {
        _isSubmitting = true;
      });

      try {
        // Combine date and time
        final collectionDateTime = DateTime(
          _collectionDate.year,
          _collectionDate.month,
          _collectionDate.day,
          _collectionTime.hour,
          _collectionTime.minute,
        );

        await ref.read(collectionsNotifierProvider.notifier).createCollection(
          supplierAccountCode: _selectedSupplier!.accountCode,
          quantity: double.parse(_quantityController.text),
          status: _selectedStatus.toLowerCase(),
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          collectionAt: collectionDateTime,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Collection recorded successfully!'),
              backgroundColor: AppTheme.snackbarSuccessColor,
            ),
          );
          
          // Invalidate providers to ensure the list refreshes on the collections screen
          // This will trigger a refresh of both FutureProvider and StateNotifierProvider
          ref.invalidate(collectionsProvider);
          ref.invalidate(collectionsNotifierProvider);
          
          // Small delay to ensure the success message is visible before navigating back
          await Future.delayed(const Duration(milliseconds: 300));
          
          Navigator.of(context).pop();
        }
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to record collection: ${error.toString()}'),
              backgroundColor: AppTheme.snackbarErrorColor,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });
        }
      }
    } else if (_selectedSupplier == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a supplier'),
          backgroundColor: AppTheme.snackbarErrorColor,
        ),
      );
    }
  }

  void _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _collectionDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _collectionDate) {
      setState(() {
        _collectionDate = picked;
      });
    }
  }

  void _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _collectionTime,
    );
    if (picked != null && picked != _collectionTime) {
      setState(() {
        _collectionTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final suppliersAsync = ref.watch(suppliersNotifierProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Record Collection'),
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
              // Collection Information
              _buildSectionTitle('Collection Information'),
              const SizedBox(height: AppTheme.spacing12),
              
              // Supplier Selection
              InkWell(
                onTap: () => _showSupplierSelectionDialog(suppliersAsync),
                child: Container(
                  padding: const EdgeInsets.all(AppTheme.spacing12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
                    border: Border.all(color: AppTheme.thinBorderColor, width: AppTheme.thinBorderWidth),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.person, color: AppTheme.textSecondaryColor),
                      const SizedBox(width: AppTheme.spacing12),
                      Expanded(
                        child: _selectedSupplier == null
                            ? Text(
                                'Select Supplier',
                                style: AppTheme.bodySmall.copyWith(
                                  color: AppTheme.textHintColor,
                                ),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selectedSupplier!.name,
                                    style: AppTheme.bodySmall.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '${_selectedSupplier!.pricePerLiter.toStringAsFixed(0)} Frw/L',
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
                          decoration: const InputDecoration(
                            hintText: 'Rejection Reason',
                            prefixIcon: Icon(Icons.cancel),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          items: reasons.map((reason) {
                            return DropdownMenuItem<String>(
                              value: reason['name'] as String,
                              child: Text(reason['name'] as String, style: AppTheme.bodySmall),
                            );
                          }).toList(),
                          onChanged: (value) => setState(() => _selectedRejectionReason = value),
                          style: AppTheme.bodySmall,
                          dropdownColor: AppTheme.surfaceColor,
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
                              '${_collectionDate.day}/${_collectionDate.month}/${_collectionDate.year}',
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
                              _collectionTime.format(context),
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
              if (_selectedSupplier != null && _quantityController.text.isNotEmpty) ...[
                _buildSummaryCard(),
                const SizedBox(height: AppTheme.spacing24),
              ],

              // Submit Button
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
                  ),
                ),
                child: _isSubmitting
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacing8),
                          Text(
                            'Recording...',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        'Record Collection',
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
    if (_selectedSupplier == null || _quantityController.text.isEmpty) {
      return const SizedBox.shrink();
    }

    final quantity = double.tryParse(_quantityController.text) ?? 0;
    final totalValue = quantity * _selectedSupplier!.pricePerLiter;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Collection Summary',
            style: AppTheme.titleMedium.copyWith(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spacing12),
          _buildSummaryRow('Supplier', _selectedSupplier!.name),
          _buildSummaryRow('Quantity', '${quantity.toStringAsFixed(1)}L'),
          _buildSummaryRow('Price per Liter', '${_selectedSupplier!.pricePerLiter.toStringAsFixed(0)} Frw'),
          _buildSummaryRow('Total Value', '${totalValue.toStringAsFixed(0)} Frw'),
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

  void _showSupplierSelectionDialog(AsyncValue<List<Supplier>> suppliersAsync) {
    final searchController = TextEditingController();
    List<Supplier> suppliers = [];
    List<Supplier> filteredSuppliers = [];

    suppliersAsync.when(
      data: (suppliersList) {
        suppliers = suppliersList;
        filteredSuppliers = suppliersList;
      },
      loading: () {
        suppliers = [];
        filteredSuppliers = [];
      },
      error: (_, __) {
        suppliers = [];
        filteredSuppliers = [];
      },
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
              padding: const EdgeInsets.all(AppTheme.spacing20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  Row(
                    children: [
                      Icon(Icons.person, color: AppTheme.primaryColor, size: 20),
                      const SizedBox(width: AppTheme.spacing8),
                      Text(
                        'Select Supplier',
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
                  const SizedBox(height: AppTheme.spacing16),
                  // Search field
                  TextField(
                    controller: searchController,
                    style: AppTheme.bodySmall,
                    decoration: InputDecoration(
                      hintText: 'Search by name, phone, or address...',
                      hintStyle: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textSecondaryColor,
                        fontSize: 12,
                      ),
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
                        if (value.isEmpty) {
                          filteredSuppliers = suppliers;
                        } else {
                          final query = value.toLowerCase();
                          filteredSuppliers = suppliers.where((supplier) {
                            return supplier.name.toLowerCase().contains(query) ||
                                supplier.phone.toLowerCase().contains(query) ||
                                (supplier.address?.toLowerCase().contains(query) ?? false);
                          }).toList();
                        }
                      });
                    },
                  ),
                  const SizedBox(height: AppTheme.spacing16),
                  // Supplier list
                  SizedBox(
                    height: 300,
                    child: filteredSuppliers.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search_off, size: 48, color: AppTheme.textSecondaryColor),
                                const SizedBox(height: AppTheme.spacing8),
                                Text(
                                  'No suppliers found',
                                  style: AppTheme.bodySmall.copyWith(
                                    color: AppTheme.textSecondaryColor,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: filteredSuppliers.length,
                            itemBuilder: (context, index) {
                              final supplier = filteredSuppliers[index];
                              return ListTile(
                                leading: CircleAvatar(
                                  radius: 20,
                                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                                  child: Text(
                                    supplier.name.isNotEmpty ? supplier.name[0].toUpperCase() : 'S',
                                    style: TextStyle(
                                      color: AppTheme.primaryColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  supplier.name,
                                  style: AppTheme.bodySmall.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      supplier.phone,
                                      style: AppTheme.bodySmall.copyWith(
                                        color: AppTheme.textSecondaryColor,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      '${supplier.pricePerLiter.toStringAsFixed(0)} Frw/L',
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
                                    _selectedSupplier = supplier;
                                  });
                                  Navigator.of(context).pop();
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