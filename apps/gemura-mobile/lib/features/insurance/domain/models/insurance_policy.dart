import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

enum InsuranceType {
  health,
  life,
  property,
  vehicle,
  business,
}

enum PolicyStatus {
  active,
  pending,
  expired,
  cancelled,
  suspended,
}

enum PaymentFrequency {
  monthly,
  quarterly,
  annually,
  oneTime,
}

class InsurancePolicy {
  final String id;
  final String name;
  final String description;
  final InsuranceType type;
  final String providerName;
  final String providerId;
  final double premiumAmount;
  final double coverageAmount;
  final PaymentFrequency paymentFrequency;
  final PolicyStatus status;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime? renewalDate;
  final List<String> beneficiaries;
  final Map<String, dynamic>? policyDetails;
  final String? policyNumber;
  final String? documentUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const InsurancePolicy({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.providerName,
    required this.providerId,
    required this.premiumAmount,
    required this.coverageAmount,
    required this.paymentFrequency,
    required this.status,
    required this.startDate,
    required this.endDate,
    this.renewalDate,
    required this.beneficiaries,
    this.policyDetails,
    this.policyNumber,
    this.documentUrl,
    required this.createdAt,
    this.updatedAt,
  });

  // Getters
  bool get isActive => status == PolicyStatus.active;
  bool get isExpired => DateTime.now().isAfter(endDate);
  bool get needsRenewal => renewalDate != null && DateTime.now().isAfter(renewalDate!);
  
  int get daysUntilExpiry {
    final remaining = endDate.difference(DateTime.now()).inDays;
    return remaining > 0 ? remaining : 0;
  }

  double get progressPercentage {
    if (status == PolicyStatus.expired || status == PolicyStatus.cancelled) return 100.0;
    if (status == PolicyStatus.pending) return 0.0;
    
    final totalDays = endDate.difference(startDate).inDays;
    final elapsedDays = DateTime.now().difference(startDate).inDays;
    
    if (elapsedDays <= 0) return 0.0;
    if (elapsedDays >= totalDays) return 100.0;
    
    return (elapsedDays / totalDays) * 100;
  }

  String get typeDisplayName {
    switch (type) {
      case InsuranceType.health:
        return 'Health Insurance';
      case InsuranceType.life:
        return 'Life Insurance';
      case InsuranceType.property:
        return 'Property Insurance';
      case InsuranceType.vehicle:
        return 'Vehicle Insurance';
      case InsuranceType.business:
        return 'Business Insurance';
    }
  }

  String get statusDisplayName {
    switch (status) {
      case PolicyStatus.active:
        return 'Active';
      case PolicyStatus.pending:
        return 'Pending';
      case PolicyStatus.expired:
        return 'Expired';
      case PolicyStatus.cancelled:
        return 'Cancelled';
      case PolicyStatus.suspended:
        return 'Suspended';
    }
  }

  Color get statusColor {
    switch (status) {
      case PolicyStatus.active:
        return AppTheme.successColor;
      case PolicyStatus.pending:
        return AppTheme.warningColor;
      case PolicyStatus.expired:
      case PolicyStatus.cancelled:
      case PolicyStatus.suspended:
        return AppTheme.errorColor;
    }
  }

  String get paymentFrequencyDisplayName {
    switch (paymentFrequency) {
      case PaymentFrequency.monthly:
        return 'Monthly';
      case PaymentFrequency.quarterly:
        return 'Quarterly';
      case PaymentFrequency.annually:
        return 'Annually';
      case PaymentFrequency.oneTime:
        return 'One Time';
    }
  }

  InsurancePolicy copyWith({
    String? id,
    String? name,
    String? description,
    InsuranceType? type,
    String? providerName,
    String? providerId,
    double? premiumAmount,
    double? coverageAmount,
    PaymentFrequency? paymentFrequency,
    PolicyStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? renewalDate,
    List<String>? beneficiaries,
    Map<String, dynamic>? policyDetails,
    String? policyNumber,
    String? documentUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InsurancePolicy(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      providerName: providerName ?? this.providerName,
      providerId: providerId ?? this.providerId,
      premiumAmount: premiumAmount ?? this.premiumAmount,
      coverageAmount: coverageAmount ?? this.coverageAmount,
      paymentFrequency: paymentFrequency ?? this.paymentFrequency,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      renewalDate: renewalDate ?? this.renewalDate,
      beneficiaries: beneficiaries ?? this.beneficiaries,
      policyDetails: policyDetails ?? this.policyDetails,
      policyNumber: policyNumber ?? this.policyNumber,
      documentUrl: documentUrl ?? this.documentUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.name,
      'providerName': providerName,
      'providerId': providerId,
      'premiumAmount': premiumAmount,
      'coverageAmount': coverageAmount,
      'paymentFrequency': paymentFrequency.name,
      'status': status.name,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'renewalDate': renewalDate?.toIso8601String(),
      'beneficiaries': beneficiaries,
      'policyDetails': policyDetails,
      'policyNumber': policyNumber,
      'documentUrl': documentUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory InsurancePolicy.fromJson(Map<String, dynamic> json) {
    return InsurancePolicy(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      type: InsuranceType.values.firstWhere(
        (e) => e.name == json['type'],
      ),
      providerName: json['providerName'],
      providerId: json['providerId'],
      premiumAmount: json['premiumAmount'].toDouble(),
      coverageAmount: json['coverageAmount'].toDouble(),
      paymentFrequency: PaymentFrequency.values.firstWhere(
        (e) => e.name == json['paymentFrequency'],
      ),
      status: PolicyStatus.values.firstWhere(
        (e) => e.name == json['status'],
      ),
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      renewalDate: json['renewalDate'] != null 
          ? DateTime.parse(json['renewalDate']) 
          : null,
      beneficiaries: List<String>.from(json['beneficiaries']),
      policyDetails: json['policyDetails'],
      policyNumber: json['policyNumber'],
      documentUrl: json['documentUrl'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : null,
    );
  }
} 