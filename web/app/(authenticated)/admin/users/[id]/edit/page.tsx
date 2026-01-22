'use client';

import { useState, useEffect } from 'react';
import { useRouter, useParams } from 'next/navigation';
import Link from 'next/link';
import { usePermission } from '@/hooks/usePermission';
import { adminApi, UpdateUserData } from '@/lib/api/admin';
import { useAuthStore } from '@/store/auth';
import Icon, { faUser, faEnvelope, faPhone, faLock, faBuilding, faUserShield, faCheckCircle, faTimes, faSpinner } from '@/app/components/Icon';

// Available roles and account types
const ROLES = [
  { value: 'owner', label: 'Owner' },
  { value: 'admin', label: 'Admin' },
  { value: 'manager', label: 'Manager' },
  { value: 'collector', label: 'Collector' },
  { value: 'supplier', label: 'Supplier' },
  { value: 'customer', label: 'Customer' },
  { value: 'agent', label: 'Agent' },
  { value: 'viewer', label: 'Viewer' },
];

const ACCOUNT_TYPES = [
  { value: 'mcc', label: 'MCC' },
  { value: 'agent', label: 'Agent' },
  { value: 'collector', label: 'Collector' },
  { value: 'veterinarian', label: 'Veterinarian' },
  { value: 'supplier', label: 'Supplier' },
  { value: 'customer', label: 'Customer' },
  { value: 'farmer', label: 'Farmer' },
  { value: 'owner', label: 'Owner' },
];

const STATUS_OPTIONS = [
  { value: 'active', label: 'Active' },
  { value: 'inactive', label: 'Inactive' },
];

// Common permissions
const PERMISSIONS = [
  { key: 'manage_users', label: 'Manage Users' },
  { key: 'view_sales', label: 'View Sales' },
  { key: 'create_sales', label: 'Create Sales' },
  { key: 'update_sales', label: 'Update Sales' },
  { key: 'delete_sales', label: 'Delete Sales' },
  { key: 'view_collections', label: 'View Collections' },
  { key: 'create_collections', label: 'Create Collections' },
  { key: 'view_suppliers', label: 'View Suppliers' },
  { key: 'create_suppliers', label: 'Create Suppliers' },
  { key: 'view_customers', label: 'View Customers' },
  { key: 'create_customers', label: 'Create Customers' },
  { key: 'view_inventory', label: 'View Inventory' },
  { key: 'manage_inventory', label: 'Manage Inventory' },
  { key: 'view_reports', label: 'View Reports' },
  { key: 'dashboard.view', label: 'View Dashboard' },
  { key: 'can_collect', label: 'Can Collect' },
  { key: 'can_add_supplier', label: 'Can Add Supplier' },
];

