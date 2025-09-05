import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/number_formatter.dart';
import '../../domain/models/product.dart';
import '../../domain/models/order.dart';
import '../../data/services/order_api_service.dart';

class OrderFormScreen extends ConsumerStatefulWidget {
  final Product product;
  final int quantity;

  const OrderFormScreen({
    super.key,
    required this.product,
    required this.quantity,
  });

  @override
  ConsumerState<OrderFormScreen> createState() => _OrderFormScreenState();
}

class _OrderFormScreenState extends ConsumerState<OrderFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _shippingAddressController = TextEditingController();
  final _shippingNotesController = TextEditingController();
  
  // For now, using hardcoded customer ID - in real app, get from auth
  final int _customerId = 1;
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill shipping address if available
    _shippingAddressController.text = 'Kigali, Rwanda';
  }

  @override
  void dispose() {
    _shippingAddressController.dispose();
    _shippingNotesController.dispose();
    super.dispose();
  }

  double get _totalAmount => widget.product.price * widget.quantity;

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final request = CreateOrderRequest(
        customerId: _customerId,
        sellerId: widget.product.sellerId,
        totalAmount: _totalAmount,
        currency: widget.product.currency,
        shippingAddress: _shippingAddressController.text.trim(),
        shippingNotes: _shippingNotesController.text.trim().isEmpty 
            ? null 
            : _shippingNotesController.text.trim(),
        items: [
          CreateOrderItem(
            productId: widget.product.id,
            quantity: widget.quantity,
            unitPrice: widget.product.price,
          ),
        ],
      );

      final order = await OrderApiService.createOrder(request);
      
      if (mounted) {
        // Show success dialog
        _showOrderSuccessDialog(order);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to place order: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showOrderSuccessDialog(Order order) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: AppTheme.spacing12),
            Text('Order Placed!', style: AppTheme.titleMedium),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your order has been placed successfully!', style: AppTheme.bodyMedium),
            SizedBox(height: AppTheme.spacing16),
            _buildOrderSummary(order),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back to product details
            },
            child: Text('Continue Shopping', style: AppTheme.bodyMedium),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              // TODO: Navigate to order details or orders list
              Navigator.of(context).pop(); // Go back to product details
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: Text('View Order', style: AppTheme.bodyMedium),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(Order order) {
    return Container(
      padding: EdgeInsets.all(AppTheme.spacing12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Order Summary', style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
          SizedBox(height: AppTheme.spacing8),
          _buildSummaryRow('Order Number', order.orderNo),
          _buildSummaryRow('Total Amount', NumberFormatter.formatCurrency(order.totalAmount, order.currency)),
          _buildSummaryRow('Status', order.status.toUpperCase()),
          _buildSummaryRow('Items', '${order.totalItems} item(s)'),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppTheme.spacing4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondaryColor)),
          ),
          Expanded(
            flex: 3,
            child: Text(value, style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'Place Order',
          style: AppTheme.titleMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppTheme.spacing16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Summary Card
              _buildProductSummaryCard(),
              
              SizedBox(height: AppTheme.spacing24),
              
              // Order Details Form
              _buildOrderDetailsForm(),
              
              SizedBox(height: AppTheme.spacing32),
              
              // Place Order Button
              _buildPlaceOrderButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductSummaryCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Product Summary', style: AppTheme.titleSmall.copyWith(fontWeight: FontWeight.w600)),
            SizedBox(height: AppTheme.spacing16),
            
            Row(
              children: [
                // Product Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                  child: Image.network(
                    widget.product.imageUrl ?? 'https://via.placeholder.com/80x80/CCCCCC/FFFFFF?text=No+Image',
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 80,
                        height: 80,
                        color: AppTheme.borderColor,
                        child: Icon(Icons.image, color: AppTheme.textSecondaryColor),
                      );
                    },
                  ),
                ),
                
                SizedBox(width: AppTheme.spacing16),
                
                // Product Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.product.name,
                        style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: AppTheme.spacing8),
                      Text(
                        'Seller: ${widget.product.seller.name}',
                        style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondaryColor),
                      ),
                      SizedBox(height: AppTheme.spacing8),
                      Text(
                        'Quantity: ${widget.quantity}',
                        style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondaryColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            SizedBox(height: AppTheme.spacing16),
            
            // Total Amount
            Container(
              padding: EdgeInsets.all(AppTheme.spacing12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total Amount:', style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                  Text(
                    NumberFormatter.formatCurrency(_totalAmount, widget.product.currency),
                    style: AppTheme.titleMedium.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderDetailsForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Order Details', style: AppTheme.titleSmall.copyWith(fontWeight: FontWeight.w600)),
        SizedBox(height: AppTheme.spacing16),
        
        // Shipping Address
        TextFormField(
          controller: _shippingAddressController,
          decoration: InputDecoration(
            labelText: 'Shipping Address *',
            hintText: 'Enter your shipping address',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
            ),
            filled: true,
            fillColor: AppTheme.backgroundColor,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Shipping address is required';
            }
            return null;
          },
          maxLines: 3,
        ),
        
        SizedBox(height: AppTheme.spacing16),
        
        // Shipping Notes
        TextFormField(
          controller: _shippingNotesController,
          decoration: InputDecoration(
            labelText: 'Shipping Notes (Optional)',
            hintText: 'Any special instructions for delivery',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
            ),
            filled: true,
            fillColor: AppTheme.backgroundColor,
          ),
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildPlaceOrderButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _placeOrder,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: AppTheme.spacing16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
          ),
        ),
        child: _isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                'Place Order',
                style: AppTheme.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
      ),
    );
  }
}
