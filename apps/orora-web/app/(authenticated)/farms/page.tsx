'use client';

import { useEffect, useState, useCallback, useRef } from 'react';
import { useAuthStore } from '@/store/auth';
import { useFarmStore } from '@/store/farms';
import { farmsApi, type Farm } from '@/lib/api/farms';
import { locationsApi, type Location } from '@/lib/api/locations';
import StatCard from '@/app/components/StatCard';
import Modal from '@/app/components/Modal';
import Icon, { faPlus, faPaw, faSpinner, faMapPin, faEdit, faTrash } from '@/app/components/Icon';

interface FarmFormProps {
  initial?: Partial<Farm>;
  onSubmit: (values: { name: string; location_id?: string; location?: string; description?: string }) => Promise<void>;
  onCancel: () => void;
}

function FarmForm({ initial, onSubmit, onCancel }: FarmFormProps) {
  const [name, setName] = useState(initial?.name ?? '');
  const [location, setLocation] = useState(initial?.location ?? '');
  const [description, setDescription] = useState(initial?.description ?? '');
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState('');

  const [provinces, setProvinces] = useState<Location[]>([]);
  const [districts, setDistricts] = useState<Location[]>([]);
  const [sectors, setSectors] = useState<Location[]>([]);
  const [cells, setCells] = useState<Location[]>([]);
  const [villages, setVillages] = useState<Location[]>([]);
  const [provinceId, setProvinceId] = useState<string>('');
  const [districtId, setDistrictId] = useState<string>('');
  const [sectorId, setSectorId] = useState<string>('');
  const [cellId, setCellId] = useState<string>('');
  const [villageId, setVillageId] = useState<string>('');
  const [loadingPath, setLoadingPath] = useState(!!initial?.location_id);
  const restoringPathRef = useRef(false);

  useEffect(() => {
    locationsApi.getProvinces().then((r) => setProvinces(Array.isArray(r?.data) ? r.data : [])).catch(() => setProvinces([]));
  }, []);

  useEffect(() => {
    if (!initial?.location_id) return;
    setLoadingPath(true);
    restoringPathRef.current = true;
    locationsApi
      .getPath(initial.location_id)
      .then(async (res) => {
        const path = Array.isArray(res?.data) ? res.data : [];
        const prov = path.find((p) => p.location_type === 'PROVINCE');
        const dist = path.find((p) => p.location_type === 'DISTRICT');
        const sec = path.find((p) => p.location_type === 'SECTOR');
        const cell = path.find((p) => p.location_type === 'CELL');
        const vill = path.find((p) => p.location_type === 'VILLAGE');
        if (prov) setProvinceId(prov.id);
        if (dist && prov) {
          const r = await locationsApi.getChildren(prov.id);
          setDistricts(Array.isArray(r?.data) ? r.data : []);
          setDistrictId(dist.id);
        }
        if (sec && dist) {
          const r = await locationsApi.getChildren(dist.id);
          setSectors(Array.isArray(r?.data) ? r.data : []);
          setSectorId(sec.id);
        }
        if (cell && sec) {
          const r = await locationsApi.getChildren(sec.id);
          setCells(Array.isArray(r?.data) ? r.data : []);
          setCellId(cell.id);
        }
        if (vill && cell) {
          const r = await locationsApi.getChildren(cell.id);
          setVillages(Array.isArray(r?.data) ? r.data : []);
          setVillageId(vill.id);
        }
      })
      .finally(() => {
        setLoadingPath(false);
        setTimeout(() => { restoringPathRef.current = false; }, 0);
      });
  }, [initial?.location_id]);

  useEffect(() => {
    if (restoringPathRef.current) return;
    if (!provinceId) {
      setDistricts([]);
      setDistrictId('');
      setSectorId('');
      setSectors([]);
      setCellId('');
      setCells([]);
      setVillageId('');
      setVillages([]);
      return;
    }
    locationsApi.getChildren(provinceId).then((r) => setDistricts(Array.isArray(r?.data) ? r.data : [])).catch(() => setDistricts([]));
    setDistrictId('');
    setSectorId('');
    setSectors([]);
    setCellId('');
    setCells([]);
    setVillageId('');
    setVillages([]);
  }, [provinceId]);

  useEffect(() => {
    if (restoringPathRef.current) return;
    if (!districtId) {
      setSectors([]);
      setSectorId('');
      setCellId('');
      setCells([]);
      setVillageId('');
      setVillages([]);
      return;
    }
    locationsApi.getChildren(districtId).then((r) => setSectors(Array.isArray(r?.data) ? r.data : [])).catch(() => setSectors([]));
    setSectorId('');
    setCellId('');
    setCells([]);
    setVillageId('');
    setVillages([]);
  }, [districtId]);

  useEffect(() => {
    if (restoringPathRef.current) return;
    if (!sectorId) {
      setCells([]);
      setCellId('');
      setVillageId('');
      setVillages([]);
      return;
    }
    locationsApi.getChildren(sectorId).then((r) => setCells(Array.isArray(r?.data) ? r.data : [])).catch(() => setCells([]));
    setCellId('');
    setVillageId('');
    setVillages([]);
  }, [sectorId]);

  useEffect(() => {
    if (restoringPathRef.current) return;
    if (!cellId) {
      setVillages([]);
      setVillageId('');
      return;
    }
    locationsApi.getChildren(cellId).then((r) => setVillages(Array.isArray(r?.data) ? r.data : [])).catch(() => setVillages([]));
    setVillageId('');
  }, [cellId]);

  const locationId = villageId || cellId || sectorId || districtId || provinceId || undefined;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    if (!name.trim()) {
      setError('Farm name is required');
      return;
    }
    setSubmitting(true);
    try {
      await onSubmit({
        name: name.trim(),
        location_id: locationId,
        location: location.trim() || undefined,
        description: description.trim() || undefined,
      });
    } catch (err: unknown) {
      const errObj = err as { response?: { data?: { message?: string } }; message?: string };
      setError(errObj?.response?.data?.message || errObj?.message || 'Failed to save farm');
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      {error && (
        <div className="bg-red-50 border border-red-200 rounded-sm p-3 text-sm text-red-600">
          {error}
        </div>
      )}
      <div className="space-y-2">
        <label className="block text-sm font-medium text-gray-700">Farm name *</label>
        <input
          type="text"
          value={name}
          onChange={(e) => setName(e.target.value)}
          className="input w-full"
          placeholder="e.g. Main Dairy Farm"
        />
      </div>
      <div className="space-y-2">
        <label className="block text-sm font-medium text-gray-700">Location (Province → District → Sector → Cell → Village)</label>
        {loadingPath ? (
          <p className="text-sm text-gray-500">Loading location…</p>
        ) : (
          <div className="grid grid-cols-1 gap-2">
            <select
              value={provinceId}
              onChange={(e) => setProvinceId(e.target.value)}
              className="input w-full"
            >
              <option value="">Select province</option>
              {provinces.map((p) => (
                <option key={p.id} value={p.id}>{p.name}</option>
              ))}
            </select>
            <select
              value={districtId}
              onChange={(e) => setDistrictId(e.target.value)}
              className="input w-full"
              disabled={!provinceId}
            >
              <option value="">Select district</option>
              {districts.map((d) => (
                <option key={d.id} value={d.id}>{d.name}</option>
              ))}
            </select>
            <select
              value={sectorId}
              onChange={(e) => setSectorId(e.target.value)}
              className="input w-full"
              disabled={!districtId}
            >
              <option value="">Select sector</option>
              {sectors.map((s) => (
                <option key={s.id} value={s.id}>{s.name}</option>
              ))}
            </select>
            <select
              value={cellId}
              onChange={(e) => setCellId(e.target.value)}
              className="input w-full"
              disabled={!sectorId}
            >
              <option value="">Select cell</option>
              {cells.map((c) => (
                <option key={c.id} value={c.id}>{c.name}</option>
              ))}
            </select>
            <select
              value={villageId}
              onChange={(e) => setVillageId(e.target.value)}
              className="input w-full"
              disabled={!cellId}
            >
              <option value="">Select village</option>
              {villages.map((v) => (
                <option key={v.id} value={v.id}>{v.name}</option>
              ))}
            </select>
          </div>
        )}
      </div>
      <div className="space-y-2">
        <label className="block text-sm font-medium text-gray-700">Extra address / notes</label>
        <input
          type="text"
          value={location}
          onChange={(e) => setLocation(e.target.value)}
          className="input w-full"
          placeholder="e.g. Near main road, plot 123"
        />
      </div>
      <div className="space-y-2">
        <label className="block text-sm font-medium text-gray-700">Description</label>
        <textarea
          value={description}
          onChange={(e) => setDescription(e.target.value)}
          className="input w-full min-h-[80px]"
          placeholder="Short description of this farm or unit"
        />
      </div>
      <div className="flex justify-end gap-2 pt-2">
        <button type="button" onClick={onCancel} className="btn btn-secondary" disabled={submitting}>
          Cancel
        </button>
        <button type="submit" className="btn btn-primary" disabled={submitting}>
          {submitting && <Icon icon={faSpinner} size="sm" className="mr-2 animate-spin" />}
          Save
        </button>
      </div>
    </form>
  );
}

