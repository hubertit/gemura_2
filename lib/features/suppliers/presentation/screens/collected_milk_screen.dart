import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/layout_widgets.dart';
import '../../../collection/presentation/screens/record_collection_screen.dart';
import '../../../collection/presentation/providers/collections_provider.dart';
import '../../presentation/providers/suppliers_provider.dart';
import '../../../../shared/models/collection.dart';
import '../../../../shared/models/supplier.dart';
import '../../../../core/providers/localization_provider.dart';

class CollectedMilkScreen extends ConsumerStatefulWidget {
  const CollectedMilkScreen({super.key});

  @override
  ConsumerState<CollectedMilkScreen> createState() => _CollectedMilkScreenState();
}

class _CollectedMilkScreenState extends ConsumerState<CollectedMilkScreen> {
  // Filter variables
  String _selectedSupplier = 'All';
  String _selectedStatus = 'All';
  DateTime? _startDate;
  DateTime? _endDate;
  RangeValues _quantityRange = const RangeValues(0, 5000);
  RangeValues _priceRange = const RangeValues(0, 1000);
  
  // Store current API filters to avoid recreation
  Map<String, dynamic>? _currentApiFilters;
  
  // Filter options
  List<String> get statuses => ['All', 'accepted', 'pending', 'cancelled'];
  
  // Get supplier name from code using actual supplier data
  String _getSupplierName(String code, List<Supplier> suppliers) {
    if (code == 'All') return 'All Suppliers';
    
    final supplier = suppliers.firstWhere(
      (s) => s.accountCode == code,
      orElse: () => Supplier(
        relationshipId: '',
        pricePerLiter: 0,
        averageSupplyQuantity: 0,
        relationshipStatus: 'inactive',
        supplier: SupplierUser(
          userCode: '',
          name: code,
          phone: '',
          accountCode: code,
          accountName: code,
        ),
      ),
    );
    
    return supplier.name;
  }

