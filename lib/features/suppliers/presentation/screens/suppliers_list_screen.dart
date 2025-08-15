import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gemura/core/theme/app_theme.dart';
import 'package:gemura/features/suppliers/presentation/providers/suppliers_provider.dart';
import 'package:gemura/shared/models/supplier.dart';
import 'package:gemura/features/suppliers/presentation/screens/add_supplier_screen.dart';
import 'package:gemura/features/suppliers/presentation/screens/supplier_details_screen.dart';
import 'package:gemura/shared/widgets/skeleton_loaders.dart';

class SuppliersListScreen extends ConsumerStatefulWidget {
  const SuppliersListScreen({super.key});

  @override
  ConsumerState<SuppliersListScreen> createState() => _SuppliersListScreenState();
}

class _SuppliersListScreenState extends ConsumerState<SuppliersListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Supplier> _getFilteredSuppliers(List<Supplier> suppliers) {
    String searchQuery = _searchController.text.toLowerCase();
    
    if (searchQuery.isEmpty) {
      return suppliers;
    }
    
    return suppliers.where((supplier) {
      return supplier.name.toLowerCase().contains(searchQuery) ||
          supplier.phone.toLowerCase().contains(searchQuery) ||
          (supplier.address != null && supplier.address!.toLowerCase().contains(searchQuery)) ||
          (supplier.email != null && supplier.email!.toLowerCase().contains(searchQuery)) ||
          (supplier.nid != null && supplier.nid!.toLowerCase().contains(searchQuery));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final suppliersAsync = ref.watch(suppliersNotifierProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Suppliers'),
            if (_searchController.text.isNotEmpty)
              Text(
                '${suppliersAsync.when(
                  data: (suppliers) => _getFilteredSuppliers(suppliers).length,
                  loading: () => 0,
                  error: (_, __) => 0,
                )} result${suppliersAsync.when(
                  data: (suppliers) => _getFilteredSuppliers(suppliers).length == 1 ? '' : 's',
                  loading: () => 's',
                  error: (_, __) => 's',
                )}',
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.textSecondaryColor,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimaryColor),
        titleTextStyle: AppTheme.titleMedium.copyWith(color: AppTheme.textPrimaryColor),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                setState(() {});
              },
              tooltip: 'Clear search',
            ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              _showSearchDialog();
            },
            tooltip: 'Search suppliers',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AddSupplierScreen(),
                ),
              );
            },
            tooltip: 'Add supplier',
          ),
        ],
      ),
      body: suppliersAsync.when(
        loading: () => _buildLoadingState(),
        error: (error, stack) => _buildErrorState(error.toString()),
        data: (suppliers) {
          final filteredSuppliers = _getFilteredSuppliers(suppliers);
          
          if (filteredSuppliers.isEmpty) {
            return _buildEmptyState(_searchController.text.isNotEmpty);
          }
          
          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(suppliersNotifierProvider.notifier).refreshSuppliers();
            },
            child: ListView.builder(
              padding: const EdgeInsets.only(
                top: AppTheme.spacing16,
                left: AppTheme.spacing16,
                right: AppTheme.spacing16,
              ),
              itemCount: filteredSuppliers.length,
              itemBuilder: (context, index) {
                final supplier = filteredSuppliers[index];
                return _buildSupplierCard(supplier);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildSupplierCard(Supplier supplier) {
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
          // TODO: Navigate to supplier details when screen is updated
          // Navigator.of(context).push(
          //   MaterialPageRoute(
          //     builder: (context) => SupplierDetailsScreen(supplier: supplier),
          //   ),
          // );
        },
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
          child: Text(
            supplier.name.isNotEmpty ? supplier.name[0].toUpperCase() : 'S',
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          supplier.name,
          style: AppTheme.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        subtitle: Row(
          children: [
            Icon(
              Icons.phone,
              size: 14,
              color: AppTheme.textSecondaryColor,
            ),
            const SizedBox(width: 6),
            Text(
              supplier.phone,
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.textSecondaryColor,
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${supplier.pricePerLiter.toStringAsFixed(0)} Frw/L',
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${supplier.averageSupplyQuantity.toStringAsFixed(1)}L/day',
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



  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppTheme.surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius16),
        ),
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spacing20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              Row(
                children: [
                  Icon(Icons.search, color: AppTheme.primaryColor, size: 18),
                  const SizedBox(width: AppTheme.spacing8),
                  Text(
                    'Search Suppliers',
                    style: AppTheme.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacing16),
              // Search Field
              TextFormField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search by name, phone, or location...',
                  hintStyle: AppTheme.bodySmall.copyWith(color: AppTheme.textHintColor),
                  prefixIcon: Icon(Icons.search, color: AppTheme.textSecondaryColor, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: AppTheme.textSecondaryColor, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
                    borderSide: BorderSide(color: AppTheme.thinBorderColor, width: AppTheme.thinBorderWidth),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
                    borderSide: BorderSide(color: AppTheme.thinBorderColor, width: AppTheme.thinBorderWidth),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
                    borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
                    borderSide: BorderSide(color: AppTheme.errorColor, width: 1),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
                    borderSide: BorderSide(color: AppTheme.thinBorderColor, width: AppTheme.thinBorderWidth),
                  ),
                  filled: true,
                  fillColor: AppTheme.backgroundColor,
                  contentPadding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing12, vertical: AppTheme.spacing8),
                ),
                style: AppTheme.bodySmall.copyWith(color: AppTheme.textPrimaryColor),
                onChanged: (value) {
                  setState(() {});
                },
              ),
              const SizedBox(height: AppTheme.spacing12),
              // Info Text
              Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: AppTheme.textSecondaryColor),
                  const SizedBox(width: AppTheme.spacing4),
                  Expanded(
                    child: Text(
                      'Search is case-insensitive and works across all supplier fields',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textSecondaryColor,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacing16),
              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      'Cancel',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing8),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: AppTheme.surfaceColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                      ),
                    ),
                    child: Text(
                      'Search',
                      style: AppTheme.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }



  Widget _buildLoadingState() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Suppliers'),
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimaryColor),
        titleTextStyle: AppTheme.titleMedium.copyWith(color: AppTheme.textPrimaryColor),
      ),
      backgroundColor: AppTheme.backgroundColor,
      body: SkeletonLoaders.supplierListSkeleton(),
    );
  }

  Widget _buildErrorState(String error) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Suppliers'),
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimaryColor),
        titleTextStyle: AppTheme.titleMedium.copyWith(color: AppTheme.textPrimaryColor),
      ),
      backgroundColor: AppTheme.backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppTheme.errorColor,
            ),
            const SizedBox(height: AppTheme.spacing16),
            Text(
              'Failed to load suppliers',
              style: AppTheme.titleMedium.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: AppTheme.spacing8),
            Text(
              error,
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.textHintColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacing16),
            ElevatedButton(
              onPressed: () {
                ref.read(suppliersNotifierProvider.notifier).loadSuppliers();
              },
              child: const Text('Retry'),
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
              isSearch ? Icons.search_off : Icons.people_outline,
              size: 40,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: AppTheme.spacing24),
          Text(
            isSearch ? 'No search results' : 'No suppliers found',
            style: AppTheme.titleMedium.copyWith(
              color: AppTheme.textPrimaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            isSearch 
                ? 'Try adjusting your search terms or browse all suppliers'
                : 'Add your first supplier to get started',
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
                    builder: (context) => const AddSupplierScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Add Supplier'),
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
        ],
      ),
    );
  }


} 