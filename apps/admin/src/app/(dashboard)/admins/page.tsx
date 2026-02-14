'use client';

import { useState, useEffect } from 'react';
import {
  UserGroupIcon,
  PlusIcon,
  TrashIcon,
  ShieldCheckIcon,
} from '@heroicons/react/24/outline';
import { api } from '@/lib/api';
import { AdminUser, AdminPermission } from '@/types';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { Badge } from '@/components/ui/Badge';
import {
  Table,
  TableHeader,
  TableBody,
  TableRow,
  TableHead,
  TableCell,
} from '@/components/ui/Table';

// Mock data
const MOCK_ADMINS: AdminUser[] = [
  {
    id: '1',
    firebaseUid: 'fb1',
    phoneNumber: '+256700000001',
    email: 'admin@tekka.ug',
    displayName: 'Super Admin',
    role: 'ADMIN',
    isOnboardingComplete: true,
    isVerified: true,
    isEmailVerified: true,
    isIdentityVerified: true,
    isSuspended: false,
    permissions: ['MANAGE_USERS', 'MANAGE_LISTINGS', 'MANAGE_REPORTS', 'MANAGE_TRANSACTIONS', 'MANAGE_SETTINGS', 'MANAGE_ADMINS', 'VIEW_ANALYTICS', 'SEND_NOTIFICATIONS'],
    lastLoginAt: '2024-01-11T08:00:00Z',
    createdAt: '2023-06-01T00:00:00Z',
    updatedAt: '2024-01-11T08:00:00Z',
  },
  {
    id: '2',
    firebaseUid: 'fb2',
    phoneNumber: '+256700000002',
    email: 'mod1@tekka.ug',
    displayName: 'Jane Moderator',
    role: 'MODERATOR',
    isOnboardingComplete: true,
    isVerified: true,
    isEmailVerified: true,
    isIdentityVerified: false,
    isSuspended: false,
    permissions: ['MANAGE_LISTINGS', 'MANAGE_REPORTS', 'VIEW_ANALYTICS'],
    lastLoginAt: '2024-01-10T14:30:00Z',
    createdAt: '2023-09-15T00:00:00Z',
    updatedAt: '2024-01-10T14:30:00Z',
  },
  {
    id: '3',
    firebaseUid: 'fb3',
    phoneNumber: '+256700000003',
    email: 'mod2@tekka.ug',
    displayName: 'John Support',
    role: 'MODERATOR',
    isOnboardingComplete: true,
    isVerified: true,
    isEmailVerified: true,
    isIdentityVerified: false,
    isSuspended: false,
    permissions: ['MANAGE_USERS', 'MANAGE_REPORTS', 'SEND_NOTIFICATIONS'],
    lastLoginAt: '2024-01-09T09:15:00Z',
    createdAt: '2023-11-20T00:00:00Z',
    updatedAt: '2024-01-09T09:15:00Z',
  },
];

const ALL_PERMISSIONS: { value: AdminPermission; label: string; description: string }[] = [
  { value: 'MANAGE_USERS', label: 'Manage Users', description: 'View, suspend, and modify user accounts' },
  { value: 'MANAGE_LISTINGS', label: 'Manage Listings', description: 'Approve, reject, and delete listings' },
  { value: 'MANAGE_REPORTS', label: 'Manage Reports', description: 'Review and resolve user reports' },
  { value: 'MANAGE_TRANSACTIONS', label: 'Manage Transactions', description: 'View and manage transactions' },
  { value: 'MANAGE_SETTINGS', label: 'Manage Settings', description: 'Modify platform settings' },
  { value: 'MANAGE_ADMINS', label: 'Manage Admins', description: 'Add and remove admin users' },
  { value: 'VIEW_ANALYTICS', label: 'View Analytics', description: 'Access platform analytics' },
  { value: 'SEND_NOTIFICATIONS', label: 'Send Notifications', description: 'Send platform notifications' },
];

