import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../../shared/widgets/confirmation_dialog.dart';
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
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddEditInventoryScreen(item: item),
            ),
          );
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
                  Row(
                    children: [
                      StatusBadge(
                        status: status.toUpperCase(),
                        color: statusColor,
                      ),
                      const SizedBox(width: AppTheme.spacing8),
                      PopupMenuButton(
                        icon: const Icon(Icons.more_vert, size: 20),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit,
                                    size: 18, color: AppTheme.primaryColor),
                                SizedBox(width: AppTheme.spacing8),
                                Text('Edit'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'toggle',
                            child: Row(
                              children: [
                                Icon(
                                  isListed
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  size: 18,
                                  color: AppTheme.infoColor,
                                ),
                                const SizedBox(width: AppTheme.spacing8),
                                Text(isListed
                                    ? 'Unlist'
                                    : 'List in Marketplace'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete,
                                    size: 18, color: AppTheme.errorColor),
                                SizedBox(width: AppTheme.spacing8),
                                Text('Delete'),
                              ],
                            ),
                          ),
                        ],
                        onSelected: (value) {
                          if (value == 'edit') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    AddEditInventoryScreen(item: item),
                              ),
                            );
                          } else if (value == 'toggle') {
                            _toggleMarketplaceListing(item['id'], isListed);
                          } else if (value == 'delete') {
                            _deleteItem(item['id']);
                          }
                        },
                      ),
                    ],
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
