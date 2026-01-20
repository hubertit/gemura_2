import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../../shared/widgets/confirmation_dialog.dart';
import '../../../../shared/widgets/layout_widgets.dart';
import '../providers/inventory_provider.dart';
import 'add_edit_inventory_screen.dart';

class InventoryListScreen extends ConsumerStatefulWidget {
  const InventoryListScreen({super.key});

  @override
  ConsumerState<InventoryListScreen> createState() =>
      _InventoryListScreenState();
}

class _InventoryListScreenState extends ConsumerState<InventoryListScreen> {
  String? _selectedStatus;
  bool _showLowStock = false;

  String _formatAmount(num amount) {
    final formatter = NumberFormat('#,##0', 'en_US');
    return formatter.format(amount);
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return AppTheme.successColor;
      case 'out_of_stock':
        return AppTheme.errorColor;
      case 'inactive':
        return AppTheme.textSecondaryColor;
      default:
        return AppTheme.textSecondaryColor;
    }
  }

  Future<void> _deleteItem(String id) async {
    print('🗑️ [DELETE] Starting deletion for item: $id');
    
    final confirmed = await ConfirmationDialog.showDelete(
      context: context,
      title: 'Delete Item',
      message: 'Are you sure you want to delete this inventory item? This action cannot be undone.',
    );

    if (!confirmed) {
      print('🗑️ [DELETE] Deletion cancelled by user');
      return;
    }

    print('🗑️ [DELETE] User confirmed deletion, calling API...');
    
    try {
      final inventoryService = ref.read(inventoryServiceProvider);
      await inventoryService.deleteInventoryItem(id);
      
      print('🗑️ [DELETE] API call successful, item deleted from backend');

      if (mounted) {
        // Create the same filter instance that's being watched
        final filters = InventoryFilters(
          status: _selectedStatus,
          lowStock: _showLowStock ? true : null,
        );
        
        print('🗑️ [DELETE] Current filters - status: $_selectedStatus, lowStock: $_showLowStock');
        print('🗑️ [DELETE] Created filter instance: ${filters.hashCode}');
        print('🗑️ [DELETE] Refreshing inventoryProvider...');
        
        // Use refresh instead of invalidate to force immediate reload
        final refreshedData = ref.refresh(inventoryProvider(filters));
        print('🗑️ [DELETE] inventoryProvider refreshed, result: ${refreshedData.hasValue ? "has value" : "no value"}');
        
        print('🗑️ [DELETE] Refreshing inventoryStatsProvider...');
        // ignore: unused_result
        ref.refresh(inventoryStatsProvider);
        print('🗑️ [DELETE] inventoryStatsProvider refreshed');
        
        print('🗑️ [DELETE] Showing success message');
        ScaffoldMessenger.of(context).showSnackBar(
          AppTheme.successSnackBar(
              message: 'Inventory item deleted successfully'),
        );
        
        print('🗑️ [DELETE] All refresh operations completed');
      } else {
        print('🗑️ [DELETE] Widget not mounted, skipping UI updates');
      }
    } catch (e, stackTrace) {
      print('🗑️ [DELETE] ERROR: $e');
      print('🗑️ [DELETE] Stack trace: $stackTrace');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppTheme.errorSnackBar(message: 'Error: ${e.toString()}'),
        );
      }
    }
  }

  Future<void> _toggleMarketplaceListing(String id, bool currentValue) async {
    try {
      final inventoryService = ref.read(inventoryServiceProvider);
      await inventoryService.toggleMarketplaceListing(
        id: id,
        isListedInMarketplace: !currentValue,
      );

      if (mounted) {
        // Create the same filter instance that's being watched
        final filters = InventoryFilters(
          status: _selectedStatus,
          lowStock: _showLowStock ? true : null,
        );
        
        // Use refresh instead of invalidate to force immediate reload
        // ignore: unused_result
        ref.refresh(inventoryProvider(filters));
        // ignore: unused_result
        ref.refresh(inventoryStatsProvider);
        
        ScaffoldMessenger.of(context).showSnackBar(
          AppTheme.successSnackBar(
            message: !currentValue
                ? 'Item listed in marketplace'
                : 'Item removed from marketplace',
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppTheme.errorSnackBar(message: 'Error: ${e.toString()}'),
        );
      }
    }
  }

  void _showInventoryItemBottomSheet(
      BuildContext context, Map<String, dynamic> item) {
    final status = item['status']?.toString() ?? 'unknown';
    final statusColor = _getStatusColor(status);
    final stockQuantity = item['stock_quantity'] ?? 0;
    final minStockLevel = item['min_stock_level'];
    final isLowStock = minStockLevel != null && stockQuantity <= minStockLevel;
    final isListed = item['is_listed_in_marketplace'] == true;
    final price = item['price'] as num? ?? 0;
    final description = item['description']?.toString() ?? '';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DetailsActionSheet(
        title: item['name'] ?? 'Inventory Item',
        headerWidget: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacing16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inventory_2,
                size: 32,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: AppTheme.spacing12),
            Text(
              '${_formatAmount(price)} Frw',
              style: AppTheme.titleLarge.copyWith(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.spacing8),
            StatusBadge(
              status: status.toUpperCase(),
              color: statusColor,
            ),
          ],
        ),
        details: [
          DetailRow(
            label: 'Stock Quantity',
            value: stockQuantity.toString(),
            valueColor: isLowStock ? AppTheme.warningColor : null,
          ),
          if (minStockLevel != null)
            DetailRow(
              label: 'Min Stock Level',
              value: minStockLevel.toString(),
            ),
          if (description.isNotEmpty)
            DetailRow(
              label: 'Description',
              value: description,
            ),
          DetailRow(
            label: 'Marketplace',
            value: isListed ? 'Listed' : 'Not Listed',
            valueColor: isListed ? AppTheme.infoColor : AppTheme.textSecondaryColor,
          ),
          if (item['created_at'] != null)
            DetailRow(
              label: 'Created',
              value: DateFormat('MMM dd, yyyy').format(
                DateTime.parse(item['created_at']),
              ),
            ),
        ],
        actions: [
          // Compact button grid
          Row(
            children: [
              // Edit Button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddEditInventoryScreen(item: item),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Edit'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: AppTheme.surfaceColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacing12,
                      vertical: AppTheme.spacing12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spacing8),
              // Stock Button
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _showStockMovementDialog(context, item);
                  },
                  icon: const Icon(Icons.inventory, size: 18),
                  label: const Text('Stock'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    side: BorderSide(color: AppTheme.primaryColor, width: 1),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacing12,
                      vertical: AppTheme.spacing12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing8),
          Row(
            children: [
              // List/Unlist Button
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _toggleMarketplaceListing(item['id'], isListed);
                  },
                  icon: Icon(
                    isListed ? Icons.visibility_off : Icons.visibility,
                    size: 18,
                  ),
                  label: Text(isListed ? 'Unlist' : 'List'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.infoColor,
                    side: BorderSide(color: AppTheme.infoColor, width: 1),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacing12,
                      vertical: AppTheme.spacing12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spacing8),
              // Delete Button
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _deleteItem(item['id']);
                  },
                  icon: const Icon(Icons.delete, size: 18),
                  label: const Text('Delete'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.errorColor,
                    side: BorderSide(color: AppTheme.errorColor, width: 1),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacing12,
                      vertical: AppTheme.spacing12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showStockMovementDialog(
      BuildContext context, Map<String, dynamic> item) {
    final currentStock = item['stock_quantity'] ?? 0;
    final itemName = item['name'] ?? 'Item';
    final stockController = TextEditingController(text: currentStock.toString());
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) => _StockMovementDialog(
        itemName: itemName,
        currentStock: currentStock,
        itemId: item['id'],
        stockController: stockController,
        formKey: formKey,
        onSuccess: () {
          // Refresh inventory data
          final filters = InventoryFilters(
            status: _selectedStatus,
            lowStock: _showLowStock ? true : null,
          );
          // ignore: unused_result
          ref.refresh(inventoryProvider(filters));
          // ignore: unused_result
          ref.refresh(inventoryStatsProvider);
        },
      ),
    );
  }
}

