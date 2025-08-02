import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gemura/core/theme/app_theme.dart';
import 'package:gemura/features/suppliers/presentation/providers/supplier_provider.dart';
import 'package:gemura/features/suppliers/domain/models/supplier.dart';
import 'package:gemura/features/suppliers/presentation/screens/add_supplier_screen.dart';
import 'package:gemura/features/suppliers/presentation/screens/supplier_details_screen.dart';

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

  List<Supplier> _getFilteredSuppliers() {
    final suppliers = ref.watch(supplierProvider);
    String searchQuery = _searchController.text.toLowerCase();
    
    if (searchQuery.isEmpty) {
      return suppliers;
    }
    
    return suppliers.where((supplier) {
      return supplier.name.toLowerCase().contains(searchQuery) ||
          supplier.phone.toLowerCase().contains(searchQuery) ||
          supplier.location.toLowerCase().contains(searchQuery) ||
          supplier.businessType.toLowerCase().contains(searchQuery) ||
          supplier.farmType.toLowerCase().contains(searchQuery) ||
          supplier.collectionSchedule.toLowerCase().contains(searchQuery) ||
          (supplier.email != null && supplier.email!.toLowerCase().contains(searchQuery)) ||
          (supplier.idNumber != null && supplier.idNumber!.toLowerCase().contains(searchQuery));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredSuppliers = _getFilteredSuppliers();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Suppliers'),
            if (_searchController.text.isNotEmpty)
              Text(
                '${filteredSuppliers.length} result${filteredSuppliers.length == 1 ? '' : 's'}',
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
      body: filteredSuppliers.isEmpty
          ? _buildEmptyState(_searchController.text.isNotEmpty)
          : ListView.builder(
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
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => SupplierDetailsScreen(supplier: supplier),
            ),
          );
        },
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
          child: Text(
            supplier.name.isNotEmpty ? supplier.name[0].toUpperCase() : 'S',
            style: TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
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
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${supplier.sellingPricePerLiter.toStringAsFixed(0)} Frw/L',
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${supplier.dailyProduction}L/day',
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
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.search, color: AppTheme.primaryColor, size: 20),
            const SizedBox(width: AppTheme.spacing8),
            Text(
              'Search Suppliers',
              style: AppTheme.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search by name, phone, or location...',
                hintStyle: AppTheme.bodyMedium.copyWith(color: AppTheme.textHintColor),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
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
              ),
              onChanged: (value) {
                setState(() {});
              },
            ),
            const SizedBox(height: AppTheme.spacing12),
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
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _searchController.clear();
              setState(() {});
              Navigator.of(context).pop();
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
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