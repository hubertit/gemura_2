import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/layout_widgets.dart';
import '../../../collection/presentation/screens/record_collection_screen.dart';

class CollectedMilkScreen extends ConsumerStatefulWidget {
  const CollectedMilkScreen({super.key});

  @override
  ConsumerState<CollectedMilkScreen> createState() => _CollectedMilkScreenState();
}

class _CollectedMilkScreenState extends ConsumerState<CollectedMilkScreen> {
  // Filter variables
  String _selectedSupplier = 'All';
  String _selectedStatus = 'All';
  String _selectedQuality = 'All';
  DateTime? _startDate;
  DateTime? _endDate;
  RangeValues _quantityRange = const RangeValues(0, 100);
  RangeValues _priceRange = const RangeValues(0, 1000);
  
  // Filter options
  List<String> get suppliers => ['All', ...collectedMilkData.map((milk) => milk['supplierName']).toSet().toList()];
  List<String> get statuses => ['All', 'available', 'sold', 'reserved'];
  List<String> get qualities => ['All', 'Grade A', 'Grade B', 'Grade C'];

  // Mock collected milk data
  List<Map<String, dynamic>> get collectedMilkData => [
    {
      'id': 'COL-001',
      'supplierName': 'Jean Pierre Ndayisaba',
      'phone': '0788123456',
      'location': 'Kigali, Gasabo',
      'quantity': 45.0,
      'pricePerLiter': 350,
      'totalValue': 15750,
      'date': DateTime.now().subtract(const Duration(hours: 2)),
      'status': 'available',
      'quality': 'Grade A',
      'notes': 'Fresh morning collection, good quality',
    },
    {
      'id': 'COL-002',
      'supplierName': 'Marie Claire Uwimana',
      'phone': '0733123456',
      'location': 'Kigali, Kicukiro',
      'quantity': 38.0,
      'pricePerLiter': 350,
      'totalValue': 13300,
      'date': DateTime.now().subtract(const Duration(hours: 1)),
      'status': 'available',
      'quality': 'Grade A',
      'notes': 'Quality milk, good fat content',
    },
    {
      'id': 'COL-003',
      'supplierName': 'Emmanuel Niyonsenga',
      'phone': '0725123456',
      'location': 'Kigali, Nyarugenge',
      'quantity': 52.0,
      'pricePerLiter': 350,
      'totalValue': 18200,
      'date': DateTime.now().subtract(const Duration(minutes: 30)),
      'status': 'available',
      'quality': 'Grade B',
      'notes': 'Large quantity, verified quality',
    },
    {
      'id': 'COL-004',
      'supplierName': 'Anastasie Mukamana',
      'phone': '0790123456',
      'location': 'Kigali, Gasabo',
      'quantity': 28.0,
      'pricePerLiter': 350,
      'totalValue': 9800,
      'date': DateTime.now().subtract(const Duration(minutes: 15)),
      'status': 'available',
      'quality': 'Grade A',
      'notes': 'Small quantity, regular supplier',
    },
    {
      'id': 'COL-005',
      'supplierName': 'Francois Nkurunziza',
      'phone': '0755123456',
      'location': 'Kigali, Gasabo',
      'quantity': 65.0,
      'pricePerLiter': 350,
      'totalValue': 22750,
      'date': DateTime.now().subtract(const Duration(hours: 3)),
      'status': 'available',
      'quality': 'Grade A',
      'notes': 'Premium quality, high fat content',
    },
  ];

