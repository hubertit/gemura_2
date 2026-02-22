class AgentReport {
  final double totalSales;
  final double totalCollections;
  final int customersAdded;
  final int suppliersAdded;
  final double salesTargetAchievement;
  final double collectionRate;
  final double customerSatisfaction;
  final double averageTransactionValue;
  final double salesCommission;
  final double collectionCommission;
  final double customerBonus;
  final double supplierBonus;
  final List<AgentActivity> recentActivities;

  const AgentReport({
    required this.totalSales,
    required this.totalCollections,
    required this.customersAdded,
    required this.suppliersAdded,
    required this.salesTargetAchievement,
    required this.collectionRate,
    required this.customerSatisfaction,
    required this.averageTransactionValue,
    required this.salesCommission,
    required this.collectionCommission,
    required this.customerBonus,
    required this.supplierBonus,
    required this.recentActivities,
  });

  double get totalCommission => salesCommission + collectionCommission + customerBonus + supplierBonus;
}

class AgentActivity {
  final String id;
  final String type; // 'sale', 'collection', 'customer_added', 'supplier_added'
  final String description;
  final double? amount;
  final DateTime timestamp;

  const AgentActivity({
    required this.id,
    required this.type,
    required this.description,
    this.amount,
    required this.timestamp,
  });
}
