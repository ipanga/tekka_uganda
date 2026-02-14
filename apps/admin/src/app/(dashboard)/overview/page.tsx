'use client';

import { useState, useEffect } from 'react';
import {
  UsersIcon,
  ShoppingBagIcon,
  CurrencyDollarIcon,
  FlagIcon,
  ClockIcon,
  CheckCircleIcon,
} from '@heroicons/react/24/outline';
import { Header } from '@/components/layout/Header';
import { StatsCard } from '@/components/dashboard/StatsCard';
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/Card';
import { Badge, getStatusVariant } from '@/components/ui/Badge';
import {
  Table,
  TableHeader,
  TableBody,
  TableRow,
  TableHead,
  TableCell,
} from '@/components/ui/Table';
import { Button } from '@/components/ui/Button';
import { api } from '@/lib/api';
import type { Listing } from '@/types';

interface DashboardStats {
  totalUsers: number;
  activeUsers: number;
  totalListings: number;
  activeListings: number;
  pendingListings: number;
  totalTransactions: number;
  pendingReports: number;
}

export default function OverviewPage() {
  const [stats, setStats] = useState<DashboardStats | null>(null);
  const [pendingListings, setPendingListings] = useState<Listing[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadDashboardData();
  }, []);

  const loadDashboardData = async () => {
    try {
      // Load real dashboard stats from API
      try {
        const dashboardStats = await api.getDashboardStats();
        setStats(dashboardStats);
      } catch (statsError) {
        console.error('Failed to load dashboard stats:', statsError);
        // Fallback to zeros if API fails
        setStats({
          totalUsers: 0,
          activeUsers: 0,
          totalListings: 0,
          activeListings: 0,
          pendingListings: 0,
          totalTransactions: 0,
          pendingReports: 0,
        });
      }

      // Load pending listings
      try {
        const response = await api.getPendingListings({ limit: 5 });
        if (response && typeof response === 'object' && 'listings' in response) {
          setPendingListings((response as any).listings || []);
        } else if (Array.isArray(response)) {
          setPendingListings(response);
        } else {
          setPendingListings([]);
        }
      } catch {
        setPendingListings([]);
      }
    } catch (error) {
      console.error('Failed to load dashboard data:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleApproveListing = async (id: string) => {
    try {
      await api.approveListing(id);
      setPendingListings((prev) => prev.filter((l) => l.id !== id));
    } catch (error) {
      console.error('Failed to approve listing:', error);
    }
  };

  const handleRejectListing = async (id: string) => {
    const reason = prompt('Enter rejection reason:');
    if (reason) {
      try {
        await api.rejectListing(id, reason);
        setPendingListings((prev) => prev.filter((l) => l.id !== id));
      } catch (error) {
        console.error('Failed to reject listing:', error);
      }
    }
  };

  if (loading) {
    return (
      <div className="flex h-full items-center justify-center">
        <div className="h-8 w-8 animate-spin rounded-full border-4 border-primary-500 border-t-transparent" />
      </div>
    );
  }

  return (
    <div>
      <Header title="Dashboard" />

      <div className="p-6">
        {/* Stats Grid */}
        <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-4">
          <StatsCard
            title="Total Users"
            value={stats?.totalUsers || 0}
            icon={<UsersIcon className="h-6 w-6" />}
            change={{ value: 12, type: 'increase' }}
            description="vs last month"
          />
          <StatsCard
            title="Active Listings"
            value={stats?.activeListings || 0}
            icon={<ShoppingBagIcon className="h-6 w-6" />}
            change={{ value: 8, type: 'increase' }}
            description="vs last month"
          />
          <StatsCard
            title="Transactions"
            value={stats?.totalTransactions || 0}
            icon={<CurrencyDollarIcon className="h-6 w-6" />}
            change={{ value: 15, type: 'increase' }}
            description="vs last month"
          />
          <StatsCard
            title="Pending Reports"
            value={stats?.pendingReports || 0}
            icon={<FlagIcon className="h-6 w-6" />}
          />
        </div>

        {/* Quick Stats */}
        <div className="mt-6 grid grid-cols-1 gap-6 lg:grid-cols-2">
          {/* Pending Listings */}
          <Card>
            <CardHeader>
              <div className="flex items-center justify-between">
                <CardTitle>Pending Listings</CardTitle>
                <Badge variant="warning">{stats?.pendingListings || 0} pending</Badge>
              </div>
            </CardHeader>
            <CardContent className="p-0">
              {pendingListings.length > 0 ? (
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead className="w-[35%]">Item</TableHead>
                      <TableHead className="w-[20%]">Seller</TableHead>
                      <TableHead className="w-[15%]">Price</TableHead>
                      <TableHead className="w-[30%]">Actions</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {pendingListings.map((listing) => (
                      <TableRow key={listing.id}>
                        <TableCell>
                          <div className="flex items-center min-w-0">
                            {listing.imageUrls?.[0] && (
                              <img
                                src={listing.imageUrls[0]}
                                alt={listing.title}
                                className="mr-3 h-10 w-10 shrink-0 rounded-md object-cover"
                              />
                            )}
                            <span className="font-medium truncate" title={listing.title}>{listing.title}</span>
                          </div>
                        </TableCell>
                        <TableCell>{listing.seller?.displayName || 'Unknown'}</TableCell>
                        <TableCell>UGX {listing.price.toLocaleString()}</TableCell>
                        <TableCell>
                          <div className="flex gap-2">
                            <Button
                              size="sm"
                              onClick={() => handleApproveListing(listing.id)}
                            >
                              <CheckCircleIcon className="mr-1 h-4 w-4" />
                              Approve
                            </Button>
                            <Button
                              size="sm"
                              variant="danger"
                              onClick={() => handleRejectListing(listing.id)}
                            >
                              Reject
                            </Button>
                          </div>
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              ) : (
                <div className="flex flex-col items-center justify-center py-12 text-gray-500">
                  <ClockIcon className="h-12 w-12 mb-3" />
                  <p>No pending listings</p>
                </div>
              )}
            </CardContent>
          </Card>

          {/* Recent Activity */}
          <Card>
            <CardHeader>
              <CardTitle>Recent Activity</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="space-y-4">
                {[
                  { action: 'New user registered', user: 'Sarah K.', time: '5 min ago' },
                  { action: 'Listing approved', user: 'Admin', time: '12 min ago' },
                  { action: 'Report resolved', user: 'Admin', time: '1 hour ago' },
                  { action: 'New listing created', user: 'John M.', time: '2 hours ago' },
                  { action: 'User suspended', user: 'Admin', time: '3 hours ago' },
                ].map((activity, index) => (
                  <div key={index} className="flex items-center justify-between">
                    <div>
                      <p className="text-sm font-medium text-gray-900">
                        {activity.action}
                      </p>
                      <p className="text-xs text-gray-500">by {activity.user}</p>
                    </div>
                    <span className="text-xs text-gray-400">{activity.time}</span>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  );
}