  Map<String, dynamic>? _buildApiFilters() {
    if (!_hasActiveFilters()) {
      _currentApiFilters = null;
      return null;
    }
    
    final Map<String, dynamic> filters = {};
    
    // Supplier filter
    if (_selectedSupplier != 'All') {
      filters['supplier_account_code'] = _selectedSupplier;
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
    if (_quantityRange.start > 0 || _quantityRange.end < 100) {
      filters['quantity_min'] = _quantityRange.start;
      filters['quantity_max'] = _quantityRange.end;
    }
    
    // Price range filter
    if (_priceRange.start > 0 || _priceRange.end < 1000) {
      filters['price_min'] = _priceRange.start;
      filters['price_max'] = _priceRange.end;
    }
    
    final result = filters.isEmpty ? null : filters;
    _currentApiFilters = result;
    return result;
  }

  List<Collection> _getFilteredCollections() {
    final apiFilters = _buildApiFilters();
    
    if (apiFilters != null) {
      // Use server-side filtering
      final filteredCollectionsAsync = ref.watch(filteredCollectionsProvider(apiFilters));
      return filteredCollectionsAsync.when(
        data: (collections) => collections,
        loading: () => [],
        error: (error, stack) => [],
      );
    } else {
      // Use client-side filtering (no filters applied)
      final collectionsAsync = ref.watch(collectionsProvider);
      return collectionsAsync.when(
        data: (collections) => collections,
        loading: () => [],
        error: (error, stack) => [],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use cached filters to avoid recreation on every build
    final collectionsAsync = _currentApiFilters != null 
        ? ref.watch(filteredCollectionsProvider(_currentApiFilters!))
        : ref.watch(collectionsProvider);
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Consumer(
          builder: (context, ref, child) {
            final localizationService = ref.watch(localizationServiceProvider);
            return Text(localizationService.translate('collectedMilk'));
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
            tooltip: ref.watch(localizationServiceProvider).translate('filterCollectedMilk'),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const RecordCollectionScreen(),
                ),
              );
            },
            tooltip: 'Add new collection',
          ),
        ],
      ),
      body: collectionsAsync.when(
              loading: () => _buildLoadingState(),
              error: (error, stack) => _buildErrorState(error.toString()),
        data: (collections) {
          return collections.isEmpty
              ? _buildEmptyState(_hasActiveFilters())
              : RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(collectionsProvider);
                    // Also invalidate filtered collections if filters are active
                    if (_currentApiFilters != null) {
                      ref.invalidate(filteredCollectionsProvider(_currentApiFilters!));
                    }
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.only(
                      top: AppTheme.spacing16,
                      left: AppTheme.spacing16,
                      right: AppTheme.spacing16,
                    ),
                    itemCount: collections.length,
                    itemBuilder: (context, index) {
                      final collection = collections[index];
                      return _buildCollectionCard(collection);
                    },
                  ),
                );
        },
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
            'Failed to load collections',
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
              ref.invalidate(collectionsProvider);
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

  Widget _buildCollectionCard(Collection collection) {
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
          _showCollectionDetails(collection);
        },
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
          child: Icon(
            Icons.inventory,
            color: AppTheme.primaryColor,
            size: 20,
          ),
        ),
        title: Text(
          collection.supplierName,
          style: AppTheme.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        subtitle: Text(
          '${DateFormat('MMM dd, yyyy').format(collection.collectionDate)}',
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
              '${collection.quantity.toStringAsFixed(1)} L',
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${NumberFormat('#,###').format(collection.totalValue)} Frw',
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.textSecondaryColor,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: _getStatusColor(collection.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: _getStatusColor(collection.status).withOpacity(0.3),
                  width: 0.5,
                ),
              ),
              child: Text(
                collection.status.toUpperCase(),
                style: AppTheme.bodySmall.copyWith(
                  color: _getStatusColor(collection.status),
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

  bool _hasActiveFilters() {
    return _selectedSupplier != 'All' ||
        _selectedStatus != 'All' ||
        _startDate != null ||
        _endDate != null ||
        _quantityRange != const RangeValues(0, 100) ||
        _priceRange != const RangeValues(0, 1000);
  }

  void _clearFilters() {
    setState(() {
      _selectedSupplier = 'All';
      _selectedStatus = 'All';
      _startDate = null;
      _endDate = null;
      _quantityRange = const RangeValues(0, 100);
      _priceRange = const RangeValues(0, 1000);
      // Reset cached filters
      _currentApiFilters = null;
    });
    // Reload all collections when clearing filters
    ref.invalidate(collectionsProvider);
  }

  void _showFilterDialog() {
    final suppliersAsync = ref.watch(suppliersNotifierProvider);
    
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
            maxHeight: MediaQuery.of(context).size.height * 0.6,
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
                    Consumer(
                      builder: (context, ref, child) {
                        final localizationService = ref.watch(localizationServiceProvider);
                        return Text(
                          localizationService.translate('filterCollectedMilk'),
                          style: AppTheme.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      },
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
                      const SizedBox(height: AppTheme.spacing16),

                      // Supplier Filter
                      Text(
                        'Supplier',
                        style: AppTheme.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacing8),
                      suppliersAsync.when(
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (error, stack) => Text('Error loading suppliers: $error'),
                        data: (suppliers) => DropdownButtonFormField<String>(
                          value: _selectedSupplier,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          items: [
                            'All',
                            ...suppliers.map((supplier) => supplier.accountCode).toList(),
                          ].map((supplierCode) {
                            return DropdownMenuItem(
                              value: supplierCode,
                              child: Text(_getSupplierName(supplierCode, suppliers)),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedSupplier = value!;
                            });
                          },
                        ),
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
                          // Rebuild filters and trigger UI update
                          _buildApiFilters();
                          setState(() {});
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

  void _showCollectionDetails(Collection collection) {
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
                child: Icon(Icons.local_shipping, color: AppTheme.primaryColor, size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                '${NumberFormat('#,###').format(collection.totalValue)} Frw',
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
                  '${collection.quantity} L',
                  style: AppTheme.badge.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(collection.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _getStatusColor(collection.status).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  collection.status.toUpperCase(),
                  style: AppTheme.badge.copyWith(
                    color: _getStatusColor(collection.status),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          details: [
            DetailRow(label: 'Supplier', value: collection.supplierName),
            DetailRow(label: 'Phone', value: collection.supplierPhone),
            DetailRow(label: 'Quantity', value: '${collection.quantity} L'),
            DetailRow(label: 'Price/Liter', value: '${collection.pricePerLiter} Frw'),
            DetailRow(label: 'Total Value', value: '${NumberFormat('#,###').format(collection.totalValue)} Frw'),
            if (collection.quality != null)
              DetailRow(label: 'Quality', value: collection.quality!),
            DetailRow(label: 'Status', value: collection.status),
            if (collection.notes != null && collection.notes!.isNotEmpty)
              DetailRow(label: 'Notes', value: collection.notes!),
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
                        _showUpdateCollectionDialog(collection);
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
                        _showCancelConfirmationDialog(collection);
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

  void _showUpdateCollectionDialog(Collection collection) {
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
          child: _UpdateCollectionForm(collection: collection, onUpdate: () {
            Navigator.of(context).pop();
            // Refresh the collections list
            ref.read(collectionsNotifierProvider.notifier).refreshCollections();
          }),
        ),
      ),
    );
  }

  void _showCancelConfirmationDialog(Collection collection) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Collection'),
        content: Text('Are you sure you want to cancel this collection?\n\nThis action cannot be undone.'),
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
              _cancelCollection(collection);
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

  void _cancelCollection(Collection collection) async {
    try {
      await ref.read(collectionsNotifierProvider.notifier).cancelCollection(
        collectionId: collection.id,
      );

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Collection cancelled successfully'),
            backgroundColor: AppTheme.snackbarSuccessColor,
          ),
        );
        
        // Refresh the collections list
        ref.read(collectionsNotifierProvider.notifier).refreshCollections();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.snackbarErrorColor,
          ),
        );
      }
    }
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
              isSearch ? Icons.search_off : Icons.inventory_outlined,
              size: 40,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: AppTheme.spacing24),
          Consumer(
            builder: (context, ref, child) {
              final localizationService = ref.watch(localizationServiceProvider);
              return Column(
                children: [
                  Text(
                    isSearch ? 'No search results' : localizationService.translate('noCollectedMilkFound'),
                    style: AppTheme.titleMedium.copyWith(
                      color: AppTheme.textPrimaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing8),
                  Text(
                    isSearch 
                        ? 'Try adjusting your search terms or browse all collected milk'
                        : 'Record your first collection to get started',
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
                              builder: (context) => const RecordCollectionScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add, size: 20),
                        label: const Text('Record Collection'),
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
                            _selectedSupplier = 'All';
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
              );
            },
          ),
        ],
      ),
    );
  }
}

class _UpdateCollectionForm extends ConsumerStatefulWidget {
  final Collection collection;
  final VoidCallback onUpdate;

  const _UpdateCollectionForm({
    required this.collection,
    required this.onUpdate,
  });

  @override
  ConsumerState<_UpdateCollectionForm> createState() => _UpdateCollectionFormState();
}

class _UpdateCollectionFormState extends ConsumerState<_UpdateCollectionForm> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _pricePerLiterController = TextEditingController();
  final _notesController = TextEditingController();
  
  String _selectedStatus = 'completed';
  DateTime _selectedDate = DateTime.now();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    _quantityController.text = widget.collection.quantity.toString();
    _pricePerLiterController.text = widget.collection.pricePerLiter.toString();
    _notesController.text = widget.collection.notes ?? '';
    _selectedStatus = widget.collection.status;
    _selectedDate = widget.collection.collectionDate;
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _pricePerLiterController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      await ref.read(collectionsNotifierProvider.notifier).updateCollection(
        collectionId: widget.collection.id,
        quantity: double.parse(_quantityController.text),
        pricePerLiter: double.parse(_pricePerLiterController.text),
        status: _selectedStatus,
        collectionAt: _selectedDate,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Collection updated successfully'),
            backgroundColor: AppTheme.snackbarSuccessColor,
          ),
        );
        widget.onUpdate();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
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
                'Update Collection',
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
                // Quantity
                Text(
                  'Quantity (Liters)',
                  style: AppTheme.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: AppTheme.spacing8),
                TextFormField(
                  controller: _quantityController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Enter quantity',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
                      borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
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
                const SizedBox(height: AppTheme.spacing16),

                // Price per Liter
                Text(
                  'Price per Liter (Frw)',
                  style: AppTheme.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: AppTheme.spacing8),
                TextFormField(
                  controller: _pricePerLiterController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Enter price per liter',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
                      borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter price per liter';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    if (double.parse(value) <= 0) {
                      return 'Price must be greater than 0';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppTheme.spacing16),

                // Status
                Text(
                  'Status',
                  style: AppTheme.bodySmall.copyWith(
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
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
                      borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
                    ),
                  ),
                  items: ['completed', 'pending', 'cancelled'].map((status) {
                    return DropdownMenuItem(
                      value: status,
                      child: Text(status.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedStatus = value!;
                    });
                  },
                ),
                const SizedBox(height: AppTheme.spacing16),

                // Collection Date
                Text(
                  'Collection Date',
                  style: AppTheme.bodySmall.copyWith(
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
                        _selectedDate = DateTime(
                          date.year,
                          date.month,
                          date.day,
                          _selectedDate.hour,
                          _selectedDate.minute,
                        );
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacing16,
                      vertical: AppTheme.spacing12,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.thinBorderColor),
                      borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, color: AppTheme.textSecondaryColor, size: 20),
                        const SizedBox(width: AppTheme.spacing12),
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
                  style: AppTheme.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: AppTheme.spacing8),
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Enter notes',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
                      borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
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
                            'Update Collection',
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