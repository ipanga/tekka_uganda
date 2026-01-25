'use client';

import { useState, useEffect } from 'react';
import {
  UsersIcon,
  ShoppingBagIcon,
  CurrencyDollarIcon,
  ArrowTrendingUpIcon,
  ArrowTrendingDownIcon,
} from '@heroicons/react/24/outline';
import { api } from '@/lib/api';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/Card';
import { StatsCard } from '@/components/dashboard/StatsCard';

// Mock data for charts (in production, use recharts with real data)
const MOCK_USER_GROWTH = [
  { date: 'Jan 1', value: 120 },
  { date: 'Jan 8', value: 145 },
  { date: 'Jan 15', value: 180 },
  { date: 'Jan 22', value: 210 },
  { date: 'Jan 29', value: 265 },
  { date: 'Feb 5', value: 320 },
  { date: 'Feb 12', value: 390 },
];

const MOCK_LISTING_GROWTH = [
  { date: 'Jan 1', value: 85 },
  { date: 'Jan 8', value: 120 },
  { date: 'Jan 15', value: 165 },
  { date: 'Jan 22', value: 195 },
  { date: 'Jan 29', value: 240 },
  { date: 'Feb 5', value: 290 },
  { date: 'Feb 12', value: 350 },
];

const MOCK_REVENUE_BY_CATEGORY = [
  { category: 'Dresses', amount: 2450000, percentage: 28 },
  { category: 'Traditional Wear', amount: 1890000, percentage: 22 },
  { category: 'Shoes', amount: 1560000, percentage: 18 },
  { category: 'Tops', amount: 1200000, percentage: 14 },
  { category: 'Bags', amount: 850000, percentage: 10 },
  { category: 'Accessories', amount: 700000, percentage: 8 },
];

const MOCK_TOP_SELLERS = [
  { name: 'Sarah Kato', sales: 45, revenue: 4500000 },
  { name: 'Grace Nambi', sales: 38, revenue: 3200000 },
  { name: 'Mary Ainomugisha', sales: 32, revenue: 2800000 },
  { name: 'Ruth Namutebi', sales: 28, revenue: 2100000 },
  { name: 'Joan Nakamya', sales: 25, revenue: 1900000 },
];

