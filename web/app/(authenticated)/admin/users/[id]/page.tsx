'use client';

import { useState, useEffect } from 'react';
import { useRouter, useParams, useSearchParams } from 'next/navigation';
import Link from 'next/link';
import { usePermission } from '@/hooks/usePermission';
import { adminApi } from '@/lib/api/admin';
import { useAuthStore } from '@/store/auth';
import Icon, { faUser, faEnvelope, faPhone, faBuilding, faUserShield, faEdit, faArrowLeft, faSpinner, faCheckCircle, faCalendar } from '@/app/components/Icon';

export default function UserDetailsPage() {
  const router = useRouter();
  const params = useParams();
  const searchParams = useSearchParams();
  const userId = params.id as string;
  const { canManageUsers, isAdmin } = usePermission();
  const { currentAccount } = useAuthStore();
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [user, setUser] = useState<any>(null);

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
        setUser(response.data);
      } else {
        setError('Failed to load user data');
      }
    } catch (err: any) {
      setError(err?.response?.data?.message || err?.message || 'Failed to load user. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  // Parse permissions
  const getPermissions = () => {
    if (!user?.permissions) return [];
    
    let permissions = user.permissions;
    if (typeof permissions === 'string') {
      try {
        permissions = JSON.parse(permissions);
      } catch {
        return [];
      }
    }

    if (Array.isArray(permissions)) {
      return permissions;
    }

    if (typeof permissions === 'object') {
      return Object.keys(permissions).filter(key => permissions[key] === true);
    }

    return [];
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

  if (error && !user) {
    return (
      <div className="space-y-4">
        <div className="bg-red-50 border border-red-200 rounded-sm p-4">
          <p className="text-sm text-red-600">{error}</p>
        </div>
        <Link href="/admin/users" className="btn btn-secondary">
          <Icon icon={faArrowLeft} size="sm" className="mr-2" />
          Back to Users
        </Link>
      </div>
    );
  }

  const permissions = getPermissions();

  return (
    <div className="space-y-4">

      {/* Page Header */}
      <div className="flex items-center justify-between">
        <div>
          <Link href="/admin/users" className="text-sm text-gray-600 hover:text-[var(--primary)] mb-2 inline-flex items-center">
            <Icon icon={faArrowLeft} size="sm" className="mr-2" />
            Back to Users
          </Link>
          <h1 className="text-2xl font-bold text-gray-900">{user?.name || 'User Details'}</h1>
          <p className="text-sm text-gray-600 mt-1">View user information and permissions</p>
        </div>
        <Link href={`/admin/users/${userId}/edit`} className="btn btn-primary">
          <Icon icon={faEdit} size="sm" className="mr-2" />
          Edit User
        </Link>
      </div>

      {/* Error Message */}
      {error && (
        <div className="bg-red-50 border border-red-200 rounded-sm p-4">
          <p className="text-sm text-red-600">{error}</p>
        </div>
      )}

      {user && (
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
          {/* Main Information */}
          <div className="lg:col-span-2 space-y-4">
            {/* Basic Information */}
            <div className="bg-white border border-gray-200 rounded-sm p-6">
              <h2 className="text-lg font-semibold text-gray-900 mb-4">Basic Information</h2>
              <div className="space-y-4">
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-500 mb-1">Full Name</label>
                    <div className="flex items-center text-gray-900">
                      <Icon icon={faUser} size="sm" className="mr-2 text-gray-400" />
                      <span>{user.name || 'N/A'}</span>
                    </div>
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-500 mb-1">Email Address</label>
                    <div className="flex items-center text-gray-900">
                      <Icon icon={faEnvelope} size="sm" className="mr-2 text-gray-400" />
                      <span>{user.email || 'N/A'}</span>
                    </div>
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-500 mb-1">Phone Number</label>
                    <div className="flex items-center text-gray-900">
                      <Icon icon={faPhone} size="sm" className="mr-2 text-gray-400" />
                      <span>{user.phone || 'N/A'}</span>
                    </div>
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-500 mb-1">Status</label>
                    <span className={`inline-flex px-2 py-1 text-xs font-medium rounded-full ${
                      user.status === 'active' 
                        ? 'bg-green-100 text-green-700' 
                        : 'bg-red-100 text-red-700'
                    }`}>
                      {user.status || 'N/A'}
                    </span>
                  </div>
                </div>
              </div>
            </div>

            {/* Account Settings */}
            <div className="bg-white border border-gray-200 rounded-sm p-6">
              <h2 className="text-lg font-semibold text-gray-900 mb-4">Account Settings</h2>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-500 mb-1">Account Type</label>
                  <div className="flex items-center text-gray-900">
                    <Icon icon={faBuilding} size="sm" className="mr-2 text-gray-400" />
                    <span className="capitalize">{user.account_type || 'N/A'}</span>
                  </div>
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-500 mb-1">Role</label>
                  <div className="flex items-center text-gray-900">
                    <Icon icon={faUserShield} size="sm" className="mr-2 text-gray-400" />
                    <span className="capitalize">{user.role || 'N/A'}</span>
                  </div>
                </div>
              </div>
            </div>

            {/* Permissions */}
            <div className="bg-white border border-gray-200 rounded-sm p-6">
              <h2 className="text-lg font-semibold text-gray-900 mb-4">Permissions</h2>
              {permissions.length > 0 ? (
                <div className="flex flex-wrap gap-2">
                  {permissions.map((permission: string) => (
                    <span
                      key={permission}
                      className="inline-flex px-3 py-1 text-xs font-medium bg-blue-100 text-blue-700 rounded-full"
                    >
                      {permission.replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase())}
                    </span>
                  ))}
                </div>
              ) : (
                <p className="text-sm text-gray-500">No specific permissions assigned</p>
              )}
            </div>
          </div>

          {/* Sidebar */}
          <div className="space-y-4">
            {/* Account Information */}
            <div className="bg-white border border-gray-200 rounded-sm p-6">
              <h2 className="text-lg font-semibold text-gray-900 mb-4">Account Information</h2>
              <div className="space-y-3">
                <div>
                  <label className="block text-sm font-medium text-gray-500 mb-1">User ID</label>
                  <p className="text-sm text-gray-900 font-mono">{user.id}</p>
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-500 mb-1">Created At</label>
                  <div className="flex items-center text-sm text-gray-900">
                    <Icon icon={faCalendar} size="sm" className="mr-2 text-gray-400" />
                    <span>{user.created_at ? new Date(user.created_at).toLocaleString() : 'N/A'}</span>
                  </div>
                </div>

                {user.last_login && (
                  <div>
                    <label className="block text-sm font-medium text-gray-500 mb-1">Last Login</label>
                    <div className="flex items-center text-sm text-gray-900">
                      <Icon icon={faCalendar} size="sm" className="mr-2 text-gray-400" />
                      <span>{new Date(user.last_login).toLocaleString()}</span>
                    </div>
                  </div>
                )}
              </div>
            </div>

            {/* Quick Actions */}
            <div className="bg-white border border-gray-200 rounded-sm p-6">
              <h2 className="text-lg font-semibold text-gray-900 mb-4">Quick Actions</h2>
              <div className="space-y-2">
                <Link href={`/admin/users/${userId}/edit`} className="btn btn-primary w-full justify-center">
                  <Icon icon={faEdit} size="sm" className="mr-2" />
                  Edit User
                </Link>
                <Link href="/admin/users" className="btn btn-secondary w-full justify-center">
                  <Icon icon={faArrowLeft} size="sm" className="mr-2" />
                  Back to List
                </Link>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