export default function AdminsPage() {
  const [admins, setAdmins] = useState<AdminUser[]>([]);
  const [loading, setLoading] = useState(true);
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [showPermissionsModal, setShowPermissionsModal] = useState(false);
  const [showDeleteModal, setShowDeleteModal] = useState(false);
  const [selectedAdmin, setSelectedAdmin] = useState<AdminUser | null>(null);

  // Form state
  const [formEmail, setFormEmail] = useState('');
  const [formDisplayName, setFormDisplayName] = useState('');
  const [formRole, setFormRole] = useState<'ADMIN' | 'MODERATOR'>('MODERATOR');
  const [formPermissions, setFormPermissions] = useState<AdminPermission[]>([]);
  const [formLoading, setFormLoading] = useState(false);

  useEffect(() => {
    loadAdmins();
  }, []);

  const loadAdmins = async () => {
    try {
      setLoading(true);
      const response = await api.getAdminUsers({ page: 1, limit: 50 });

      if (Array.isArray(response)) {
        setAdmins(response);
      } else if (response.data) {
        setAdmins(response.data);
      } else {
        setAdmins(MOCK_ADMINS);
      }
    } catch (error) {
      console.error('Error loading admins:', error);
      setAdmins(MOCK_ADMINS);
    } finally {
      setLoading(false);
    }
  };

  const handleCreateAdmin = async () => {
    if (!formEmail || !formDisplayName) return;

    setFormLoading(true);
    try {
      await api.createAdminUser({
        email: formEmail,
        displayName: formDisplayName,
        role: formRole,
        permissions: formPermissions,
      });

      await loadAdmins();
      resetForm();
      setShowCreateModal(false);
    } catch (error) {
      console.error('Error creating admin:', error);
    } finally {
      setFormLoading(false);
    }
  };

  const handleUpdatePermissions = async () => {
    if (!selectedAdmin) return;

    setFormLoading(true);
    try {
      await api.updateAdminPermissions(selectedAdmin.id, formPermissions);
      await loadAdmins();
      setShowPermissionsModal(false);
      setSelectedAdmin(null);
    } catch (error) {
      console.error('Error updating permissions:', error);
    } finally {
      setFormLoading(false);
    }
  };

  const handleRemoveAdmin = async () => {
    if (!selectedAdmin) return;

    setFormLoading(true);
    try {
      await api.removeAdmin(selectedAdmin.id);
      await loadAdmins();
      setShowDeleteModal(false);
      setSelectedAdmin(null);
    } catch (error) {
      console.error('Error removing admin:', error);
    } finally {
      setFormLoading(false);
    }
  };

  const resetForm = () => {
    setFormEmail('');
    setFormDisplayName('');
    setFormRole('MODERATOR');
    setFormPermissions([]);
  };

  const togglePermission = (permission: AdminPermission) => {
    if (formPermissions.includes(permission)) {
      setFormPermissions(formPermissions.filter((p) => p !== permission));
    } else {
      setFormPermissions([...formPermissions, permission]);
    }
  };

  const formatDate = (dateStr: string) => {
    return new Date(dateStr).toLocaleDateString('en-UG', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
    });
  };

  const formatDateTime = (dateStr: string) => {
    return new Date(dateStr).toLocaleString('en-UG', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Admin Users</h1>
          <p className="text-gray-500">Manage administrators and moderators</p>
        </div>
        <Button onClick={() => setShowCreateModal(true)}>
          <PlusIcon className="w-5 h-5 mr-2" />
          Add Admin
        </Button>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <Card>
          <CardContent className="py-4">
            <div className="flex items-center gap-4">
              <div className="p-3 bg-primary-100 rounded-lg">
                <ShieldCheckIcon className="w-6 h-6 text-primary-500" />
              </div>
              <div>
                <p className="text-2xl font-bold text-gray-900">
                  {admins.filter((a) => a.role === 'ADMIN').length}
                </p>
                <p className="text-sm text-gray-500">Administrators</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="py-4">
            <div className="flex items-center gap-4">
              <div className="p-3 bg-primary-100 rounded-lg">
                <UserGroupIcon className="w-6 h-6 text-primary-500" />
              </div>
              <div>
                <p className="text-2xl font-bold text-gray-900">
                  {admins.filter((a) => a.role === 'MODERATOR').length}
                </p>
                <p className="text-sm text-gray-500">Moderators</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="py-4">
            <div className="flex items-center gap-4">
              <div className="p-3 bg-green-100 rounded-lg">
                <UserGroupIcon className="w-6 h-6 text-green-600" />
              </div>
              <div>
                <p className="text-2xl font-bold text-gray-900">{admins.length}</p>
                <p className="text-sm text-gray-500">Total Team Members</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Admin Table */}
      <Card>
        <CardHeader>
          <CardTitle>Team Members</CardTitle>
        </CardHeader>
        <CardContent>
          {loading ? (
            <div className="flex justify-center py-8">
              <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-500"></div>
            </div>
          ) : admins.length === 0 ? (
            <div className="text-center py-8">
              <UserGroupIcon className="w-12 h-12 text-gray-300 mx-auto mb-4" />
              <p className="text-gray-500">No admin users found</p>
            </div>
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>User</TableHead>
                  <TableHead>Role</TableHead>
                  <TableHead>Permissions</TableHead>
                  <TableHead>Last Login</TableHead>
                  <TableHead>Joined</TableHead>
                  <TableHead>Actions</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {admins.map((admin) => (
                  <TableRow key={admin.id}>
                    <TableCell>
                      <div className="flex items-center gap-3">
                        <div className="w-10 h-10 rounded-full bg-gray-200 flex items-center justify-center">
                          <span className="text-sm font-medium text-gray-600">
                            {admin.displayName?.charAt(0).toUpperCase() || 'A'}
                          </span>
                        </div>
                        <div>
                          <p className="font-medium text-gray-900">{admin.displayName}</p>
                          <p className="text-sm text-gray-500">{admin.email}</p>
                        </div>
                      </div>
                    </TableCell>
                    <TableCell>
                      <Badge variant={admin.role === 'ADMIN' ? 'success' : 'info'}>
                        {admin.role}
                      </Badge>
                    </TableCell>
                    <TableCell>
                      <div className="flex flex-wrap gap-1 max-w-xs">
                        {(admin.permissions || []).slice(0, 3).map((perm) => (
                          <Badge key={perm} variant="default" className="text-xs">
                            {perm.replace('MANAGE_', '').replace('_', ' ')}
                          </Badge>
                        ))}
                        {(admin.permissions || []).length > 3 && (
                          <Badge variant="default" className="text-xs">
                            +{admin.permissions.length - 3} more
                          </Badge>
                        )}
                        {(!admin.permissions || admin.permissions.length === 0) && (
                          <span className="text-gray-400 text-sm">Full access</span>
                        )}
                      </div>
                    </TableCell>
                    <TableCell>
                      {admin.lastLoginAt ? (
                        <p className="text-gray-900">{formatDateTime(admin.lastLoginAt)}</p>
                      ) : (
                        <p className="text-gray-400">Never</p>
                      )}
                    </TableCell>
                    <TableCell>
                      <p className="text-gray-900">{formatDate(admin.createdAt)}</p>
                    </TableCell>
                    <TableCell>
                      <div className="flex gap-2">
                        <Button
                          size="sm"
                          variant="secondary"
                          onClick={() => {
                            setSelectedAdmin(admin);
                            setFormPermissions([...admin.permissions]);
                            setShowPermissionsModal(true);
                          }}
                        >
                          Permissions
                        </Button>
                        <Button
                          size="sm"
                          variant="danger"
                          onClick={() => {
                            setSelectedAdmin(admin);
                            setShowDeleteModal(true);
                          }}
                        >
                          <TrashIcon className="w-4 h-4" />
                        </Button>
                      </div>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          )}
        </CardContent>
      </Card>

      {/* Create Admin Modal */}
      {showCreateModal && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-6 max-w-lg w-full mx-4 max-h-[90vh] overflow-y-auto">
            <h3 className="text-lg font-bold text-gray-900 mb-4">Add Admin User</h3>

            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Email</label>
                <input
                  type="email"
                  value={formEmail}
                  onChange={(e) => setFormEmail(e.target.value)}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500"
                  placeholder="admin@tekka.ug"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Display Name</label>
                <input
                  type="text"
                  value={formDisplayName}
                  onChange={(e) => setFormDisplayName(e.target.value)}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500"
                  placeholder="John Doe"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Role</label>
                <select
                  value={formRole}
                  onChange={(e) => setFormRole(e.target.value as 'ADMIN' | 'MODERATOR')}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500"
                >
                  <option value="MODERATOR">Moderator</option>
                  <option value="ADMIN">Administrator</option>
                </select>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">Permissions</label>
                <div className="space-y-2 max-h-48 overflow-y-auto border border-gray-200 rounded-lg p-3">
                  {ALL_PERMISSIONS.map((perm) => (
                    <label key={perm.value} className="flex items-start gap-3 cursor-pointer">
                      <input
                        type="checkbox"
                        checked={formPermissions.includes(perm.value)}
                        onChange={() => togglePermission(perm.value)}
                        className="mt-1 rounded border-gray-300 text-primary-500 focus:ring-primary-500"
                      />
                      <div>
                        <p className="text-sm font-medium text-gray-900">{perm.label}</p>
                        <p className="text-xs text-gray-500">{perm.description}</p>
                      </div>
                    </label>
                  ))}
                </div>
              </div>
            </div>

            <div className="flex justify-end gap-2 mt-6">
              <Button
                variant="secondary"
                onClick={() => {
                  setShowCreateModal(false);
                  resetForm();
                }}
              >
                Cancel
              </Button>
              <Button
                onClick={handleCreateAdmin}
                disabled={!formEmail || !formDisplayName || formLoading}
              >
                {formLoading ? 'Creating...' : 'Create Admin'}
              </Button>
            </div>
          </div>
        </div>
      )}

      {/* Edit Permissions Modal */}
      {showPermissionsModal && selectedAdmin && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-6 max-w-lg w-full mx-4 max-h-[90vh] overflow-y-auto">
            <h3 className="text-lg font-bold text-gray-900 mb-4">
              Edit Permissions - {selectedAdmin.displayName}
            </h3>

            <div className="space-y-2 max-h-64 overflow-y-auto border border-gray-200 rounded-lg p-3">
              {ALL_PERMISSIONS.map((perm) => (
                <label key={perm.value} className="flex items-start gap-3 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={formPermissions.includes(perm.value)}
                    onChange={() => togglePermission(perm.value)}
                    className="mt-1 rounded border-gray-300 text-primary-500 focus:ring-primary-500"
                  />
                  <div>
                    <p className="text-sm font-medium text-gray-900">{perm.label}</p>
                    <p className="text-xs text-gray-500">{perm.description}</p>
                  </div>
                </label>
              ))}
            </div>

            <div className="flex justify-end gap-2 mt-6">
              <Button
                variant="secondary"
                onClick={() => {
                  setShowPermissionsModal(false);
                  setSelectedAdmin(null);
                }}
              >
                Cancel
              </Button>
              <Button onClick={handleUpdatePermissions} disabled={formLoading}>
                {formLoading ? 'Saving...' : 'Save Permissions'}
              </Button>
            </div>
          </div>
        </div>
      )}

      {/* Delete Confirmation Modal */}
      {showDeleteModal && selectedAdmin && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-6 max-w-md w-full mx-4">
            <h3 className="text-lg font-bold text-gray-900 mb-4">Remove Admin</h3>
            <p className="text-gray-600 mb-4">
              Are you sure you want to remove <strong>{selectedAdmin.displayName}</strong> from the
              admin team? They will lose all admin privileges.
            </p>
            <div className="flex justify-end gap-2">
              <Button
                variant="secondary"
                onClick={() => {
                  setShowDeleteModal(false);
                  setSelectedAdmin(null);
                }}
              >
                Cancel
              </Button>
              <Button variant="danger" onClick={handleRemoveAdmin} disabled={formLoading}>
                {formLoading ? 'Removing...' : 'Remove Admin'}
              </Button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
