import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/custom_app_bar.dart';
import '../providers/account_access_provider.dart';
import '../../../../shared/models/account_access.dart';
import '../../../../shared/models/user.dart';

class ManageAccountAccessScreen extends ConsumerStatefulWidget {
  final String accountId;
  final String accountName;

  const ManageAccountAccessScreen({
    super.key,
    required this.accountId,
    required this.accountName,
  });

  @override
  ConsumerState<ManageAccountAccessScreen> createState() => _ManageAccountAccessScreenState();
}

class _ManageAccountAccessScreenState extends ConsumerState<ManageAccountAccessScreen> {
  @override
  Widget build(BuildContext context) {
    final accountUsersAsync = ref.watch(accountUsersProvider(widget.accountId));

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Manage Access',
        subtitle: widget.accountName,
      ),
      body: accountUsersAsync.when(
        data: (users) => _buildUsersList(users),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: $error', style: AppTheme.bodyMedium),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showGrantAccessBottomSheet(),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }

  Widget _buildUsersList(List<User> users) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return Card(
          margin: const EdgeInsets.only(bottom: AppTheme.spacing12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              child: Text(
                user.name.substring(0, 1).toUpperCase(),
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(user.name, style: AppTheme.bodyMedium),
            subtitle: Text(user.email, style: AppTheme.bodySmall),
            trailing: PopupMenuButton<String>(
              onSelected: (value) => _handleUserAction(value, user),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 16),
                      SizedBox(width: 8),
                      Text('Edit Access'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'revoke',
                  child: Row(
                    children: [
                      Icon(Icons.remove_circle, size: 16, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Revoke Access', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleUserAction(String action, User user) {
    switch (action) {
      case 'edit':
        _showEditAccessBottomSheet(user);
        break;
      case 'revoke':
        _showRevokeAccessBottomSheet(user);
        break;
    }
  }

  void _showGrantAccessBottomSheet() {
    final emailController = TextEditingController();
    String selectedRole = AccountAccess.roleViewer;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + AppTheme.spacing16,
          left: AppTheme.spacing16,
          right: AppTheme.spacing16,
          top: AppTheme.spacing16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppTheme.spacing16),
            Text(
              'Grant Access',
              style: AppTheme.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacing24),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'User Email',
                hintText: 'Enter user email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: AppTheme.spacing16),
            DropdownButtonFormField<String>(
              value: selectedRole,
              decoration: const InputDecoration(
                labelText: 'Role',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.security),
              ),
              items: [
                DropdownMenuItem(
                  value: AccountAccess.roleViewer,
                  child: const Text('Viewer - Read only access'),
                ),
                DropdownMenuItem(
                  value: AccountAccess.roleAgent,
                  child: const Text('Agent - Collect & sell milk'),
                ),
                DropdownMenuItem(
                  value: AccountAccess.roleManager,
                  child: const Text('Manager - Can edit data'),
                ),
                DropdownMenuItem(
                  value: AccountAccess.roleAdmin,
                  child: const Text('Admin - Full access'),
                ),
              ],
              onChanged: (value) => selectedRole = value!,
            ),
            const SizedBox(height: AppTheme.spacing24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: AppTheme.spacing12),
                Expanded(
                  child: PrimaryButton(
                    label: 'Grant Access',
                    onPressed: () async {
                      final success = await ref.read(accountAccessProvider.notifier).grantAccess(
                        accountId: widget.accountId,
                        targetUserId: emailController.text,
                        role: selectedRole,
                        permissions: _getPermissionsForRole(selectedRole),
                      );
                      
                      if (success && mounted) {
                        Navigator.of(context).pop();
                        ref.invalidate(accountUsersProvider(widget.accountId));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Access granted successfully!')),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacing16),
          ],
        ),
      ),
    );
  }

  void _showEditAccessBottomSheet(User user) {
    String selectedRole = AccountAccess.roleViewer;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + AppTheme.spacing16,
          left: AppTheme.spacing16,
          right: AppTheme.spacing16,
          top: AppTheme.spacing16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppTheme.spacing16),
            Text(
              'Edit ${user.name}\'s Access',
              style: AppTheme.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacing24),
            DropdownButtonFormField<String>(
              value: selectedRole,
              decoration: const InputDecoration(
                labelText: 'Role',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.security),
              ),
              items: [
                DropdownMenuItem(
                  value: AccountAccess.roleViewer,
                  child: const Text('Viewer - Read only access'),
                ),
                DropdownMenuItem(
                  value: AccountAccess.roleAgent,
                  child: const Text('Agent - Collect & sell milk'),
                ),
                DropdownMenuItem(
                  value: AccountAccess.roleManager,
                  child: const Text('Manager - Can edit data'),
                ),
                DropdownMenuItem(
                  value: AccountAccess.roleAdmin,
                  child: const Text('Admin - Full access'),
                ),
              ],
              onChanged: (value) => selectedRole = value!,
            ),
            const SizedBox(height: AppTheme.spacing24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: AppTheme.spacing12),
                Expanded(
                  child: PrimaryButton(
                    label: 'Update',
                    onPressed: () async {
                      final success = await ref.read(accountAccessProvider.notifier).updateAccess(
                        accessId: 'mock_access_id',
                        role: selectedRole,
                        permissions: _getPermissionsForRole(selectedRole),
                      );
                      
                      if (success && mounted) {
                        Navigator.of(context).pop();
                        ref.invalidate(accountUsersProvider(widget.accountId));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Access updated successfully!')),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacing16),
          ],
        ),
      ),
    );
  }

  void _showRevokeAccessBottomSheet(User user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppTheme.spacing16),
            Icon(
              Icons.warning_amber_rounded,
              size: 48,
              color: Colors.orange[600],
            ),
            const SizedBox(height: AppTheme.spacing16),
            Text(
              'Revoke Access',
              style: AppTheme.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacing12),
            Text(
              'Are you sure you want to revoke ${user.name}\'s access?',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacing24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: AppTheme.spacing12),
                Expanded(
                  child: PrimaryButton(
                    label: 'Revoke',
                    onPressed: () async {
                      final success = await ref.read(accountAccessProvider.notifier).revokeAccess('mock_access_id');
                      
                      if (success && mounted) {
                        Navigator.of(context).pop();
                        ref.invalidate(accountUsersProvider(widget.accountId));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Access revoked successfully!')),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacing16),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _getPermissionsForRole(String role) {
    switch (role) {
      case AccountAccess.roleAdmin:
        return {
          'view': true,
          'edit': true,
          'delete': true,
          'share': true,
          'manage_users': true,
        };
      case AccountAccess.roleManager:
        return {
          'view': true,
          'edit': true,
          'delete': false,
          'share': false,
          'manage_users': false,
        };
      case AccountAccess.roleAgent:
        return {
          'view': true,
          'edit': true,
          'delete': false,
          'share': false,
          'manage_users': false,
          'collect_milk': true,
          'record_sales': true,
        };
      case AccountAccess.roleViewer:
      default:
        return {
          'view': true,
          'edit': false,
          'delete': false,
          'share': false,
          'manage_users': false,
        };
    }
  }
}
