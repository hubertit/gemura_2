'use client';

import { useState, useEffect } from 'react';
import { loansApi, CreateLoanData } from '@/lib/api/loans';
import { suppliersApi, Supplier } from '@/lib/api/suppliers';
import { customersApi, Customer } from '@/lib/api/customers';
import { useAuthStore } from '@/store/auth';
import { useToastStore } from '@/store/toast';
import Icon, { faCheckCircle, faSpinner } from '@/app/components/Icon';
import SearchableSelect, { SearchableSelectOption } from '@/app/components/SearchableSelect';

interface CreateLoanFormProps {
  onSuccess: () => void;
  onCancel: () => void;
}

export default function CreateLoanForm({ onSuccess, onCancel }: CreateLoanFormProps) {
  const { currentAccount } = useAuthStore();
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [suppliers, setSuppliers] = useState<Supplier[]>([]);
  const [customers, setCustomers] = useState<Customer[]>([]);
  const [formData, setFormData] = useState<CreateLoanData & { borrower_name: string }>({
    borrower_type: 'supplier',
    principal: 0,
    currency: 'RWF',
    disbursement_date: new Date().toISOString().slice(0, 10),
    due_date: '',
    notes: '',
    borrower_name: '',
    borrower_phone: '',
  });

  useEffect(() => {
    if (!currentAccount?.account_id) return;
    suppliersApi.getAllSuppliers(currentAccount.account_id).then((r) => {
      if (r.code === 200 && r.data) setSuppliers(r.data);
    });
    customersApi.getAllCustomers(currentAccount.account_id).then((r) => {
      if (r.code === 200 && r.data) setCustomers(r.data);
    });
  }, [currentAccount?.account_id]);

  // Deduplicate by account id (same account can be both supplier and customer)
  const borrowerOptions: SearchableSelectOption[] = (() => {
    const byId = new Map<string, SearchableSelectOption>();
    suppliers.forEach((s) => {
      const id = s.account.id;
      if (!byId.has(id)) {
        byId.set(id, { value: id, label: `${s.name || s.account.name} (${s.account.code})` });
      }
    });
    customers.forEach((c) => {
      const id = c.account.id;
      if (!byId.has(id)) {
        byId.set(id, { value: id, label: `${c.name || c.account.name} (${c.account.code})` });
      }
    });
    return Array.from(byId.values());
  })();

  const handleChange = (
    e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>
  ) => {
    const { name, value } = e.target;
    setFormData((prev) => ({
      ...prev,
      [name]:
        name === 'principal' ? parseFloat(value) || 0 : name === 'borrower_type' ? value : value,
    }));
    setError('');
  };

  const validateForm = (): boolean => {
    if (formData.borrower_type !== 'other' && !formData.borrower_account_id) {
      setError('Please select a borrower (supplier or customer).');
      return false;
    }
    if (formData.borrower_type === 'other') {
      if (!formData.borrower_name?.trim()) {
        setError('Borrower name is required for "Other".');
        return false;
      }
      if (!formData.borrower_phone?.trim()) {
        setError('Borrower phone is required for "Other".');
        return false;
      }
    }
    if (!formData.principal || formData.principal <= 0) {
      setError('Principal must be greater than 0.');
      return false;
    }
    if (!formData.disbursement_date) {
      setError('Disbursement date is required.');
      return false;
    }
    return true;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    if (!validateForm()) return;
    setLoading(true);
    try {
      const payload: CreateLoanData = {
        account_id: currentAccount?.account_id,
        borrower_type: formData.borrower_type as 'supplier' | 'customer' | 'other',
        principal: formData.principal,
        currency: formData.currency,
        disbursement_date: formData.disbursement_date,
        notes: formData.notes || undefined,
        due_date: formData.due_date || undefined,
      };
      if (formData.borrower_type !== 'other') {
        payload.borrower_account_id = formData.borrower_account_id;
      } else {
        payload.borrower_name = formData.borrower_name?.trim();
        payload.borrower_phone = formData.borrower_phone?.trim();
      }
      const response = await loansApi.createLoan(payload);
      if (response.code === 200 || response.code === 201) {
        useToastStore.getState().success('Loan created successfully.');
        onSuccess();
      } else {
        setError(response.message || 'Failed to create loan');
      }
    } catch (err: unknown) {
      setError(
        (err as { response?: { data?: { message?: string } }; message?: string })?.response?.data
          ?.message ||
          (err as { message?: string })?.message ||
          'Failed to create loan.'
      );
    } finally {
      setLoading(false);
    }
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      {error && (
        <div className="rounded bg-red-50 p-3 text-sm text-red-700">{error}</div>
      )}

      <div>
        <label className="mb-1 block text-sm font-medium text-gray-700">Borrower type</label>
        <select
          name="borrower_type"
          value={formData.borrower_type}
          onChange={handleChange}
          className="input w-full"
        >
          <option value="supplier">Supplier</option>
          <option value="customer">Customer</option>
          <option value="other">Other</option>
        </select>
      </div>

      {formData.borrower_type !== 'other' ? (
        <div>
          <label className="mb-1 block text-sm font-medium text-gray-700">Borrower</label>
          <SearchableSelect
            options={borrowerOptions}
            value={formData.borrower_account_id || ''}
            onChange={(v) =>
              setFormData((prev) => ({ ...prev, borrower_account_id: v || undefined }))
            }
            placeholder="Search supplier or customer..."
            required
          />
        </div>
      ) : (
        <>
          <div>
            <label className="mb-1 block text-sm font-medium text-gray-700">Borrower name</label>
            <input
              type="text"
              name="borrower_name"
              value={formData.borrower_name}
              onChange={handleChange}
              className="input w-full"
              placeholder="Full name"
              required
            />
          </div>
          <div>
            <label className="mb-1 block text-sm font-medium text-gray-700">Borrower phone</label>
            <input
              type="tel"
              name="borrower_phone"
              value={formData.borrower_phone}
              onChange={handleChange}
              className="input w-full"
              placeholder="e.g. 250788123456"
              required
            />
          </div>
        </>
      )}

      <div>
        <label className="mb-1 block text-sm font-medium text-gray-700">Principal (RWF)</label>
        <input
          type="number"
          name="principal"
          value={formData.principal || ''}
          onChange={handleChange}
          className="input w-full"
          min={0.01}
          step={0.01}
          required
        />
      </div>

      <div className="grid grid-cols-2 gap-4">
        <div>
          <label className="mb-1 block text-sm font-medium text-gray-700">Disbursement date</label>
          <input
            type="date"
            name="disbursement_date"
            value={formData.disbursement_date}
            onChange={handleChange}
            className="input w-full"
            required
          />
        </div>
        <div>
          <label className="mb-1 block text-sm font-medium text-gray-700">Due date (optional)</label>
          <input
            type="date"
            name="due_date"
            value={formData.due_date}
            onChange={handleChange}
            className="input w-full"
          />
        </div>
      </div>

      <div>
        <label className="mb-1 block text-sm font-medium text-gray-700">Notes (optional)</label>
        <textarea
          name="notes"
          value={formData.notes || ''}
          onChange={handleChange}
          className="input w-full min-h-[80px]"
          rows={3}
        />
      </div>

      <div className="flex justify-end gap-2 pt-2">
        <button type="button" onClick={onCancel} className="btn btn-secondary">
          Cancel
        </button>
        <button type="submit" className="btn btn-primary" disabled={loading}>
          {loading ? (
            <Icon icon={faSpinner} size="sm" className="animate-spin mr-2" />
          ) : (
            <Icon icon={faCheckCircle} size="sm" className="mr-2" />
          )}
          Create loan
        </button>
      </div>
    </form>
  );
}
