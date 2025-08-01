import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../providers/insurance_provider.dart';
import '../../domain/models/insurance_policy.dart';
import '../../domain/models/insurance_provider.dart' as insurance_provider_model;

class PurchaseInsuranceScreen extends ConsumerStatefulWidget {
  const PurchaseInsuranceScreen({super.key});

  @override
  ConsumerState<PurchaseInsuranceScreen> createState() => _PurchaseInsuranceScreenState();
}

class _PurchaseInsuranceScreenState extends ConsumerState<PurchaseInsuranceScreen> {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  
  // Form controllers
  final _policyNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _coverageAmountController = TextEditingController();
  final _premiumAmountController = TextEditingController();
  
  // Selected values
  insurance_provider_model.InsuranceProvider? _selectedProvider;
  InsuranceType? _selectedType;
  Map<String, dynamic>? _selectedPlan;
  PaymentFrequency? _selectedFrequency;
  final List<String> _beneficiaries = [];
  final _beneficiaryController = TextEditingController();
  String? _selectedPaymentMethod;
  
  // Insurance plans by provider and type
  final Map<String, Map<InsuranceType, List<Map<String, dynamic>>>> _insurancePlans = {
    'Sanlam Rwanda': {
      InsuranceType.health: [
        {
          'id': 'sanlam_health_basic',
          'name': 'Basic Health Plan',
          'coverage': 2000000,
          'premium': 25000,
          'description': 'Basic health coverage for individuals',
          'features': ['Hospitalization', 'Outpatient care', 'Prescription drugs'],
          'term': '1 year',
        },
        {
          'id': 'sanlam_health_premium',
          'name': 'Premium Health Plan',
          'coverage': 5000000,
          'premium': 45000,
          'description': 'Comprehensive health coverage for families',
          'features': ['Hospitalization', 'Outpatient care', 'Prescription drugs', 'Dental care', 'Vision care'],
          'term': '1 year',
        },
        {
          'id': 'sanlam_health_family',
          'name': 'Family Health Plan',
          'coverage': 10000000,
          'premium': 75000,
          'description': 'Complete family health protection',
          'features': ['Hospitalization', 'Outpatient care', 'Prescription drugs', 'Dental care', 'Vision care', 'Maternity care'],
          'term': '1 year',
        },
      ],
      InsuranceType.life: [
        {
          'id': 'sanlam_life_basic',
          'name': 'Basic Life Plan',
          'coverage': 10000000,
          'premium': 20000,
          'description': 'Basic life insurance protection',
          'features': ['Death benefit', 'Accidental death', 'Funeral expenses'],
          'term': '10 years',
        },
        {
          'id': 'sanlam_life_premium',
          'name': 'Premium Life Plan',
          'coverage': 25000000,
          'premium': 40000,
          'description': 'Comprehensive life insurance',
          'features': ['Death benefit', 'Accidental death', 'Funeral expenses', 'Critical illness', 'Disability benefit'],
          'term': '20 years',
        },
      ],
    },
    'Radiant Insurance': {
      InsuranceType.vehicle: [
        {
          'id': 'radiant_vehicle_basic',
          'name': 'Basic Vehicle Plan',
          'coverage': 5000000,
          'premium': 45000,
          'description': 'Basic vehicle insurance coverage',
          'features': ['Third party liability', 'Accident damage', 'Theft protection'],
          'term': '1 year',
        },
        {
          'id': 'radiant_vehicle_comprehensive',
          'name': 'Comprehensive Vehicle Plan',
          'coverage': 15000000,
          'premium': 85000,
          'description': 'Complete vehicle protection',
          'features': ['Third party liability', 'Accident damage', 'Theft protection', 'Natural disasters', 'Personal accident'],
          'term': '1 year',
        },
      ],
      InsuranceType.property: [
        {
          'id': 'radiant_property_basic',
          'name': 'Basic Property Plan',
          'coverage': 10000000,
          'premium': 35000,
          'description': 'Basic property insurance',
          'features': ['Fire damage', 'Theft protection', 'Natural disasters'],
          'term': '1 year',
        },
      ],
    },
    'Prime Insurance': {
      InsuranceType.business: [
        {
          'id': 'prime_business_basic',
          'name': 'Basic Business Plan',
          'coverage': 20000000,
          'premium': 60000,
          'description': 'Basic business insurance coverage',
          'features': ['Property damage', 'Liability protection', 'Business interruption'],
          'term': '1 year',
        },
        {
          'id': 'prime_business_premium',
          'name': 'Premium Business Plan',
          'coverage': 50000000,
          'premium': 120000,
          'description': 'Comprehensive business protection',
          'features': ['Property damage', 'Liability protection', 'Business interruption', 'Employee benefits', 'Cyber protection'],
          'term': '1 year',
        },
      ],
    },
  };

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _policyNameController.dispose();
    _descriptionController.dispose();
    _coverageAmountController.dispose();
    _premiumAmountController.dispose();
    _beneficiaryController.dispose();
    super.dispose();
  }

  void _updatePremiumFromPlan() {
    if (_selectedPlan != null) {
      setState(() {
        _premiumAmountController.text = NumberFormat('#,##0', 'en_US').format(_selectedPlan!['premium']);
        _coverageAmountController.text = NumberFormat('#,##0', 'en_US').format(_selectedPlan!['coverage']);
      });
    }
  }

  void _addBeneficiary() {
    if (_beneficiaryController.text.trim().isNotEmpty) {
      setState(() {
        _beneficiaries.add(_beneficiaryController.text.trim());
        _beneficiaryController.clear();
      });
    }
  }

  void _removeBeneficiary(int index) {
    setState(() {
      _beneficiaries.removeAt(index);
    });
  }

  void _nextStep() {
    if (_currentStep < 5) {
      setState(() {
        _currentStep++;
      });
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  void _submitPolicy() async {
    if (_formKey.currentState!.validate() && _selectedProvider != null && _selectedType != null && _selectedPlan != null && _selectedPaymentMethod != null) {
      setState(() => _isLoading = true);
      
      // Simulate payment processing
      await Future.delayed(const Duration(seconds: 2));
      
      if (!mounted) return;
      
      setState(() => _isLoading = false);
      
      final newPolicy = InsurancePolicy(
        id: 'POL-${DateTime.now().millisecondsSinceEpoch}',
        name: _policyNameController.text,
        description: _descriptionController.text,
        type: _selectedType!,
        providerName: _selectedProvider!.name,
        providerId: _selectedProvider!.id,
        premiumAmount: _selectedPlan!['premium'].toDouble(),
        coverageAmount: _selectedPlan!['coverage'].toDouble(),
        paymentFrequency: _selectedFrequency ?? PaymentFrequency.monthly,
        status: PolicyStatus.pending,
        startDate: DateTime.now().add(const Duration(days: 7)),
        endDate: DateTime.now().add(const Duration(days: 372)),
        renewalDate: DateTime.now().add(const Duration(days: 365)),
        beneficiaries: _beneficiaries,
        policyNumber: 'POL-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch}',
        createdAt: DateTime.now(),
      );

      ref.read(insuranceProvider.notifier).addPolicy(newPolicy);
      
      ScaffoldMessenger.of(context).showSnackBar(
        AppTheme.successSnackBar(message: 'Insurance policy purchased successfully!'),
      );
      
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final providers = ref.watch(insuranceProvidersProvider);
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Purchase Insurance',
          style: TextStyle(
            color: AppTheme.textPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimaryColor),
      ),
      body: Column(
        children: [
          // Progress indicator
          Container(
            padding: const EdgeInsets.all(AppTheme.spacing16),
            child: Row(
              children: [
                for (int i = 0; i < 6; i++)
                  Expanded(
                    child: Container(
                      height: 4,
                      margin: EdgeInsets.only(right: i < 5 ? AppTheme.spacing8 : 0),
                      decoration: BoxDecoration(
                        color: i <= _currentStep ? AppTheme.primaryColor : AppTheme.textSecondaryColor.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
                  // Step indicator
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Provider', style: TextStyle(fontSize: 12, color: _currentStep >= 0 ? AppTheme.primaryColor : AppTheme.textSecondaryColor)),
              Text('Type', style: TextStyle(fontSize: 12, color: _currentStep >= 1 ? AppTheme.primaryColor : AppTheme.textSecondaryColor)),
              Text('Plan', style: TextStyle(fontSize: 12, color: _currentStep >= 2 ? AppTheme.primaryColor : AppTheme.textSecondaryColor)),
              Text('Details', style: TextStyle(fontSize: 12, color: _currentStep >= 3 ? AppTheme.primaryColor : AppTheme.textSecondaryColor)),
              Text('Review', style: TextStyle(fontSize: 12, color: _currentStep >= 4 ? AppTheme.primaryColor : AppTheme.textSecondaryColor)),
              Text('Payment', style: TextStyle(fontSize: 12, color: _currentStep >= 5 ? AppTheme.primaryColor : AppTheme.textSecondaryColor)),
            ],
          ),
        ),
          
          const SizedBox(height: AppTheme.spacing16),
          
          // Step content
          Expanded(
            child: Form(
              key: _formKey,
              child: IndexedStack(
                index: _currentStep,
                children: [
                  _buildProviderSelection(providers),
                  _buildTypeSelection(),
                  _buildPlanSelection(),
                  _buildPolicyDetails(),
                  _buildReviewStep(),
                  _buildPaymentStep(),
                ],
              ),
            ),
          ),
          
          // Navigation buttons
          Container(
            padding: const EdgeInsets.all(AppTheme.spacing16),
            child: Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _previousStep,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                        side: const BorderSide(color: AppTheme.primaryColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                        ),
                      ),
                      child: Text(
                        'Previous',
                        style: TextStyle(color: AppTheme.primaryColor),
                      ),
                    ),
                  ),
                if (_currentStep > 0) const SizedBox(width: AppTheme.spacing12),
                Expanded(
                  child: PrimaryButton(
                    label: _currentStep == 5 ? 'Confirm & Pay' : 'Next',
                    onPressed: _currentStep == 5 ? _submitPolicy : _nextStep,
                    isLoading: _currentStep == 5 ? _isLoading : false,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderSelection(List<insurance_provider_model.InsuranceProvider> providers) {
    return ListView(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      children: [
        Text(
          'Select Insurance Provider',
          style: AppTheme.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: AppTheme.spacing8),
        Text(
          'Choose from our trusted insurance partners in Rwanda',
          style: AppTheme.bodyMedium.copyWith(
            color: AppTheme.textSecondaryColor,
          ),
        ),
        const SizedBox(height: AppTheme.spacing24),
        
        ...providers.map((provider) => _buildProviderCard(provider)),
      ],
    );
  }

  Widget _buildProviderCard(insurance_provider_model.InsuranceProvider provider) {
    final isSelected = _selectedProvider?.id == provider.id;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedProvider = provider;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: AppTheme.spacing12),
        padding: const EdgeInsets.all(AppTheme.spacing16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : AppTheme.thinBorderColor,
            width: isSelected ? 2 : AppTheme.thinBorderWidth,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
              ),
              child: Icon(
                Icons.account_balance,
                color: AppTheme.primaryColor,
                size: 30,
              ),
            ),
            const SizedBox(width: AppTheme.spacing16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    provider.name,
                    style: AppTheme.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing4),
                  Text(
                    provider.description,
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),

                ],
              ),
            ),
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: AppTheme.surfaceColor,
                  size: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelection() {
    if (_selectedProvider == null) return Container();
    
    final availableTypes = _insurancePlans[_selectedProvider!.name]?.keys.toList() ?? [];
    
    return ListView(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      children: [
        Text(
          'Select Insurance Type',
          style: AppTheme.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: AppTheme.spacing8),
        Text(
          'Choose the type of insurance coverage you need',
          style: AppTheme.bodyMedium.copyWith(
            color: AppTheme.textSecondaryColor,
          ),
        ),
        const SizedBox(height: AppTheme.spacing24),
        
        ...availableTypes.map((type) => _buildTypeCard(type)),
      ],
    );
  }

    Widget _buildPlanSelection() {
    if (_selectedProvider == null || _selectedType == null) return Container();
    
    final plans = _insurancePlans[_selectedProvider!.name]?[_selectedType!] ?? [];
    
    return ListView(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      children: [
        Text(
          'Select Insurance Plan',
          style: AppTheme.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: AppTheme.spacing8),
        Text(
          'Choose a plan that fits your needs',
          style: AppTheme.bodyMedium.copyWith(
            color: AppTheme.textSecondaryColor,
          ),
        ),
        const SizedBox(height: AppTheme.spacing24),
        
        ...plans.map((plan) => _buildPlanCard(plan)),
      ],
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan) {
    final isSelected = _selectedPlan?['id'] == plan['id'];
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPlan = plan;
          _updatePremiumFromPlan();
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: AppTheme.spacing16),
        padding: const EdgeInsets.all(AppTheme.spacing16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : AppTheme.thinBorderColor,
            width: isSelected ? 2 : AppTheme.thinBorderWidth,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan['name'] as String,
                        style: AppTheme.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacing4),
                      Text(
                        plan['description'] as String,
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: AppTheme.surfaceColor,
                      size: 16,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppTheme.spacing12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Coverage',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                      Text(
                        'RWF ${NumberFormat('#,##0', 'en_US').format(plan['coverage'])}',
                        style: AppTheme.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Premium',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                      Text(
                        'RWF ${NumberFormat('#,##0', 'en_US').format(plan['premium'])}',
                        style: AppTheme.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Term',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                      Text(
                        plan['term'] as String,
                        style: AppTheme.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacing12),
            Text(
              'Features:',
              style: AppTheme.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: AppTheme.spacing4),
            ...(plan['features'] as List<String>).map((feature) => Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spacing2),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: AppTheme.primaryColor, size: 16),
                  const SizedBox(width: AppTheme.spacing8),
                  Expanded(
                    child: Text(
                      feature,
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeCard(InsuranceType type) {
    final isSelected = _selectedType == type;
    
    // Get icon for insurance type
    IconData getIconForType(InsuranceType type) {
      switch (type) {
        case InsuranceType.health:
          return Icons.health_and_safety;
        case InsuranceType.life:
          return Icons.favorite;
        case InsuranceType.vehicle:
          return Icons.directions_car;
        case InsuranceType.property:
          return Icons.home;
        case InsuranceType.business:
          return Icons.business;
      }
    }
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = type;
          _selectedPlan = null; // Reset plan selection when type changes
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: AppTheme.spacing12),
        padding: const EdgeInsets.all(AppTheme.spacing16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : AppTheme.thinBorderColor,
            width: isSelected ? 2 : AppTheme.thinBorderWidth,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
              ),
              child: Icon(
                getIconForType(type),
                color: AppTheme.primaryColor,
                size: 30,
              ),
            ),
            const SizedBox(width: AppTheme.spacing16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    type.name.toUpperCase(),
                    style: AppTheme.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing4),
                  Text(
                    'Available plans from ${_selectedProvider?.name}',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: AppTheme.surfaceColor,
                  size: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPolicyDetails() {
    return ListView(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      children: [
        Text(
          'Policy Details',
          style: AppTheme.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: AppTheme.spacing8),
        Text(
          'Fill in the details for your insurance policy',
          style: AppTheme.bodyMedium.copyWith(
            color: AppTheme.textSecondaryColor,
          ),
        ),
        const SizedBox(height: AppTheme.spacing24),
        
        // Policy Name
        Text('Policy Name', style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: AppTheme.spacing8),
        TextFormField(
          controller: _policyNameController,
          style: AppTheme.bodySmall,
          decoration: const InputDecoration(
            hintText: 'e.g., Family Health Coverage',
            prefixIcon: Icon(Icons.policy),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a policy name';
            }
            return null;
          },
        ),
        const SizedBox(height: AppTheme.spacing16),
        
        // Description
        Text('Description', style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: AppTheme.spacing8),
        TextFormField(
          controller: _descriptionController,
          style: AppTheme.bodySmall,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Brief description of the policy',
            prefixIcon: Icon(Icons.description),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a description';
            }
            return null;
          },
        ),
        const SizedBox(height: AppTheme.spacing16),
        
        // Selected Plan Summary
        if (_selectedPlan != null) ...[
          Container(
            padding: const EdgeInsets.all(AppTheme.spacing16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
              border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selected Plan: ${_selectedPlan!['name']}',
                  style: AppTheme.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: AppTheme.spacing8),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Coverage',
                            style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                          Text(
                            'RWF ${NumberFormat('#,##0', 'en_US').format(_selectedPlan!['coverage'])}',
                            style: AppTheme.bodyMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Premium',
                            style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                          Text(
                            'RWF ${NumberFormat('#,##0', 'en_US').format(_selectedPlan!['premium'])}',
                            style: AppTheme.bodyMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Term',
                            style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                          Text(
                            _selectedPlan!['term'] as String,
                            style: AppTheme.bodyMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacing16),
        ],
        const SizedBox(height: AppTheme.spacing16),
        
        // Payment Frequency
        Text('Payment Frequency', style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: AppTheme.spacing8),
        DropdownButtonFormField<PaymentFrequency>(
          value: _selectedFrequency,
          style: AppTheme.bodySmall,
          decoration: const InputDecoration(
            hintText: 'Select payment frequency',
            prefixIcon: Icon(Icons.schedule),
          ),
          items: PaymentFrequency.values.map((frequency) {
            return DropdownMenuItem(
              value: frequency,
              child: Text(frequency.name.toUpperCase()),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedFrequency = value;
            });
          },
          validator: (value) {
            if (value == null) {
              return 'Please select payment frequency';
            }
            return null;
          },
        ),
        const SizedBox(height: AppTheme.spacing16),
        
        // Beneficiaries
        Text('Beneficiaries', style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: AppTheme.spacing8),
        
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _beneficiaryController,
                style: AppTheme.bodySmall,
                decoration: const InputDecoration(
                  hintText: 'Enter beneficiary name',
                  prefixIcon: Icon(Icons.person_add),
                ),
              ),
            ),
            const SizedBox(width: AppTheme.spacing12),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                border: Border.all(color: AppTheme.thinBorderColor, width: AppTheme.thinBorderWidth),
              ),
              child: IconButton(
                icon: const Icon(Icons.add, color: AppTheme.primaryColor),
                tooltip: 'Add beneficiary',
                onPressed: _addBeneficiary,
              ),
            ),
          ],
        ),
        
        if (_beneficiaries.isNotEmpty) ...[
          const SizedBox(height: AppTheme.spacing12),
          ..._beneficiaries.asMap().entries.map((entry) {
            final index = entry.key;
            final beneficiary = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: AppTheme.spacing8),
              padding: const EdgeInsets.all(AppTheme.spacing12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  width: AppTheme.thinBorderWidth,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.person,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: AppTheme.spacing8),
                  Expanded(
                    child: Text(
                      beneficiary,
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _removeBeneficiary(index),
                    icon: const Icon(Icons.remove_circle, color: AppTheme.errorColor),
                    iconSize: 20,
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ],
    );
  }

  Widget _buildReviewStep() {
    return ListView(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      children: [
        Text(
          'Review Policy',
          style: AppTheme.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: AppTheme.spacing8),
        Text(
          'Please review your insurance policy details before purchase',
          style: AppTheme.bodyMedium.copyWith(
            color: AppTheme.textSecondaryColor,
          ),
        ),
        const SizedBox(height: AppTheme.spacing24),
        
        // Policy Summary Card
        Container(
          padding: const EdgeInsets.all(AppTheme.spacing16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
            border: Border.all(
              color: AppTheme.thinBorderColor,
              width: AppTheme.thinBorderWidth,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Policy Summary',
                style: AppTheme.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: AppTheme.spacing16),
              
              _buildReviewRow('Policy Name', _policyNameController.text),
              _buildReviewRow('Provider', _selectedProvider?.name ?? ''),
              _buildReviewRow('Type', _selectedType?.name.toUpperCase() ?? ''),
              _buildReviewRow('Coverage Amount', 'RWF ${_coverageAmountController.text}'),
              _buildReviewRow('Monthly Premium', 'RWF ${_premiumAmountController.text}'),
              _buildReviewRow('Payment Frequency', _selectedFrequency?.name.toUpperCase() ?? ''),
              _buildReviewRow('Beneficiaries', _beneficiaries.join(', ')),
              
              const SizedBox(height: AppTheme.spacing16),
              
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppTheme.spacing12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                  border: Border.all(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    width: AppTheme.thinBorderWidth,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Important Notes:',
                      style: AppTheme.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing8),
                    Text(
                      '• Policy will be reviewed by ${_selectedProvider?.name ?? 'the insurance provider'}\n'
                      '• Coverage starts 7 days after approval\n'
                      '• Premium payments are due monthly\n'
                      '• Policy can be cancelled with 30 days notice',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacing8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: AppTheme.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textPrimaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentStep() {
    final paymentMethods = [
      {'id': 'mobile_money', 'name': 'Mobile Money'},
      {'id': 'card', 'name': 'Credit/Debit Card'},
      {'id': 'bank', 'name': 'Bank Transfer'},
    ];

    return ListView(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      children: [
        Text(
          'Select Payment Method',
          style: AppTheme.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: AppTheme.spacing8),
        Text(
          'Choose your preferred payment method',
          style: AppTheme.bodyMedium.copyWith(
            color: AppTheme.textSecondaryColor,
          ),
        ),
        const SizedBox(height: AppTheme.spacing24),
        
        // Payment Method Dropdown
        Text('Payment Method', style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: AppTheme.spacing8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
            border: Border.all(
              color: AppTheme.thinBorderColor,
              width: AppTheme.thinBorderWidth,
            ),
          ),
          child: DropdownButtonFormField<String>(
            value: _selectedPaymentMethod,
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.textPrimaryColor,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: AppTheme.spacing12),
              hintText: 'Select payment method',
            ),
            dropdownColor: AppTheme.surfaceColor,
            items: paymentMethods.map((method) {
              return DropdownMenuItem<String>(
                value: method['id'] as String,
                child: Text(
                  method['name'] as String,
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedPaymentMethod = value;
              });
            },
            validator: (value) {
              if (value == null) {
                return 'Please select a payment method';
              }
              return null;
            },
          ),
        ),
        
        const SizedBox(height: AppTheme.spacing24),
        
        // Payment Summary
        Container(
          padding: const EdgeInsets.all(AppTheme.spacing16),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.05),
            borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
            border: Border.all(
              color: AppTheme.primaryColor.withOpacity(0.2),
              width: AppTheme.thinBorderWidth,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Payment Summary',
                style: AppTheme.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: AppTheme.spacing12),
              _buildPaymentSummaryRow('Policy Premium', 'RWF ${_premiumAmountController.text}'),
              _buildPaymentSummaryRow('Processing Fee', 'RWF 1,000'),
              const Divider(),
              _buildPaymentSummaryRow('Total Amount', 'RWF ${NumberFormat('#,##0', 'en_US').format((double.tryParse(_premiumAmountController.text.replaceAll(',', '')) ?? 0) + 1000)}', isTotal: true),
            ],
          ),
        ),
      ],
    );
  }



  Widget _buildPaymentSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacing8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTheme.bodyMedium.copyWith(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          Text(
            value,
            style: AppTheme.bodyMedium.copyWith(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: isTotal ? AppTheme.primaryColor : AppTheme.textPrimaryColor,
            ),
          ),
        ],
      ),
    );
  }
} 