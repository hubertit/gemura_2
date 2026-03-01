'use client';

import { useState, useEffect } from 'react';
import { collectionsApi, CreateCollectionData, SupplierAnimal } from '@/lib/api/collections';
import { suppliersApi, Supplier } from '@/lib/api/suppliers';
import { useToastStore } from '@/store/toast';
import Icon, { faCheckCircle, faSpinner, faPaw } from '@/app/components/Icon';
import SearchableSelect from '@/app/components/SearchableSelect';
import DateTimePicker from '@/app/components/DateTimePicker';
import Select from '@/app/components/Select';

const STATUS_OPTIONS = [
  { value: 'pending', label: 'Pending' },
  { value: 'accepted', label: 'Accepted' },
  { value: 'rejected', label: 'Rejected' },
];

interface CreateCollectionFormProps {
  onSuccess: () => void;
  onCancel: () => void;
}

export default function CreateCollectionForm({ onSuccess, onCancel }: CreateCollectionFormProps) {
  const [loading, setLoading] = useState(false);
  const [loadingSuppliers, setLoadingSuppliers] = useState(true);
  const [loadingAnimals, setLoadingAnimals] = useState(false);
  const [error, setError] = useState('');
  const [suppliers, setSuppliers] = useState<Supplier[]>([]);
  const [supplierAnimals, setSupplierAnimals] = useState<SupplierAnimal[]>([]);
  const [formData, setFormData] = useState<CreateCollectionData & { unit_price: number }>({
    supplier_account_code: '',
    quantity: 0,
    unit_price: 0,
    status: 'accepted',
    collection_at: new Date().toISOString().slice(0, 16),
    notes: '',
    payment_status: 'unpaid',
    animal_id: undefined,
  });

  useEffect(() => {
    let cancelled = false;
    suppliersApi.getAllSuppliers().then((res) => {
      if (!cancelled && res.code === 200) setSuppliers(res.data || []);
    }).finally(() => { if (!cancelled) setLoadingSuppliers(false); });
    return () => { cancelled = true; };
  }, []);

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>) => {
    const { name, value } = e.target;
    setFormData(prev => ({ ...prev, [name]: value === '' ? undefined : value }));
    setError('');
  };

  const handleSupplierSelect = (supplier_account_code: string) => {
    setFormData(prev => ({ ...prev, supplier_account_code, animal_id: undefined }));
    setError('');
    setSupplierAnimals([]);
    const supplier = suppliers.find(s => s.account.code === supplier_account_code);
    const price = supplier?.price_per_liter;
    if (typeof price === 'number') setFormData(prev => ({ ...prev, unit_price: price }));
    if (!supplier_account_code) return;
    setLoadingAnimals(true);
    collectionsApi.getSupplierAnimals(supplier_account_code).then((res) => {
      if (res.code === 200 && res.data) setSupplierAnimals(res.data);
      else setSupplierAnimals([]);
    }).catch(() => setSupplierAnimals([])).finally(() => setLoadingAnimals(false));
  };

  const validateForm = (): boolean => {
    if (!formData.supplier_account_code) { setError('Please select a supplier'); return false; }
    if (!formData.quantity || formData.quantity <= 0) { setError('Quantity must be greater than 0'); return false; }
    if (!formData.collection_at) { setError('Collection date and time is required'); return false; }
    return true;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    if (!validateForm()) return;
    setLoading(true);
    try {
      const collectionDate = formData.collection_at.replace('T', ' ').slice(0, 19);
      const finalData: CreateCollectionData = {
        supplier_account_code: formData.supplier_account_code,
        quantity: formData.quantity,
        status: formData.status,
        collection_at: collectionDate,
        notes: formData.notes,
        payment_status: formData.payment_status,
        animal_id: formData.animal_id || undefined,
      };
      const response = await collectionsApi.createCollection(finalData);
      if (response.code === 200 || response.code === 201) {
        useToastStore.getState().success('Collection created successfully!');
        onSuccess();
      } else {
        setError(response.message || 'Failed to create collection');
      }
    } catch (err: unknown) {
      setError((err as { response?: { data?: { message?: string } }; message?: string })?.response?.data?.message || (err as { message?: string })?.message || 'Failed to create collection.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      {error && <div className="bg-red-50 border border-red-200 rounded p-3 text-sm text-red-600">{error}</div>}
      <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
        <div className="sm:col-span-2">
          <label htmlFor="coll-supplier" className="block text-sm font-medium text-gray-700 mb-1">Supplier <span className="text-red-500">*</span></label>
          {loadingSuppliers ? (
            <div className="input w-full flex items-center text-gray-500 text-sm"><Icon icon={faSpinner} size="sm" spin className="mr-2" />Loading suppliers...</div>
          ) : (
            <SearchableSelect
              id="coll-supplier"
              name="supplier_account_code"
              options={suppliers.map(s => ({ value: s.account.code, label: `${s.name} (${s.account.code})` }))}
              value={formData.supplier_account_code}
              onChange={handleSupplierSelect}
              placeholder="Search or select a supplier..."
              disabled={loading}
              required
            />
          )}
        </div>
        {formData.supplier_account_code && (
          <div className="sm:col-span-2">
            <label htmlFor="coll-animal" className="block text-sm font-medium text-gray-700 mb-1">
              <Icon icon={faPaw} size="sm" className="inline mr-1 text-gray-500" />
              Animal (optional)
            </label>
            {loadingAnimals ? (
              <div className="input w-full flex items-center text-gray-500 text-sm"><Icon icon={faSpinner} size="sm" spin className="mr-2" />Loading animals...</div>
            ) : (
              <Select
                id="coll-animal"
                name="animal_id"
                value={formData.animal_id ?? ''}
                onChange={(v) => setFormData((prev) => ({ ...prev, animal_id: v || undefined }))}
                options={supplierAnimals.map((a) => ({
                  value: a.id,
                  label: `${a.tag_number} ${a.name ? `(${a.name})` : ''} · ${a.breed}`,
                }))}
                placeholder="— None —"
                allowEmpty
                disabled={loading}
                className="w-full"
              />
            )}
          </div>
        )}
        <div>
          <label htmlFor="coll-quantity" className="block text-sm font-medium text-gray-700 mb-1">Quantity (L) <span className="text-red-500">*</span></label>
          <input id="coll-quantity" name="quantity" type="number" step="0.01" min="0.01" required value={formData.quantity} onChange={handleChange} className="input w-full" disabled={loading} />
        </div>
        <div>
          <label htmlFor="coll-status" className="block text-sm font-medium text-gray-700 mb-1">Status</label>
          <Select
            id="coll-status"
            name="status"
            value={formData.status}
            onChange={(v) => setFormData((prev) => ({ ...prev, status: v as 'pending' | 'accepted' | 'rejected' | 'cancelled' }))}
            options={STATUS_OPTIONS}
            placeholder="Select status"
            disabled={loading}
            className="w-full"
          />
        </div>
        <div className="sm:col-span-2">
          <label htmlFor="coll-collection_at" className="block text-sm font-medium text-gray-700 mb-1">Date & time <span className="text-red-500">*</span></label>
          <DateTimePicker
            id="coll-collection_at"
            name="collection_at"
            value={formData.collection_at}
            onChange={(v) => setFormData((prev) => ({ ...prev, collection_at: v }))}
            max={new Date().toISOString().slice(0, 16)}
            placeholder="Select date and time"
            required
            disabled={loading}
            className="w-full"
          />
        </div>
        <div className="sm:col-span-2">
          <label htmlFor="coll-notes" className="block text-sm font-medium text-gray-700 mb-1">Notes</label>
          <textarea id="coll-notes" name="notes" rows={2} value={formData.notes} onChange={handleChange} className="input w-full" disabled={loading} placeholder="Optional" />
        </div>
      </div>
      <div className="flex justify-end gap-2 pt-2 border-t border-gray-200">
        <button type="button" onClick={onCancel} className="btn btn-secondary">Cancel</button>
        <button type="submit" className="btn btn-primary" disabled={loading}>
          {loading ? <><Icon icon={faSpinner} size="sm" spin className="mr-2" />Creating...</> : <><Icon icon={faCheckCircle} size="sm" className="mr-2" />Create Collection</>}
        </button>
      </div>
    </form>
  );
}
