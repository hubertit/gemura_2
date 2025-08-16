import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/layout_widgets.dart';
import '../../../../shared/widgets/skeleton_loaders.dart';
import '../../../sales/presentation/screens/record_sale_screen.dart';
import '../../../sales/presentation/providers/sales_provider.dart';
import '../../../../shared/models/sale.dart';

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
  RangeValues _quantityRange = const RangeValues(0, 100);
  RangeValues _priceRange = const RangeValues(0, 1000);
  
  // Filter options
  List<String> get customers => ['All', ..._getFilteredSales().map((sale) => sale.customerAccount?.name ?? 'Unknown').toSet().toList()];
  List<String> get statuses => ['All', 'accepted', 'pending', 'cancelled'];

  List<Sale> _getFilteredSales() {
    final salesAsync = ref.watch(salesProvider);
    return salesAsync.when(
      data: (sales) => sales,
      loading: () => [],
      error: (error, stack) => [],
    );
  }

  List<Sale> _getFilteredSoldMilk() {
    final sales = _getFilteredSales();
    return sales.where((sale) {
      // Filter by customer
      if (_selectedCustomer != 'All' && (sale.customerAccount?.name ?? 'Unknown') != _selectedCustomer) {
        return false;
      }
      
      // Filter by status
      if (_selectedStatus != 'All' && sale.status != _selectedStatus) {
        return false;
      }
      
      // Filter by date range
      if (_startDate != null && sale.saleAtDateTime.isBefore(_startDate!)) {
        return false;
      }
      if (_endDate != null && sale.saleAtDateTime.isAfter(_endDate!)) {
        return false;
      }
      
      // Filter by quantity range
      if (sale.quantityAsDouble < _quantityRange.start || sale.quantityAsDouble > _quantityRange.end) {
        return false;
      }
      
      // Filter by price range
      if (sale.unitPriceAsDouble < _priceRange.start || sale.unitPriceAsDouble > _priceRange.end) {
        return false;
      }
      
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final salesAsync = ref.watch(salesProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Sold Milk'),
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
          final filteredSales = _getFilteredSoldMilk();
          return filteredSales.isEmpty
              ? _buildEmptyState(_hasActiveFilters())
              : RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(salesProvider);
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
        _quantityRange != const RangeValues(0, 100) ||
        _priceRange != const RangeValues(0, 1000);
  }

  void _clearFilters() {
    setState(() {
      _selectedCustomer = 'All';
      _selectedStatus = 'All';
      _startDate = null;
      _endDate = null;
      _quantityRange = const RangeValues(0, 100);
      _priceRange = const RangeValues(0, 1000);
    });
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
                        values: _quantityRange,
                        min: 0,
                        max: 100,
                        divisions: 20,
                        labels: RangeLabels(
                          '${_quantityRange.start.round()} L',
                          '${_quantityRange.end.round()} L',
                        ),
                        onChanged: (values) {
                          setState(() {
                            _quantityRange = values;
                          });
                        },
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
                        values: _priceRange,
                        min: 0,
                        max: 1000,
                        divisions: 20,
                        labels: RangeLabels(
                          '${_priceRange.start.round()} Frw',
                          '${_priceRange.end.round()} Frw',
                        ),
                        onChanged: (values) {
                          setState(() {
                            _priceRange = values;
                          });
                        },
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
          ElevatedButton(
            onPressed: () {
              ref.invalidate(salesProvider);
            },
            child: const Text('Retry'),
          ),
        ],
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
            DetailRow(label: 'Customer', value: sale.customerAccount?.name ?? 'Unknown'),
            DetailRow(label: 'Customer Code', value: sale.customerAccount?.code ?? 'N/A'),
            DetailRow(label: 'Supplier', value: sale.supplierAccount?.name ?? 'Unknown'),
            DetailRow(label: 'Supplier Code', value: sale.supplierAccount?.code ?? 'N/A'),
            DetailRow(label: 'Quantity', value: '${sale.quantityAsDouble} L'),
            DetailRow(label: 'Price/Liter', value: '${sale.unitPriceAsDouble} Frw'),
            DetailRow(label: 'Total Value', value: '${NumberFormat('#,###').format(sale.totalAmountAsDouble)} Frw'),
            DetailRow(label: 'Status', value: sale.status),
            DetailRow(label: 'Sale Date', value: DateFormat('MMM dd, yyyy HH:mm').format(sale.saleAtDateTime)),
            if (sale.notes != null && sale.notes!.isNotEmpty)
              DetailRow(label: 'Notes', value: sale.notes!),
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
                : 'Sold milk will appear here after recording sales',
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
} 