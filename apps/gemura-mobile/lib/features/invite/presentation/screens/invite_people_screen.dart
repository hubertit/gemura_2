import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/invite_service.dart';
import '../widgets/contact_list_widget.dart';
import '../widgets/invite_method_card.dart';

class InvitePeopleScreen extends ConsumerStatefulWidget {
  const InvitePeopleScreen({super.key});

  @override
  ConsumerState<InvitePeopleScreen> createState() => _InvitePeopleScreenState();
}

class _InvitePeopleScreenState extends ConsumerState<InvitePeopleScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final InviteService _inviteService = InviteService.instance;
  String _referralCode = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _generateReferralCode();
  }

  Future<void> _generateReferralCode() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // In a real app, you would get the current user's ID from your auth service
      // For now, we'll use a mock user ID
      const mockUserId = 'USR001';
      _referralCode = _inviteService.generateReferralCode(mockUserId);
    } catch (e) {
      print('Error generating referral code: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Invite People',
          style: AppTheme.titleMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryColor,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textSecondaryColor,
          labelStyle: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Quick Invite'),
            Tab(text: 'Contacts'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildQuickInviteTab(),
                _buildContactsTab(),
              ],
            ),
    );
  }

  Widget _buildQuickInviteTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Referral Code Section
          _buildReferralCodeSection(),
          const SizedBox(height: AppTheme.spacing24),
          
          // Invite Methods
          Text(
            'Share via',
            style: AppTheme.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: AppTheme.spacing16),
          
          // Share Methods Grid
          _buildShareMethodsGrid(),
          const SizedBox(height: AppTheme.spacing24),
          
          // Benefits Section
          _buildBenefitsSection(),
        ],
      ),
    );
  }

  Widget _buildReferralCodeSection() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.card_giftcard,
                color: AppTheme.primaryColor,
                size: 24,
              ),
              const SizedBox(width: AppTheme.spacing8),
              Text(
                'Your Referral Code',
                style: AppTheme.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing16),
          Container(
            padding: const EdgeInsets.all(AppTheme.spacing16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
              border: Border.all(
                color: AppTheme.primaryColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _referralCode,
                    style: AppTheme.titleLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _copyReferralCode(),
                  icon: Icon(
                    Icons.copy,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacing12),
          Text(
            'Share this code with friends to earn rewards when they join!',
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareMethodsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: AppTheme.spacing12,
      mainAxisSpacing: AppTheme.spacing12,
      childAspectRatio: 1.2,
      children: [
        InviteMethodCard(
          icon: Icons.share,
          title: 'Share App',
          subtitle: 'System share',
          onTap: () => _shareApp(),
        ),
        InviteMethodCard(
          icon: Icons.message,
          title: 'WhatsApp',
          subtitle: 'Send message',
          onTap: () => _shareViaWhatsApp(),
        ),
        InviteMethodCard(
          icon: Icons.sms,
          title: 'SMS',
          subtitle: 'Text message',
          onTap: () => _shareViaSMS(),
        ),
        InviteMethodCard(
          icon: Icons.email,
          title: 'Email',
          subtitle: 'Send email',
          onTap: () => _shareViaEmail(),
        ),
      ],
    );
  }

  Widget _buildBenefitsSection() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Invite Benefits',
            style: AppTheme.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: AppTheme.spacing16),
          _buildBenefitItem(
            icon: Icons.card_giftcard,
            title: 'Earn Rewards',
            description: 'Get rewards for each successful referral',
          ),
          const SizedBox(height: AppTheme.spacing12),
          _buildBenefitItem(
            icon: Icons.people,
            title: 'Grow Network',
            description: 'Connect with more dairy professionals',
          ),
          const SizedBox(height: AppTheme.spacing12),
          _buildBenefitItem(
            icon: Icons.trending_up,
            title: 'Business Growth',
            description: 'Expand your business opportunities',
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
          ),
          child: Icon(
            icon,
            color: AppTheme.primaryColor,
            size: 20,
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
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              Text(
                description,
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContactsTab() {
    return const ContactListWidget();
  }

  // Action Methods
  Future<void> _copyReferralCode() async {
    try {
      await _inviteService.copyReferralCode(_referralCode);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Referral code copied to clipboard!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error copying code: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _shareApp() async {
    try {
      await _inviteService.shareApp(referralCode: _referralCode);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing app: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _shareViaWhatsApp() async {
    try {
      await _inviteService.shareViaWhatsApp(referralCode: _referralCode);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing via WhatsApp: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _shareViaSMS() async {
    try {
      await _inviteService.shareViaSMS(referralCode: _referralCode);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing via SMS: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _shareViaEmail() async {
    try {
      await _inviteService.shareViaEmail(referralCode: _referralCode);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing via email: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
}
