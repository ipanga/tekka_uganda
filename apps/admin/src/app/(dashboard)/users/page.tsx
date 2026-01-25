'use client';

import { useState, useEffect } from 'react';
import { Header } from '@/components/layout/Header';
import { Card, CardContent } from '@/components/ui/Card';
import { Badge, getStatusVariant } from '@/components/ui/Badge';
import { Button } from '@/components/ui/Button';
import {
  Table,
  TableHeader,
  TableBody,
  TableRow,
  TableHead,
  TableCell,
} from '@/components/ui/Table';
import {
  MagnifyingGlassIcon,
  EyeIcon,
  NoSymbolIcon,
  CheckCircleIcon,
  ShieldCheckIcon,
} from '@heroicons/react/24/outline';
import { api } from '@/lib/api';
import type { User } from '@/types';
import { format } from 'date-fns';

const roles = ['USER', 'ADMIN', 'MODERATOR'];

export default function UsersPage() {
  const [users, setUsers] = useState<User[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [roleFilter, setRoleFilter] = useState<string>('');
  const [page, setPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);

  useEffect(() => {
    loadUsers();
  }, [page, roleFilter]);

  const loadUsers = async () => {
    setLoading(true);
    try {
      const response = await api.getUsers({
        page,
        limit: 10,
        role: roleFilter || undefined,
      });

      if (response && !Array.isArray(response) && Array.isArray(response.data)) {
        setUsers(response.data);
        setTotalPages(response.totalPages || 1);
      } else if (Array.isArray(response)) {
        setUsers(response);
      } else {
        // Mock data for demo
        setUsers([
          {
            id: '1',
            firebaseUid: 'fb1',
            phoneNumber: '+256700000001',
            email: 'sarah@example.com',
            displayName: 'Sarah Kamya',
            photoUrl: 'https://via.placeholder.com/40',
            bio: 'Fashion lover',
            location: 'Kampala',
            isOnboardingComplete: true,
            isVerified: true,
            isEmailVerified: true,
            isIdentityVerified: false,
            isSuspended: false,
            role: 'USER',
            createdAt: new Date().toISOString(),
            updatedAt: new Date().toISOString(),
            lastActiveAt: new Date().toISOString(),
          },
          {
            id: '2',
            firebaseUid: 'fb2',
            phoneNumber: '+256700000002',
            email: 'john@example.com',
            displayName: 'John Mukasa',
            photoUrl: 'https://via.placeholder.com/40',
            location: 'Entebbe',
            isOnboardingComplete: true,
            isVerified: false,
            isEmailVerified: false,
            isIdentityVerified: false,
            isSuspended: true,
            suspendedReason: 'Violated terms of service',
            role: 'USER',
            createdAt: new Date(Date.now() - 86400000 * 30).toISOString(),
            updatedAt: new Date().toISOString(),
          },
        ]);
      }
    } catch (error) {
      console.error('Failed to load users:', error);
      setUsers([]);
    } finally {
      setLoading(false);
    }
  };

  const handleSuspend = async (id: string) => {
    const reason = prompt('Enter suspension reason:');
    if (reason) {
      try {
        await api.suspendUser(id, reason);
        loadUsers();
      } catch (error) {
        console.error('Failed to suspend user:', error);
      }
    }
  };

  const handleUnsuspend = async (id: string) => {
    try {
      await api.unsuspendUser(id);
      loadUsers();
    } catch (error) {
      console.error('Failed to unsuspend user:', error);
    }
  };

  const handleChangeRole = async (id: string, newRole: string) => {
    try {
      await api.updateUserRole(id, newRole);
      loadUsers();
    } catch (error) {
      console.error('Failed to update role:', error);
    }
  };

  const filteredUsers = users.filter(
    (user) =>
      user.displayName?.toLowerCase().includes(search.toLowerCase()) ||
      user.email?.toLowerCase().includes(search.toLowerCase()) ||
      user.phoneNumber.includes(search)
  );

  return (
    <div>
      <Header title="Users" />

      <div className="p-6">
        {/* Filters */}
        <Card className="mb-6">
          <CardContent className="py-4">
            <div className="flex flex-wrap items-center gap-4">
              {/* Search */}
              <div className="relative flex-1 min-w-[200px]">
                <MagnifyingGlassIcon className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
                <input
                  type="text"
                  placeholder="Search by name, email, or phone..."
                  value={search}
                  onChange={(e) => setSearch(e.target.value)}
                  className="h-9 w-full rounded-md border border-gray-300 pl-9 pr-3 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
                />
              </div>

              {/* Role Filter */}
              <select
                value={roleFilter}
                onChange={(e) => setRoleFilter(e.target.value)}
                className="h-9 rounded-md border border-gray-300 px-3 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
              >
                <option value="">All Roles</option>
                {roles.map((role) => (
                  <option key={role} value={role}>
                    {role}
                  </option>
                ))}
              </select>
            </div>
          </CardContent>
        </Card>

        {/* Users Table */}
        <Card>
          <CardContent className="p-0">
            {loading ? (
              <div className="flex items-center justify-center py-12">
                <div className="h-8 w-8 animate-spin rounded-full border-4 border-blue-600 border-t-transparent" />
              </div>
            ) : (
              <>
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>User</TableHead>
                      <TableHead>Contact</TableHead>
                      <TableHead>Role</TableHead>
                      <TableHead>Status</TableHead>
                      <TableHead>Verified</TableHead>
                      <TableHead>Joined</TableHead>
                      <TableHead>Actions</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {filteredUsers.length > 0 ? (
                      filteredUsers.map((user) => (
                        <TableRow key={user.id}>
                          <TableCell>
                            <div className="flex items-center">
                              {user.photoUrl ? (
                                <img
                                  src={user.photoUrl}
                                  alt={user.displayName || ''}
                                  className="mr-3 h-10 w-10 rounded-full object-cover"
                                />
                              ) : (
                                <div className="mr-3 h-10 w-10 rounded-full bg-gray-200 flex items-center justify-center">
                                  <span className="text-gray-500 font-medium">
                                    {user.displayName?.charAt(0) || '?'}
                                  </span>
                                </div>
                              )}
                              <div>
                                <p className="font-medium">
                                  {user.displayName || 'Unknown'}
                                </p>
                                <p className="text-xs text-gray-500">
                                  {user.location || 'No location'}
                                </p>
                              </div>
                            </div>
                          </TableCell>
                          <TableCell>
                            <div>
                              <p className="text-sm">{user.phoneNumber}</p>
                              {user.email && (
                                <p className="text-xs text-gray-500">{user.email}</p>
                              )}
                            </div>
                          </TableCell>
                          <TableCell>
                            <select
                              value={user.role}
                              onChange={(e) =>
                                handleChangeRole(user.id, e.target.value)
                              }
                              className="rounded border border-gray-300 px-2 py-1 text-xs"
                            >
                              {roles.map((role) => (
                                <option key={role} value={role}>
                                  {role}
                                </option>
                              ))}
                            </select>
                          </TableCell>
                          <TableCell>
                            {user.isSuspended ? (
                              <Badge variant="danger">Suspended</Badge>
                            ) : (
                              <Badge variant="success">Active</Badge>
                            )}
                          </TableCell>
                          <TableCell>
                            <div className="flex gap-1">
                              {user.isVerified && (
                                <ShieldCheckIcon
                                  className="h-5 w-5 text-blue-500"
                                  title="Verified"
                                />
                              )}
                              {user.isEmailVerified && (
                                <CheckCircleIcon
                                  className="h-5 w-5 text-green-500"
                                  title="Email Verified"
                                />
                              )}
                            </div>
                          </TableCell>
                          <TableCell>
                            {format(new Date(user.createdAt), 'MMM d, yyyy')}
                          </TableCell>
                          <TableCell>
                            <div className="flex gap-1">
                              <Button size="sm" variant="ghost" title="View">
                                <EyeIcon className="h-4 w-4" />
                              </Button>
                              {user.isSuspended ? (
                                <Button
                                  size="sm"
                                  variant="ghost"
                                  title="Unsuspend"
                                  onClick={() => handleUnsuspend(user.id)}
                                >
                                  <CheckCircleIcon className="h-4 w-4 text-green-600" />
                                </Button>
                              ) : (
                                <Button
                                  size="sm"
                                  variant="ghost"
                                  title="Suspend"
                                  onClick={() => handleSuspend(user.id)}
                                >
                                  <NoSymbolIcon className="h-4 w-4 text-red-600" />
                                </Button>
                              )}
                            </div>
                          </TableCell>
                        </TableRow>
                      ))
                    ) : (
                      <TableRow>
                        <TableCell className="text-center py-12 text-gray-500" colSpan={7}>
                          No users found
                        </TableCell>
                      </TableRow>
                    )}
                  </TableBody>
                </Table>

                {/* Pagination */}
                <div className="flex items-center justify-between border-t px-6 py-3">
                  <p className="text-sm text-gray-500">
                    Page {page} of {totalPages}
                  </p>
                  <div className="flex gap-2">
                    <Button
                      size="sm"
                      variant="secondary"
                      disabled={page === 1}
                      onClick={() => setPage((p) => p - 1)}
                    >
                      Previous
                    </Button>
                    <Button
                      size="sm"
                      variant="secondary"
                      disabled={page === totalPages}
                      onClick={() => setPage((p) => p + 1)}
                    >
                      Next
                    </Button>
                  </div>
                </div>
              </>
            )}
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
