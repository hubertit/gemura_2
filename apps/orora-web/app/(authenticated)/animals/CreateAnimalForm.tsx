'use client';

import { useState, useEffect } from 'react';
import { animalsApi, CreateAnimalData, Animal, AnimalStatus, AnimalSource, AnimalGender } from '@/lib/api/animals';
import { useAuthStore } from '@/store/auth';
import { useFarmStore } from '@/store/farms';
import { useToastStore } from '@/store/toast';
import Icon, { faCheckCircle, faSpinner } from '@/app/components/Icon';

const STATUS_OPTIONS: { value: AnimalStatus; label: string }[] = [
  { value: 'active', label: 'Active' },
  { value: 'lactating', label: 'Lactating' },
  { value: 'dry', label: 'Dry' },
  { value: 'pregnant', label: 'Pregnant' },
  { value: 'sick', label: 'Sick' },
  { value: 'sold', label: 'Sold' },
  { value: 'dead', label: 'Dead' },
  { value: 'culled', label: 'Culled' },
];

const SOURCE_OPTIONS: { value: AnimalSource; label: string }[] = [
  { value: 'born_on_farm', label: 'Born on farm' },
  { value: 'purchased', label: 'Purchased' },
  { value: 'donated', label: 'Donated' },
  { value: 'other', label: 'Other' },
];

const GENDER_OPTIONS: { value: AnimalGender; label: string }[] = [
  { value: 'male', label: 'Male' },
  { value: 'female', label: 'Female' },
];

interface CreateAnimalFormProps {
  onSuccess: () => void;
  onCancel: () => void;
  initialData?: Partial<CreateAnimalData> & { id?: string };
}

