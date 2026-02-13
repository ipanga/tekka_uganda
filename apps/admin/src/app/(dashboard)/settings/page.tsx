'use client';

import { Header } from '@/components/layout/Header';
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';

export default function SettingsPage() {
  return (
    <div>
      <Header title="Settings" />

      <div className="p-6 space-y-6">
        {/* General Settings */}
        <Card>
          <CardHeader>
            <CardTitle>General Settings</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                Platform Name
              </label>
              <input
                type="text"
                defaultValue="Tekka"
                className="w-full max-w-md rounded-md border border-gray-300 px-3 py-2 text-sm focus:border-primary-500 focus:outline-none focus:ring-1 focus:ring-primary-500 dark:border-gray-600 dark:bg-gray-700 dark:text-gray-100"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                Support Email
              </label>
              <input
                type="email"
                defaultValue="support@tekka.ug"
                className="w-full max-w-md rounded-md border border-gray-300 px-3 py-2 text-sm focus:border-primary-500 focus:outline-none focus:ring-1 focus:ring-primary-500 dark:border-gray-600 dark:bg-gray-700 dark:text-gray-100"
              />
            </div>
            <Button>Save Changes</Button>
          </CardContent>
        </Card>

        {/* Moderation Settings */}
        <Card>
          <CardHeader>
            <CardTitle>Moderation Settings</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="flex items-center justify-between max-w-md">
              <div>
                <p className="font-medium dark:text-gray-100">Auto-approve listings</p>
                <p className="text-sm text-gray-500 dark:text-gray-400">
                  Automatically approve listings from verified sellers
                </p>
              </div>
              <input
                type="checkbox"
                className="h-4 w-4 rounded border-gray-300 text-primary-500 focus:ring-primary-500 dark:border-gray-600"
              />
            </div>
            <div className="flex items-center justify-between max-w-md">
              <div>
                <p className="font-medium dark:text-gray-100">Require phone verification</p>
                <p className="text-sm text-gray-500 dark:text-gray-400">
                  Users must verify phone before posting
                </p>
              </div>
              <input
                type="checkbox"
                defaultChecked
                className="h-4 w-4 rounded border-gray-300 text-primary-500 focus:ring-primary-500 dark:border-gray-600"
              />
            </div>
            <Button>Save Changes</Button>
          </CardContent>
        </Card>

        {/* Notification Settings */}
        <Card>
          <CardHeader>
            <CardTitle>Notification Settings</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="flex items-center justify-between max-w-md">
              <div>
                <p className="font-medium dark:text-gray-100">Email alerts for new reports</p>
                <p className="text-sm text-gray-500 dark:text-gray-400">
                  Receive email when new reports are submitted
                </p>
              </div>
              <input
                type="checkbox"
                defaultChecked
                className="h-4 w-4 rounded border-gray-300 text-primary-500 focus:ring-primary-500 dark:border-gray-600"
              />
            </div>
            <div className="flex items-center justify-between max-w-md">
              <div>
                <p className="font-medium dark:text-gray-100">Daily summary emails</p>
                <p className="text-sm text-gray-500 dark:text-gray-400">
                  Receive daily summary of platform activity
                </p>
              </div>
              <input
                type="checkbox"
                className="h-4 w-4 rounded border-gray-300 text-primary-500 focus:ring-primary-500 dark:border-gray-600"
              />
            </div>
            <Button>Save Changes</Button>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
