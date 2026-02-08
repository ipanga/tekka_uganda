'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import {
  ArrowLeftIcon,
  BellIcon,
  ShieldCheckIcon,
  EyeIcon,
  TrashIcon,
  ArrowRightOnRectangleIcon,
} from '@heroicons/react/24/outline';
import { signOut } from 'firebase/auth';
import { auth } from '@/lib/firebase';
import { api } from '@/lib/api';
import { UserSettings } from '@/types';
import Header from '@/components/layout/Header';
import Footer from '@/components/layout/Footer';
import { Button } from '@/components/ui/Button';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/Card';
import { PageLoader } from '@/components/ui/Spinner';
import { Modal, ModalFooter } from '@/components/ui/Modal';
import { useAuthStore } from '@/stores/authStore';

export default function SettingsPage() {
  const router = useRouter();
  const { isAuthenticated, isLoading: authLoading, logout } = useAuthStore();

  const [settings, setSettings] = useState<UserSettings | null>(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [showDeleteModal, setShowDeleteModal] = useState(false);
  const [deleteLoading, setDeleteLoading] = useState(false);

  useEffect(() => {
    if (!authLoading && !isAuthenticated) {
      router.push('/login');
      return;
    }

    if (isAuthenticated) {
      loadSettings();
    }
  }, [authLoading, isAuthenticated]);

  const loadSettings = async () => {
    try {
      setLoading(true);
      const data = await api.getMySettings();
      setSettings(data);
    } catch (error) {
      console.error('Error loading settings:', error);
    } finally {
      setLoading(false);
    }
  };

  const updateSetting = async (
    category: 'notifications' | 'privacy' | 'security',
    key: string,
    value: unknown
  ) => {
    if (!settings) return;

    setSaving(true);
    try {
      const updated = await api.updateMySettings({
        [category]: {
          ...settings[category],
          [key]: value,
        },
      });
      setSettings(updated);
    } catch (error) {
      console.error('Error updating setting:', error);
    } finally {
      setSaving(false);
    }
  };

  const handleSignOut = async () => {
    try {
      await signOut(auth);
      logout();
      router.push('/');
    } catch (error) {
      console.error('Error signing out:', error);
    }
  };

  const handleDeleteAccount = async () => {
    setDeleteLoading(true);
    try {
      await api.deleteAccount();
      await signOut(auth);
      logout();
      router.push('/');
    } catch (error) {
      console.error('Error deleting account:', error);
    } finally {
      setDeleteLoading(false);
    }
  };

  if (authLoading || loading) {
    return (
      <div className="min-h-screen flex flex-col">
        <Header />
        <PageLoader message="Loading settings..." />
        <Footer />
      </div>
    );
  }

  return (
    <div className="min-h-screen flex flex-col bg-gray-50">
      <Header />

      <main className="flex-1 py-8">
        <div className="max-w-2xl mx-auto px-4">
          {/* Back Button */}
          <button
            onClick={() => router.back()}
            className="flex items-center gap-2 text-gray-600 hover:text-gray-900 mb-6"
          >
            <ArrowLeftIcon className="w-5 h-5" />
            Back
          </button>

          <h1 className="text-2xl font-bold text-gray-900 mb-6">Settings</h1>

          {/* Notification Settings */}
          <Card className="mb-6">
            <CardHeader>
              <div className="flex items-center gap-2">
                <BellIcon className="w-5 h-5 text-gray-500" />
                <CardTitle>Notifications</CardTitle>
              </div>
              <CardDescription>Manage how you receive notifications</CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <ToggleSetting
                label="Push Notifications"
                description="Receive push notifications on your device"
                checked={settings?.notifications.pushEnabled ?? true}
                onChange={(v) => updateSetting('notifications', 'pushEnabled', v)}
              />
              <ToggleSetting
                label="Email Notifications"
                description="Receive notifications via email"
                checked={settings?.notifications.emailEnabled ?? true}
                onChange={(v) => updateSetting('notifications', 'emailEnabled', v)}
              />
              <ToggleSetting
                label="New Messages"
                description="Get notified when you receive new messages"
                checked={settings?.notifications.newMessage ?? true}
                onChange={(v) => updateSetting('notifications', 'newMessage', v)}
              />
              <ToggleSetting
                label="Price Drops"
                description="Get notified when saved items drop in price"
                checked={settings?.notifications.priceDrops ?? true}
                onChange={(v) => updateSetting('notifications', 'priceDrops', v)}
              />
            </CardContent>
          </Card>

          {/* Privacy Settings */}
          <Card className="mb-6">
            <CardHeader>
              <div className="flex items-center gap-2">
                <EyeIcon className="w-5 h-5 text-gray-500" />
                <CardTitle>Privacy</CardTitle>
              </div>
              <CardDescription>Control who can see your information</CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <ToggleSetting
                label="Show Location"
                description="Display your location on your profile"
                checked={settings?.privacy.showLocation ?? true}
                onChange={(v) => updateSetting('privacy', 'showLocation', v)}
              />
              <ToggleSetting
                label="Show Last Seen"
                description="Let others see when you were last active"
                checked={settings?.privacy.showLastSeen ?? true}
                onChange={(v) => updateSetting('privacy', 'showLastSeen', v)}
              />
            </CardContent>
          </Card>

          {/* Security Settings */}
          <Card className="mb-6">
            <CardHeader>
              <div className="flex items-center gap-2">
                <ShieldCheckIcon className="w-5 h-5 text-gray-500" />
                <CardTitle>Security</CardTitle>
              </div>
              <CardDescription>Manage your account security</CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <ToggleSetting
                label="Two-Factor Authentication"
                description="Add an extra layer of security to your account"
                checked={settings?.security.twoFactorEnabled ?? false}
                onChange={(v) => updateSetting('security', 'twoFactorEnabled', v)}
              />
              <ToggleSetting
                label="Login Alerts"
                description="Get notified of new login attempts"
                checked={settings?.security.loginAlerts ?? true}
                onChange={(v) => updateSetting('security', 'loginAlerts', v)}
              />
            </CardContent>
          </Card>

          {/* Account Actions */}
          <Card className="mb-6">
            <CardHeader>
              <CardTitle>Account</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <Button
                variant="outline"
                onClick={handleSignOut}
                className="w-full justify-start"
              >
                <ArrowRightOnRectangleIcon className="w-5 h-5 mr-2" />
                Sign Out
              </Button>

              <Button
                variant="outline"
                onClick={() => setShowDeleteModal(true)}
                className="w-full justify-start text-red-600 hover:text-red-700 hover:bg-red-50"
              >
                <TrashIcon className="w-5 h-5 mr-2" />
                Delete Account
              </Button>
            </CardContent>
          </Card>
        </div>
      </main>

      <Footer />

      {/* Delete Account Modal */}
      <Modal
        isOpen={showDeleteModal}
        onClose={() => setShowDeleteModal(false)}
        title="Delete Account"
        size="sm"
      >
        <div className="space-y-4">
          <p className="text-gray-600">
            Are you sure you want to delete your account? This action cannot be undone.
          </p>
          <ul className="text-sm text-gray-500 list-disc list-inside space-y-1">
            <li>All your listings will be removed</li>
            <li>Your messages will be deleted</li>
            <li>Your reviews will be anonymized</li>
          </ul>
        </div>

        <ModalFooter>
          <Button variant="outline" onClick={() => setShowDeleteModal(false)}>
            Cancel
          </Button>
          <Button
            onClick={handleDeleteAccount}
            loading={deleteLoading}
            className="bg-red-600 hover:bg-red-700"
          >
            Delete Account
          </Button>
        </ModalFooter>
      </Modal>
    </div>
  );
}

interface ToggleSettingProps {
  label: string;
  description: string;
  checked: boolean;
  onChange: (checked: boolean) => void;
}

function ToggleSetting({ label, description, checked, onChange }: ToggleSettingProps) {
  return (
    <div className="flex items-center justify-between">
      <div>
        <p className="font-medium text-gray-900">{label}</p>
        <p className="text-sm text-gray-500">{description}</p>
      </div>
      <button
        onClick={() => onChange(!checked)}
        className={`relative w-12 h-6 rounded-full transition-colors ${
          checked ? 'bg-pink-600' : 'bg-gray-200'
        }`}
      >
        <span
          className={`absolute top-1 left-1 w-4 h-4 bg-white rounded-full transition-transform ${
            checked ? 'translate-x-6' : ''
          }`}
        />
      </button>
    </div>
  );
}
