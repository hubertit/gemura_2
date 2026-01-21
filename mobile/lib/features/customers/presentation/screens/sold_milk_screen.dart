import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/layout_widgets.dart';

import '../../../sales/presentation/screens/record_sale_screen.dart';
import '../../../sales/presentation/providers/sales_provider.dart';
import '../../../market/presentation/screens/user_profile_screen.dart';
import '../../../market/presentation/providers/products_provider.dart';
import '../../../../shared/models/sale.dart';
import '../../../../core/providers/localization_provider.dart';

class SoldMilkScreen extends ConsumerStatefulWidget {
  const SoldMilkScreen({super.key});

  @override
  ConsumerState<SoldMilkScreen> createState() => _SoldMilkScreenState();
}

class _SoldMilkScreenState extends ConsumerState<SoldMilkScreen> {
  // Filter variables
  String _selectedCustomer = 'All';
  String _selectedStatus = 'All';
  DateTime? _startDate;
  DateTime? _endDate;
  RangeValues _quantityRange = const RangeValues(0, 200);
  RangeValues _priceRange = const RangeValues(0, 2000);
  
  // Store current API filters to avoid recreation
  Map<String, dynamic>? _currentApiFilters;
  
  // Text controllers for input fields
  late TextEditingController _minQuantityController;
  late TextEditingController _maxQuantityController;
  late TextEditingController _minPriceController;
  late TextEditingController _maxPriceController;
  
  @override
  void initState() {
    super.initState();
    _minQuantityController = TextEditingController(text: _quantityRange.start.toStringAsFixed(1));
    _maxQuantityController = TextEditingController(text: _quantityRange.end.toStringAsFixed(1));
    _minPriceController = TextEditingController(text: _priceRange.start.toStringAsFixed(0));
    _maxPriceController = TextEditingController(text: _priceRange.end.toStringAsFixed(0));
  }
  
  @override
  void dispose() {
    _minQuantityController.dispose();
    _maxQuantityController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }
  
  // Filter options
  List<String> get customers => ['All', ..._getFilteredSales().map((sale) => sale.customerAccount?.name ?? 'Unknown').toSet().toList()];
  List<String> get statuses => ['All', 'accepted', 'pending', 'cancelled'];

  Map<String, dynamic>? _buildApiFilters() {
    if (!_hasActiveFilters()) {
      _currentApiFilters = null;
      return null;
    }
    
    final Map<String, dynamic> filters = {};
    
    // Customer filter
    if (_selectedCustomer != 'All') {
      // Find the customer account code for the selected customer name
      final salesAsync = ref.read(salesProvider);
      final sales = salesAsync.value ?? [];
      final customer = sales.firstWhere(
        (sale) => (sale.customerAccount?.name ?? 'Unknown') == _selectedCustomer,
        orElse: () => sales.first,
      );
      if (customer.customerAccount?.code != null) {
        filters['customer_account_code'] = customer.customerAccount!.code;
      }
    }
    
    // Status filter
    if (_selectedStatus != 'All') {
      filters['status'] = _selectedStatus;
    }
    
    // Date range filter
    if (_startDate != null) {
      filters['date_from'] = DateFormat('yyyy-MM-dd').format(_startDate!);
    }
    if (_endDate != null) {
      filters['date_to'] = DateFormat('yyyy-MM-dd').format(_endDate!);
    }
    
    // Quantity range filter
    if (_quantityRange.start > 0 || _quantityRange.end < 200) {
      filters['quantity_min'] = _quantityRange.start;
      filters['quantity_max'] = _quantityRange.end;
    }
    
    // Price range filter
    if (_priceRange.start > 0 || _priceRange.end < 2000) {
      filters['price_min'] = _priceRange.start;
      filters['price_max'] = _priceRange.end;
    }
    
    final result = filters.isEmpty ? null : filters;
    _currentApiFilters = result;
    return result;
  }

