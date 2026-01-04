import 'package:flutter/material.dart';
import 'package:contacts_service/contacts_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/invite_service.dart';

class ContactListWidget extends StatefulWidget {
  const ContactListWidget({super.key});

  @override
  State<ContactListWidget> createState() => _ContactListWidgetState();
}

class _ContactListWidgetState extends State<ContactListWidget> {
  final InviteService _inviteService = InviteService.instance;
  List<Contact> _contacts = [];
  List<Contact> _filteredContacts = [];
  bool _isLoading = true;
  bool _hasPermission = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkPermissionAndLoadContacts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _checkPermissionAndLoadContacts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _hasPermission = await _inviteService.hasContactsPermission();
      
      if (_hasPermission) {
        await _loadContacts();
      } else {
        // Request permission
        _hasPermission = await _inviteService.requestContactsPermission();
        if (_hasPermission) {
          await _loadContacts();
        }
      }
    } catch (e) {
      print('Error loading contacts: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadContacts() async {
    try {
      final contacts = await _inviteService.getContactsWithPhone();
      setState(() {
        _contacts = contacts;
        _filteredContacts = contacts;
      });
    } catch (e) {
      print('Error loading contacts: $e');
    }
  }

  void _filterContacts(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredContacts = _contacts;
      } else {
        _filteredContacts = _contacts.where((contact) {
          final name = contact.displayName?.toLowerCase() ?? '';
          final phone = contact.phones?.first.value?.toLowerCase() ?? '';
          return name.contains(query.toLowerCase()) || 
                 phone.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (!_hasPermission) {
      return _buildPermissionDeniedView();
    }

    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.all(AppTheme.spacing16),
          child: TextField(
            controller: _searchController,
            onChanged: _filterContacts,
            decoration: InputDecoration(
              hintText: 'Search contacts...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _filterContacts('');
                      },
                    )
                  : null,
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
            ),
          ),
        ),
        
        // Contacts List
        Expanded(
          child: _filteredContacts.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  itemCount: _filteredContacts.length,
                  itemBuilder: (context, index) {
                    final contact = _filteredContacts[index];
                    return _buildContactItem(contact);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildPermissionDeniedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.contacts_outlined,
              size: 64,
              color: AppTheme.textSecondaryColor,
            ),
            const SizedBox(height: AppTheme.spacing16),
            Text(
              'Contacts Permission Required',
              style: AppTheme.titleMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacing8),
            Text(
              'We need access to your contacts to help you invite friends easily.',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacing24),
            ElevatedButton(
              onPressed: _checkPermissionAndLoadContacts,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacing24,
                  vertical: AppTheme.spacing12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                ),
              ),
              child: const Text('Grant Permission'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchQuery.isNotEmpty ? Icons.search_off : Icons.contacts_outlined,
              size: 64,
              color: AppTheme.textSecondaryColor,
            ),
            const SizedBox(height: AppTheme.spacing16),
            Text(
              _searchQuery.isNotEmpty ? 'No contacts found' : 'No contacts available',
              style: AppTheme.titleMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacing8),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Try adjusting your search terms'
                  : 'Make sure you have contacts with phone numbers',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem(Contact contact) {
    final phoneNumber = contact.phones?.isNotEmpty == true 
        ? contact.phones!.first.value 
        : 'No phone number';
    final displayName = contact.displayName ?? 'Unknown';

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing16,
        vertical: AppTheme.spacing4,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
        border: Border.all(
          color: AppTheme.thinBorderColor,
          width: AppTheme.thinBorderWidth,
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
          child: Text(
            displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
            style: AppTheme.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
        title: Text(
          displayName,
          style: AppTheme.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        subtitle: Text(
          phoneNumber ?? 'No phone number',
          style: AppTheme.bodySmall.copyWith(
            color: AppTheme.textSecondaryColor,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => _inviteViaWhatsApp(phoneNumber),
              icon: Icon(
                Icons.message,
                color: AppTheme.primaryColor,
                size: 20,
              ),
            ),
            IconButton(
              onPressed: () => _inviteViaSMS(phoneNumber),
              icon: Icon(
                Icons.sms,
                color: AppTheme.primaryColor,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _inviteViaWhatsApp(String? phoneNumber) async {
    if (phoneNumber == null || phoneNumber.isEmpty) return;
    
    try {
      // Clean phone number (remove spaces, dashes, etc.)
      final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      await _inviteService.shareViaWhatsApp(
        referralCode: 'GEMUSR00112345', // This should come from the parent widget
        phoneNumber: cleanPhone,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error inviting via WhatsApp: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _inviteViaSMS(String? phoneNumber) async {
    if (phoneNumber == null || phoneNumber.isEmpty) return;
    
    try {
      // Clean phone number (remove spaces, dashes, etc.)
      final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      await _inviteService.shareViaSMS(
        referralCode: 'GEMUSR00112345', // This should come from the parent widget
        phoneNumber: cleanPhone,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error inviting via SMS: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
}
