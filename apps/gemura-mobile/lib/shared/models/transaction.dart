class Transaction {
  final String id;
  final double amount;
  final String currency;
  final String type; // e.g., 'payment', 'refund', 'settlement'
  final String status; // e.g., 'success', 'pending', 'failed', 'refunded'
  final DateTime date;
  final String description; // e.g., label or order reference
  final String paymentMethod; // e.g., 'Mobile Money', 'Card', 'Bank', 'QR/USSD'
  final String customerName;
  final String customerPhone;
  final String reference; // e.g., payment reference or order number
  final String? walletId; // ID of the wallet this transaction belongs to

  Transaction({
    required this.id,
    required this.amount,
    required this.currency,
    required this.type,
    required this.status,
    required this.date,
    required this.description,
    required this.paymentMethod,
    required this.customerName,
    required this.customerPhone,
    required this.reference,
    this.walletId,
  });
} 