export default function EditUserPage() {
  const router = useRouter();
  const params = useParams();
  const userId = params.id as string;
  const { canManageUsers, isAdmin } = usePermission();
  const { currentAccount } = useAuthStore();
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [formData, setFormData] = useState<UpdateUserData & { confirmPassword: string }>({
    name: '',
    email: '',
    phone: '',
    password: '',
    confirmPassword: '',
    account_type: 'mcc',
    status: 'active',
    role: 'viewer',
    permissions: {},
  });

  // Check permission on mount
  useEffect(() => {
    if (!canManageUsers() && !isAdmin()) {
      router.push('/admin/users');
      return;
    }
    loadUser();
  }, [userId, canManageUsers, isAdmin, router]);

  const loadUser = async () => {
    try {
      setLoading(true);
      setError('');
      const response = await adminApi.getUserById(userId, currentAccount?.account_id);

      if (response.code === 200 && response.data) {
        const user = response.data;
        
        // Parse permissions if it's a string
        let permissions = user.permissions || {};
        if (typeof permissions === 'string') {
          try {
            permissions = JSON.parse(permissions);
          } catch {
            permissions = {};
          }
        }

        setFormData({
          name: user.name || '',
          email: user.email || '',
          phone: user.phone || '',
          password: '',
          confirmPassword: '',
          account_type: user.account_type || 'mcc',
          status: user.status || 'active',
          role: user.role || 'viewer',
          permissions: permissions || {},
        });
      } else {
        setError('Failed to load user data');
      }
    } catch (err: any) {
      setError(err?.response?.data?.message || err?.message || 'Failed to load user. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: value,
    }));
    setError('');
  };

  const handlePermissionToggle = (permissionKey: string) => {
    setFormData(prev => ({
      ...prev,
      permissions: {
        ...prev.permissions,
        [permissionKey]: !prev.permissions?.[permissionKey],
      },
    }));
  };

  const validateForm = (): boolean => {
    if (!formData.name?.trim()) {
      setError('Name is required');
      return false;
    }

    if (formData.email && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(formData.email)) {
      setError('Invalid email format');
      return false;
    }

    // Password is optional for update, but if provided, must be valid
    if (formData.password) {
      if (formData.password.length < 6) {
        setError('Password must be at least 6 characters');
        return false;
      }

      if (formData.password !== formData.confirmPassword) {
        setError('Passwords do not match');
        return false;
      }
    }

    return true;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');

    if (!validateForm()) {
      return;
    }

    setSaving(true);

    try {
      // Remove password fields if password is empty
      const updateData: UpdateUserData = { ...formData };
      if (!updateData.password) {
        delete updateData.password;
      }
      delete (updateData as any).confirmPassword;

      const response = await adminApi.updateUser(userId, updateData, currentAccount?.account_id);

      if (response.code === 200) {
        router.push(`/admin/users/${userId}?updated=true`);
      } else {
        setError(response.message || 'Failed to update user');
      }
    } catch (err: any) {
      setError(err?.response?.data?.message || err?.message || 'Failed to update user. Please try again.');
    } finally {
      setSaving(false);
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-[400px]">
        <div className="text-center">
          <Icon icon={faSpinner} size="lg" spin className="text-[var(--primary)] mb-4" />
          <p className="text-gray-600">Loading user data...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-4">
      {/* Page Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Edit User</h1>
          <p className="text-sm text-gray-600 mt-1">Update user information and permissions</p>
        </div>
        <Link href={`/admin/users/${userId}`} className="btn btn-secondary">
          <Icon icon={faTimes} size="sm" className="mr-2" />
          Cancel
        </Link>
      </div>

      {/* Error Message */}
      {error && (
        <div className="bg-red-50 border border-red-200 rounded-sm p-4">
          <p className="text-sm text-red-600">{error}</p>
        </div>
      )}

      {/* Form */}
      <form onSubmit={handleSubmit} className="bg-white border border-gray-200 rounded-sm p-6 space-y-6">
        {/* Basic Information */}
        <div>
          <h2 className="text-lg font-semibold text-gray-900 mb-4">Basic Information</h2>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {/* Name */}
            <div>
              <label htmlFor="name" className="block text-sm font-medium text-gray-700 mb-2">
                Full Name <span className="text-red-500">*</span>
              </label>
              <div className="relative">
                <div className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 z-10">
                  <Icon icon={faUser} size="sm" />
                </div>
                <input
                  id="name"
                  name="name"
                  type="text"
                  required
                  value={formData.name}
                  onChange={handleChange}
                  className="input pl-11 w-full"
                  placeholder="Enter full name"
                  disabled={saving}
                />
              </div>
            </div>

            {/* Email */}
            <div>
              <label htmlFor="email" className="block text-sm font-medium text-gray-700 mb-2">
                Email Address
              </label>
              <div className="relative">
                <div className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 z-10">
                  <Icon icon={faEnvelope} size="sm" />
                </div>
                <input
                  id="email"
                  name="email"
                  type="email"
                  value={formData.email}
                  onChange={handleChange}
                  className="input pl-11 w-full"
                  placeholder="Enter email address"
                  disabled={saving}
                />
              </div>
            </div>

            {/* Phone */}
            <div>
              <label htmlFor="phone" className="block text-sm font-medium text-gray-700 mb-2">
                Phone Number
              </label>
              <div className="relative">
                <div className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 z-10">
                  <Icon icon={faPhone} size="sm" />
                </div>
                <input
                  id="phone"
                  name="phone"
                  type="tel"
                  value={formData.phone}
                  onChange={handleChange}
                  className="input pl-11 w-full"
                  placeholder="250788123456"
                  disabled={saving}
                />
              </div>
            </div>
          </div>
        </div>

        {/* Password (Optional for update) */}
        <div>
          <h2 className="text-lg font-semibold text-gray-900 mb-4">Change Password (Optional)</h2>
          <p className="text-sm text-gray-600 mb-4">Leave blank to keep current password</p>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {/* Password */}
            <div>
              <label htmlFor="password" className="block text-sm font-medium text-gray-700 mb-2">
                New Password
              </label>
              <div className="relative">
                <div className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 z-10">
                  <Icon icon={faLock} size="sm" />
                </div>
                <input
                  id="password"
                  name="password"
                  type={showPassword ? 'text' : 'password'}
                  value={formData.password}
                  onChange={handleChange}
                  className="input pl-11 w-full"
                  placeholder="Enter new password (min 6 characters)"
                  disabled={saving}
                  minLength={6}
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  className="absolute right-3 top-1/2 transform -translate-y-1/2 text-gray-400 hover:text-gray-600"
                >
                  <Icon icon={showPassword ? faTimes : faLock} size="sm" />
                </button>
              </div>
            </div>

            {/* Confirm Password */}
            <div>
              <label htmlFor="confirmPassword" className="block text-sm font-medium text-gray-700 mb-2">
                Confirm New Password
              </label>
              <div className="relative">
                <div className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 z-10">
                  <Icon icon={faLock} size="sm" />
                </div>
                <input
                  id="confirmPassword"
                  name="confirmPassword"
                  type={showPassword ? 'text' : 'password'}
                  value={formData.confirmPassword}
                  onChange={handleChange}
                  className="input pl-11 w-full"
                  placeholder="Confirm new password"
                  disabled={saving}
                />
              </div>
            </div>
          </div>
        </div>

        {/* Account Settings */}
        <div>
          <h2 className="text-lg font-semibold text-gray-900 mb-4">Account Settings</h2>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            {/* Account Type */}
            <div>
              <label htmlFor="account_type" className="block text-sm font-medium text-gray-700 mb-2">
                <Icon icon={faBuilding} size="sm" className="inline mr-2" />
                Account Type
              </label>
              <select
                id="account_type"
                name="account_type"
                value={formData.account_type}
                onChange={handleChange}
                className="input w-full"
                disabled={saving}
              >
                {ACCOUNT_TYPES.map(type => (
                  <option key={type.value} value={type.value}>
                    {type.label}
                  </option>
                ))}
              </select>
            </div>

            {/* Role */}
            <div>
              <label htmlFor="role" className="block text-sm font-medium text-gray-700 mb-2">
                <Icon icon={faUserShield} size="sm" className="inline mr-2" />
                Role
              </label>
              <select
                id="role"
                name="role"
                value={formData.role}
                onChange={handleChange}
                className="input w-full"
                disabled={saving}
              >
                {ROLES.map(role => (
                  <option key={role.value} value={role.value}>
                    {role.label}
                  </option>
                ))}
              </select>
            </div>

            {/* Status */}
            <div>
              <label htmlFor="status" className="block text-sm font-medium text-gray-700 mb-2">
                Status
              </label>
              <select
                id="status"
                name="status"
                value={formData.status}
                onChange={handleChange}
                className="input w-full"
                disabled={saving}
              >
                {STATUS_OPTIONS.map(status => (
                  <option key={status.value} value={status.value}>
                    {status.label}
                  </option>
                ))}
              </select>
            </div>
          </div>
        </div>

        {/* Permissions */}
        <div>
          <h2 className="text-lg font-semibold text-gray-900 mb-4">Permissions</h2>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-3">
            {PERMISSIONS.map(permission => (
              <label
                key={permission.key}
                className="flex items-center p-3 border border-gray-200 rounded-sm hover:bg-gray-50 cursor-pointer"
              >
                <input
                  type="checkbox"
                  checked={formData.permissions?.[permission.key] || false}
                  onChange={() => handlePermissionToggle(permission.key)}
                  className="mr-3 h-4 w-4 text-[var(--primary)] focus:ring-[var(--primary)] border-gray-300 rounded"
                  disabled={saving}
                />
                <span className="text-sm text-gray-700">{permission.label}</span>
              </label>
            ))}
          </div>
        </div>

        {/* Form Actions */}
        <div className="flex items-center justify-end gap-3 pt-4 border-t border-gray-200">
          <Link href={`/admin/users/${userId}`} className="btn btn-secondary" tabIndex={-1}>
            Cancel
          </Link>
          <button type="submit" className="btn btn-primary" disabled={saving}>
            {saving ? (
              <>
                <Icon icon={faSpinner} size="sm" spin className="mr-2" />
                Saving...
              </>
            ) : (
              <>
                <Icon icon={faCheckCircle} size="sm" className="mr-2" />
                Update User
              </>
            )}
          </button>
        </div>
      </form>
    </div>
  );
}
