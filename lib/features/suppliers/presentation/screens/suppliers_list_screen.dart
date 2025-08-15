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
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
      }
    });
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
        title: _isSearching 
          ? _buildSearchField()
          : Column(
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
            child: Column(
              children: [
                // Search results indicator
                if (_searchController.text.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacing16,
                      vertical: AppTheme.spacing8,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.05),
                      border: Border(
                        bottom: BorderSide(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search,
                          size: 16,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: AppTheme.spacing8),
                        Text(
                          '${filteredSuppliers.length} supplier${filteredSuppliers.length == 1 ? '' : 's'} found for "${_searchController.text}"',
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                          child: Text(
                            'Clear',
                            style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                // Suppliers list
                Expanded(
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
                ),
              ],
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

  Widget _buildSearchField() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: TextField(
        controller: _searchController,
        autofocus: true,
        style: AppTheme.bodyMedium.copyWith(
          color: AppTheme.textPrimaryColor,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          hintText: 'Search suppliers...',
          hintStyle: AppTheme.bodyMedium.copyWith(
            color: AppTheme.textHintColor,
            fontSize: 16,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: AppTheme.primaryColor,
            size: 20,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: AppTheme.textSecondaryColor,
                    size: 18,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                  tooltip: 'Clear search',
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        onChanged: (value) {
          setState(() {});
        },
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
              color: isSearch 
                ? AppTheme.primaryColor.withOpacity(0.1)
                : AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isSearch ? Icons.search_off : Icons.people_outline,
              size: 40,
              color: isSearch ? AppTheme.primaryColor : AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: AppTheme.spacing24),
          Text(
            isSearch ? 'No suppliers found' : 'No suppliers yet',
            style: AppTheme.titleMedium.copyWith(
              color: AppTheme.textPrimaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            isSearch 
                ? 'No suppliers match "${_searchController.text}"\nTry different keywords or browse all suppliers'
                : 'Add your first supplier to get started with milk collection',
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
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing32),
              child: OutlinedButton.icon(
                onPressed: () {
                  _searchController.clear();
                  setState(() {});
                },
                icon: const Icon(Icons.clear, size: 20),
                label: const Text('Clear Search'),
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


} 