  List<Sale> _getFilteredSales() {
    final apiFilters = _buildApiFilters();
    
    if (apiFilters != null) {
      // Use server-side filtering
      final filteredSalesAsync = ref.watch(filteredSalesProvider(apiFilters));
      return filteredSalesAsync.when(
        data: (sales) => sales,
        loading: () => [],
        error: (error, stack) => [],
      );
    } else {
      // Use client-side filtering (no filters applied)
      final salesAsync = ref.watch(salesProvider);
      return salesAsync.when(
        data: (sales) => sales,
        loading: () => [],
        error: (error, stack) => [],
      );
    }
  }

  List<Sale> _getFilteredSoldMilk() {
    final sales = _getFilteredSales();
    
    // If using server-side filtering, return the results directly
    if (_buildApiFilters() != null) {
      return sales;
    }
    
    // Otherwise, return all sales (no client-side filtering)
    return sales;
  }

  @override
  Widget build(BuildContext context) {
    final apiFilters = _buildApiFilters();
    final salesAsync = apiFilters != null 
        ? ref.watch(filteredSalesProvider(apiFilters))
        : ref.watch(salesProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Consumer(
          builder: (context, ref, child) {
            final localizationService = ref.watch(localizationServiceProvider);
            return Text(localizationService.translate('soldMilk'));
          },
        ),
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimaryColor),
        titleTextStyle: AppTheme.titleMedium.copyWith(color: AppTheme.textPrimaryColor),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              _showFilterDialog();
            },
            tooltip: 'Filter sold milk',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const RecordSaleScreen(),
                ),
              );
            },
            tooltip: 'Add new sale',
          ),
        ],
      ),
      body: salesAsync.when(
        loading: () => _buildLoadingState(),
        error: (error, stack) => _buildErrorState(error.toString()),
        data: (sales) {
          final filteredSales = apiFilters != null ? sales : _getFilteredSoldMilk();
          return filteredSales.isEmpty
              ? _buildEmptyState(_hasActiveFilters())
              : RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(salesProvider);
                    // Also invalidate filtered sales if filters are active
                    if (_currentApiFilters != null) {
                      ref.invalidate(filteredSalesProvider(_currentApiFilters!));
                    }
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.only(
                      top: AppTheme.spacing16,
                      left: AppTheme.spacing16,
                      right: AppTheme.spacing16,
                    ),
                    itemCount: filteredSales.length,
                    itemBuilder: (context, index) {
                      final sale = filteredSales[index];
                      return _buildSoldMilkCard(sale);
                    },
                  ),
                );
        },
      ),
    );
  }

  Widget _buildSoldMilkCard(Sale sale) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacing4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
        border: Border.all(
          color: AppTheme.thinBorderColor,
          width: AppTheme.thinBorderWidth,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacing16,
          vertical: AppTheme.spacing4,
        ),
        onTap: () {
          _showMilkDetails(sale);
        },
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
          child: Icon(
            Icons.shopping_cart,
            color: AppTheme.primaryColor,
            size: 20,
          ),
        ),
        title: Text(
          sale.customerAccount?.name ?? 'Unknown Customer',
          style: AppTheme.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        subtitle: Text(
          '${DateFormat('MMM dd, yyyy').format(sale.saleAtDateTime)}',
          style: AppTheme.bodySmall.copyWith(
            color: AppTheme.textHintColor,
            fontSize: 11,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${sale.quantityAsDouble.toStringAsFixed(1)} L',
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${NumberFormat('#,###').format(sale.totalAmountAsDouble)} Frw',
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.textSecondaryColor,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: _getStatusColor(sale.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: _getStatusColor(sale.status).withOpacity(0.3),
                  width: 0.5,
                ),
              ),
              child: Text(
                sale.status.toUpperCase(),
                style: AppTheme.bodySmall.copyWith(
                  color: _getStatusColor(sale.status),
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _hasActiveFilters() {
    return _selectedCustomer != 'All' ||
        _selectedStatus != 'All' ||
        _startDate != null ||
        _endDate != null ||
        _quantityRange != const RangeValues(0, 200) ||
        _priceRange != const RangeValues(0, 2000);
  }

  void _clearFilters() {
    setState(() {
      _selectedCustomer = 'All';
      _selectedStatus = 'All';
      _startDate = null;
      _endDate = null;
      _quantityRange = const RangeValues(0, 200);
      _priceRange = const RangeValues(0, 2000);
      _currentApiFilters = null;
      
      // Reset text controllers
      _minQuantityController.text = '0.0';
      _maxQuantityController.text = '200.0';
      _minPriceController.text = '0';
      _maxPriceController.text = '2000';
    });
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      default:
        return AppTheme.textSecondaryColor;
    }
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.borderRadius16)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.textHintColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing20),
                child: Row(
                  children: [
                    Icon(Icons.filter_list, color: AppTheme.primaryColor, size: 20),
                    const SizedBox(width: AppTheme.spacing8),
                    Text(
                      'Filter Sold Milk',
                      style: AppTheme.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _clearFilters,
                      child: const Text('Clear All'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppTheme.spacing16),

              // Filter content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Customer Filter
                      Text(
                        'Customer',
                        style: AppTheme.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacing8),
                      DropdownButtonFormField<String>(
                        value: _selectedCustomer,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: customers.map((customer) {
                          return DropdownMenuItem(
                            value: customer,
                            child: Text(customer),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCustomer = value!;
                          });
                        },
                      ),
                      const SizedBox(height: AppTheme.spacing16),

                      // Status Filter
                      Text(
                        'Status',
                        style: AppTheme.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacing8),
                      DropdownButtonFormField<String>(
                        value: _selectedStatus,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: statuses.map((status) {
                          return DropdownMenuItem(
                            value: status,
                            child: Text(status),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedStatus = value!;
                          });
                        },
                      ),


                      // Date Range Filter
                      Text(
                        'Date Range',
                        style: AppTheme.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacing8),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: _startDate ?? DateTime.now(),
                                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                                  lastDate: DateTime.now(),
                                );
                                if (date != null) {
                                  setState(() {
                                    _startDate = date;
                                  });
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppTheme.thinBorderColor),
                                  borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
                                ),
                                child: Text(
                                  _startDate != null 
                                      ? DateFormat('MMM dd, yyyy').format(_startDate!)
                                      : 'Start Date',
                                  style: AppTheme.bodyMedium.copyWith(
                                    color: _startDate != null 
                                        ? AppTheme.textPrimaryColor 
                                        : AppTheme.textHintColor,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacing8),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: _endDate ?? DateTime.now(),
                                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                                  lastDate: DateTime.now(),
                                );
                                if (date != null) {
                                  setState(() {
                                    _endDate = date;
                                  });
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppTheme.thinBorderColor),
                                  borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
                                ),
                                child: Text(
                                  _endDate != null 
                                      ? DateFormat('MMM dd, yyyy').format(_endDate!)
                                      : 'End Date',
                                  style: AppTheme.bodyMedium.copyWith(
                                    color: _endDate != null 
                                        ? AppTheme.textPrimaryColor 
                                        : AppTheme.textHintColor,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spacing16),

                      // Quantity Range Filter
                      Text(
                        'Quantity Range (L)',
                        style: AppTheme.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacing8),
                      RangeSlider(
                        values: RangeValues(
                          _quantityRange.start.clamp(0.0, 200.0),
                          _quantityRange.end.clamp(0.0, 200.0),
                        ),
                        min: 0,
                        max: 200,
                        divisions: 40,
                        activeColor: AppTheme.primaryColor,
                        inactiveColor: AppTheme.primaryColor.withOpacity(0.3),
                        labels: RangeLabels(
                          '${_quantityRange.start.clamp(0.0, 200.0).toStringAsFixed(1)} L',
                          '${_quantityRange.end.clamp(0.0, 200.0).toStringAsFixed(1)} L',
                        ),
                        onChanged: (values) {
                          setState(() {
                            _quantityRange = RangeValues(
                              values.start.clamp(0.0, 200.0),
                              values.end.clamp(0.0, 200.0),
                            );
                          });
                          // Update text controllers
                          _minQuantityController.text = _quantityRange.start.toStringAsFixed(1);
                          _maxQuantityController.text = _quantityRange.end.toStringAsFixed(1);
                        },
                      ),
                      // Quantity input fields
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _minQuantityController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                labelText: 'Min Quantity (L)',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: AppTheme.spacing12,
                                  vertical: AppTheme.spacing8,
                                ),
                              ),
                              onChanged: (value) {
                                final newValue = double.tryParse(value) ?? 0.0;
                                final clampedValue = newValue.clamp(0.0, 200.0);
                                if (clampedValue <= _quantityRange.end && clampedValue >= 0) {
                                  setState(() {
                                    _quantityRange = RangeValues(clampedValue, _quantityRange.end);
                                  });
                                  _minQuantityController.text = clampedValue.toStringAsFixed(1);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacing12),
                          Expanded(
                            child: TextFormField(
                              controller: _maxQuantityController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                labelText: 'Max Quantity (L)',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: AppTheme.spacing12,
                                  vertical: AppTheme.spacing8,
                                ),
                              ),
                              onChanged: (value) {
                                final newValue = double.tryParse(value) ?? 200.0;
                                final clampedValue = newValue.clamp(0.0, 200.0);
                                if (clampedValue >= _quantityRange.start && clampedValue <= 200) {
                                  setState(() {
                                    _quantityRange = RangeValues(_quantityRange.start, clampedValue);
                                  });
                                  _maxQuantityController.text = clampedValue.toStringAsFixed(1);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spacing16),

                      // Price Range Filter
                      Text(
                        'Price Range (Frw/L)',
                        style: AppTheme.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacing8),
                      RangeSlider(
                        values: RangeValues(
                          _priceRange.start.clamp(0.0, 2000.0),
                          _priceRange.end.clamp(0.0, 2000.0),
                        ),
                        min: 0,
                        max: 2000,
                        divisions: 40,
                        activeColor: AppTheme.primaryColor,
                        inactiveColor: AppTheme.primaryColor.withOpacity(0.3),
                        labels: RangeLabels(
                          '${_priceRange.start.clamp(0.0, 2000.0).toStringAsFixed(0)} Frw',
                          '${_priceRange.end.clamp(0.0, 2000.0).toStringAsFixed(0)} Frw',
                        ),
                        onChanged: (values) {
                          setState(() {
                            _priceRange = RangeValues(
                              values.start.clamp(0.0, 2000.0),
                              values.end.clamp(0.0, 2000.0),
                            );
                          });
                          // Update text controllers
                          _minPriceController.text = _priceRange.start.toStringAsFixed(0);
                          _maxPriceController.text = _priceRange.end.toStringAsFixed(0);
                        },
                      ),
                      // Price input fields
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _minPriceController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Min Price (Frw)',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: AppTheme.spacing12,
                                  vertical: AppTheme.spacing8,
                                ),
                              ),
                              onChanged: (value) {
                                final newValue = double.tryParse(value) ?? 0.0;
                                final clampedValue = newValue.clamp(0.0, 2000.0);
                                if (clampedValue <= _priceRange.end && clampedValue >= 0) {
                                  setState(() {
                                    _priceRange = RangeValues(clampedValue, _priceRange.end);
                                  });
                                  _minPriceController.text = clampedValue.toStringAsFixed(0);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacing12),
                          Expanded(
                            child: TextFormField(
                              controller: _maxPriceController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Max Price (Frw)',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: AppTheme.spacing12,
                                  vertical: AppTheme.spacing8,
                                ),
                              ),
                              onChanged: (value) {
                                final newValue = double.tryParse(value) ?? 2000.0;
                                final clampedValue = newValue.clamp(0.0, 2000.0);
                                if (clampedValue >= _priceRange.start && clampedValue <= 2000) {
                                  setState(() {
                                    _priceRange = RangeValues(_priceRange.start, clampedValue);
                                  });
                                  _maxPriceController.text = clampedValue.toStringAsFixed(0);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spacing20),
                    ],
                  ),
                ),
              ),

              // Action buttons
              Padding(
                padding: const EdgeInsets.all(AppTheme.spacing20),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
                          ),
                          side: BorderSide(
                            color: AppTheme.primaryColor,
                            width: AppTheme.thinBorderWidth,
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: AppTheme.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacing12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          // Refresh the data with new filters
                          if (_currentApiFilters != null) {
                            ref.invalidate(filteredSalesProvider(_currentApiFilters!));
                          }
                          // The provider watching will handle the rebuild automatically
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: AppTheme.surfaceColor,
                          padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
                          ),
                        ),
                        child: Text(
                          'Apply',
                          style: AppTheme.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.surfaceColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: AppTheme.errorColor),
          const SizedBox(height: AppTheme.spacing16),
          Text(
            'Failed to load sales',
            style: AppTheme.titleMedium.copyWith(
              color: AppTheme.textPrimaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            error,
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacing16),
          ElevatedButton.icon(
            onPressed: () {
              ref.invalidate(salesProvider);
            },
            icon: const Icon(Icons.refresh, size: 20),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacing24,
                vertical: AppTheme.spacing16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToCustomerProfile(Sale sale) {
    // Create a TopSeller from customer data
    final customer = TopSeller(
      id: int.tryParse(sale.customerAccount?.code ?? '1') ?? 1,
      code: sale.customerAccount?.code ?? 'CUST001',
      name: sale.customerAccount?.name ?? 'Unknown Customer',
      email: '${sale.customerAccount?.code ?? 'customer'}@example.com',
      phone: '+250700000000', // Default phone since SaleAccount doesn't have phone
      imageUrl: null,
      totalProducts: 0,
      totalSales: 0,
      totalReviews: 0,
      rating: 4.5,
      isVerified: false,
      location: '-1.9441,30.0619', // Default Kigali coordinates
      joinDate: DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
    );

    Navigator.of(context).pop(); // Close bottom sheet
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => UserProfileScreen(user: customer),
      ),
    );
  }

  void _navigateToSupplierProfile(Sale sale) {
    // Create a TopSeller from supplier data
    final supplier = TopSeller(
      id: int.tryParse(sale.supplierAccount?.code ?? '1') ?? 1,
      code: sale.supplierAccount?.code ?? 'SUP001',
      name: sale.supplierAccount?.name ?? 'Unknown Supplier',
      email: '${sale.supplierAccount?.code ?? 'supplier'}@example.com',
      phone: '+250700000000', // Default phone since SaleAccount doesn't have phone
      imageUrl: null,
      totalProducts: 0,
      totalSales: 0,
      totalReviews: 0,
      rating: 4.5,
      isVerified: false,
      location: '-1.9441,30.0619', // Default Kigali coordinates
      joinDate: DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
    );

    Navigator.of(context).pop(); // Close bottom sheet
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => UserProfileScreen(user: supplier),
      ),
    );
  }

  void _showMilkDetails(Sale sale) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.borderRadius16)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: DetailsActionSheet(
          title: 'Milk Details',
          headerWidget: Column(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: AppTheme.primaryColor.withOpacity(0.12),
                child: Icon(Icons.shopping_cart, color: AppTheme.primaryColor, size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                '${NumberFormat('#,###').format(sale.totalAmountAsDouble)} Frw',
                style: AppTheme.headlineLarge.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  '${sale.quantityAsDouble} L',
                  style: AppTheme.badge.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          details: [
            DetailRow(
              label: 'Customer', 
              value: sale.customerAccount?.name ?? 'Unknown',
              customValue: GestureDetector(
                onTap: () => _navigateToCustomerProfile(sale),
                child: Text(
                  sale.customerAccount?.name ?? 'Unknown',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
            DetailRow(label: 'Quantity', value: '${sale.quantityAsDouble} L'),
            DetailRow(label: 'Price/Liter', value: '${sale.unitPriceAsDouble} Frw'),
            DetailRow(label: 'Total Value', value: '${NumberFormat('#,###').format(sale.totalAmountAsDouble)} Frw'),
            DetailRow(label: 'Status', value: sale.status),
            DetailRow(label: 'Sale Date', value: DateFormat('MMM dd, yyyy HH:mm').format(sale.saleAtDateTime)),
            if (sale.notes != null && sale.notes!.isNotEmpty)
              DetailRow(label: 'Notes', value: sale.notes!),
          ],
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing20),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _showUpdateSaleDialog(sale);
                      },
                      icon: const Icon(Icons.edit, size: 20),
                      label: const Text('Update'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacing24,
                          vertical: AppTheme.spacing16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _showCancelConfirmationDialog(sale);
                      },
                      icon: const Icon(Icons.cancel, size: 20),
                      label: const Text('Cancel'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.errorColor,
                        side: BorderSide(color: AppTheme.errorColor, width: 1),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacing24,
                          vertical: AppTheme.spacing16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildEmptyState([bool isSearch = false]) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isSearch ? Icons.search_off : Icons.shopping_cart_outlined,
              size: 40,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: AppTheme.spacing24),
          Text(
            isSearch ? 'No search results' : 'No sold milk found',
            style: AppTheme.titleMedium.copyWith(
              color: AppTheme.textPrimaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            isSearch 
                ? 'Try adjusting your search terms or browse all sold milk'
                : 'Record your first sale to get started',
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacing32),
          if (!isSearch)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing32),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const RecordSaleScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Record Sale'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacing24,
                    vertical: AppTheme.spacing16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
                  ),
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing32),
              child: OutlinedButton.icon(
                onPressed: () {
                  // Clear search filters
                  setState(() {
                    _selectedCustomer = 'All';
                    _selectedStatus = 'All';
                    _startDate = null;
                    _endDate = null;
                    _quantityRange = const RangeValues(0, 200);
                    _priceRange = const RangeValues(0, 2000);
                    _currentApiFilters = null;
                  });
                },
                icon: const Icon(Icons.clear, size: 20),
                label: const Text('Clear Filters'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                  side: BorderSide(color: AppTheme.primaryColor, width: 1),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacing24,
                    vertical: AppTheme.spacing16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showUpdateSaleDialog(Sale sale) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.borderRadius16)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: _UpdateSaleForm(sale: sale, onUpdate: () {
            Navigator.of(context).pop();
            // Refresh the sales list
            ref.invalidate(salesProvider);
            if (_currentApiFilters != null) {
              ref.invalidate(filteredSalesProvider(_currentApiFilters!));
            }
          }),
        ),
      ),
    );
  }

  void _showCancelConfirmationDialog(Sale sale) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Sale'),
        content: Text('Are you sure you want to cancel this sale?\n\nThis action cannot be undone.'),
        backgroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('No, Keep'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop(); // Close confirmation dialog
              // Close the action sheet as well
              Navigator.of(context).pop();
              // Wait a bit for the sheets to close
              await Future.delayed(const Duration(milliseconds: 100));
              _cancelSale(sale);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _cancelSale(Sale sale) async {
    try {
      await ref.read(salesNotifierProvider.notifier).cancelSale(
        saleId: sale.id,
      );

      // Wait a bit for the state to update
      await Future.delayed(const Duration(milliseconds: 100));
      
      final salesState = ref.read(salesNotifierProvider);
      
      if (salesState.isSuccess) {
        if (mounted) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Sale cancelled successfully'),
              backgroundColor: AppTheme.successColor,
            ),
          );
          
          // Force refresh the sales list
          ref.invalidate(salesProvider);
          if (_currentApiFilters != null) {
            ref.invalidate(filteredSalesProvider(_currentApiFilters!));
          }
          
          // Additional refresh to ensure UI updates
          setState(() {});
        }
      } else if (salesState.error != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${salesState.error}'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      } else {
        // If no success or error state, show a generic message
        if (mounted) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Sale cancelled'),
              backgroundColor: AppTheme.successColor,
            ),
          );
          
          // Force refresh the sales list
          ref.invalidate(salesProvider);
          if (_currentApiFilters != null) {
            ref.invalidate(filteredSalesProvider(_currentApiFilters!));
          }
          
          // Additional refresh to ensure UI updates
          setState(() {});
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
}

