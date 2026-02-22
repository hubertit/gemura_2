import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

enum ClaimStatus {
  pending,
  submitted,
  underReview,
  approved,
  rejected,
  paid,
  closed,
}

enum ClaimType {
  health,
  property,
  vehicle,
  life,
  business,
  other,
}

class InsuranceClaim {
  final String id;
  final String policyId;
  final String policyName;
  final String description;
  final ClaimType type;
  final ClaimStatus status;
  final double claimAmount;
  final double? approvedAmount;
  final DateTime incidentDate;
  final DateTime claimDate;
  final DateTime? processedDate;
  final List<String> documents;
  final String? notes;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const InsuranceClaim({
    required this.id,
    required this.policyId,
    required this.policyName,
    required this.description,
    required this.type,
    required this.status,
    required this.claimAmount,
    this.approvedAmount,
    required this.incidentDate,
    required this.claimDate,
    this.processedDate,
    required this.documents,
    this.notes,
    this.rejectionReason,
    required this.createdAt,
    this.updatedAt,
  });

  // Getters
  bool get isPending => status == ClaimStatus.pending;
  bool get isSubmitted => status == ClaimStatus.submitted;
  bool get isUnderReview => status == ClaimStatus.underReview;
  bool get isApproved => status == ClaimStatus.approved;
  bool get isRejected => status == ClaimStatus.rejected;
  bool get isPaid => status == ClaimStatus.paid;
  bool get isClosed => status == ClaimStatus.closed;

  int get daysSinceSubmission {
    return DateTime.now().difference(claimDate).inDays;
  }

  String get typeDisplayName {
    switch (type) {
      case ClaimType.health:
        return 'Health Claim';
      case ClaimType.property:
        return 'Property Claim';
      case ClaimType.vehicle:
        return 'Vehicle Claim';
      case ClaimType.life:
        return 'Life Claim';
      case ClaimType.business:
        return 'Business Claim';
      case ClaimType.other:
        return 'Other Claim';
    }
  }

  String get statusDisplayName {
    switch (status) {
      case ClaimStatus.pending:
        return 'Pending';
      case ClaimStatus.submitted:
        return 'Submitted';
      case ClaimStatus.underReview:
        return 'Under Review';
      case ClaimStatus.approved:
        return 'Approved';
      case ClaimStatus.rejected:
        return 'Rejected';
      case ClaimStatus.paid:
        return 'Paid';
      case ClaimStatus.closed:
        return 'Closed';
    }
  }

  Color get statusColor {
    switch (status) {
      case ClaimStatus.pending:
      case ClaimStatus.submitted:
        return AppTheme.warningColor;
      case ClaimStatus.underReview:
        return AppTheme.primaryColor;
      case ClaimStatus.approved:
      case ClaimStatus.paid:
        return AppTheme.successColor;
      case ClaimStatus.rejected:
      case ClaimStatus.closed:
        return AppTheme.errorColor;
    }
  }

  IconData get statusIcon {
    switch (status) {
      case ClaimStatus.pending:
      case ClaimStatus.submitted:
        return Icons.schedule;
      case ClaimStatus.underReview:
        return Icons.search;
      case ClaimStatus.approved:
        return Icons.check_circle;
      case ClaimStatus.paid:
        return Icons.payment;
      case ClaimStatus.rejected:
        return Icons.cancel;
      case ClaimStatus.closed:
        return Icons.close;
    }
  }

  InsuranceClaim copyWith({
    String? id,
    String? policyId,
    String? policyName,
    String? description,
    ClaimType? type,
    ClaimStatus? status,
    double? claimAmount,
    double? approvedAmount,
    DateTime? incidentDate,
    DateTime? claimDate,
    DateTime? processedDate,
    List<String>? documents,
    String? notes,
    String? rejectionReason,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InsuranceClaim(
      id: id ?? this.id,
      policyId: policyId ?? this.policyId,
      policyName: policyName ?? this.policyName,
      description: description ?? this.description,
      type: type ?? this.type,
      status: status ?? this.status,
      claimAmount: claimAmount ?? this.claimAmount,
      approvedAmount: approvedAmount ?? this.approvedAmount,
      incidentDate: incidentDate ?? this.incidentDate,
      claimDate: claimDate ?? this.claimDate,
      processedDate: processedDate ?? this.processedDate,
      documents: documents ?? this.documents,
      notes: notes ?? this.notes,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'policyId': policyId,
      'policyName': policyName,
      'description': description,
      'type': type.name,
      'status': status.name,
      'claimAmount': claimAmount,
      'approvedAmount': approvedAmount,
      'incidentDate': incidentDate.toIso8601String(),
      'claimDate': claimDate.toIso8601String(),
      'processedDate': processedDate?.toIso8601String(),
      'documents': documents,
      'notes': notes,
      'rejectionReason': rejectionReason,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory InsuranceClaim.fromJson(Map<String, dynamic> json) {
    return InsuranceClaim(
      id: json['id'],
      policyId: json['policyId'],
      policyName: json['policyName'],
      description: json['description'],
      type: ClaimType.values.firstWhere(
        (e) => e.name == json['type'],
      ),
      status: ClaimStatus.values.firstWhere(
        (e) => e.name == json['status'],
      ),
      claimAmount: json['claimAmount'].toDouble(),
      approvedAmount: json['approvedAmount']?.toDouble(),
      incidentDate: DateTime.parse(json['incidentDate']),
      claimDate: DateTime.parse(json['claimDate']),
      processedDate: json['processedDate'] != null 
          ? DateTime.parse(json['processedDate']) 
          : null,
      documents: List<String>.from(json['documents']),
      notes: json['notes'],
      rejectionReason: json['rejectionReason'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : null,
    );
  }
} 