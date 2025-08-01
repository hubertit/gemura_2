import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class DetailsActionSheet extends StatelessWidget {
  final String? title;
  final Widget? headerWidget;
  final List<DetailRow> details;
  final VoidCallback? onClose;

  const DetailsActionSheet({
    super.key,
    this.title,
    this.headerWidget,
    required this.details,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with drag handle
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textHintColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          // Close button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                InkWell(
                  onTap: onClose ?? () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppTheme.textHintColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close,
                      color: AppTheme.textSecondaryColor,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Optional header widget (for transaction amount, wallet balance, etc.)
          if (headerWidget != null) ...[
            const SizedBox(height: 12),
            headerWidget!,
            const SizedBox(height: 16),
          ],
          // Details with dotted separators
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: details.map((detail) => _DetailRowWidget(detail: detail)).toList(),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class DetailRow {
  final String label;
  final String value;
  final Color? valueColor;
  final Widget? customValue;

  const DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.customValue,
  });
}

class _DetailRowWidget extends StatelessWidget {
  final DetailRow detail;

  const _DetailRowWidget({required this.detail});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 100,
              child: Text(
                detail.label,
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.textSecondaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              child: detail.customValue ?? Text(
                detail.value,
                style: AppTheme.bodyMedium.copyWith(
                  color: detail.valueColor ?? AppTheme.textPrimaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Dotted separator
        Row(
          children: [
            Expanded(
              child: Container(
                height: 1,
                child: CustomPaint(
                  painter: DottedLinePainter(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

// Custom painter for dotted lines
class DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.textHintColor.withOpacity(0.3)
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;

    const dashWidth = 3;
    const dashSpace = 3;
    double startX = 0;
    final double endX = size.width;

    while (startX < endX) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset(startX + dashWidth, 0),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class AddItemCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const AddItemCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppTheme.spacing12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius16),
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spacing16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(AppTheme.borderRadius16),
            border: Border.all(
              color: AppTheme.thinBorderColor,
              width: AppTheme.thinBorderWidth,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacing8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
                ),
                child: Icon(
                  icon,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppTheme.spacing12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.textPrimaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing2),
                    Text(
                      subtitle,
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textSecondaryColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: AppTheme.textSecondaryColor,
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CustomRulesActionSheet extends StatefulWidget {
  final Map<String, dynamic> initialRules;
  final Function(Map<String, dynamic>) onRulesChanged;
  final String title;

  const CustomRulesActionSheet({
    super.key,
    required this.initialRules,
    required this.onRulesChanged,
    this.title = 'Customize Rules',
  });

  @override
  State<CustomRulesActionSheet> createState() => _CustomRulesActionSheetState();
}

class _CustomRulesActionSheetState extends State<CustomRulesActionSheet> {
  late Map<String, dynamic> _rules;
  int _minContribution = 1000;
  int _maxWithdrawal = 50;
  int _cycleDuration = 9;
  String _interestType = 'percentage'; // 'percentage' or 'fixed'
  int _interestRate = 10;
  int _interestAmount = 5000;
  String _contributionFrequency = 'monthly';
  bool _enablePenalties = false;
  String _penaltyType = 'percentage'; // 'percentage' or 'fixed'
  int _penaltyRate = 5;
  int _penaltyAmount = 1000;
  int _gracePeriod = 3; // days
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _rules = Map<String, dynamic>.from(widget.initialRules);
    _minContribution = _rules['minContribution'] ?? 1000;
    _maxWithdrawal = _rules['maxWithdrawal'] ?? 50;
    _cycleDuration = _rules['cycleDuration'] ?? 9;
    _interestType = _rules['interestType'] ?? 'percentage';
    _interestRate = _rules['interestRate'] ?? 10;
    _interestAmount = _rules['interestAmount'] ?? 5000;
    _contributionFrequency = _rules['contributionFrequency'] ?? 'monthly';
    _enablePenalties = _rules['enablePenalties'] ?? false;
    _penaltyType = _rules['penaltyType'] ?? 'percentage';
    _penaltyRate = _rules['penaltyRate'] ?? 5;
    _penaltyAmount = _rules['penaltyAmount'] ?? 1000;
    _gracePeriod = _rules['gracePeriod'] ?? 3;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _saveRules() {
    setState(() {
      _rules['minContribution'] = _minContribution;
      _rules['maxWithdrawal'] = _maxWithdrawal;
      _rules['cycleDuration'] = _cycleDuration;
      _rules['interestType'] = _interestType;
      _rules['interestRate'] = _interestRate;
      _rules['interestAmount'] = _interestAmount;
      _rules['contributionFrequency'] = _contributionFrequency;
      _rules['enablePenalties'] = _enablePenalties;
      _rules['penaltyType'] = _penaltyType;
      _rules['penaltyRate'] = _penaltyRate;
      _rules['penaltyAmount'] = _penaltyAmount;
      _rules['gracePeriod'] = _gracePeriod;
    });
    widget.onRulesChanged(_rules);
    Navigator.of(context).pop();
  }

  void _togglePenalties(bool value) {
    setState(() {
      _enablePenalties = value;
    });
    
    // Auto-scroll to show penalty fields when enabled
    if (value) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final maxHeight = screenHeight * 0.75; // 75% of screen height
    final minHeight = 400.0; // Minimum height to ensure usability
    
    return Container(
      constraints: BoxConstraints(
        maxHeight: maxHeight,
        minHeight: minHeight,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with drag handle
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textHintColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          // Title and close button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Icon(
                  Icons.settings,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: AppTheme.spacing12),
                Expanded(
                  child: Text(
                    widget.title,
                    style: AppTheme.titleMedium.copyWith(
                      color: AppTheme.textPrimaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppTheme.textHintColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close,
                      color: AppTheme.textSecondaryColor,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Rules Form - Scrollable content
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Minimum Contribution
                  _buildStepperField(
                    label: 'Minimum Contribution (RWF)',
                    value: _minContribution,
                    onChanged: (value) => setState(() => _minContribution = value),
                    icon: Icons.attach_money,
                    min: 500,
                    max: 10000,
                    step: 500,
                    suffix: ' RWF',
                  ),
                  const SizedBox(height: AppTheme.spacing16),
                  
                  // Maximum Withdrawal
                  _buildStepperField(
                    label: 'Maximum Withdrawal (%)',
                    value: _maxWithdrawal,
                    onChanged: (value) => setState(() => _maxWithdrawal = value),
                    icon: Icons.trending_up,
                    min: 10,
                    max: 100,
                    step: 5,
                    suffix: '%',
                  ),
                  const SizedBox(height: AppTheme.spacing16),
                  
                  // Cycle Duration
                  _buildStepperField(
                    label: 'Cycle Duration',
                    value: _cycleDuration,
                    onChanged: (value) => setState(() => _cycleDuration = value),
                    icon: Icons.calendar_today,
                    min: 3,
                    max: 24,
                    step: 1,
                    suffix: ' months',
                  ),
                  const SizedBox(height: AppTheme.spacing16),
                  
                  // Interest Rate Type and Value
                  _buildInterestRateField(),
                  const SizedBox(height: AppTheme.spacing16),
                  
                  // Contribution Frequency
                  _buildDropdownField(
                    label: 'Contribution Frequency',
                    value: _contributionFrequency,
                    onChanged: (value) => setState(() => _contributionFrequency = value ?? 'monthly'),
                    icon: Icons.schedule,
                    options: ['daily', 'weekly', 'monthly'],
                  ),
                  const SizedBox(height: AppTheme.spacing20),
                  
                  // Toggle Rules
                  _buildToggleRule(
                    label: 'Require Majority Approval',
                    value: _rules['requireApproval'],
                    onChanged: (value) => setState(() => _rules['requireApproval'] = value),
                    icon: Icons.how_to_vote,
                  ),
                  const SizedBox(height: AppTheme.spacing12),
                  
                  // Penalties Configuration
                  _buildPenaltiesSection(),
                  const SizedBox(height: AppTheme.spacing20),
                ],
              ),
            ),
          ),
          
          // Action Buttons - Fixed at bottom
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(
                  color: AppTheme.thinBorderColor,
                  width: AppTheme.thinBorderWidth,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textSecondaryColor,
                      side: BorderSide(color: AppTheme.thinBorderColor),
                      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacing12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveRules,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                      ),
                    ),
                    child: Text(
                      'Save Rules',
                      style: AppTheme.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepperField({
    required String label,
    required int value,
    required ValueChanged<int> onChanged,
    required IconData icon,
    required int min,
    required int max,
    required int step,
    String? suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppTheme.primaryColor, size: 16),
            const SizedBox(width: AppTheme.spacing8),
            Text(
              label,
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.textPrimaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacing8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.thinBorderColor),
            borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: value > min ? () => onChanged(value - step) : null,
                icon: Icon(
                  Icons.remove,
                  color: value > min ? AppTheme.primaryColor : AppTheme.textHintColor,
                  size: 20,
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    '$value${suffix ?? ''}',
                    style: AppTheme.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: value < max ? () => onChanged(value + step) : null,
                icon: Icon(
                  Icons.add,
                  color: value < max ? AppTheme.primaryColor : AppTheme.textHintColor,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required ValueChanged<String?> onChanged,
    required IconData icon,
    required List<String> options,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppTheme.primaryColor, size: 16),
            const SizedBox(width: AppTheme.spacing8),
            Text(
              label,
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.textPrimaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacing8),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
              borderSide: BorderSide(color: AppTheme.thinBorderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
              borderSide: BorderSide(color: AppTheme.thinBorderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
              borderSide: BorderSide(color: AppTheme.primaryColor),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacing12,
              vertical: AppTheme.spacing8,
            ),
          ),
          items: options.map((option) => DropdownMenuItem(
            value: option,
            child: Text(
              option.substring(0, 1).toUpperCase() + option.substring(1),
              style: AppTheme.bodySmall,
            ),
          )).toList(),
          onChanged: onChanged,
          style: AppTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildInterestRateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Interest Type Selection
        Row(
          children: [
            Icon(Icons.percent, color: AppTheme.primaryColor, size: 16),
            const SizedBox(width: AppTheme.spacing8),
            Text(
              'Interest Type',
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.textPrimaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacing8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.thinBorderColor),
            borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
          ),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _interestType = 'percentage'),
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing12),
                    decoration: BoxDecoration(
                      color: _interestType == 'percentage' 
                          ? AppTheme.primaryColor.withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                    ),
                    child: Center(
                      child: Text(
                        'Percentage',
                        style: AppTheme.bodySmall.copyWith(
                          color: _interestType == 'percentage' 
                              ? AppTheme.primaryColor 
                              : AppTheme.textSecondaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _interestType = 'fixed'),
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing12),
                    decoration: BoxDecoration(
                      color: _interestType == 'fixed' 
                          ? AppTheme.primaryColor.withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                    ),
                    child: Center(
                      child: Text(
                        'Fixed Amount',
                        style: AppTheme.bodySmall.copyWith(
                          color: _interestType == 'fixed' 
                              ? AppTheme.primaryColor 
                              : AppTheme.textSecondaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.spacing12),
        
        // Interest Value
        Row(
          children: [
            Icon(
              _interestType == 'percentage' ? Icons.percent : Icons.attach_money,
              color: AppTheme.primaryColor,
              size: 16,
            ),
            const SizedBox(width: AppTheme.spacing8),
            Text(
              _interestType == 'percentage' ? 'Interest Rate (%)' : 'Interest Amount (RWF)',
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.textPrimaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacing8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.thinBorderColor),
            borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: _interestType == 'percentage' 
                    ? (_interestRate > 1 ? () => setState(() => _interestRate--) : null)
                    : (_interestAmount > 1000 ? () => setState(() => _interestAmount -= 500) : null),
                icon: Icon(
                  Icons.remove,
                  color: _interestType == 'percentage' 
                      ? (_interestRate > 1 ? AppTheme.primaryColor : AppTheme.textHintColor)
                      : (_interestAmount > 1000 ? AppTheme.primaryColor : AppTheme.textHintColor),
                  size: 20,
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    _interestType == 'percentage' 
                        ? '$_interestRate% per month'
                        : '${_interestAmount.toStringAsFixed(0)} RWF per month',
                    style: AppTheme.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: _interestType == 'percentage' 
                    ? (_interestRate < 20 ? () => setState(() => _interestRate++) : null)
                    : (_interestAmount < 50000 ? () => setState(() => _interestAmount += 500) : null),
                icon: Icon(
                  Icons.add,
                  color: _interestType == 'percentage' 
                      ? (_interestRate < 20 ? AppTheme.primaryColor : AppTheme.textHintColor)
                      : (_interestAmount < 50000 ? AppTheme.primaryColor : AppTheme.textHintColor),
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPenaltiesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Enable Penalties Toggle
        _buildToggleRule(
          label: 'Enable Penalties',
          value: _enablePenalties,
          onChanged: _togglePenalties,
          icon: Icons.warning,
        ),
        
        if (_enablePenalties) ...[
          const SizedBox(height: AppTheme.spacing16),
          
          // Penalty Type Selection
          Row(
            children: [
              Icon(Icons.gavel, color: AppTheme.primaryColor, size: 16),
              const SizedBox(width: AppTheme.spacing8),
              Text(
                'Penalty Type',
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.textPrimaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing8),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.thinBorderColor),
              borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _penaltyType = 'percentage'),
                    borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing12),
                      decoration: BoxDecoration(
                        color: _penaltyType == 'percentage' 
                            ? AppTheme.primaryColor.withOpacity(0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                      ),
                      child: Center(
                        child: Text(
                          'Percentage',
                          style: AppTheme.bodySmall.copyWith(
                            color: _penaltyType == 'percentage' 
                                ? AppTheme.primaryColor 
                                : AppTheme.textSecondaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _penaltyType = 'fixed'),
                    borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing12),
                      decoration: BoxDecoration(
                        color: _penaltyType == 'fixed' 
                            ? AppTheme.primaryColor.withOpacity(0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                      ),
                      child: Center(
                        child: Text(
                          'Fixed Amount',
                          style: AppTheme.bodySmall.copyWith(
                            color: _penaltyType == 'fixed' 
                                ? AppTheme.primaryColor 
                                : AppTheme.textSecondaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacing12),
          
          // Penalty Value
          Row(
            children: [
              Icon(
                _penaltyType == 'percentage' ? Icons.percent : Icons.attach_money,
                color: AppTheme.primaryColor,
                size: 16,
              ),
              const SizedBox(width: AppTheme.spacing8),
              Text(
                _penaltyType == 'percentage' ? 'Penalty Rate (%)' : 'Penalty Amount (RWF)',
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.textPrimaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing8),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.thinBorderColor),
              borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: _penaltyType == 'percentage' 
                      ? (_penaltyRate > 1 ? () => setState(() => _penaltyRate--) : null)
                      : (_penaltyAmount > 500 ? () => setState(() => _penaltyAmount -= 100) : null),
                  icon: Icon(
                    Icons.remove,
                    color: _penaltyType == 'percentage' 
                        ? (_penaltyRate > 1 ? AppTheme.primaryColor : AppTheme.textHintColor)
                        : (_penaltyAmount > 500 ? AppTheme.primaryColor : AppTheme.textHintColor),
                    size: 20,
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      _penaltyType == 'percentage' 
                          ? '$_penaltyRate% per late payment'
                          : '${_penaltyAmount.toStringAsFixed(0)} RWF per late payment',
                      style: AppTheme.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _penaltyType == 'percentage' 
                      ? (_penaltyRate < 20 ? () => setState(() => _penaltyRate++) : null)
                      : (_penaltyAmount < 10000 ? () => setState(() => _penaltyAmount += 100) : null),
                  icon: Icon(
                    Icons.add,
                    color: _penaltyType == 'percentage' 
                        ? (_penaltyRate < 20 ? AppTheme.primaryColor : AppTheme.textHintColor)
                        : (_penaltyAmount < 10000 ? AppTheme.primaryColor : AppTheme.textHintColor),
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacing12),
          
          // Grace Period
          Row(
            children: [
              Icon(Icons.schedule, color: AppTheme.primaryColor, size: 16),
              const SizedBox(width: AppTheme.spacing8),
              Text(
                'Grace Period',
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.textPrimaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing8),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.thinBorderColor),
              borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: _gracePeriod > 1 
                      ? () => setState(() => _gracePeriod--) 
                      : null,
                  icon: Icon(
                    Icons.remove,
                    color: _gracePeriod > 1 ? AppTheme.primaryColor : AppTheme.textHintColor,
                    size: 20,
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      '$_gracePeriod days',
                      style: AppTheme.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _gracePeriod < 7 
                      ? () => setState(() => _gracePeriod++) 
                      : null,
                  icon: Icon(
                    Icons.add,
                    color: _gracePeriod < 7 ? AppTheme.primaryColor : AppTheme.textHintColor,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildToggleRule({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
        border: Border.all(color: AppTheme.thinBorderColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 20),
          const SizedBox(width: AppTheme.spacing12),
          Expanded(
            child: Text(
              label,
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.textPrimaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.primaryColor,
            inactiveThumbColor: AppTheme.textSecondaryColor,
            inactiveTrackColor: AppTheme.textSecondaryColor.withOpacity(0.3),
          ),
        ],
      ),
    );
  }
} 