  List<Map<String, dynamic>> _getFilteredCollectedMilk() {
    return collectedMilkData.where((milk) {
      // Filter by supplier
      if (_selectedSupplier != 'All' && milk['supplierName'] != _selectedSupplier) {
        return false;
      }
      
      // Filter by status
      if (_selectedStatus != 'All' && milk['status'] != _selectedStatus) {
        return false;
      }
      
      // Filter by quality
      if (_selectedQuality != 'All' && milk['quality'] != _selectedQuality) {
        return false;
      }
      
      // Filter by date range
      if (_startDate != null && milk['date'].isBefore(_startDate!)) {
        return false;
      }
      if (_endDate != null && milk['date'].isAfter(_endDate!)) {
        return false;
      }
      
      // Filter by quantity range
      if (milk['quantity'] < _quantityRange.start || milk['quantity'] > _quantityRange.end) {
        return false;
      }
      
      // Filter by price range
      if (milk['pricePerLiter'] < _priceRange.start || milk['pricePerLiter'] > _priceRange.end) {
        return false;
      }
      
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredMilk = _getFilteredCollectedMilk();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Collected Milk'),
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
            tooltip: 'Filter collected milk',
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
      body: filteredMilk.isEmpty
          ? _buildEmptyState(_hasActiveFilters())
          : ListView.builder(
              padding: const EdgeInsets.only(
                top: AppTheme.spacing16,
                left: AppTheme.spacing16,
                right: AppTheme.spacing16,
              ),
              itemCount: filteredMilk.length,
              itemBuilder: (context, index) {
                final milk = filteredMilk[index];
                return _buildCollectedMilkCard(milk);
              },
            ),
    );
  }

  Widget _buildCollectedMilkCard(Map<String, dynamic> milk) {
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
          _showMilkDetails(milk);
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
          milk['supplierName'],
          style: AppTheme.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        subtitle: Text(
          '${DateFormat('MMM dd, yyyy').format(milk['date'])}',
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
              '${milk['quantity'].toStringAsFixed(1)} L',
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${NumberFormat('#,###').format(milk['totalValue'])} Frw',
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
    return _selectedSupplier != 'All' ||
        _selectedStatus != 'All' ||
        _selectedQuality != 'All' ||
        _startDate != null ||
        _endDate != null ||
        _quantityRange != const RangeValues(0, 100) ||
        _priceRange != const RangeValues(0, 1000);
  }

  void _clearFilters() {
    setState(() {
      _selectedSupplier = 'All';
      _selectedStatus = 'All';
      _selectedQuality = 'All';
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
                      'Filter Collected Milk',
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
                      // Supplier Filter
                      Text(
                        'Supplier',
                        style: AppTheme.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacing8),
                      DropdownButtonFormField<String>(
                        value: _selectedSupplier,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: suppliers.map((supplier) {
                          return DropdownMenuItem(
                            value: supplier,
                            child: Text(supplier),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedSupplier = value!;
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
                      const SizedBox(height: AppTheme.spacing16),

                      // Quality Filter
                      Text(
                        'Quality',
                        style: AppTheme.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacing8),
                      DropdownButtonFormField<String>(
                        value: _selectedQuality,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: qualities.map((quality) {
                          return DropdownMenuItem(
                            value: quality,
                            child: Text(quality),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedQuality = value!;
                          });
                        },
                      ),
                      const SizedBox(height: AppTheme.spacing16),

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

  void _showMilkDetails(Map<String, dynamic> milk) {
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
                '${NumberFormat('#,###').format(milk['totalValue'])} Frw',
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
                  '${milk['quantity']} L',
                  style: AppTheme.badge.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          details: [
            DetailRow(label: 'Supplier', value: milk['supplierName']),
            DetailRow(label: 'Phone', value: milk['phone']),
            DetailRow(label: 'Location', value: milk['location']),
            DetailRow(label: 'Quantity', value: '${milk['quantity']} L'),
            DetailRow(label: 'Price/Liter', value: '${milk['pricePerLiter']} Frw'),
            DetailRow(label: 'Total Value', value: '${NumberFormat('#,###').format(milk['totalValue'])} Frw'),
            DetailRow(label: 'Quality', value: milk['quality']),
            DetailRow(label: 'Status', value: milk['status']),
            if (milk['notes'] != null && milk['notes'].isNotEmpty)
              DetailRow(label: 'Notes', value: milk['notes']),
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
            isSearch ? Icons.search_off : Icons.inventory_outlined,
            size: 40,
            color: AppTheme.primaryColor,
          ),
          ),
          const SizedBox(height: AppTheme.spacing24),
          Text(
            isSearch ? 'No search results' : 'No collected milk found',
            style: AppTheme.titleMedium.copyWith(
              color: AppTheme.textPrimaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            isSearch 
                ? 'Try adjusting your search terms or browse all collected milk'
                : 'Collected milk will appear here after recording collections',
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