class _UpdateSaleForm extends ConsumerStatefulWidget {
  final Sale sale;
  final VoidCallback onUpdate;

  const _UpdateSaleForm({
    required this.sale,
    required this.onUpdate,
  });

  @override
  ConsumerState<_UpdateSaleForm> createState() => _UpdateSaleFormState();
}

class _UpdateSaleFormState extends ConsumerState<_UpdateSaleForm> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _notesController = TextEditingController();
  
  String _selectedStatus = 'accepted';
  DateTime _selectedDate = DateTime.now();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    _quantityController.text = widget.sale.quantityAsDouble.toString();
    _notesController.text = widget.sale.notes ?? '';
    _selectedStatus = widget.sale.status;
    _selectedDate = widget.sale.saleAtDateTime;
    
    // Set the customer from the sale data
    if (widget.sale.customerAccount != null) {
      // We'll need to find the customer from the customers list
      // For now, we'll use the sale's customer data
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      await ref.read(salesNotifierProvider.notifier).updateSale(
        saleId: widget.sale.id,
        customerAccountId: widget.sale.customerAccount?.id,
        customerAccountCode: widget.sale.customerAccount?.id == null ? (widget.sale.customerAccount?.code ?? '') : null,
        quantity: double.parse(_quantityController.text),
        status: _selectedStatus,
        saleAt: _selectedDate,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      // Wait a bit for the state to update
      await Future.delayed(const Duration(milliseconds: 100));
      
      final salesState = ref.read(salesNotifierProvider);
      
      if (salesState.isSuccess) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Sale updated successfully'),
              backgroundColor: AppTheme.successColor,
            ),
          );
          widget.onUpdate();
        }
      } else if (salesState.error != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${salesState.error}'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      } else {
        // If no success or error state, show a generic message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Sale update completed'),
              backgroundColor: AppTheme.successColor,
            ),
          );
          widget.onUpdate();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorColor,
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
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.edit, color: AppTheme.primaryColor, size: 20),
              const SizedBox(width: AppTheme.spacing8),
              Text(
                'Update Sale',
                style: AppTheme.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing20),

          // Form
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Customer Info (Read-only)
                Text(
                  'Customer',
                  style: AppTheme.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: AppTheme.spacing8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppTheme.spacing12),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                    border: Border.all(
                      color: AppTheme.thinBorderColor,
                      width: AppTheme.thinBorderWidth,
                    ),
                  ),
                  child: Text(
                    widget.sale.customerAccount?.name ?? 'Unknown Customer',
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spacing16),

                // Quantity
                Text(
                  'Quantity (L)',
                  style: AppTheme.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: AppTheme.spacing8),
                TextFormField(
                  controller: _quantityController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    hintText: 'Enter quantity in liters',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacing12,
                      vertical: AppTheme.spacing12,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Quantity is required';
                    }
                    final quantity = double.tryParse(value);
                    if (quantity == null || quantity <= 0) {
                      return 'Please enter a valid quantity';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppTheme.spacing16),

                // Status
                Text(
                  'Status',
                  style: AppTheme.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: AppTheme.spacing8),
                DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacing12,
                      vertical: AppTheme.spacing12,
                    ),
                  ),
                  items: ['accepted', 'pending', 'cancelled'].map((status) {
                    return DropdownMenuItem(
                      value: status,
                      child: Text(status.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedStatus = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: AppTheme.spacing16),

                // Date
                Text(
                  'Sale Date',
                  style: AppTheme.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: AppTheme.spacing8),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() {
                        _selectedDate = date;
                      });
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppTheme.spacing12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppTheme.thinBorderColor,
                        width: AppTheme.thinBorderWidth,
                      ),
                      borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, color: AppTheme.textSecondaryColor, size: 20),
                        const SizedBox(width: AppTheme.spacing8),
                        Text(
                          DateFormat('MMM dd, yyyy').format(_selectedDate),
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spacing16),

                // Notes
                Text(
                  'Notes (Optional)',
                  style: AppTheme.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: AppTheme.spacing8),
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Add any additional notes...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacing12,
                      vertical: AppTheme.spacing12,
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spacing24),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: AppTheme.surfaceColor,
                      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
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
                            'Update Sale',
                            style: AppTheme.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.surfaceColor,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 