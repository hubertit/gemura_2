import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gemura/core/theme/app_theme.dart';
import '../../../../shared/models/customer.dart';
import '../../../../shared/widgets/skeleton_loaders.dart';
import '../../../../shared/widgets/confirmation_dialog.dart';
import '../providers/customers_provider.dart';
import 'add_customer_screen.dart';

class CustomersListScreen extends ConsumerStatefulWidget {
  const CustomersListScreen({super.key});

  @override
  ConsumerState<CustomersListScreen> createState() => _CustomersListScreenState();
}

class _CustomersListScreenState extends ConsumerState<CustomersListScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
      }
    });
  }

  List<Customer> _getFilteredCustomers(List<Customer> customers) {
    String searchQuery = _searchController.text.toLowerCase();
    
    if (searchQuery.isEmpty) {
      return customers;
    }
    
    return customers.where((customer) {
      return customer.name.toLowerCase().contains(searchQuery) ||
          customer.phone.toLowerCase().contains(searchQuery) ||
          (customer.address != null && customer.address!.toLowerCase().contains(searchQuery)) ||
          (customer.nid != null && customer.nid!.toLowerCase().contains(searchQuery));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customersNotifierProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: _isSearching
            ? _buildSearchField()
            : const Text('Customers'),
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimaryColor),
        titleTextStyle: AppTheme.titleMedium.copyWith(color: AppTheme.textPrimaryColor),
        actions: [
          if (_isSearching)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _toggleSearch,
              tooltip: 'Close search',
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: _toggleSearch,
              tooltip: 'Search customers',
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AddCustomerScreen(),
                  ),
                );
              },
              tooltip: 'Add customer',
            ),
          ],
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(customersNotifierProvider.notifier).refreshCustomers();
        },
        child: customersAsync.when(
          loading: () => _buildLoadingState(),
          error: (error, stackTrace) => _buildErrorState(error.toString()),
          data: (customers) {
            final filteredCustomers = _getFilteredCustomers(customers);
            return Column(
              children: [
                if (_searchController.text.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(AppTheme.spacing16),
                    child: Text(
                      '${filteredCustomers.length} result${filteredCustomers.length == 1 ? '' : 's'} found',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ),
                Expanded(
                  child: filteredCustomers.isEmpty
                      ? _buildEmptyState(_searchController.text.isNotEmpty)
                      : ListView.builder(
                          padding: const EdgeInsets.only(
                            top: AppTheme.spacing16,
                            left: AppTheme.spacing16,
                            right: AppTheme.spacing16,
                          ),
                          itemCount: filteredCustomers.length,
                          itemBuilder: (context, index) {
                            final customer = filteredCustomers[index];
                            return _buildCustomerCard(customer);
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showCustomerBottomSheet(Customer customer) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            
            // Customer info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                    child: Text(
                      customer.name.isNotEmpty 
                          ? customer.name[0].toUpperCase() 
                          : 'C',
                      style: AppTheme.titleMedium.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    customer.name,
                    style: AppTheme.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (customer.phone.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      customer.phone,
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Stats
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(
                        'RWF ${customer.pricePerLiter.toStringAsFixed(0)}',
                        style: AppTheme.titleMedium.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Price per liter',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.grey[300],
                  ),
                  Column(
                    children: [
                      Text(
                        '${customer.averageSupplyQuantity.toStringAsFixed(1)}L',
                        style: AppTheme.titleMedium.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Daily average',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Action buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _showUpdatePriceDialog(customer);
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
                          Navigator.of(context).pop();
                          _showDeleteConfirmationDialog(customer);
                        },
                        icon: const Icon(Icons.delete, size: 20),
                        label: const Text('Delete'),
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
            
            const SizedBox(height: AppTheme.spacing20),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      autofocus: true,
      style: AppTheme.bodyMedium,
      decoration: InputDecoration(
        hintText: 'Search customers...',
        hintStyle: AppTheme.bodyMedium.copyWith(color: AppTheme.textHintColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
          borderSide: BorderSide.none,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
          borderSide: BorderSide.none,
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: AppTheme.textHintColor.withOpacity(0.1),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  setState(() {});
                },
              )
            : null,
      ),
      onChanged: (value) {
        setState(() {});
      },
    );
  }

  Widget _buildCustomerCard(Customer customer) {
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
        onTap: () => _showCustomerBottomSheet(customer),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
          child: Text(
            customer.name.isNotEmpty 
                ? customer.name[0].toUpperCase() 
                : 'C',
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          customer.name,
          style: AppTheme.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (customer.phone.isNotEmpty)
              Row(
                children: [
                  Icon(
                    Icons.phone,
                    size: 14,
                    color: AppTheme.textSecondaryColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    customer.phone,
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.textSecondaryColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),

          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${customer.pricePerLiter.toStringAsFixed(0)} Frw/L',
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${customer.averageSupplyQuantity.toStringAsFixed(1)}L/day',
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



  void _showUpdatePriceDialog(Customer customer) {
    final TextEditingController priceController = TextEditingController(
      text: customer.pricePerLiter.toString(),
    );
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Colors.white,
          title: Text(
            'Update Price',
            style: AppTheme.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Update price for ${customer.name}',
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Price per liter (RWF)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final newPrice = double.tryParse(priceController.text);
                      if (newPrice == null || newPrice <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a valid price'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      setState(() {
                        isSubmitting = true;
                      });

                      try {
                        await ref.read(customersNotifierProvider.notifier).updateCustomerPrice(
                          customerAccountCode: customer.accountCode, // Use account code, not relationship ID
                          pricePerLiter: newPrice,
                        );

                        if (mounted) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Price updated successfully'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          setState(() {
                            isSubmitting = false;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to update price: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog(Customer customer) {
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => ConfirmationDialog(
          title: 'Delete Customer',
          message: 'Are you sure you want to delete ${customer.name}? This action cannot be undone.',
          isDestructive: true,
          isLoading: isSubmitting,
          onConfirm: () async {
            setState(() {
              isSubmitting = true;
            });

            try {
              await ref.read(customersNotifierProvider.notifier).deleteCustomer(
                customerAccountCode: customer.accountCode,
              );

              if (mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  AppTheme.successSnackBar(
                    message: 'Customer deleted successfully',
                  ),
                );
              }
            } catch (e) {
              if (mounted) {
                setState(() {
                  isSubmitting = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  AppTheme.errorSnackBar(
                    message: 'Failed to delete customer: $e',
                  ),
                );
              }
            }
          },
          onCancel: () => Navigator.of(context).pop(),
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
              isSearch ? Icons.search_off : Icons.people_outline,
              size: 40,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: AppTheme.spacing24),
          Text(
            isSearch ? 'No search results' : 'No customers found',
            style: AppTheme.titleMedium.copyWith(
              color: AppTheme.textPrimaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            isSearch 
                ? 'Try adjusting your search terms or browse all customers'
                : 'Add your first customer to get started',
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacing32),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing32),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AddCustomerScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Add Customer'),
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
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return SkeletonLoaders.customerListSkeleton();
  }

  Widget _buildErrorState(String errorMessage) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.errorColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline,
              size: 40,
              color: AppTheme.errorColor,
            ),
          ),
          const SizedBox(height: AppTheme.spacing24),
          Text(
            'Failed to load customers',
            style: AppTheme.titleMedium.copyWith(
              color: AppTheme.textPrimaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spacing8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing32),
            child: Text(
              errorMessage,
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppTheme.spacing24),
          ElevatedButton.icon(
            onPressed: () {
              ref.read(customersNotifierProvider.notifier).loadCustomers();
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
} 