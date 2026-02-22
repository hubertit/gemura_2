import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/insurance_policy.dart';
import '../../domain/models/insurance_claim.dart';
import '../../domain/models/insurance_provider.dart' as insurance_provider_model;

class InsuranceNotifier extends StateNotifier<List<InsurancePolicy>> {
  InsuranceNotifier() : super([]) {
    _loadMockData();
    _initializeClaims();
  }

  // Claims storage
  final Map<String, List<InsuranceClaim>> _claims = {};
  
  // Mock insurance providers
  final List<insurance_provider_model.InsuranceProvider> _providers = [
    insurance_provider_model.InsuranceProvider(
      id: 'PROV-1',
      name: 'Sanlam Rwanda',
      description: 'Leading pan-African insurance and financial services group',
      logoUrl: 'assets/images/logo.png',
      website: 'https://www.sanlam.co.rw',
      phone: '+250 788 123 456',
      email: 'info@sanlam.co.rw',
      address: 'Kigali, Rwanda',
      supportedTypes: ['health', 'life', 'property', 'vehicle', 'business'],
      rating: 4.6,
      reviewCount: 1850,
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 365)),
    ),
    insurance_provider_model.InsuranceProvider(
      id: 'PROV-2',
      name: 'Radiant Insurance',
      description: 'Comprehensive insurance solutions for individuals and businesses',
      logoUrl: 'assets/images/logo.png',
      website: 'https://www.radiant.rw',
      phone: '+250 788 654 321',
      email: 'contact@radiant.rw',
      address: 'Kigali, Rwanda',
      supportedTypes: ['health', 'life', 'property', 'vehicle', 'business'],
      rating: 4.4,
      reviewCount: 1200,
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 300)),
    ),
    insurance_provider_model.InsuranceProvider(
      id: 'PROV-3',
      name: 'Prime Insurance',
      description: 'Trusted insurance partner for comprehensive coverage',
      logoUrl: 'assets/images/logo.png',
      website: 'https://www.prime.rw',
      phone: '+250 788 987 654',
      email: 'support@prime.rw',
      address: 'Kigali, Rwanda',
      supportedTypes: ['health', 'life', 'property', 'vehicle'],
      rating: 4.3,
      reviewCount: 950,
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 250)),
    ),
    insurance_provider_model.InsuranceProvider(
      id: 'PROV-4',
      name: 'Rwanda National Insurance Company',
      description: 'State-owned insurance company providing reliable coverage',
      logoUrl: 'assets/images/logo.png',
      website: 'https://www.rnic.rw',
      phone: '+250 788 456 789',
      email: 'info@rnic.rw',
      address: 'Kigali, Rwanda',
      supportedTypes: ['health', 'life', 'property', 'vehicle', 'business'],
      rating: 4.5,
      reviewCount: 2100,
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 400)),
    ),
    insurance_provider_model.InsuranceProvider(
      id: 'PROV-5',
      name: 'Soras Insurance',
      description: 'Leading insurance company with extensive local experience',
      logoUrl: 'assets/images/logo.png',
      website: 'https://www.soras.rw',
      phone: '+250 788 321 654',
      email: 'contact@soras.rw',
      address: 'Kigali, Rwanda',
      supportedTypes: ['health', 'life', 'property', 'vehicle', 'business'],
      rating: 4.7,
      reviewCount: 1650,
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 350)),
    ),
  ];

  void _loadMockData() {
    state = [
      InsurancePolicy(
        id: 'POL-1',
        name: 'Family Health Coverage',
        description: 'Comprehensive health insurance for the entire family',
        type: InsuranceType.health,
        providerName: 'Sanlam Rwanda',
        providerId: 'PROV-1',
        premiumAmount: 45000,
        coverageAmount: 5000000,
        paymentFrequency: PaymentFrequency.monthly,
        status: PolicyStatus.active,
        startDate: DateTime.now().subtract(const Duration(days: 180)),
        endDate: DateTime.now().add(const Duration(days: 185)),
        renewalDate: DateTime.now().add(const Duration(days: 175)),
        beneficiaries: ['John Doe', 'Jane Doe', 'Junior Doe'],
        policyNumber: 'POL-2024-001',
        createdAt: DateTime.now().subtract(const Duration(days: 180)),
      ),
      InsurancePolicy(
        id: 'POL-2',
        name: 'Vehicle Comprehensive',
        description: 'Full coverage for personal vehicle',
        type: InsuranceType.vehicle,
        providerName: 'Radiant Insurance',
        providerId: 'PROV-2',
        premiumAmount: 75000,
        coverageAmount: 8000000,
        paymentFrequency: PaymentFrequency.annually,
        status: PolicyStatus.active,
        startDate: DateTime.now().subtract(const Duration(days: 90)),
        endDate: DateTime.now().add(const Duration(days: 275)),
        renewalDate: DateTime.now().add(const Duration(days: 265)),
        beneficiaries: ['John Doe'],
        policyNumber: 'POL-2024-002',
        createdAt: DateTime.now().subtract(const Duration(days: 90)),
      ),
      InsurancePolicy(
        id: 'POL-3',
        name: 'Business Property Protection',
        description: 'Insurance coverage for business premises and equipment',
        type: InsuranceType.business,
        providerName: 'Prime Insurance',
        providerId: 'PROV-3',
        premiumAmount: 120000,
        coverageAmount: 15000000,
        paymentFrequency: PaymentFrequency.quarterly,
        status: PolicyStatus.active,
        startDate: DateTime.now().subtract(const Duration(days: 60)),
        endDate: DateTime.now().add(const Duration(days: 305)),
        renewalDate: DateTime.now().add(const Duration(days: 295)),
        beneficiaries: ['John Doe', 'Business Partners'],
        policyNumber: 'POL-2024-003',
        createdAt: DateTime.now().subtract(const Duration(days: 60)),
      ),
      InsurancePolicy(
        id: 'POL-4',
        name: 'Life Insurance Premium',
        description: 'Life insurance with death benefit and savings component',
        type: InsuranceType.life,
        providerName: 'Rwanda National Insurance Company',
        providerId: 'PROV-4',
        premiumAmount: 35000,
        coverageAmount: 20000000,
        paymentFrequency: PaymentFrequency.monthly,
        status: PolicyStatus.pending,
        startDate: DateTime.now().add(const Duration(days: 7)),
        endDate: DateTime.now().add(const Duration(days: 372)),
        beneficiaries: ['Jane Doe', 'Junior Doe'],
        policyNumber: 'POL-2024-004',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
      InsurancePolicy(
        id: 'POL-5',
        name: 'Home Insurance',
        description: 'Property insurance for residential home',
        type: InsuranceType.property,
        providerName: 'Soras Insurance',
        providerId: 'PROV-5',
        premiumAmount: 55000,
        coverageAmount: 12000000,
        paymentFrequency: PaymentFrequency.annually,
        status: PolicyStatus.expired,
        startDate: DateTime.now().subtract(const Duration(days: 400)),
        endDate: DateTime.now().subtract(const Duration(days: 10)),
        beneficiaries: ['John Doe', 'Jane Doe'],
        policyNumber: 'POL-2023-005',
        createdAt: DateTime.now().subtract(const Duration(days: 400)),
      ),
    ];
  }

  void _initializeClaims() {
    _claims['POL-1'] = [
      InsuranceClaim(
        id: 'CLAIM-1',
        policyId: 'POL-1',
        policyName: 'Family Health Coverage',
        description: 'Medical treatment for flu and fever at King Faisal Hospital',
        type: ClaimType.health,
        status: ClaimStatus.approved,
        claimAmount: 25000,
        approvedAmount: 25000,
        incidentDate: DateTime.now().subtract(const Duration(days: 30)),
        claimDate: DateTime.now().subtract(const Duration(days: 28)),
        processedDate: DateTime.now().subtract(const Duration(days: 25)),
        documents: ['medical_bill.pdf', 'prescription.pdf'],
        notes: 'Claim processed successfully by Sanlam Rwanda',
        createdAt: DateTime.now().subtract(const Duration(days: 28)),
      ),
      InsuranceClaim(
        id: 'CLAIM-2',
        policyId: 'POL-1',
        policyName: 'Family Health Coverage',
        description: 'Dental treatment and cleaning at Kigali Dental Clinic',
        type: ClaimType.health,
        status: ClaimStatus.underReview,
        claimAmount: 45000,
        incidentDate: DateTime.now().subtract(const Duration(days: 15)),
        claimDate: DateTime.now().subtract(const Duration(days: 12)),
        documents: ['dental_bill.pdf', 'xray_report.pdf'],
        notes: 'Under review by medical team at Sanlam Rwanda',
        createdAt: DateTime.now().subtract(const Duration(days: 12)),
      ),
    ];

    _claims['POL-2'] = [
      InsuranceClaim(
        id: 'CLAIM-3',
        policyId: 'POL-2',
        policyName: 'Vehicle Comprehensive',
        description: 'Minor accident damage repair at Kigali Auto Services',
        type: ClaimType.vehicle,
        status: ClaimStatus.paid,
        claimAmount: 180000,
        approvedAmount: 175000,
        incidentDate: DateTime.now().subtract(const Duration(days: 45)),
        claimDate: DateTime.now().subtract(const Duration(days: 43)),
        processedDate: DateTime.now().subtract(const Duration(days: 40)),
        documents: ['accident_report.pdf', 'repair_quotes.pdf'],
        notes: 'Payment processed to repair shop by Radiant Insurance',
        createdAt: DateTime.now().subtract(const Duration(days: 43)),
      ),
    ];

    _claims['POL-3'] = [
      InsuranceClaim(
        id: 'CLAIM-4',
        policyId: 'POL-3',
        policyName: 'Business Property Protection',
        description: 'Equipment damage due to power surge at business premises',
        type: ClaimType.business,
        status: ClaimStatus.submitted,
        claimAmount: 350000,
        incidentDate: DateTime.now().subtract(const Duration(days: 8)),
        claimDate: DateTime.now().subtract(const Duration(days: 5)),
        documents: ['damage_assessment.pdf', 'equipment_list.pdf'],
        notes: 'Awaiting assessment report from Prime Insurance',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
    ];

    _claims['POL-4'] = [
      InsuranceClaim(
        id: 'CLAIM-5',
        policyId: 'POL-4',
        policyName: 'Life Insurance Premium',
        description: 'Policy activation and initial setup',
        type: ClaimType.life,
        status: ClaimStatus.pending,
        claimAmount: 0,
        incidentDate: DateTime.now().subtract(const Duration(days: 3)),
        claimDate: DateTime.now().subtract(const Duration(days: 2)),
        documents: ['policy_documents.pdf', 'medical_exam.pdf'],
        notes: 'Policy pending activation by Rwanda National Insurance Company',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ];

    _claims['POL-5'] = [
      InsuranceClaim(
        id: 'CLAIM-6',
        policyId: 'POL-5',
        policyName: 'Home Insurance',
        description: 'Water damage from roof leak during rainy season',
        type: ClaimType.property,
        status: ClaimStatus.rejected,
        claimAmount: 85000,
        incidentDate: DateTime.now().subtract(const Duration(days: 60)),
        claimDate: DateTime.now().subtract(const Duration(days: 55)),
        processedDate: DateTime.now().subtract(const Duration(days: 50)),
        documents: ['damage_photos.pdf', 'repair_estimate.pdf'],
        notes: 'Claim rejected due to policy expiration by Soras Insurance',
        rejectionReason: 'Policy expired before incident date',
        createdAt: DateTime.now().subtract(const Duration(days: 55)),
      ),
    ];
  }

  // Policy Management
  void addPolicy(InsurancePolicy policy) {
    state = [...state, policy];
  }

  void updatePolicy(InsurancePolicy policy) {
    state = state.map((p) => p.id == policy.id ? policy : p).toList();
  }

  void deletePolicy(String policyId) {
    state = state.where((policy) => policy.id != policyId).toList();
  }

  void updatePolicyStatus(String policyId, PolicyStatus status) {
    state = state.map((policy) {
      if (policy.id == policyId) {
        return policy.copyWith(status: status);
      }
      return policy;
    }).toList();
  }

  // Claims Management
  void addClaim(InsuranceClaim claim) {
    if (!_claims.containsKey(claim.policyId)) {
      _claims[claim.policyId] = [];
    }
    _claims[claim.policyId]!.add(claim);
  }

  void updateClaim(InsuranceClaim claim) {
    if (_claims.containsKey(claim.policyId)) {
      _claims[claim.policyId] = _claims[claim.policyId]!
          .map((c) => c.id == claim.id ? claim : c)
          .toList();
    }
  }

  List<InsuranceClaim> getClaimsForPolicy(String policyId) {
    return _claims[policyId] ?? [];
  }

  List<InsuranceClaim> getAllClaims() {
    return _claims.values.expand((claims) => claims).toList();
  }

  // Computed Lists
  List<InsurancePolicy> get activePolicies => 
      state.where((policy) => policy.status == PolicyStatus.active).toList();

  List<InsurancePolicy> get pendingPolicies => 
      state.where((policy) => policy.status == PolicyStatus.pending).toList();

  List<InsurancePolicy> get expiredPolicies => 
      state.where((policy) => policy.status == PolicyStatus.expired).toList();

  List<InsurancePolicy> get cancelledPolicies => 
      state.where((policy) => policy.status == PolicyStatus.cancelled).toList();

  List<InsurancePolicy> get policiesNeedingRenewal => 
      state.where((policy) => policy.needsRenewal).toList();

  List<InsurancePolicy> getPoliciesByType(InsuranceType type) {
    return state.where((policy) => policy.type == type).toList();
  }

  // Statistics
  double get totalCoverageAmount {
    return state.fold(0, (sum, policy) => sum + policy.coverageAmount);
  }

  double get totalPremiumAmount {
    return state.fold(0, (sum, policy) => sum + policy.premiumAmount);
  }

  double get averagePremiumAmount {
    if (state.isEmpty) return 0;
    return totalPremiumAmount / state.length;
  }

  Map<String, dynamic> get insuranceStats {
    return {
      'totalPolicies': state.length,
      'activePolicies': activePolicies.length,
      'pendingPolicies': pendingPolicies.length,
      'expiredPolicies': expiredPolicies.length,
      'totalCoverage': totalCoverageAmount,
      'totalPremium': totalPremiumAmount,
      'averagePremium': averagePremiumAmount,
      'policiesNeedingRenewal': policiesNeedingRenewal.length,
    };
  }

  // Provider Management
  List<insurance_provider_model.InsuranceProvider> get providers => _providers;

  insurance_provider_model.InsuranceProvider? getProviderById(String id) {
    try {
      return _providers.firstWhere((provider) => provider.id == id);
    } catch (e) {
      return null;
    }
  }

  List<insurance_provider_model.InsuranceProvider> getProvidersByType(String type) {
    return _providers.where((provider) => 
        provider.supportedTypes.contains(type)).toList();
  }
}

// Providers
final insuranceProvider = StateNotifierProvider<InsuranceNotifier, List<InsurancePolicy>>((ref) {
  return InsuranceNotifier();
});

final activePoliciesProvider = Provider<List<InsurancePolicy>>((ref) {
  final notifier = ref.watch(insuranceProvider.notifier);
  return notifier.activePolicies;
});

final pendingPoliciesProvider = Provider<List<InsurancePolicy>>((ref) {
  final notifier = ref.watch(insuranceProvider.notifier);
  return notifier.pendingPolicies;
});

final expiredPoliciesProvider = Provider<List<InsurancePolicy>>((ref) {
  final notifier = ref.watch(insuranceProvider.notifier);
  return notifier.expiredPolicies;
});

final cancelledPoliciesProvider = Provider<List<InsurancePolicy>>((ref) {
  final notifier = ref.watch(insuranceProvider.notifier);
  return notifier.cancelledPolicies;
});

final policiesNeedingRenewalProvider = Provider<List<InsurancePolicy>>((ref) {
  final notifier = ref.watch(insuranceProvider.notifier);
  return notifier.policiesNeedingRenewal;
});

final insuranceStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final notifier = ref.watch(insuranceProvider.notifier);
  return notifier.insuranceStats;
});

final insuranceProvidersProvider = Provider<List<insurance_provider_model.InsuranceProvider>>((ref) {
  final notifier = ref.watch(insuranceProvider.notifier);
  return notifier.providers;
});

final policyClaimsProvider = Provider.family<List<InsuranceClaim>, String>((ref, policyId) {
  final notifier = ref.watch(insuranceProvider.notifier);
  return notifier.getClaimsForPolicy(policyId);
});

final allClaimsProvider = Provider<List<InsuranceClaim>>((ref) {
  final notifier = ref.watch(insuranceProvider.notifier);
  return notifier.getAllClaims();
}); 