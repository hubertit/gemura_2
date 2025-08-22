import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/agent_report.dart';

final agentReportProvider = FutureProvider.family<AgentReport, String>((ref, period) async {
  // Simulate API delay
  await Future.delayed(const Duration(seconds: 1));
  
  // Generate mock data based on period
  return _generateMockReport(period);
});

AgentReport _generateMockReport(String period) {
  // Generate different data based on period
  double multiplier = 1.0;
  switch (period) {
    case 'Today':
      multiplier = 0.1;
      break;
    case 'This Week':
      multiplier = 0.7;
      break;
    case 'This Month':
      multiplier = 1.0;
      break;
    case 'Last Month':
      multiplier = 0.9;
      break;
    case 'This Year':
      multiplier = 12.0;
      break;
  }

  return AgentReport(
    totalSales: (250000 * multiplier).roundToDouble(),
    totalCollections: (200000 * multiplier).roundToDouble(),
    customersAdded: (5 * multiplier).round(),
    suppliersAdded: (3 * multiplier).round(),
    salesTargetAchievement: 85.0,
    collectionRate: 92.0,
    customerSatisfaction: 88.0,
    averageTransactionValue: 45000.0,
    salesCommission: (15000 * multiplier).roundToDouble(),
    collectionCommission: (8000 * multiplier).roundToDouble(),
    customerBonus: (5000 * multiplier).roundToDouble(),
    supplierBonus: (3000 * multiplier).roundToDouble(),
    recentActivities: _generateMockActivities(period),
  );
}

List<AgentActivity> _generateMockActivities(String period) {
  final activities = <AgentActivity>[];
  final now = DateTime.now();
  
  // Generate activities based on period
  int activityCount = 5;
  switch (period) {
    case 'Today':
      activityCount = 3;
      break;
    case 'This Week':
      activityCount = 8;
      break;
    case 'This Month':
      activityCount = 15;
      break;
    case 'Last Month':
      activityCount = 12;
      break;
    case 'This Year':
      activityCount = 50;
      break;
  }

  for (int i = 0; i < activityCount; i++) {
    final daysAgo = i * 2;
    final timestamp = now.subtract(Duration(days: daysAgo));
    
    switch (i % 4) {
      case 0:
        activities.add(AgentActivity(
          id: 'ACT-${i + 1}',
          type: 'sale',
          description: 'Sold milk to customer',
          amount: 25000 + (i * 5000),
          timestamp: timestamp,
        ));
        break;
      case 1:
        activities.add(AgentActivity(
          id: 'ACT-${i + 1}',
          type: 'collection',
          description: 'Collected milk from supplier',
          amount: 15000 + (i * 3000),
          timestamp: timestamp,
        ));
        break;
      case 2:
        activities.add(AgentActivity(
          id: 'ACT-${i + 1}',
          type: 'customer_added',
          description: 'Added new customer',
          timestamp: timestamp,
        ));
        break;
      case 3:
        activities.add(AgentActivity(
          id: 'ACT-${i + 1}',
          type: 'supplier_added',
          description: 'Added new supplier',
          timestamp: timestamp,
        ));
        break;
    }
  }

  // Sort by timestamp (most recent first)
  activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  
  return activities;
}
