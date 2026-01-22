'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { usePermission } from '@/hooks/usePermission';
import { accountsApi, Account } from '@/lib/api/accounts';
import { useAuthStore } from '@/store/auth';
import DataTable, { TableColumn } from '@/app/components/DataTable';
import Icon, { faBuilding, faUserShield, faCheckCircle, faArrowsUpDown, faSpinner, faEye } from '@/app/components/Icon';
import Link from 'next/link';

export default function AccountsPage() {
  const router = useRouter();
  const { hasPermission, isAdmin } = usePermission();
  const { setCurrentAccount, setUser } = useAuthStore();
  const [loading, setLoading] = useState(true);
  const [accounts, setAccounts] = useState<Account[]>([]);
  const [error, setError] = useState('');
  const [switching, setSwitching] = useState<string | null>(null);

  useEffect(() => {
    loadAccounts();
  }, []);

  const loadAccounts = async () => {
    try {
      setLoading(true);
      setError('');
      const response = await accountsApi.getUserAccounts();
      if (response.code === 200) {
        setAccounts(response.data.accounts || []);
      } else {
        setError(response.message || 'Failed to load accounts');
      }
    } catch (err: any) {
      setError(err?.response?.data?.message || err?.message || 'Failed to load accounts');
    } finally {
      setLoading(false);
    }
  };

  const handleSwitchAccount = async (accountId: string) => {
    if (switching) return;

    try {
      setSwitching(accountId);
      setError('');
      const response = await accountsApi.switchAccount({ account_id: accountId });

      if (response.code === 200) {
        // Update auth store with new account
        const newAccount = response.data.accounts.find(acc => acc.account_id === accountId);
        if (newAccount) {
          setCurrentAccount({
            account_id: newAccount.account_id,
            account_code: newAccount.account_code,
            account_name: newAccount.account_name,
            account_type: newAccount.account_type,
            account_status: newAccount.account_status,
            role: newAccount.role,
            permissions: newAccount.permissions,
            user_account_status: newAccount.user_account_status,
            access_granted_at: newAccount.access_granted_at,
            is_default: newAccount.is_default,
          });
        }

        // Update accounts list
        setAccounts(response.data.accounts);

        // Reload accounts to update is_default flags
        await loadAccounts();

        // Show success message
        alert('Account switched successfully!');
      } else {
        setError(response.message || 'Failed to switch account');
      }
    } catch (err: any) {
      setError(err?.response?.data?.message || err?.message || 'Failed to switch account. Please try again.');
    } finally {
      setSwitching(null);
    }
  };

  const columns: TableColumn<Account>[] = [
    {
      key: 'account_name',
      label: 'Account Name',
      sortable: true,
      render: (value, row) => (
        <div>
          <div className="font-medium text-gray-900">{value}</div>
          <div className="text-xs text-gray-500">{row.account_code}</div>
        </div>
      ),
    },
    {
      key: 'account_type',
      label: 'Type',
      sortable: true,
      render: (value) => (
        <span className="capitalize text-gray-900">{String(value)}</span>
      ),
    },
    {
      key: 'role',
      label: 'Role',
      sortable: true,
      render: (value) => (
        <div className="flex items-center">
          <Icon icon={faUserShield} size="sm" className="mr-2 text-gray-400" />
          <span className="capitalize text-gray-900">{String(value) || 'N/A'}</span>
        </div>
      ),
    },
    {
      key: 'account_status',
      label: 'Status',
      sortable: true,
      render: (value) => (
        <span className={`px-2 py-1 rounded text-xs font-medium ${
          value === 'active' 
            ? 'bg-green-100 text-green-700' 
            : 'bg-gray-100 text-gray-700'
        }`}>
          {String(value)}
        </span>
      ),
    },
    {
      key: 'is_default',
      label: 'Default',
      sortable: true,
      render: (value) => value ? (
        <div className="flex items-center text-green-600">
          <Icon icon={faCheckCircle} size="sm" className="mr-1" />
          <span className="text-xs font-medium">Default</span>
        </div>
      ) : null,
    },
    {
      key: 'actions',
      label: 'Actions',
      render: (_, row) => (
        <div className="flex items-center gap-2">
          {!row.is_default && (
            <button
              onClick={() => handleSwitchAccount(row.account_id)}
              disabled={switching === row.account_id}
              className="p-1.5 text-gray-600 hover:text-[var(--primary)] transition-colors disabled:opacity-50"
              title="Switch to this account"
            >
              {switching === row.account_id ? (
                <Icon icon={faSpinner} size="sm" spin />
              ) : (
                <Icon icon={faArrowsUpDown} size="sm" />
              )}
            </button>
          )}
          <Link
            href={`/accounts/${row.account_id}`}
            className="p-1.5 text-gray-600 hover:text-[var(--primary)] transition-colors"
            title="View Details"
          >
            <Icon icon={faEye} size="sm" />
          </Link>
        </div>
      ),
    },
  ];

  return (
    <div className="space-y-4">
      {/* Page Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Accounts</h1>
          <p className="text-sm text-gray-600 mt-1">Manage your accounts and switch between them</p>
        </div>
      </div>

      {/* Error Message */}
      {error && (
        <div className="bg-red-50 border border-red-200 rounded-sm p-4">
          <p className="text-sm text-red-600">{error}</p>
        </div>
      )}

      {/* Accounts Table */}
      <DataTable
        data={accounts}
        columns={columns}
        loading={loading}
        emptyMessage="No accounts found"
      />

      {/* Summary */}
      {accounts.length > 0 && (
        <div className="bg-white border border-gray-200 rounded-sm p-4">
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div>
              <p className="text-sm text-gray-600">Total Accounts</p>
              <p className="text-lg font-semibold text-gray-900">{accounts.length}</p>
            </div>
            <div>
              <p className="text-sm text-gray-600">Default Account</p>
              <p className="text-lg font-semibold text-gray-900">
                {accounts.find(acc => acc.is_default)?.account_name || 'None'}
              </p>
            </div>
            <div>
              <p className="text-sm text-gray-600">Active Accounts</p>
              <p className="text-lg font-semibold text-gray-900">
                {accounts.filter(acc => acc.account_status === 'active').length}
              </p>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
