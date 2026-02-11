'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import Icon, { faCog, faUser, faLock, faEnvelope, faPhone, faSpinner, faCheckCircle } from '@/app/components/Icon';
import { SkeletonBar } from '@/app/components/SkeletonLoader';
import { useAuthStore } from '@/store/auth';
import { useToastStore } from '@/store/toast';
import { profileApi, UpdateProfilePayload } from '@/lib/api/profile';

export default function SettingsPage() {
  const { user, setUser } = useAuthStore();
  const showToast = useToastStore((s) => s.show);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [profile, setProfile] = useState<{ name: string; email: string; phone: string }>({
    name: '',
    email: '',
    phone: '',
  });

  useEffect(() => {
    profileApi
      .getProfile()
      .then((res) => {
        if (res.code === 200 && res.data?.user) {
          const u = res.data.user;
          setProfile({
            name: u.name || '',
            email: u.email || '',
            phone: u.phone || '',
          });
        }
      })
      .catch(() => {
        if (user) {
          setProfile({
            name: [user.firstName, user.lastName].filter(Boolean).join(' ') || '',
            email: user.email || '',
            phone: user.phone || '',
          });
        }
      })
      .finally(() => setLoading(false));
  }, [user]);

  const handleProfileSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setSaving(true);
    try {
      const payload: UpdateProfilePayload = {
        name: profile.name.trim() || undefined,
        email: profile.email.trim() || undefined,
        phone: profile.phone.trim() || undefined,
      };
      const res = await profileApi.updateProfile(payload);
      if (res.code === 200 && res.data?.user) {
        const u = res.data.user;
        const parts = (u.name || '').split(' ');
        setUser({
          ...user!,
          firstName: parts[0] || u.name || '',
          lastName: parts.slice(1).join(' ') || '',
          email: u.email || '',
          phone: u.phone || '',
        });
        showToast('Profile updated successfully', 'success');
      } else {
        showToast(res.message || 'Failed to update profile', 'error');
      }
    } catch (err: any) {
      showToast(err?.response?.data?.message || 'Failed to update profile', 'error');
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Settings</h1>
      </div>

      {/* Profile */}
      <section className="bg-white border border-gray-200 rounded-sm overflow-hidden">
        <div className="px-6 py-4 border-b border-gray-200 flex items-center gap-3">
          <Icon icon={faUser} className="text-[var(--primary)]" size="sm" />
          <h2 className="text-lg font-semibold text-gray-900 m-0">Profile</h2>
        </div>
        <div className="p-6">
          {loading ? (
            <div className="max-w-md space-y-4">
              {[1, 2, 3].map((i) => (
                <div key={i}>
                  <SkeletonBar className="h-4 w-20 mb-1.5" />
                  <SkeletonBar className="h-10 w-full rounded-sm" />
                </div>
              ))}
              <div className="flex gap-2 pt-2">
                <SkeletonBar className="h-10 w-24 rounded-sm" />
                <SkeletonBar className="h-10 w-20 rounded-sm" />
              </div>
            </div>
          ) : (
            <form onSubmit={handleProfileSubmit} className="max-w-md space-y-4">
              <div>
                <label htmlFor="settings-name" className="block text-sm font-medium text-gray-700 mb-1">
                  Full name
                </label>
                <input
                  id="settings-name"
                  type="text"
                  value={profile.name}
                  onChange={(e) => setProfile((p) => ({ ...p, name: e.target.value }))}
                  className="w-full px-3 py-2 border border-gray-200 rounded-sm text-gray-900 focus:outline-none focus:border-[var(--primary)] focus:ring-1 focus:ring-[var(--primary)]"
                  placeholder="Your full name"
                />
              </div>
              <div>
                <label htmlFor="settings-email" className="block text-sm font-medium text-gray-700 mb-1">
                  Email
                </label>
                <div className="relative">
                  <Icon icon={faEnvelope} className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400 pointer-events-none" size="sm" />
                  <input
                    id="settings-email"
                    type="email"
                    value={profile.email}
                    onChange={(e) => setProfile((p) => ({ ...p, email: e.target.value }))}
                    className="w-full pl-10 pr-3 py-2 border border-gray-200 rounded-sm text-gray-900 placeholder:text-gray-400 focus:outline-none focus:border-[var(--primary)] focus:ring-1 focus:ring-[var(--primary)]"
                    placeholder="you@example.com"
                  />
                </div>
              </div>
              <div>
                <label htmlFor="settings-phone" className="block text-sm font-medium text-gray-700 mb-1">
                  Phone
                </label>
                <div className="relative">
                  <Icon icon={faPhone} className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400 pointer-events-none" size="sm" />
                  <input
                    id="settings-phone"
                    type="tel"
                    value={profile.phone}
                    onChange={(e) => setProfile((p) => ({ ...p, phone: e.target.value }))}
                    className="w-full pl-10 pr-3 py-2 border border-gray-200 rounded-sm text-gray-900 placeholder:text-gray-400 focus:outline-none focus:border-[var(--primary)] focus:ring-1 focus:ring-[var(--primary)]"
                    placeholder="250788123456"
                  />
                </div>
              </div>
              <button
                type="submit"
                disabled={saving}
                className="inline-flex items-center gap-2 px-4 py-2 bg-[var(--primary)] text-white rounded-sm text-sm font-medium hover:opacity-90 disabled:opacity-60"
              >
                {saving ? (
                  <>
                    <Icon icon={faSpinner} className="animate-spin" size="sm" />
                    Saving...
                  </>
                ) : (
                  <>
                    <Icon icon={faCheckCircle} size="sm" />
                    Save profile
                  </>
                )}
              </button>
            </form>
          )}
        </div>
      </section>

      {/* Password */}
      <section className="bg-white border border-gray-200 rounded-sm overflow-hidden">
        <div className="px-6 py-4 border-b border-gray-200 flex items-center gap-3">
          <Icon icon={faLock} className="text-[var(--primary)]" size="sm" />
          <h2 className="text-lg font-semibold text-gray-900 m-0">Password</h2>
        </div>
        <div className="p-6">
          <p className="text-sm text-gray-600 mb-4">
            To change your password, we&apos;ll send a reset link to your email.
          </p>
          <Link
            href="/auth/forgot-password"
            className="inline-flex items-center gap-2 px-4 py-2 border border-gray-300 rounded-sm text-sm font-medium text-gray-700 hover:bg-gray-50"
          >
            <Icon icon={faLock} size="sm" />
            Change password via email
          </Link>
        </div>
      </section>

      {/* App preferences (optional) */}
      <section className="bg-white border border-gray-200 rounded-sm overflow-hidden">
        <div className="px-6 py-4 border-b border-gray-200 flex items-center gap-3">
          <Icon icon={faCog} className="text-[var(--primary)]" size="sm" />
          <h2 className="text-lg font-semibold text-gray-900 m-0">Preferences</h2>
        </div>
        <div className="p-6">
          <p className="text-sm text-gray-500">Sidebar collapse state is saved in your browser.</p>
        </div>
      </section>
    </div>
  );
}
