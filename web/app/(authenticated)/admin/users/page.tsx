'use client';

import { useEffect, useState, useCallback, useRef } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import Link from 'next/link';
import { usePermission } from '@/hooks/usePermission';
import { adminApi, UserListItem, UsersResponse } from '@/lib/api/admin';
import { useAuthStore } from '@/store/auth';
import { useToastStore } from '@/store/toast';
import DataTable, { TableColumn } from '@/app/components/DataTable';
import Icon, { faPlus, faEdit, faTrash, faEye, faCheckCircle } from '@/app/components/Icon';

export default function UsersPage() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const { canManageUsers, isAdmin } = usePermission();
  const { currentAccount } = useAuthStore();
  const [loading, setLoading] = useState(true);
  const [users, setUsers] = useState<UserListItem[]>([]);
  const [pagination, setPagination] = useState({ page: 1, limit: 20, total: 0, totalPages: 0 });
  const [search, setSearch] = useState('');
  const [error, setError] = useState('');
  const LIMIT = 20; // Constant limit to avoid dependency issues
  const hasLoadedRef = useRef(false);
  const isLoadingRef = useRef(false);

  const loadUsers = useCallback(async (page: number = 1, searchTerm?: string) => {
    // Prevent concurrent loads
    if (isLoadingRef.current) {
      console.log('Load already in progress, skipping...');
      return;
    }

    try {
      isLoadingRef.current = true;
      setLoading(true);
      setError('');
      const searchValue = searchTerm !== undefined ? searchTerm : search;
      
      console.log('Loading users...', { page, searchValue, accountId: currentAccount?.account_id });
      const response: UsersResponse = await adminApi.getUsers(page, LIMIT, searchValue || undefined, currentAccount?.account_id);
      console.log('Users response:', { code: response?.code, hasData: !!response?.data, usersCount: response?.data?.users?.length });
      
      // Ensure we always set loading to false, even if response structure is unexpected
      if (response && response.code === 200 && response.data) {
        const usersArray = Array.isArray(response.data.users) ? response.data.users : [];
        const paginationData = response.data.pagination || { page: 1, limit: LIMIT, total: 0, totalPages: 0 };
        
        console.log('Setting users:', usersArray.length, 'Setting pagination:', paginationData);
        setUsers(usersArray);
        setPagination(paginationData);
        hasLoadedRef.current = true;
      } else {
        console.error('Invalid response structure:', response);
        setError(response?.message || 'Failed to load users');
        setUsers([]);
        setPagination({ page: 1, limit: LIMIT, total: 0, totalPages: 0 });
      }
    } catch (err: any) {
      console.error('Error loading users:', err);
      const errorMessage = err?.response?.data?.message || err?.message || 'Failed to load users';
      setError(errorMessage);
      setUsers([]);
      setPagination({ page: 1, limit: LIMIT, total: 0, totalPages: 0 });
      useToastStore.getState().error(errorMessage);
    } finally {
      // Always set loading to false, no matter what
      console.log('Setting loading to false');
      isLoadingRef.current = false;
      setLoading(false);
    }
  }, [search, currentAccount?.account_id]);

  // Initial load and permission check - only run once
  useEffect(() => {
    if (!canManageUsers() && !isAdmin()) {
      router.push('/dashboard');
      return;
    }
    
    // Only load if we haven't loaded yet
    if (!hasLoadedRef.current && !isLoadingRef.current) {
      loadUsers(1);
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [canManageUsers, isAdmin, router]);

  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault();
    setPagination(prev => ({ ...prev, page: 1 }));
    loadUsers(1, search);
  };

  const handleDelete = async (userId: string) => {
    if (!confirm('Are you sure you want to delete this user?')) {
      return;
    }

    try {
      await adminApi.deleteUser(userId, currentAccount?.account_id);
      loadUsers(pagination.page);
    } catch (err: any) {
      useToastStore.getState().error(err?.response?.data?.message || 'Failed to delete user');
    }
  };

  const columns: TableColumn<UserListItem>[] = [
    {
      key: 'name',
      label: 'Name',
      sortable: true,
    },
    {
      key: 'email',
      label: 'Email',
      sortable: true,
    },
    {
      key: 'phone',
      label: 'Phone',
      sortable: true,
    },
    {
      key: 'role',
      label: 'Role',
      sortable: true,
      render: (value) => (
        <span className="px-2 py-1 bg-gray-100 text-gray-700 rounded text-xs font-medium capitalize">
          {value || 'N/A'}
        </span>
      ),
    },
    {
      key: 'status',
      label: 'Status',
      sortable: true,
      render: (value) => (
        <span className={`px-2 py-1 rounded text-xs font-medium ${
          value === 'active' 
            ? 'bg-green-100 text-green-700' 
            : 'bg-red-100 text-red-700'
        }`}>
          {value}
        </span>
      ),
    },
    {
      key: 'created_at',
      label: 'Created',
      sortable: true,
      render: (value) => new Date(value).toLocaleDateString(),
    },
    {
      key: 'actions',
      label: 'Actions',
      render: (_, row) => (
        <div className="flex items-center gap-2">
          <Link
            href={`/admin/users/${row.id}`}
            className="p-1.5 text-gray-600 hover:text-[var(--primary)] transition-colors"
            title="View"
          >
            <Icon icon={faEye} size="sm" />
          </Link>
          <Link
            href={`/admin/users/${row.id}/edit`}
            className="p-1.5 text-gray-600 hover:text-[var(--primary)] transition-colors"
            title="Edit"
          >
            <Icon icon={faEdit} size="sm" />
          </Link>
          <button
            onClick={() => handleDelete(row.id)}
            className="p-1.5 text-gray-600 hover:text-red-600 transition-colors"
            title="Delete"
          >
            <Icon icon={faTrash} size="sm" />
          </button>
        </div>
      ),
    },
  ];

  return (
    <div className="space-y-4">
      {/* Page Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Users</h1>
          <p className="text-sm text-gray-600 mt-1">Manage system users</p>
        </div>
        <Link href="/admin/users/new" className="btn btn-primary">
          <Icon icon={faPlus} size="sm" className="mr-2" />
          Add User
        </Link>
      </div>


      {/* Search */}
      <form onSubmit={handleSearch} className="flex gap-2">
        <input
          type="text"
          placeholder="Search users by name, email, or phone..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          className="input flex-1"
        />
        <button type="submit" className="btn btn-primary">
          Search
        </button>
      </form>

      {/* Error Message */}
      {error && (
        <div className="bg-red-50 border border-red-200 rounded-sm p-4">
          <p className="text-sm text-red-600">{error}</p>
        </div>
      )}

      {/* Users Table */}
      <DataTable
        data={users}
        columns={columns}
        loading={loading}
        emptyMessage="No users found"
      />

      {/* Pagination */}
      {pagination.total > 0 && (
        <div className="flex items-center justify-between">
          <div className="text-sm text-gray-600">
            Showing {(pagination.page - 1) * pagination.limit + 1} to{' '}
            {Math.min(pagination.page * pagination.limit, pagination.total)} of{' '}
            {pagination.total} users
          </div>
          {pagination.totalPages > 1 && (
            <div className="flex gap-2">
              <button
                onClick={() => loadUsers(pagination.page - 1)}
                disabled={pagination.page === 1}
                className="btn btn-secondary btn-sm"
              >
                Previous
              </button>
              <button
                onClick={() => loadUsers(pagination.page + 1)}
                disabled={pagination.page >= pagination.totalPages}
                className="btn btn-secondary btn-sm"
              >
                Next
              </button>
            </div>
          )}
        </div>
      )}
    </div>
  );
}