export default function CreateAnimalForm({ onSuccess, onCancel, initialData }: CreateAnimalFormProps) {
  const { currentAccount } = useAuthStore();
  const accountId = currentAccount?.account_id;
  const farmsByAccount = useFarmStore((state) => state.farmsByAccount);
  const selectedFarmByAccount = useFarmStore((state) => state.selectedFarmByAccount);
  const farmsForAccount = accountId ? farmsByAccount[accountId] || [] : [];
  const selectedFarmId = accountId ? selectedFarmByAccount[accountId] ?? null : null;
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [parents, setParents] = useState<Animal[]>([]);
  const [formData, setFormData] = useState<CreateAnimalData>({
    tag_number: initialData?.tag_number ?? '',
    name: initialData?.name ?? '',
    breed: initialData?.breed ?? '',
    gender: initialData?.gender ?? 'female',
    date_of_birth: initialData?.date_of_birth ?? '',
    source: initialData?.source ?? 'born_on_farm',
    purchase_date: initialData?.purchase_date ?? '',
    purchase_price: initialData?.purchase_price ?? undefined,
    mother_id: initialData?.mother_id ?? '',
    father_id: initialData?.father_id ?? '',
    status: initialData?.status ?? 'active',
    notes: initialData?.notes ?? '',
    farm_id: initialData && 'farm_id' in initialData ? (initialData as any).farm_id : selectedFarmId ?? undefined,
  });

  const isEdit = Boolean(initialData?.id);

  useEffect(() => {
    animalsApi.getList(accountId).then((res) => res.data && setParents(res.data)).catch(() => {});
  }, [accountId]);

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>) => {
    const { name, value } = e.target;
    setFormData((prev) => ({
      ...prev,
      [name]: name === 'purchase_price' ? (value === '' ? undefined : parseFloat(value)) : value,
    }));
    setError('');
  };

  const validate = (): boolean => {
    if (!formData.tag_number.trim()) {
      setError('Tag number is required');
      return false;
    }
    if (!formData.breed.trim()) {
      setError('Breed is required');
      return false;
    }
    if (!formData.date_of_birth) {
      setError('Date of birth is required');
      return false;
    }
    return true;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    if (!validate()) return;
    setLoading(true);
    try {
      const payload: CreateAnimalData = {
        tag_number: formData.tag_number.trim(),
        breed: formData.breed.trim(),
        gender: formData.gender,
        date_of_birth: formData.date_of_birth,
        source: formData.source,
        name: formData.name?.trim() || undefined,
        purchase_date: formData.purchase_date?.trim() || undefined,
        purchase_price: formData.purchase_price,
        mother_id: formData.mother_id?.trim() || undefined,
        father_id: formData.father_id?.trim() || undefined,
        status: formData.status,
        notes: formData.notes?.trim() || undefined,
        farm_id: formData.farm_id || selectedFarmId || undefined,
      };
      if (isEdit && initialData?.id) {
        await animalsApi.update(initialData.id, payload, accountId);
        useToastStore.getState().show('Animal updated successfully', 'success');
      } else {
        await animalsApi.create(payload, accountId);
        useToastStore.getState().show('Animal registered successfully', 'success');
      }
      onSuccess();
    } catch (err: unknown) {
      const e = err as { response?: { data?: { message?: string } }; message?: string };
      setError(e?.response?.data?.message || e?.message || 'Something went wrong');
    } finally {
      setLoading(false);
    }
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      {error && (
        <div className="bg-red-50 border border-red-200 rounded-sm p-3 text-sm text-red-600">
          {error}
        </div>
      )}

      <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">Tag number *</label>
          <input
            type="text"
            name="tag_number"
            value={formData.tag_number}
            onChange={handleChange}
            className="input w-full"
            placeholder="e.g. TAG-001"
            disabled={isEdit}
          />
        </div>
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">Name</label>
          <input
            type="text"
            name="name"
            value={formData.name ?? ''}
            onChange={handleChange}
            className="input w-full"
            placeholder="Optional"
          />
        </div>
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">Breed *</label>
          <input
            type="text"
            name="breed"
            value={formData.breed}
            onChange={handleChange}
            className="input w-full"
            placeholder="e.g. Holstein"
          />
        </div>
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">Gender *</label>
          <select
            name="gender"
            value={formData.gender}
            onChange={handleChange}
            className="input w-full"
          >
            {GENDER_OPTIONS.map((o) => (
              <option key={o.value} value={o.value}>
                {o.label}
              </option>
            ))}
          </select>
        </div>
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">Date of birth *</label>
          <input
            type="date"
            name="date_of_birth"
            value={formData.date_of_birth}
            onChange={handleChange}
            className="input w-full"
          />
        </div>
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">Source *</label>
          <select
            name="source"
            value={formData.source}
            onChange={handleChange}
            className="input w-full"
          >
            {SOURCE_OPTIONS.map((o) => (
              <option key={o.value} value={o.value}>
                {o.label}
              </option>
            ))}
          </select>
        </div>
      </div>

      {formData.source === 'purchased' && (
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Purchase date</label>
            <input
              type="date"
              name="purchase_date"
              value={formData.purchase_date ?? ''}
              onChange={handleChange}
              className="input w-full"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Purchase price (RWF)</label>
            <input
              type="number"
              name="purchase_price"
              value={formData.purchase_price ?? ''}
              onChange={handleChange}
              min={0}
              step={1}
              className="input w-full"
            />
          </div>
        </div>
      )}

      <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">Mother</label>
          <select
            name="mother_id"
            value={formData.mother_id ?? ''}
            onChange={handleChange}
            className="input w-full"
          >
            <option value="">— None —</option>
            {parents
              .filter((a) => a.gender === 'female' && a.id !== initialData?.id)
              .map((a) => (
                <option key={a.id} value={a.id}>
                  {a.tag_number} {a.name ? `(${a.name})` : ''}
                </option>
              ))}
          </select>
        </div>
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">Father</label>
          <select
            name="father_id"
            value={formData.father_id ?? ''}
            onChange={handleChange}
            className="input w-full"
          >
            <option value="">— None —</option>
            {parents
              .filter((a) => a.gender === 'male' && a.id !== initialData?.id)
              .map((a) => (
                <option key={a.id} value={a.id}>
                  {a.tag_number} {a.name ? `(${a.name})` : ''}
                </option>
              ))}
          </select>
        </div>
      </div>

      <div>
        <label className="block text-sm font-medium text-gray-700 mb-1">Status</label>
        <select
          name="status"
          value={formData.status}
          onChange={handleChange}
          className="input w-full"
        >
          {STATUS_OPTIONS.map((o) => (
            <option key={o.value} value={o.value}>
              {o.label}
            </option>
          ))}
        </select>
      </div>

      {farmsForAccount.length > 0 && (
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">Farm</label>
          <select
            name="farm_id"
            value={formData.farm_id ?? selectedFarmId ?? ''}
            onChange={handleChange}
            className="input w-full"
          >
            <option value="">All farms</option>
            {farmsForAccount.map((farm) => (
              <option key={farm.id} value={farm.id}>
                {farm.name}
              </option>
            ))}
          </select>
        </div>
      )}

      <div>
        <label className="block text-sm font-medium text-gray-700 mb-1">Notes</label>
        <textarea
          name="notes"
          value={formData.notes ?? ''}
          onChange={handleChange}
          className="input w-full min-h-[80px]"
          placeholder="Optional notes"
          rows={3}
        />
      </div>

      <div className="flex justify-end gap-2 pt-2">
        <button type="button" onClick={onCancel} className="btn btn-secondary">
          Cancel
        </button>
        <button type="submit" className="btn btn-primary" disabled={loading}>
          {loading ? (
            <Icon icon={faSpinner} size="sm" className="mr-2 animate-spin" />
          ) : (
            <Icon icon={faCheckCircle} size="sm" className="mr-2" />
          )}
          {isEdit ? 'Update Animal' : 'Register Animal'}
        </button>
      </div>
    </form>
  );
}
