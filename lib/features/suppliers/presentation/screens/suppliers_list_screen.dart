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
    
    return suppliers.where((supplier) {
      return supplier.name.toLowerCase().contains(searchQuery) ||
          supplier.phone.toLowerCase().contains(searchQuery) ||
          supplier.location.toLowerCase().contains(searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredSuppliers = _getFilteredSuppliers();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Suppliers'),
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimaryColor),
        titleTextStyle: AppTheme.titleMedium.copyWith(color: AppTheme.textPrimaryColor),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              _showSearchDialog();
            },
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
          ),
        ],
      ),
      body: filteredSuppliers.isEmpty
          ? _buildEmptyState()
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
        title: const Text('Search Suppliers'),
        content: TextFormField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search by name, phone, or location...',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (value) {
            setState(() {});
            Navigator.of(context).pop();
          },
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
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }



  Widget _buildEmptyState() {
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
              Icons.people_outline,
              size: 40,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: AppTheme.spacing24),
          Text(
            'No suppliers found',
            style: AppTheme.titleMedium.copyWith(
              color: AppTheme.textPrimaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            'Add your first supplier to get started',
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