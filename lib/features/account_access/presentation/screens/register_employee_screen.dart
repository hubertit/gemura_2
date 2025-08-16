import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/custom_app_bar.dart';
import '../providers/account_access_provider.dart';
import '../../../../shared/models/account_access.dart';

class RegisterEmployeeScreen extends ConsumerStatefulWidget {
  final String accountId;
  final String accountName;

  const RegisterEmployeeScreen({
    super.key,
    required this.accountId,
    required this.accountName,
  });

  @override
  ConsumerState<RegisterEmployeeScreen> createState() => _RegisterEmployeeScreenState();
}

class _RegisterEmployeeScreenState extends ConsumerState<RegisterEmployeeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nidController = TextEditingController();
  
  String _selectedRole = AccountAccess.roleViewer;
  final Map<String, bool> _permissions = {
    'view_sales': false,
    'create_sales': false,
    'manage_suppliers': false,
    'view_reports': false,
    'manage_users': false,
    'view_all_data': false,
    'manage_accounts': false,
  };

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _nidController.dispose();
    super.dispose();
  }

  List<String> _getSelectedPermissions() {
    return _permissions.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Add Employee',
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacing16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Personal Information Section
              _buildSectionHeader('Personal Information', Icons.person),
              const SizedBox(height: AppTheme.spacing16),
              
              // Name Field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter employee name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.spacing16),
              
              // Email Field
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter email address';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.spacing16),
              
              // Phone Field
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.spacing16),
              
              // NID Field
              TextFormField(
                controller: _nidController,
                decoration: const InputDecoration(
                  labelText: 'National ID',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.badge),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter national ID';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.spacing24),
              
              // Role and Permissions Section
              _buildSectionHeader('Role & Permissions', Icons.security),
              const SizedBox(height: AppTheme.spacing16),
              
              // Role Selection
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.work),
                ),
                items: [
                  DropdownMenuItem(
                    value: AccountAccess.roleViewer,
                    child: Text(
                      'Viewer - Read only access',
                      style: AppTheme.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'umucunda',
                    child: Text(
                      'Umucunda - Collect milk from sources',
                      style: AppTheme.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  DropdownMenuItem(
                    value: AccountAccess.roleAgent,
                    child: Text(
                      'Agent - Collect & sell milk',
                      style: AppTheme.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  DropdownMenuItem(
                    value: AccountAccess.roleManager,
                    child: Text(
                      'Manager - Can edit data',
                      style: AppTheme.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  DropdownMenuItem(
                    value: AccountAccess.roleAdmin,
                    child: Text(
                      'Admin - Full access',
                      style: AppTheme.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedRole = value!;
                    // Auto-select permissions based on role
                    _updatePermissionsForRole(value);
                  });
                },
              ),
              const SizedBox(height: AppTheme.spacing16),
              
              // Permissions Section
              Text(
                'Permissions',
                style: AppTheme.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppTheme.spacing8),
              
              // Permission Checkboxes
              _buildPermissionCheckbox('View Sales', 'view_sales', Icons.visibility),
              _buildPermissionCheckbox('Create Sales', 'create_sales', Icons.add_shopping_cart),
              _buildPermissionCheckbox('Manage Suppliers', 'manage_suppliers', Icons.people),
              _buildPermissionCheckbox('View Reports', 'view_reports', Icons.analytics),
              _buildPermissionCheckbox('Manage Users', 'manage_users', Icons.manage_accounts),
              _buildPermissionCheckbox('View All Data', 'view_all_data', Icons.data_usage),
              _buildPermissionCheckbox('Manage Accounts', 'manage_accounts', Icons.account_balance),
              
              const SizedBox(height: AppTheme.spacing32),
              
              // Register Button
              PrimaryButton(
                label: 'Add Employee',
                onPressed: _registerEmployee,
              ),
              const SizedBox(height: AppTheme.spacing16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 24),
        const SizedBox(width: AppTheme.spacing8),
        Text(
          title,
          style: AppTheme.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionCheckbox(String label, String permission, IconData icon) {
    return CheckboxListTile(
      title: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.textSecondaryColor),
          const SizedBox(width: AppTheme.spacing8),
          Expanded(
            child: Text(
              label,
              style: AppTheme.bodyMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      value: _permissions[permission],
      onChanged: (value) {
        setState(() {
          _permissions[permission] = value ?? false;
        });
      },
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
    );
  }

  void _updatePermissionsForRole(String role) {
    setState(() {
      // Reset all permissions
      _permissions.forEach((key, value) {
        _permissions[key] = false;
      });
      
      // Set permissions based on role
      switch (role) {
        case AccountAccess.roleViewer:
          _permissions['view_sales'] = true;
          _permissions['view_reports'] = true;
          break;
        case 'umucunda':
          _permissions['view_sales'] = true;
          _permissions['create_sales'] = true;
          _permissions['manage_suppliers'] = true;
          _permissions['view_reports'] = true;
          break;
        case AccountAccess.roleAgent:
          _permissions['view_sales'] = true;
          _permissions['create_sales'] = true;
          _permissions['view_reports'] = true;
          break;
        case AccountAccess.roleManager:
          _permissions['view_sales'] = true;
          _permissions['create_sales'] = true;
          _permissions['manage_suppliers'] = true;
          _permissions['view_reports'] = true;
          _permissions['manage_users'] = true;
          _permissions['view_all_data'] = true;
          break;
        case AccountAccess.roleAdmin:
          _permissions['view_sales'] = true;
          _permissions['create_sales'] = true;
          _permissions['manage_suppliers'] = true;
          _permissions['view_reports'] = true;
          _permissions['manage_users'] = true;
          _permissions['view_all_data'] = true;
          _permissions['manage_accounts'] = true;
          break;
      }
    });
  }

  Future<void> _registerEmployee() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final selectedPermissions = _getSelectedPermissions();
    if (selectedPermissions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one permission')),
      );
      return;
    }

    final success = await ref.read(accountAccessProvider.notifier).registerEmployee(
      userData: {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'nid': _nidController.text.trim(),
      },
      accountAccess: {
        'account_id': int.parse(widget.accountId),
        'role': _selectedRole,
        'permissions': selectedPermissions,
        'set_as_default': false,
      },
    );

    if (success && mounted) {
      Navigator.of(context).pop();
      ref.invalidate(accountUsersProvider(widget.accountId));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Employee registered successfully!')),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to register employee. Please try again.')),
      );
    }
  }
}