export default function AnalyticsPage() {
  const [period, setPeriod] = useState<'day' | 'week' | 'month' | 'year'>('month');
  const [loading, setLoading] = useState(true);
  const [stats, setStats] = useState({
    totalUsers: 1250,
    newUsers: 156,
    userGrowth: 12.5,
    totalListings: 3420,
    newListings: 234,
    listingGrowth: 8.3,
    totalTransactions: 856,
    completedTransactions: 745,
    transactionGrowth: 15.2,
    totalRevenue: 125000000,
    revenueGrowth: 22.4,
  });

  useEffect(() => {
    loadAnalytics();
  }, [period]);

  const loadAnalytics = async () => {
    try {
      setLoading(true);
      // In production, fetch real data from API
      // const overview = await api.getAnalyticsOverview(period);
      // setStats(overview);

      // Simulate API delay
      await new Promise(resolve => setTimeout(resolve, 500));
    } catch (error) {
      console.error('Error loading analytics:', error);
    } finally {
      setLoading(false);
    }
  };

  const formatPrice = (amount: number) => {
    if (amount >= 1000000) {
      return `UGX ${(amount / 1000000).toFixed(1)}M`;
    }
    if (amount >= 1000) {
      return `UGX ${(amount / 1000).toFixed(0)}K`;
    }
    return new Intl.NumberFormat('en-UG', {
      style: 'currency',
      currency: 'UGX',
      minimumFractionDigits: 0,
    }).format(amount);
  };

  const formatNumber = (num: number) => {
    return new Intl.NumberFormat('en-UG').format(num);
  };

  // Simple bar chart component
  const SimpleBarChart = ({ data, color }: { data: { date: string; value: number }[]; color: string }) => {
    const maxValue = Math.max(...data.map(d => d.value));
    return (
      <div className="flex items-end gap-2 h-32">
        {data.map((item, index) => (
          <div key={index} className="flex-1 flex flex-col items-center gap-1">
            <div
              className={`w-full rounded-t ${color}`}
              style={{ height: `${(item.value / maxValue) * 100}%` }}
            />
            <span className="text-xs text-gray-500 truncate">{item.date}</span>
          </div>
        ))}
      </div>
    );
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Analytics</h1>
          <p className="text-gray-500">Platform performance and insights</p>
        </div>
        <select
          value={period}
          onChange={(e) => setPeriod(e.target.value as any)}
          className="px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-pink-500"
        >
          <option value="day">Last 24 Hours</option>
          <option value="week">Last 7 Days</option>
          <option value="month">Last 30 Days</option>
          <option value="year">Last Year</option>
        </select>
      </div>

      {loading ? (
        <div className="flex justify-center py-12">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-pink-600"></div>
        </div>
      ) : (
        <>
          {/* Key Metrics */}
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
            <StatsCard
              title="Total Users"
              value={formatNumber(stats.totalUsers)}
              change={stats.userGrowth}
              icon={UsersIcon}
              trend={stats.userGrowth >= 0 ? 'up' : 'down'}
            />
            <StatsCard
              title="Total Listings"
              value={formatNumber(stats.totalListings)}
              change={stats.listingGrowth}
              icon={ShoppingBagIcon}
              trend={stats.listingGrowth >= 0 ? 'up' : 'down'}
            />
            <StatsCard
              title="Transactions"
              value={formatNumber(stats.totalTransactions)}
              change={stats.transactionGrowth}
              icon={CurrencyDollarIcon}
              trend={stats.transactionGrowth >= 0 ? 'up' : 'down'}
            />
            <StatsCard
              title="Total Revenue"
              value={formatPrice(stats.totalRevenue)}
              change={stats.revenueGrowth}
              icon={ArrowTrendingUpIcon}
              trend={stats.revenueGrowth >= 0 ? 'up' : 'down'}
            />
          </div>

          {/* Charts Row */}
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            {/* User Growth Chart */}
            <Card>
              <CardHeader>
                <CardTitle>User Growth</CardTitle>
              </CardHeader>
              <CardContent>
                <SimpleBarChart data={MOCK_USER_GROWTH} color="bg-pink-500" />
                <div className="flex items-center justify-between mt-4 pt-4 border-t">
                  <div>
                    <p className="text-sm text-gray-500">New Users</p>
                    <p className="text-xl font-bold text-gray-900">+{stats.newUsers}</p>
                  </div>
                  <div className="flex items-center gap-1 text-green-600">
                    <ArrowTrendingUpIcon className="w-4 h-4" />
                    <span className="font-medium">{stats.userGrowth}%</span>
                  </div>
                </div>
              </CardContent>
            </Card>

            {/* Listing Growth Chart */}
            <Card>
              <CardHeader>
                <CardTitle>Listing Growth</CardTitle>
              </CardHeader>
              <CardContent>
                <SimpleBarChart data={MOCK_LISTING_GROWTH} color="bg-blue-500" />
                <div className="flex items-center justify-between mt-4 pt-4 border-t">
                  <div>
                    <p className="text-sm text-gray-500">New Listings</p>
                    <p className="text-xl font-bold text-gray-900">+{stats.newListings}</p>
                  </div>
                  <div className="flex items-center gap-1 text-green-600">
                    <ArrowTrendingUpIcon className="w-4 h-4" />
                    <span className="font-medium">{stats.listingGrowth}%</span>
                  </div>
                </div>
              </CardContent>
            </Card>
          </div>

          {/* Revenue by Category & Top Sellers */}
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            {/* Revenue by Category */}
            <Card>
              <CardHeader>
                <CardTitle>Revenue by Category</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="space-y-4">
                  {MOCK_REVENUE_BY_CATEGORY.map((item, index) => (
                    <div key={index}>
                      <div className="flex items-center justify-between mb-1">
                        <span className="text-sm font-medium text-gray-900">{item.category}</span>
                        <span className="text-sm text-gray-500">{formatPrice(item.amount)}</span>
                      </div>
                      <div className="w-full bg-gray-200 rounded-full h-2">
                        <div
                          className="bg-pink-500 h-2 rounded-full"
                          style={{ width: `${item.percentage}%` }}
                        />
                      </div>
                    </div>
                  ))}
                </div>
              </CardContent>
            </Card>

            {/* Top Sellers */}
            <Card>
              <CardHeader>
                <CardTitle>Top Sellers</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="space-y-4">
                  {MOCK_TOP_SELLERS.map((seller, index) => (
                    <div key={index} className="flex items-center gap-4">
                      <div className="flex-shrink-0 w-8 h-8 bg-gray-100 rounded-full flex items-center justify-center">
                        <span className="text-sm font-bold text-gray-600">{index + 1}</span>
                      </div>
                      <div className="flex-1 min-w-0">
                        <p className="font-medium text-gray-900 truncate">{seller.name}</p>
                        <p className="text-sm text-gray-500">{seller.sales} sales</p>
                      </div>
                      <div className="text-right">
                        <p className="font-bold text-gray-900">{formatPrice(seller.revenue)}</p>
                      </div>
                    </div>
                  ))}
                </div>
              </CardContent>
            </Card>
          </div>

          {/* Transaction Summary */}
          <Card>
            <CardHeader>
              <CardTitle>Transaction Summary</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="grid grid-cols-2 md:grid-cols-4 gap-6">
                <div className="text-center p-4 bg-green-50 rounded-lg">
                  <p className="text-3xl font-bold text-green-600">{stats.completedTransactions}</p>
                  <p className="text-sm text-green-700">Completed</p>
                </div>
                <div className="text-center p-4 bg-yellow-50 rounded-lg">
                  <p className="text-3xl font-bold text-yellow-600">
                    {stats.totalTransactions - stats.completedTransactions - 12}
                  </p>
                  <p className="text-sm text-yellow-700">Pending</p>
                </div>
                <div className="text-center p-4 bg-red-50 rounded-lg">
                  <p className="text-3xl font-bold text-red-600">12</p>
                  <p className="text-sm text-red-700">Cancelled</p>
                </div>
                <div className="text-center p-4 bg-blue-50 rounded-lg">
                  <p className="text-3xl font-bold text-blue-600">
                    {((stats.completedTransactions / stats.totalTransactions) * 100).toFixed(1)}%
                  </p>
                  <p className="text-sm text-blue-700">Success Rate</p>
                </div>
              </div>
            </CardContent>
          </Card>
        </>
      )}
    </div>
  );
}
