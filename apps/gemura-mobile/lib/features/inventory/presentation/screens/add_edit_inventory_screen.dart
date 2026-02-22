import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../providers/inventory_provider.dart';

class AddEditInventoryScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? item;

  const AddEditInventoryScreen({super.key, this.item});

  @override
  ConsumerState<AddEditInventoryScreen> createState() =>
      _AddEditInventoryScreenState();
}

class _AddEditInventoryScreenState
    extends ConsumerState<AddEditInventoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockQuantityController = TextEditingController();
  final _minStockLevelController = TextEditingController();

  /// For Add mode: selected predefined item (id + name).
  String? _selectedInventoryItemId;
  String? _selectedInventoryItemName;

  bool _isListedInMarketplace = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      _nameController.text = widget.item!['name']?.toString() ?? '';
      _descriptionController.text =
          widget.item!['description']?.toString() ?? '';
      _priceController.text = (widget.item!['price'] as num?)?.toString() ?? '';
      _stockQuantityController.text =
          (widget.item!['stock_quantity'] as num?)?.toString() ?? '';
      _minStockLevelController.text =
          (widget.item!['min_stock_level'] as num?)?.toString() ?? '';
      _isListedInMarketplace = widget.item!['is_listed_in_marketplace'] == true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockQuantityController.dispose();
    _minStockLevelController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final isEdit = widget.item != null;
    if (!isEdit && _selectedInventoryItemId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        AppTheme.errorSnackBar(message: 'Please select an item type'),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final inventoryService = ref.read(inventoryServiceProvider);

      if (isEdit) {
        await inventoryService.updateInventoryItem(
          id: widget.item!['id'],
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          price: double.parse(_priceController.text),
          stockQuantity: int.parse(_stockQuantityController.text),
          minStockLevel: _minStockLevelController.text.trim().isEmpty
              ? null
              : int.parse(_minStockLevelController.text),
          isListedInMarketplace: _isListedInMarketplace,
        );
      } else {
        await inventoryService.createInventoryItem(
          inventoryItemId: _selectedInventoryItemId,
          name: _selectedInventoryItemId != null
              ? null
              : _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          price: double.parse(_priceController.text),
          stockQuantity: int.parse(_stockQuantityController.text),
          minStockLevel: _minStockLevelController.text.trim().isEmpty
              ? null
              : int.parse(_minStockLevelController.text),
          isListedInMarketplace: _isListedInMarketplace,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppTheme.successSnackBar(
            message: isEdit
                ? 'Inventory item updated successfully'
                : 'Inventory item created successfully',
          ),
        );

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

  void _showItemPicker(BuildContext context, Map<String, dynamic> grouped) {
    final categories =
        (grouped['categories'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return _ItemPickerSheet(
          categories: categories,
          onSelect: (id, name) {
            setState(() {
              _selectedInventoryItemId = id;
              _selectedInventoryItemName = name;
            });
            Navigator.of(ctx).pop();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.item != null;
    final groupedAsync = ref.watch(predefinedInventoryItemsProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Item' : 'Add Item'),
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimaryColor),
        titleTextStyle:
            AppTheme.titleMedium.copyWith(color: AppTheme.textPrimaryColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isEdit) ...[
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Item Name *',
                    hintText: 'e.g., Fresh Milk 1L',
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Item name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppTheme.spacing16),
              ] else ...[
                // Add mode: select from predefined list
                groupedAsync.when(
                  data: (grouped) {
                    final categories = grouped['categories'] as List<dynamic>? ?? [];
                    final hasItems = categories.isNotEmpty;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        InkWell(
                          onTap: hasItems
                              ? () => _showItemPicker(context, grouped)
                              : null,
                          borderRadius:
                              BorderRadius.circular(AppTheme.borderRadius8),
                          child: Container(
                            padding: const EdgeInsets.all(AppTheme.spacing16),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceColor,
                              borderRadius:
                                  BorderRadius.circular(AppTheme.borderRadius8),
                              border: Border.all(
                                color: _selectedInventoryItemId != null
                                    ? AppTheme.primaryColor
                                    : AppTheme.thinBorderColor,
                                width: AppTheme.thinBorderWidth,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.inventory_2_outlined,
                                  color: _selectedInventoryItemId != null
                                      ? AppTheme.primaryColor
                                      : AppTheme.textHintColor,
                                  size: 24,
                                ),
                                const SizedBox(width: AppTheme.spacing12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Item type *',
                                        style: AppTheme.labelSmall.copyWith(
                                          color: AppTheme.textSecondaryColor,
                                        ),
                                      ),
                                      const SizedBox(height: AppTheme.spacing4),
                                      Text(
                                        _selectedInventoryItemName ??
                                            (hasItems
                                                ? 'Tap to select'
                                                : 'No items loaded'),
                                        style: AppTheme.bodyMedium.copyWith(
                                          color: _selectedInventoryItemName != null
                                              ? AppTheme.textPrimaryColor
                                              : AppTheme.textHintColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (hasItems)
                                  const Icon(
                                    Icons.arrow_drop_down,
                                    color: AppTheme.textSecondaryColor,
                                  ),
                              ],
                            ),
                          ),
                        ),
                        if (!hasItems)
                          Padding(
                            padding: const EdgeInsets.only(top: AppTheme.spacing8),
                            child: Text(
                              'Item list could not be loaded. Check your connection.',
                              style: AppTheme.labelSmall.copyWith(
                                color: AppTheme.textSecondaryColor,
                              ),
                            ),
                          ),
                        const SizedBox(height: AppTheme.spacing16),
                      ],
                    );
                  },
                  loading: () => const SizedBox(
                    height: 56,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (_, __) => Container(
                    padding: const EdgeInsets.all(AppTheme.spacing16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius:
                          BorderRadius.circular(AppTheme.borderRadius8),
                      border: Border.all(color: AppTheme.thinBorderColor),
                    ),
                    child: const Text(
                      'Could not load item list. Try again later.',
                      style: AppTheme.bodySmall,
                    ),
                  ),
                ),
              ],

              // Description Field
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Optional description',
                ),
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: AppTheme.spacing16),

              // Price Field
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Price (Frw) *',
                  hintText: '0',
                  prefixText: 'Frw ',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Price is required';
                  }
                  final price = double.tryParse(value);
                  if (price == null || price < 0) {
                    return 'Please enter a valid price';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.spacing16),

              // Stock Quantity Field
              TextFormField(
                controller: _stockQuantityController,
                decoration: const InputDecoration(
                  labelText: 'Stock Quantity *',
                  hintText: '0',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
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
              const SizedBox(height: AppTheme.spacing16),

              // Min Stock Level Field
              TextFormField(
                controller: _minStockLevelController,
                decoration: const InputDecoration(
                  labelText: 'Min Stock Level (Optional)',
                  hintText: 'Alert when stock reaches this level',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    final minLevel = int.tryParse(value);
                    if (minLevel == null || minLevel < 0) {
                      return 'Please enter a valid number';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.spacing16),

              // List in Marketplace Toggle
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
                child: Row(
                  children: [
                    const Icon(Icons.store,
                        color: AppTheme.infoColor, size: 20),
                    const SizedBox(width: AppTheme.spacing12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'List in Marketplace',
                            style: AppTheme.bodySmall.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacing2),
                          Text(
                            'Make this item visible in marketplace',
                            style: AppTheme.labelSmall.copyWith(
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isListedInMarketplace,
                      onChanged: (value) {
                        setState(() {
                          _isListedInMarketplace = value;
                        });
                      },
                      activeColor: AppTheme.primaryColor,
                      inactiveThumbColor: AppTheme.errorColor.withOpacity(0.7),
                      inactiveTrackColor: AppTheme.errorColor.withOpacity(0.3),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacing24),

              PrimaryButton(
                label: isEdit ? 'Update Item' : 'Create Item',
                onPressed: _isSubmitting ? null : _submitForm,
                isLoading: _isSubmitting,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Two-step item picker: tap category first, then see items with search.
class _ItemPickerSheet extends StatefulWidget {
  final List<Map<String, dynamic>> categories;
  final void Function(String id, String name) onSelect;

  const _ItemPickerSheet({
    required this.categories,
    required this.onSelect,
  });

  @override
  State<_ItemPickerSheet> createState() => _ItemPickerSheetState();
}

class _ItemPickerSheetState extends State<_ItemPickerSheet> {
  Map<String, dynamic>? _selectedCategory;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _items {
    if (_selectedCategory == null) return [];
    final list =
        (_selectedCategory!['items'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    if (_searchQuery.trim().isEmpty) return list;
    final q = _searchQuery.trim().toLowerCase();
    return list.where((item) {
      final name = (item['name'] as String? ?? '').toLowerCase();
      return name.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, scrollController) {
        if (_selectedCategory == null) {
          // Step 1: show categories
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppTheme.spacing16),
                child: Text(
                  'Select category',
                  style: AppTheme.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: widget.categories.length,
                  itemBuilder: (_, index) {
                    final cat = widget.categories[index];
                    final name = cat['name'] as String? ?? 'Category';
                    final items =
                        (cat['items'] as List<dynamic>?)?.length ?? 0;
                    return ListTile(
                      title: Text(name),
                      subtitle: Text('$items items'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        setState(() {
                          _selectedCategory = cat;
                          _searchQuery = '';
                          _searchController.clear();
                        });
                      },
                    );
                  },
                ),
              ),
            ],
          );
        }

        // Step 2: show items in selected category with search
        final items = _items;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacing16,
                vertical: AppTheme.spacing8,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      setState(() {
                        _selectedCategory = null;
                        _searchQuery = '';
                        _searchController.clear();
                      });
                    },
                  ),
                  Expanded(
                    child: Text(
                      _selectedCategory!['name'] as String? ?? 'Items',
                      style: AppTheme.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spacing16,
                0,
                AppTheme.spacing16,
                AppTheme.spacing8,
              ),
              child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by name...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppTheme.borderRadius8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacing12,
                      vertical: AppTheme.spacing12,
                    ),
                  ),
                  textCapitalization: TextCapitalization.none,
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ),
            const Divider(height: 1),
            Expanded(
              child: items.isEmpty
                  ? SizedBox(
                      width: double.infinity,
                      child: Center(
                        child: Text(
                          _searchQuery.trim().isEmpty
                              ? 'No items in this category'
                              : 'No items match "$_searchQuery"',
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: items.length,
                      itemBuilder: (_, index) {
                        final item = items[index];
                        final id = item['id'] as String? ?? '';
                        final name = item['name'] as String? ?? '';
                        final unit = item['unit'] as String?;
                        final label = unit != null && unit.isNotEmpty
                            ? '$name ($unit)'
                            : name;
                        return ListTile(
                          title: Text(label),
                          onTap: () => widget.onSelect(id, name),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}