class _StockMovementDialog extends ConsumerStatefulWidget {
  final String itemName;
  final int currentStock;
  final String itemId;
  final TextEditingController stockController;
  final GlobalKey<FormState> formKey;

  const _StockMovementDialog({
    required this.itemName,
    required this.currentStock,
    required this.itemId,
    required this.stockController,
    required this.formKey,
    required this.onSuccess,
  });

  final VoidCallback onSuccess;

  @override
  ConsumerState<_StockMovementDialog> createState() =>
      _StockMovementDialogState();
}

class _StockMovementDialogState extends ConsumerState<_StockMovementDialog> {
  bool _isSubmitting = false;

  @override
  void dispose() {
    widget.stockController.dispose();
    super.dispose();
  }

  Future<void> _updateStock() async {
    if (widget.formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      try {
        final newStock = int.parse(widget.stockController.text);
        final inventoryService = ref.read(inventoryServiceProvider);
        await inventoryService.updateStock(
          id: widget.itemId,
          stockQuantity: newStock,
        );

        if (mounted) {
          widget.onSuccess();
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            AppTheme.successSnackBar(
              message: 'Stock updated successfully',
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            AppTheme.errorSnackBar(
              message: 'Error: ${e.toString()}',
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surfaceColor,
      title: Text(
        'Adjust Stock',
        style: AppTheme.titleMedium.copyWith(
          color: AppTheme.textPrimaryColor,
        ),
      ),
      content: Form(
        key: widget.formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.itemName,
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: AppTheme.spacing8),
            Text(
              'Current Stock: ${widget.currentStock}',
              style: AppTheme.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: AppTheme.spacing16),
            TextFormField(
              controller: widget.stockController,
              decoration: const InputDecoration(
                labelText: 'New Stock Quantity *',
                hintText: 'Enter new quantity',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              autofocus: true,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Stock quantity is required';
                }
                final quantity = int.tryParse(value);
                if (quantity == null || quantity < 0) {
                  return 'Please enter a valid quantity';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting
              ? null
              : () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _updateStock,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: AppTheme.surfaceColor,
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Update'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final filters = InventoryFilters(
      status: _selectedStatus,
      lowStock: _showLowStock ? true : null,
    );
    
    print('🔄 [BUILD] InventoryListScreen building');
    print('🔄 [BUILD] Current filters - status: $_selectedStatus, lowStock: $_showLowStock');
    print('🔄 [BUILD] Filter instance hashCode: ${filters.hashCode}');
    
    final inventoryAsync = ref.watch(inventoryProvider(filters));
    final statsAsync = ref.watch(inventoryStatsProvider);
    
    print('🔄 [BUILD] inventoryAsync state: ${inventoryAsync.runtimeType}');
    inventoryAsync.when(
      data: (items) => print('🔄 [BUILD] Data state - ${items.length} items: ${items.map((e) => e['id']).toList()}'),
      loading: () => print('🔄 [BUILD] Loading state'),
      error: (err, stack) => print('🔄 [BUILD] Error state: $err'),
    );

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Inventory'),
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimaryColor),
        titleTextStyle:
            AppTheme.titleMedium.copyWith(color: AppTheme.textPrimaryColor),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Item',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddEditInventoryScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Statistics Card
          statsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (stats) => Container(
              margin: const EdgeInsets.all(AppTheme.spacing16),
              padding: const EdgeInsets.all(AppTheme.spacing16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                border: Border.all(
                  color: AppTheme.thinBorderColor,
                  width: AppTheme.thinBorderWidth,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('Total', stats['total_items'] ?? 0,
                      AppTheme.primaryColor),
                  _buildStatItem('Active', stats['active_items'] ?? 0,
                      AppTheme.successColor),
                  _buildStatItem('Low Stock', stats['low_stock_items'] ?? 0,
                      AppTheme.warningColor),
                  _buildStatItem('Listed', stats['listed_in_marketplace'] ?? 0,
                      AppTheme.infoColor),
                ],
              ),
            ),
          ),
          // Filters
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: AppTheme.spacing12,
                        vertical: AppTheme.spacing12,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem<String>(value: null, child: Text('All')),
                      DropdownMenuItem<String>(
                          value: 'active', child: Text('Active')),
                      DropdownMenuItem<String>(
                          value: 'out_of_stock', child: Text('Out of Stock')),
                      DropdownMenuItem<String>(
                          value: 'inactive', child: Text('Inactive')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedStatus = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: AppTheme.spacing8),
                FilterChip(
                  label: const Text('Low Stock'),
                  selected: _showLowStock,
                  onSelected: (selected) {
                    setState(() {
                      _showLowStock = selected;
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacing8),
          // Inventory List
          Expanded(
            child: inventoryAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacing24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppTheme.errorColor, size: 48),
                      const SizedBox(height: AppTheme.spacing16),
                      Text(
                        'Error loading inventory',
                        style: AppTheme.titleSmall.copyWith(
                          color: AppTheme.errorColor,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacing8),
                      Text(
                        error.toString(),
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.textSecondaryColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppTheme.spacing16),
                      ElevatedButton(
                        onPressed: () {
                          ref.invalidate(inventoryProvider(filters));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacing24,
                            vertical: AppTheme.spacing12,
                          ),
                        ),
                        child: const Text(
                          'Retry',
                          style: TextStyle(color: AppTheme.surfaceColor),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.spacing24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 64,
                            color: AppTheme.textSecondaryColor.withOpacity(0.5),
                          ),
                          const SizedBox(height: AppTheme.spacing16),
                          Text(
                            'No inventory items found',
                            style: AppTheme.titleSmall.copyWith(
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacing8),
                          Text(
                            'Add your first inventory item to get started',
                            style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.textSecondaryColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppTheme.spacing24),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const AddEditInventoryScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Add Item'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: AppTheme.surfaceColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(inventoryProvider(filters));
                    ref.invalidate(inventoryStatsProvider);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppTheme.spacing16),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return _buildInventoryCard(context, item);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: AppTheme.titleMedium.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppTheme.spacing4),
        Text(
          label,
          style: AppTheme.labelSmall.copyWith(
            color: AppTheme.textSecondaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildInventoryCard(BuildContext context, Map<String, dynamic> item) {
    final status = item['status']?.toString() ?? 'unknown';
    final statusColor = _getStatusColor(status);
    final stockQuantity = item['stock_quantity'] ?? 0;
    final minStockLevel = item['min_stock_level'];
    final isLowStock = minStockLevel != null && stockQuantity <= minStockLevel;
    final isListed = item['is_listed_in_marketplace'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacing8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
        border: Border.all(
          color: AppTheme.thinBorderColor,
          width: AppTheme.thinBorderWidth,
        ),
      ),
      child: InkWell(
        onTap: () {
          _showInventoryItemBottomSheet(context, item);
        },
        borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacing12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['name'] ?? 'Unknown',
                          style: AppTheme.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacing4),
                        if (item['description'] != null &&
                            item['description'].toString().isNotEmpty)
                          Text(
                            item['description'].toString(),
                            style: AppTheme.labelSmall.copyWith(
                              color: AppTheme.textSecondaryColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  StatusBadge(
                    status: status.toUpperCase(),
                    color: statusColor,
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacing8),
              Row(
                children: [
                  const Icon(
                    Icons.inventory_2_outlined,
                    size: 14,
                    color: AppTheme.textSecondaryColor,
                  ),
                  const SizedBox(width: AppTheme.spacing4),
                  Text(
                    'Stock: $stockQuantity',
                    style: AppTheme.bodySmall.copyWith(
                      color: isLowStock
                          ? AppTheme.warningColor
                          : AppTheme.textSecondaryColor,
                      fontWeight:
                          isLowStock ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  if (minStockLevel != null) ...[
                    const SizedBox(width: AppTheme.spacing8),
                    Text(
                      '(Min: $minStockLevel)',
                      style: AppTheme.labelSmall.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                  const Spacer(),
                  Text(
                    '${_formatAmount(item['price'] as num)} Frw',
                    style: AppTheme.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
              if (isListed) ...[
                const SizedBox(height: AppTheme.spacing4),
                Row(
                  children: [
                    const Icon(
                      Icons.store,
                      size: 12,
                      color: AppTheme.infoColor,
                    ),
                    const SizedBox(width: AppTheme.spacing4),
                    Text(
                      'Listed in Marketplace',
                      style: AppTheme.labelXSmall.copyWith(
                        color: AppTheme.infoColor,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
