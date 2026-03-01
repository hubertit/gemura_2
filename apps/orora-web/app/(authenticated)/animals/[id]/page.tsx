'use client';

import { useState, useEffect, useCallback } from 'react';
import Link from 'next/link';
import { useParams } from 'next/navigation';
import {
  animalsApi,
  Animal,
  AnimalWeight,
  AnimalHealth,
  CreateWeightData,
  CreateHealthData,
  HealthEventType,
} from '@/lib/api/animals';
import { useAuthStore } from '@/store/auth';
import { useToastStore } from '@/store/toast';
import Modal from '@/app/components/Modal';
import Icon, {
  faArrowLeft,
  faEdit,
  faPaw,
  faWeightScale,
  faNotesMedical,
  faPlus,
  faTrash,
  faCalendar,
  faSpinner,
} from '@/app/components/Icon';
import { DetailPageSkeleton } from '@/app/components/SkeletonLoader';

const HEALTH_EVENT_LABELS: Record<HealthEventType, string> = {
  vaccination: 'Vaccination',
  treatment: 'Treatment',
  deworming: 'Deworming',
  examination: 'Examination',
  surgery: 'Surgery',
  injury: 'Injury',
  illness: 'Illness',
  other: 'Other',
};

export default function AnimalDetailPage() {
  const params = useParams();
  const id = params.id as string;
  const { currentAccount } = useAuthStore();
  const accountId = currentAccount?.account_id;
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [animal, setAnimal] = useState<Animal | null>(null);
  const [weightModalOpen, setWeightModalOpen] = useState(false);
  const [healthModalOpen, setHealthModalOpen] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [weightForm, setWeightForm] = useState<CreateWeightData>({
    weight_kg: 0,
    recorded_at: new Date().toISOString().slice(0, 16),
    notes: '',
  });
  const [healthForm, setHealthForm] = useState<CreateHealthData>({
    event_type: 'vaccination',
    event_date: new Date().toISOString().slice(0, 10),
    description: '',
    notes: '',
  });

  const loadAnimal = useCallback(async () => {
    try {
      setLoading(true);
      setError('');
      const res = await animalsApi.getById(id, accountId);
      if (res.code === 200 && res.data) setAnimal(res.data);
      else setError(res.message || 'Animal not found');
    } catch (err: unknown) {
      const e = err as { response?: { data?: { message?: string } }; message?: string };
      setError(e?.response?.data?.message || e?.message || 'Failed to load animal');
    } finally {
      setLoading(false);
    }
  }, [id, accountId]);

  useEffect(() => {
    loadAnimal();
  }, [loadAnimal]);

  const handleAddWeight = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!weightForm.weight_kg || weightForm.weight_kg <= 0) return;
    setSubmitting(true);
    try {
      await animalsApi.addWeight(id, { ...weightForm, recorded_at: weightForm.recorded_at || new Date().toISOString() }, accountId);
      useToastStore.getState().show('Weight recorded', 'success');
      setWeightModalOpen(false);
      setWeightForm({ weight_kg: 0, recorded_at: new Date().toISOString().slice(0, 16), notes: '' });
      loadAnimal();
    } catch (err: unknown) {
      const e = err as { response?: { data?: { message?: string } }; message?: string };
      useToastStore.getState().show(e?.response?.data?.message || e?.message || 'Failed to add weight', 'error');
    } finally {
      setSubmitting(false);
    }
  };

  const handleDeleteWeight = async (weightId: string) => {
    if (!confirm('Delete this weight record?')) return;
    try {
      await animalsApi.deleteWeight(id, weightId, accountId);
      useToastStore.getState().show('Weight record deleted', 'success');
      loadAnimal();
    } catch {
      useToastStore.getState().show('Failed to delete weight record', 'error');
    }
  };

  const handleAddHealth = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!healthForm.description.trim()) return;
    setSubmitting(true);
    try {
      await animalsApi.addHealth(id, healthForm, accountId);
      useToastStore.getState().show('Health record added', 'success');
      setHealthModalOpen(false);
      setHealthForm({
        event_type: 'vaccination',
        event_date: new Date().toISOString().slice(0, 10),
        description: '',
        notes: '',
      });
      loadAnimal();
    } catch (err: unknown) {
      const e = err as { response?: { data?: { message?: string } }; message?: string };
      useToastStore.getState().show(e?.response?.data?.message || e?.message || 'Failed to add health record', 'error');
    } finally {
      setSubmitting(false);
    }
  };

  const handleDeleteHealth = async (healthId: string) => {
    if (!confirm('Delete this health record?')) return;
    try {
      await animalsApi.deleteHealth(id, healthId, accountId);
      useToastStore.getState().show('Health record deleted', 'success');
      loadAnimal();
    } catch {
      useToastStore.getState().show('Failed to delete health record', 'error');
    }
  };

  if (loading && !animal) return <DetailPageSkeleton />;

  if (error && !animal) {
    return (
      <div className="space-y-4">
        <div className="bg-red-50 border border-red-200 rounded-sm p-4">
          <p className="text-sm text-red-600">{error}</p>
        </div>
        <Link href="/animals" className="btn btn-secondary">
          <Icon icon={faArrowLeft} size="sm" className="mr-2" />
          Back to Animals
        </Link>
      </div>
    );
  }

  if (!animal) return null;

  const weights = animal.weights ?? [];
  const healthRecords = animal.health_records ?? [];

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <div>
          <Link href="/animals" className="text-sm text-gray-600 hover:text-[var(--primary)] mb-2 inline-flex items-center">
            <Icon icon={faArrowLeft} size="sm" className="mr-2" />
            Back to Animals
          </Link>
          <h1 className="text-2xl font-bold text-gray-900">
            {animal.tag_number}
            {animal.name && <span className="font-normal text-gray-600"> · {animal.name}</span>}
          </h1>
          <p className="text-sm text-gray-500 mt-0.5">
            {animal.breed} · {animal.gender} · {new Date(animal.date_of_birth).toLocaleDateString()}
          </p>
        </div>
        <Link href={`/animals/${id}/edit`} className="btn btn-primary">
          <Icon icon={faEdit} size="sm" className="mr-2" />
          Edit Animal
        </Link>
      </div>

      {error && (
        <div className="bg-red-50 border border-red-200 rounded-sm p-4">
          <p className="text-sm text-red-600">{error}</p>
        </div>
      )}

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
        <div className="lg:col-span-2 space-y-4">
          <div className="bg-white border border-gray-200 rounded-sm p-6">
            <h2 className="text-lg font-semibold text-gray-900 mb-4 flex items-center">
              <Icon icon={faPaw} size="sm" className="mr-2 text-gray-500" />
              Basic information
            </h2>
            <dl className="grid grid-cols-1 sm:grid-cols-2 gap-3">
              <div>
                <dt className="text-sm font-medium text-gray-500">Tag number</dt>
                <dd className="text-gray-900">{animal.tag_number}</dd>
              </div>
              <div>
                <dt className="text-sm font-medium text-gray-500">Breed</dt>
                <dd className="text-gray-900">{animal.breed}</dd>
              </div>
              <div>
                <dt className="text-sm font-medium text-gray-500">Gender</dt>
                <dd className="text-gray-900 capitalize">{animal.gender}</dd>
              </div>
              <div>
                <dt className="text-sm font-medium text-gray-500">Date of birth</dt>
                <dd className="text-gray-900">{new Date(animal.date_of_birth).toLocaleDateString()}</dd>
              </div>
              <div>
                <dt className="text-sm font-medium text-gray-500">Source</dt>
                <dd className="text-gray-900">{animal.source.replace('_', ' ')}</dd>
              </div>
              <div>
                <dt className="text-sm font-medium text-gray-500">Status</dt>
                <dd>
                  <span
                    className={`inline-flex px-2 py-1 rounded text-xs font-medium ${
                      animal.status === 'active'
                        ? 'bg-green-100 text-green-700'
                        : animal.status === 'lactating' || animal.status === 'pregnant'
                          ? 'bg-blue-100 text-blue-700'
                          : 'bg-gray-100 text-gray-700'
                    }`}
                  >
                    {animal.status}
                  </span>
                </dd>
              </div>
              {animal.mother && (
                <div>
                  <dt className="text-sm font-medium text-gray-500">Mother</dt>
                  <dd className="text-gray-900">
                    <Link href={`/animals/${animal.mother.id}`} className="text-[var(--primary)] hover:underline">
                      {animal.mother.tag_number} {animal.mother.name && `(${animal.mother.name})`}
                    </Link>
                  </dd>
                </div>
              )}
              {animal.father && (
                <div>
                  <dt className="text-sm font-medium text-gray-500">Father</dt>
                  <dd className="text-gray-900">
                    <Link href={`/animals/${animal.father!.id}`} className="text-[var(--primary)] hover:underline">
                      {animal.father!.tag_number} {animal.father!.name && `(${animal.father!.name})`}
                    </Link>
                  </dd>
                </div>
              )}
            </dl>
            {animal.notes && (
              <div className="mt-4 pt-4 border-t border-gray-100">
                <dt className="text-sm font-medium text-gray-500 mb-1">Notes</dt>
                <dd className="text-gray-700 text-sm">{animal.notes}</dd>
              </div>
            )}
          </div>

          <div className="bg-white border border-gray-200 rounded-sm p-6">
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-lg font-semibold text-gray-900 flex items-center">
                <Icon icon={faWeightScale} size="sm" className="mr-2 text-gray-500" />
                Weight history
              </h2>
              <button
                type="button"
                onClick={() => setWeightModalOpen(true)}
                className="btn btn-secondary text-sm"
              >
                <Icon icon={faPlus} size="sm" className="mr-1" />
                Add weight
              </button>
            </div>
            {weights.length === 0 ? (
              <p className="text-sm text-gray-500">No weight records yet.</p>
            ) : (
              <div className="overflow-x-auto">
                <table className="w-full text-sm">
                  <thead>
                    <tr className="border-b border-gray-200 text-left text-gray-500">
                      <th className="py-2 pr-4">Date</th>
                      <th className="py-2 pr-4">Weight (kg)</th>
                      <th className="py-2 pr-4">Notes</th>
                      <th className="py-2 w-10" />
                    </tr>
                  </thead>
                  <tbody>
                    {weights.map((w) => (
                      <tr key={w.id} className="border-b border-gray-100">
                        <td className="py-2 pr-4 text-gray-900">
                          {new Date(w.recorded_at).toLocaleDateString()}
                        </td>
                        <td className="py-2 pr-4 font-medium">{Number(w.weight_kg)}</td>
                        <td className="py-2 pr-4 text-gray-600">{w.notes || '—'}</td>
                        <td className="py-2">
                          <button
                            type="button"
                            onClick={() => handleDeleteWeight(w.id)}
                            className="text-gray-400 hover:text-red-600 p-1"
                            title="Delete"
                          >
                            <Icon icon={faTrash} size="sm" />
                          </button>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </div>

          <div className="bg-white border border-gray-200 rounded-sm p-6">
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-lg font-semibold text-gray-900 flex items-center">
                <Icon icon={faNotesMedical} size="sm" className="mr-2 text-gray-500" />
                Health records
              </h2>
              <button
                type="button"
                onClick={() => setHealthModalOpen(true)}
                className="btn btn-secondary text-sm"
              >
                <Icon icon={faPlus} size="sm" className="mr-1" />
                Add record
              </button>
            </div>
            {healthRecords.length === 0 ? (
              <p className="text-sm text-gray-500">No health records yet.</p>
            ) : (
              <div className="space-y-3">
                {healthRecords.map((h) => (
                  <div
                    key={h.id}
                    className="border border-gray-100 rounded-sm p-3 flex items-start justify-between gap-2"
                  >
                    <div>
                      <span className="text-xs font-medium text-gray-500 uppercase">
                        {HEALTH_EVENT_LABELS[h.event_type] ?? h.event_type}
                      </span>
                      <span className="text-gray-500 text-sm ml-2">
                        {new Date(h.event_date).toLocaleDateString()}
                      </span>
                      <p className="text-gray-900 mt-1">{h.description}</p>
                      {h.treatment && (
                        <p className="text-sm text-gray-600 mt-1">Treatment: {h.treatment}</p>
                      )}
                      {h.medicine_name && (
                        <p className="text-sm text-gray-600">Medicine: {h.medicine_name}</p>
                      )}
                    </div>
                    <button
                      type="button"
                      onClick={() => handleDeleteHealth(h.id)}
                      className="text-gray-400 hover:text-red-600 p-1 shrink-0"
                      title="Delete"
                    >
                      <Icon icon={faTrash} size="sm" />
                    </button>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>

        <div className="space-y-4">
          <div className="bg-white border border-gray-200 rounded-sm p-6">
            <h2 className="text-lg font-semibold text-gray-900 mb-3">Quick info</h2>
            <div className="space-y-2 text-sm">
              <div className="flex justify-between">
                <span className="text-gray-500">Created</span>
                <span className="text-gray-900">{new Date(animal.created_at).toLocaleDateString()}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-500">Updated</span>
                <span className="text-gray-900">{new Date(animal.updated_at).toLocaleDateString()}</span>
              </div>
            </div>
          </div>
        </div>
      </div>

      <Modal open={weightModalOpen} onClose={() => setWeightModalOpen(false)} title="Record weight" maxWidth="max-w-md">
        <form onSubmit={handleAddWeight} className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Weight (kg) *</label>
            <input
              type="number"
              step="0.01"
              min="0"
              value={weightForm.weight_kg || ''}
              onChange={(e) => setWeightForm((p) => ({ ...p, weight_kg: parseFloat(e.target.value) || 0 }))}
              className="input w-full"
              required
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Date & time</label>
            <input
              type="datetime-local"
              value={weightForm.recorded_at}
              onChange={(e) => setWeightForm((p) => ({ ...p, recorded_at: e.target.value }))}
              className="input w-full"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Notes</label>
            <input
              type="text"
              value={weightForm.notes ?? ''}
              onChange={(e) => setWeightForm((p) => ({ ...p, notes: e.target.value }))}
              className="input w-full"
            />
          </div>
          <div className="flex justify-end gap-2">
            <button type="button" onClick={() => setWeightModalOpen(false)} className="btn btn-secondary">
              Cancel
            </button>
            <button type="submit" className="btn btn-primary" disabled={submitting || !weightForm.weight_kg}>
              {submitting ? <Icon icon={faSpinner} size="sm" className="animate-spin" /> : 'Save'}
            </button>
          </div>
        </form>
      </Modal>

      <Modal open={healthModalOpen} onClose={() => setHealthModalOpen(false)} title="Add health record" maxWidth="max-w-md">
        <form onSubmit={handleAddHealth} className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Event type *</label>
            <select
              value={healthForm.event_type}
              onChange={(e) => setHealthForm((p) => ({ ...p, event_type: e.target.value as HealthEventType }))}
              className="input w-full"
            >
              {(Object.keys(HEALTH_EVENT_LABELS) as HealthEventType[]).map((k) => (
                <option key={k} value={k}>
                  {HEALTH_EVENT_LABELS[k]}
                </option>
              ))}
            </select>
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Date *</label>
            <input
              type="date"
              value={healthForm.event_date}
              onChange={(e) => setHealthForm((p) => ({ ...p, event_date: e.target.value }))}
              className="input w-full"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Description *</label>
            <textarea
              value={healthForm.description}
              onChange={(e) => setHealthForm((p) => ({ ...p, description: e.target.value }))}
              className="input w-full min-h-[80px]"
              required
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Treatment</label>
            <input
              type="text"
              value={healthForm.treatment ?? ''}
              onChange={(e) => setHealthForm((p) => ({ ...p, treatment: e.target.value }))}
              className="input w-full"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Medicine</label>
            <input
              type="text"
              value={healthForm.medicine_name ?? ''}
              onChange={(e) => setHealthForm((p) => ({ ...p, medicine_name: e.target.value }))}
              className="input w-full"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Notes</label>
            <input
              type="text"
              value={healthForm.notes ?? ''}
              onChange={(e) => setHealthForm((p) => ({ ...p, notes: e.target.value }))}
              className="input w-full"
            />
          </div>
          <div className="flex justify-end gap-2">
            <button type="button" onClick={() => setHealthModalOpen(false)} className="btn btn-secondary">
              Cancel
            </button>
            <button type="submit" className="btn btn-primary" disabled={submitting || !healthForm.description.trim()}>
              {submitting ? <Icon icon={faSpinner} size="sm" className="animate-spin" /> : 'Save'}
            </button>
          </div>
        </form>
      </Modal>
    </div>
  );
}