export default function FarmsPage() {
  const { currentAccount } = useAuthStore();
  const accountId = currentAccount?.account_id;
  const { farmsByAccount, setFarms, selectedFarmByAccount, setSelectedFarm } = useFarmStore();
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [createOpen, setCreateOpen] = useState(false);
  const [editFarm, setEditFarm] = useState<Farm | null>(null);
  const [deletingId, setDeletingId] = useState<string | null>(null);

  const farms = accountId ? farmsByAccount[accountId] || [] : [];
  const selectedFarmId = accountId ? selectedFarmByAccount[accountId] ?? null : null;

  const load = useCallback(async () => {
    if (!accountId) return;
    setLoading(true);
    setError('');
    try {
      const res = await farmsApi.list(accountId);
      if (res.code === 200 && Array.isArray(res.data)) {
        setFarms(accountId, res.data);
      } else {
        setError(res.message || 'Failed to load farms');
      }
    } catch (err: unknown) {
      const e = err as { response?: { data?: { message?: string } }; message?: string };
      setError(e?.response?.data?.message || e?.message || 'Failed to load farms');
    } finally {
      setLoading(false);
    }
  }, [accountId, setFarms]);

  useEffect(() => {
    void load();
  }, [load]);

  const handleCreate = async (values: { name: string; location_id?: string; location?: string; description?: string }) => {
    if (!accountId) return;
    await farmsApi.create(values, accountId);
    setCreateOpen(false);
    await load();
  };

  const handleUpdate = async (values: { name: string; location_id?: string; location?: string; description?: string }) => {
    if (!accountId || !editFarm) return;
    await farmsApi.update(editFarm.id, values, accountId);
    setEditFarm(null);
    await load();
  };

  const handleDelete = async (farm: Farm) => {
    if (!accountId) return;
    setDeletingId(farm.id);
    try {
      await farmsApi.delete(farm.id, accountId);
      // If this farm was selected, reset selection to "All farms"
      if (selectedFarmId === farm.id) {
        setSelectedFarm(accountId, null);
      }
      await load();
    } finally {
      setDeletingId(null);
    }
  };

  const totalAnimals = farms.reduce((sum, f) => sum + (f._count?.animals ?? 0), 0);
  const activeFarms = farms.filter((f) => f.status === 'active').length;
  const inactiveFarms = farms.filter((f) => f.status !== 'active').length;

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Farms</h1>
          <p className="text-sm text-gray-500 mt-0.5">
            Manage farms / production units and see where your animals live.
          </p>
        </div>
        <button
          type="button"
          onClick={() => setCreateOpen(true)}
          className="btn btn-primary"
        >
          <Icon icon={faPlus} size="sm" className="mr-2" />
          Add Farm
        </button>
      </div>

      {error && (
        <div className="bg-red-50 border border-red-200 rounded-sm p-3 text-sm text-red-600">
          {error}
        </div>
      )}

      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <StatCard
          label="Farms"
          value={String(farms.length)}
          subtitle={`${activeFarms} active, ${inactiveFarms} inactive`}
          icon={faPaw}
          href="/farms"
          iconBgColor="#f3e8ff"
          iconColor="#7c3aed"
        />
        <StatCard
          label="Animals"
          value={String(totalAnimals)}
          subtitle="Across all farms"
          icon={faPaw}
          href="/animals"
          iconBgColor="#e0f2fe"
          iconColor="#0369a1"
        />
        <StatCard
          label="Selected farm"
          value={selectedFarmId ? (farms.find((f) => f.id === selectedFarmId)?.name ?? 'One farm') : 'All farms'}
          subtitle={selectedFarmId ? 'Dashboard and animals scoped to this farm' : 'Dashboard and animals for all farms'}
          icon={faMapPin}
          href="/farms"
          iconBgColor="#ecfdf3"
          iconColor="#16a34a"
        />
      </div>

      <div className="bg-white border border-gray-200 rounded-sm">
        <div className="p-4 border-b border-gray-200 flex items-center justify-between">
          <h2 className="text-base font-semibold text-gray-900">Farm list</h2>
          {loading && (
            <span className="inline-flex items-center text-xs text-gray-500">
              <Icon icon={faSpinner} size="sm" className="mr-1 animate-spin" />
              Loading...
            </span>
          )}
        </div>
        <div className="divide-y divide-gray-100">
          {farms.length === 0 && !loading ? (
            <div className="p-6 text-sm text-gray-500">
              No farms yet. Create your first farm to start assigning animals to locations.
            </div>
          ) : (
            farms.map((farm) => {
              const isSelected = selectedFarmId === farm.id;
              return (
                <div key={farm.id} className="p-4 flex items-start justify-between gap-4">
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2">
                      <button
                        type="button"
                        onClick={() => accountId && setSelectedFarm(accountId, farm.id)}
                        className={`text-sm font-semibold truncate ${
                          isSelected ? 'text-[var(--primary)]' : 'text-gray-900'
                        }`}
                      >
                        {farm.name}
                      </button>
                      {farm.code && (
                        <span className="inline-flex px-2 py-0.5 rounded-full text-[11px] bg-gray-100 text-gray-600">
                          {farm.code}
                        </span>
                      )}
                      <span
                        className={`inline-flex px-2 py-0.5 rounded-full text-[11px] ${
                          farm.status === 'active'
                            ? 'bg-emerald-50 text-emerald-700'
                            : 'bg-gray-100 text-gray-600'
                        }`}
                      >
                        {farm.status}
                      </span>
                      {isSelected && (
                        <span className="inline-flex items-center px-2 py-0.5 rounded-full text-[11px] bg-[var(--primary)]/10 text-[var(--primary)]">
                          Selected
                        </span>
                      )}
                    </div>
                    <div className="mt-1 text-xs text-gray-500 flex flex-wrap items-center gap-3">
                      {(farm.locationRef?.name || farm.location) && (
                        <span className="inline-flex items-center gap-1">
                          <Icon icon={faMapPin} size="xs" />
                          <span>{farm.locationRef?.name ?? farm.location}</span>
                        </span>
                      )}
                      <span>
                        {(farm._count?.animals ?? 0).toString()} animals
                      </span>
                    </div>
                    {farm.description && (
                      <p className="mt-2 text-sm text-gray-600 line-clamp-2">
                        {farm.description}
                      </p>
                    )}
                  </div>
                  <div className="flex flex-col items-end gap-2 flex-shrink-0">
                    <button
                      type="button"
                      onClick={() => setEditFarm(farm)}
                      className="inline-flex items-center px-2 py-1.5 text-xs rounded border border-gray-200 text-gray-700 hover:bg-gray-50"
                    >
                      <Icon icon={faEdit} size="sm" className="mr-1" />
                      Edit
                    </button>
                    <button
                      type="button"
                      onClick={() => void handleDelete(farm)}
                      disabled={!!deletingId}
                      className="inline-flex items-center px-2 py-1.5 text-xs rounded border border-red-100 text-red-600 hover:bg-red-50 disabled:opacity-60"
                    >
                      {deletingId === farm.id ? (
                        <Icon icon={faSpinner} size="sm" className="mr-1 animate-spin" />
                      ) : (
                        <Icon icon={faTrash} size="sm" className="mr-1" />
                      )}
                      {farm._count?.animals ? 'Deactivate' : 'Delete'}
                    </button>
                  </div>
                </div>
              );
            })
          )}
        </div>
      </div>

      <Modal
        open={createOpen}
        onClose={() => setCreateOpen(false)}
        title="Add Farm"
        maxWidth="max-w-lg"
      >
        <FarmForm
          onSubmit={handleCreate}
          onCancel={() => setCreateOpen(false)}
        />
      </Modal>

      <Modal
        open={!!editFarm}
        onClose={() => setEditFarm(null)}
        title="Edit Farm"
        maxWidth="max-w-lg"
      >
        {editFarm && (
          <FarmForm
            initial={editFarm}
            onSubmit={handleUpdate}
            onCancel={() => setEditFarm(null)}
          />
        )}
      </Modal>
    </div>
  );
}

