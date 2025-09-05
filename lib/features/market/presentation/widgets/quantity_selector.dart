import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class QuantitySelector extends StatefulWidget {
  final int initialQuantity;
  final int minQuantity;
  final int maxQuantity;
  final int stockQuantity;
  final Function(int) onQuantityChanged;

  const QuantitySelector({
    super.key,
    this.initialQuantity = 1,
    required this.minQuantity,
    required this.maxQuantity,
    required this.stockQuantity,
    required this.onQuantityChanged,
  });

  @override
  State<QuantitySelector> createState() => _QuantitySelectorState();
}

class _QuantitySelectorState extends State<QuantitySelector> {
  late int _quantity;

  @override
  void initState() {
    super.initState();
    _quantity = widget.initialQuantity;
  }

  void _decreaseQuantity() {
    if (_quantity > widget.minQuantity) {
      setState(() {
        _quantity--;
      });
      widget.onQuantityChanged(_quantity);
    }
  }

  void _increaseQuantity() {
    if (_quantity < widget.maxQuantity && _quantity < widget.stockQuantity) {
      setState(() {
        _quantity++;
      });
      widget.onQuantityChanged(_quantity);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppTheme.spacing12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Quantity',
                style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
              ),
              Text(
                'Stock: ${widget.stockQuantity}',
                style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondaryColor),
              ),
            ],
          ),
          
          SizedBox(height: AppTheme.spacing12),
          
          Row(
            children: [
              // Decrease button
              IconButton(
                onPressed: _quantity > widget.minQuantity ? _decreaseQuantity : null,
                icon: Icon(
                  Icons.remove_circle_outline,
                  color: _quantity > widget.minQuantity 
                      ? AppTheme.primaryColor 
                      : AppTheme.textSecondaryColor,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.backgroundColor,
                  shape: CircleBorder(),
                ),
              ),
              
              // Quantity display
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: AppTheme.spacing16, vertical: AppTheme.spacing8),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Text(
                    '$_quantity',
                    textAlign: TextAlign.center,
                    style: AppTheme.titleMedium.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              
              // Increase button
              IconButton(
                onPressed: _quantity < widget.maxQuantity && _quantity < widget.stockQuantity 
                    ? _increaseQuantity 
                    : null,
                icon: Icon(
                  Icons.add_circle_outline,
                  color: _quantity < widget.maxQuantity && _quantity < widget.stockQuantity 
                      ? AppTheme.primaryColor 
                      : AppTheme.textSecondaryColor,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.backgroundColor,
                  shape: CircleBorder(),
                ),
              ),
            ],
          ),
          
          SizedBox(height: AppTheme.spacing8),
          
          // Quantity constraints info
          Text(
            'Min: ${widget.minQuantity} | Max: ${widget.maxQuantity}',
            style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondaryColor),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
