import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/utils/phone_validator.dart';
import '../../../../shared/utils/rwandan_phone_input_formatter.dart';
import '../providers/inventory_provider.dart';
import '../../../../core/services/inventory_service.dart';
import '../../../../features/customers/presentation/providers/customers_provider.dart';
import '../../../../features/suppliers/presentation/providers/suppliers_provider.dart';
import '../../../../shared/models/customer.dart';
import '../../../../shared/models/supplier.dart';

class SellInventoryScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> item;

  const SellInventoryScreen({super.key, required this.item});

  @override
  ConsumerState<SellInventoryScreen> createState() => _SellInventoryScreenState();
}

class _SellInventoryScreenState extends ConsumerState<SellInventoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _amountPaidController = TextEditingController();
  final _buyerNameController = TextEditingController();
  final _buyerPhoneController = TextEditingController();
  final _notesController = TextEditingController();

  String _buyerType = 'supplier'; // 'supplier', 'customer', 'other'
  String? _selectedBuyerAccountId;
  DateTime _saleDate = DateTime.now();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final price = (widget.item['price'] as num?) ?? 0;
    final stockQuantity = widget.item['stock_quantity'] ?? 0;
    _quantityController.text = '1';
    _amountPaidController.text = price.toString();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _amountPaidController.dispose();
    _buyerNameController.dispose();
    _buyerPhoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _formatAmount(num amount) {
    final formatter = NumberFormat('#,##0', 'en_US');
    return formatter.format(amount);
  }

  double get _unitPrice => (widget.item['price'] as num?)?.toDouble() ?? 0.0;
  int get _availableStock => widget.item['stock_quantity'] ?? 0;

  double get _calculatedTotal {
    final quantity = double.tryParse(_quantityController.text) ?? 0;
    return quantity * _unitPrice;
  }

  Future<void> _selectSaleDate(BuildContext context) async {
    final now = DateTime.now();
    final firstDate = DateTime(2020);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _saleDate,
      firstDate: firstDate,
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppTheme.textPrimaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _saleDate) {
      setState(() {
        _saleDate = picked;
      });
    }
  }

  Future<void> _submitSale() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final quantity = double.tryParse(_quantityController.text);
    final amountPaid = double.tryParse(_amountPaidController.text) ?? 0;

    if (quantity == null || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        AppTheme.errorSnackBar(message: 'Please enter a valid quantity'),
      );
      return;
    }

    if (quantity > _availableStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        AppTheme.errorSnackBar(
          message: 'Insufficient stock. Available: $_availableStock',
        ),
      );
      return;
    }

    // Validate payment rules
    final totalAmount = _calculatedTotal;
    if (_buyerType != 'supplier' && amountPaid < totalAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        AppTheme.errorSnackBar(
          message: 'Customers and other buyers must pay the full amount upfront',
        ),
      );
      return;
    }

    // Validate supplier requires buyer_account_id
    if (_buyerType == 'supplier' && _selectedBuyerAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        AppTheme.errorSnackBar(
          message: 'Please select a supplier or provide phone number and name',
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final inventoryService = ref.read(inventoryServiceProvider);
      await inventoryService.sellInventoryItem(
        productId: widget.item['id'] as String,
        buyerType: _buyerType,
        buyerAccountId: _selectedBuyerAccountId,
        buyerName: _buyerNameController.text.trim().isEmpty
            ? null
            : _buyerNameController.text.trim(),
        buyerPhone: _buyerPhoneController.text.trim().isEmpty
            ? null
            : _buyerPhoneController.text.trim(),
        quantity: quantity,
        unitPrice: _unitPrice,
        amountPaid: amountPaid,
        saleDate: _saleDate,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppTheme.successSnackBar(message: 'Item sold successfully'),
        );

        // Refresh inventory data
        // ignore: unused_result
        ref.refresh(inventoryProvider(InventoryFilters()));
        // ignore: unused_result
        ref.refresh(inventoryStatsProvider);

        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppTheme.errorSnackBar(message: 'Error: ${e.toString()}'),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customersProvider);
    final suppliersAsync = ref.watch(suppliersProvider);
    final itemName = widget.item['name'] ?? 'Item';

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Sell Item'),
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimaryColor),
        titleTextStyle: AppTheme.titleMedium.copyWith(
          color: AppTheme.textPrimaryColor,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Product Info Card
              Container(
                padding: const EdgeInsets.all(AppTheme.spacing12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                  border: Border.all(
                    color: AppTheme.thinBorderColor,
                    width: AppTheme.thinBorderWidth,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      itemName,
                      style: AppTheme.titleSmall.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Price:',
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                        Text(
                          '${_formatAmount(_unitPrice)} Frw',
                          style: AppTheme.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacing4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Available Stock:',
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                        Text(
                          '$_availableStock units',
                          style: AppTheme.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                            color: _availableStock == 0
                                ? AppTheme.errorColor
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacing16),

              // Buyer Type Selection
              Text(
                'Buyer Type *',
                style: AppTheme.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              const SizedBox(height: AppTheme.spacing8),
              Row(
                children: [
                  Expanded(
                    child: FilterChip(
                      label: const Text('Supplier'),
                      selected: _buyerType == 'supplier',
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _buyerType = 'supplier';
                            _selectedBuyerAccountId = null;
                            _buyerNameController.clear();
                            _buyerPhoneController.clear();
                          });
                        }
                      },
                      backgroundColor: AppTheme.surfaceColor,
                      selectedColor: AppTheme.primaryColor.withOpacity(0.12),
                      checkmarkColor: AppTheme.primaryColor,
                      labelStyle: TextStyle(
                        color: _buyerType == 'supplier'
                            ? AppTheme.primaryColor
                            : AppTheme.textPrimaryColor,
                        fontWeight: _buyerType == 'supplier'
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                      side: BorderSide(
                        color: _buyerType == 'supplier'
                            ? AppTheme.primaryColor
                            : AppTheme.thinBorderColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing8),
                  Expanded(
                    child: FilterChip(
                      label: const Text('Customer'),
                      selected: _buyerType == 'customer',
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _buyerType = 'customer';
                            _selectedBuyerAccountId = null;
                            _buyerNameController.clear();
                            _buyerPhoneController.clear();
                          });
                        }
                      },
                      backgroundColor: AppTheme.surfaceColor,
                      selectedColor: AppTheme.primaryColor.withOpacity(0.12),
                      checkmarkColor: AppTheme.primaryColor,
                      labelStyle: TextStyle(
                        color: _buyerType == 'customer'
                            ? AppTheme.primaryColor
                            : AppTheme.textPrimaryColor,
                        fontWeight: _buyerType == 'customer'
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                      side: BorderSide(
                        color: _buyerType == 'customer'
                            ? AppTheme.primaryColor
                            : AppTheme.thinBorderColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing8),
                  Expanded(
                    child: FilterChip(
                      label: const Text('Other'),
                      selected: _buyerType == 'other',
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _buyerType = 'other';
                            _selectedBuyerAccountId = null;
                            _buyerNameController.clear();
                            _buyerPhoneController.clear();
                          });
                        }
                      },
                      backgroundColor: AppTheme.surfaceColor,
                      selectedColor: AppTheme.primaryColor.withOpacity(0.12),
                      checkmarkColor: AppTheme.primaryColor,
                      labelStyle: TextStyle(
                        color: _buyerType == 'other'
                            ? AppTheme.primaryColor
                            : AppTheme.textPrimaryColor,
                        fontWeight: _buyerType == 'other'
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                      side: BorderSide(
                        color: _buyerType == 'other'
                            ? AppTheme.primaryColor
                            : AppTheme.thinBorderColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacing16),

              // Buyer Selection (for supplier/customer)
              if (_buyerType == 'supplier' || _buyerType == 'customer') ...[
                Text(
                  _buyerType == 'supplier' ? 'Select Supplier *' : 'Select Customer',
                  style: AppTheme.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: AppTheme.spacing8),
                if (_buyerType == 'supplier')
                  suppliersAsync.when(
                    data: (suppliers) => DropdownButtonFormField<String>(
                      value: _selectedBuyerAccountId,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacing12,
                          vertical: AppTheme.spacing12,
                        ),
                      ),
                      hint: Text(
                        'Select supplier',
                        style: AppTheme.hintText,
                      ),
                      items: suppliers.map((supplier) {
                        return DropdownMenuItem<String>(
                          value: supplier.accountCode,
                          child: Text(
                            supplier.name,
                            style: AppTheme.bodySmall,
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedBuyerAccountId = value;
                          _buyerNameController.clear();
                          _buyerPhoneController.clear();
                        });
                      },
                      validator: (value) {
                        if (_buyerType == 'supplier' && value == null) {
                          return 'Please select a supplier or provide phone/name';
                        }
                        return null;
                      },
                    ),
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(AppTheme.spacing16),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (error, stack) => Container(
                      padding: const EdgeInsets.all(AppTheme.spacing12),
                      decoration: BoxDecoration(
                        color: AppTheme.errorColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                      ),
                      child: Text(
                        'Failed to load suppliers',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.errorColor,
                        ),
                      ),
                    ),
                  ),
                if (_buyerType == 'customer')
                  customersAsync.when(
                    data: (customers) => DropdownButtonFormField<String>(
                      value: _selectedBuyerAccountId,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacing12,
                          vertical: AppTheme.spacing12,
                        ),
                      ),
                      hint: Text(
                        'Select customer (optional)',
                        style: AppTheme.hintText,
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('None (new customer)'),
                        ),
                        ...customers.map((customer) {
                          return DropdownMenuItem<String>(
                            value: customer.accountCode,
                            child: Text(
                              customer.name,
                              style: AppTheme.bodySmall,
                            ),
                          );
                        }).toList(),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedBuyerAccountId = value;
                          if (value != null) {
                            _buyerNameController.clear();
                            _buyerPhoneController.clear();
                          }
                        });
                      },
                    ),
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(AppTheme.spacing16),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (error, stack) => Container(
                      padding: const EdgeInsets.all(AppTheme.spacing12),
                      decoration: BoxDecoration(
                        color: AppTheme.errorColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                      ),
                      child: Text(
                        'Failed to load customers',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.errorColor,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: AppTheme.spacing16),
              ],

              // New Client Form (for other buyers or when no buyer selected)
              if (_buyerType == 'other' ||
                  (_buyerType != 'other' && _selectedBuyerAccountId == null)) ...[
                Text(
                  'New Client Info (Optional)',
                  style: AppTheme.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: AppTheme.spacing8),
                TextFormField(
                  controller: _buyerNameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    hintText: 'Buyer name',
                    prefixIcon: Icon(Icons.person_outline, size: 20),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: AppTheme.spacing12),
                TextFormField(
                  controller: _buyerPhoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [PhoneInputFormatter()],
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    hintText: '788606765',
                    prefixIcon: Icon(Icons.phone_outlined, size: 20),
                  ),
                  validator: (value) {
                    if (value != null && value.trim().isNotEmpty) {
                      return PhoneValidator.validateRwandanPhone(value);
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppTheme.spacing16),
              ],

              // Quantity Field
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(
                  labelText: 'Quantity *',
                  hintText: '1',
                  prefixIcon: Icon(Icons.inventory_2_outlined, size: 20),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Quantity is required';
                  }
                  final qty = double.tryParse(value);
                  if (qty == null || qty <= 0) {
                    return 'Quantity must be greater than 0';
                  }
                  if (qty > _availableStock) {
                    return 'Insufficient stock. Available: $_availableStock';
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {
                    // Update amount paid to match total if customer/other
                    if (_buyerType != 'supplier') {
                      final qty = double.tryParse(value) ?? 0;
                      _amountPaidController.text = (qty * _unitPrice).toStringAsFixed(0);
                    }
                  });
                },
              ),
              const SizedBox(height: AppTheme.spacing16),

              // Total Amount Display
              Container(
                padding: const EdgeInsets.all(AppTheme.spacing12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Amount:',
                      style: AppTheme.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${_formatAmount(_calculatedTotal)} Frw',
                      style: AppTheme.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacing16),

              // Amount Paid Field
              TextFormField(
                controller: _amountPaidController,
                decoration: InputDecoration(
                  labelText: _buyerType == 'supplier'
                      ? 'Amount Paid (can be partial) *'
                      : 'Amount Paid (must be full) *',
                  hintText: '0',
                  prefixIcon: const Icon(Icons.payment_outlined, size: 20),
                  suffixText: 'Frw',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Amount paid is required';
                  }
                  final paid = double.tryParse(value) ?? 0;
                  if (paid < 0) {
                    return 'Amount paid cannot be negative';
                  }
                  final total = _calculatedTotal;
                  if (_buyerType != 'supplier' && paid < total) {
                    return 'Must pay full amount for customers/other buyers';
                  }
                  if (paid > total) {
                    return 'Amount paid cannot exceed total amount';
                  }
                  return null;
                },
              ),
              if (_buyerType == 'supplier')
                Padding(
                  padding: const EdgeInsets.only(top: AppTheme.spacing4),
                  child: Text(
                    'Suppliers can buy on credit (debt will be deducted from payroll)',
                    style: AppTheme.labelSmall.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ),
              const SizedBox(height: AppTheme.spacing16),

              // Sale Date Field
              InkWell(
                onTap: () => _selectSaleDate(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Sale Date *',
                    prefixIcon: Icon(Icons.calendar_today_outlined, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(AppTheme.borderRadius8)),
                    ),
                  ),
                  child: Text(
                    DateFormat('MMM dd, yyyy').format(_saleDate),
                    style: AppTheme.bodySmall,
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacing16),

              // Notes Field
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  hintText: 'Additional notes about the sale',
                  prefixIcon: Icon(Icons.note_outlined, size: 20),
                ),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: AppTheme.spacing24),

              // Submit Button
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitSale,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.successColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'Sell Item',
                        style: AppTheme.titleSmall.copyWith(
                          color: Colors.white,
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
}
