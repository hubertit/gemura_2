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

    setState(() {
      _isSubmitting = true;
    });

    try {
      final inventoryService = ref.read(inventoryServiceProvider);

      if (widget.item != null) {
        // Update existing item
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
        );
      } else {
        // Create new item
        await inventoryService.createInventoryItem(
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
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppTheme.successSnackBar(
            message: widget.item != null
                ? 'Inventory item updated successfully'
                : 'Inventory item created successfully',
          ),
        );

        // Refresh providers to get updated data
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
    final isEdit = widget.item != null;

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
              // Name Field
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

              // Description Field
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Optional description',
                ),
                maxLines: 3,
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
                  helperText: 'Leave empty to disable low stock alerts',
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

              // List in Marketplace Toggle (only for new items)
              if (!isEdit) ...[
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
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spacing24),
              ],

              // Submit Button
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
