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
  CheckCircleIcon,
  XCircleIcon,
  EyeIcon,
} from '@heroicons/react/24/outline';
import { api } from '@/lib/api';
import type { Report, ReportStatus } from '@/types';
import { format } from 'date-fns';

const statuses: ReportStatus[] = ['PENDING', 'INVESTIGATING', 'RESOLVED', 'DISMISSED'];

export default function ReportsPage() {
  const [reports, setReports] = useState<Report[]>([]);
  const [loading, setLoading] = useState(true);
  const [statusFilter, setStatusFilter] = useState<string>('');
  const [page, setPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);

  useEffect(() => {
    loadReports();
  }, [page, statusFilter]);

  const loadReports = async () => {
    setLoading(true);
    try {
      const response = await api.getReports({
        page,
        limit: 10,
        status: statusFilter || undefined,
      });

      if (response && !Array.isArray(response) && Array.isArray(response.data)) {
        setReports(response.data);
        setTotalPages(response.totalPages || 1);
      } else if (Array.isArray(response)) {
        setReports(response);
      } else {
        // Mock data for demo
        setReports([
          {
            id: '1',
            reporterId: 'user1',
            reportedUserId: 'user2',
            reason: 'Spam',
            description: 'User is posting spam listings',
            status: 'PENDING',
            createdAt: new Date().toISOString(),
            updatedAt: new Date().toISOString(),
            reporter: { displayName: 'Sarah K.' } as any,
            reportedUser: { displayName: 'John M.' } as any,
          },
          {
            id: '2',
            reporterId: 'user3',
            reportedListingId: 'listing1',
            reason: 'Inappropriate Content',
            description: 'Listing contains inappropriate images',
            status: 'INVESTIGATING',
            createdAt: new Date(Date.now() - 86400000).toISOString(),
            updatedAt: new Date().toISOString(),
            reporter: { displayName: 'Mary N.' } as any,
          },
        ]);
      }
    } catch (error) {
      console.error('Failed to load reports:', error);
      setReports([]);
    } finally {
      setLoading(false);
    }
  };

  const handleResolve = async (id: string) => {
    const resolution = prompt('Enter resolution:');
    if (resolution) {
      try {
        await api.resolveReport(id, resolution);
        loadReports();
      } catch (error) {
        console.error('Failed to resolve report:', error);
      }
    }
  };

  const handleDismiss = async (id: string) => {
    if (confirm('Are you sure you want to dismiss this report?')) {
      try {
        await api.dismissReport(id);
        loadReports();
      } catch (error) {
        console.error('Failed to dismiss report:', error);
      }
    }
  };

  return (
    <div>
      <Header title="Reports" />

      <div className="p-6">
        {/* Filters */}
        <Card className="mb-6">
          <CardContent className="py-4">
            <div className="flex flex-wrap items-center gap-4">
              {/* Status Filter */}
              <select
                value={statusFilter}
                onChange={(e) => setStatusFilter(e.target.value)}
                className="h-9 rounded-md border border-gray-300 px-3 text-sm focus:border-primary-500 focus:outline-none focus:ring-1 focus:ring-primary-500"
              >
                <option value="">All Statuses</option>
                {statuses.map((status) => (
                  <option key={status} value={status}>
                    {status}
                  </option>
                ))}
              </select>
            </div>
          </CardContent>
        </Card>

        {/* Reports Table */}
        <Card>
          <CardContent className="p-0">
            {loading ? (
              <div className="flex items-center justify-center py-12">
                <div className="h-8 w-8 animate-spin rounded-full border-4 border-primary-500 border-t-transparent" />
              </div>
            ) : (
              <>
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>Reporter</TableHead>
                      <TableHead>Reported</TableHead>
                      <TableHead>Reason</TableHead>
                      <TableHead>Status</TableHead>
                      <TableHead>Date</TableHead>
                      <TableHead>Actions</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {reports.length > 0 ? (
                      reports.map((report) => (
                        <TableRow key={report.id}>
                          <TableCell>
                            {report.reporter?.displayName || 'Unknown'}
                          </TableCell>
                          <TableCell>
                            {report.reportedUserId ? (
                              <div>
                                <p className="font-medium">
                                  {report.reportedUser?.displayName || 'User'}
                                </p>
                                <p className="text-xs text-gray-500">User Report</p>
                              </div>
                            ) : (
                              <div>
                                <p className="font-medium">Listing</p>
                                <p className="text-xs text-gray-500">
                                  ID: {report.reportedListingId}
                                </p>
                              </div>
                            )}
                          </TableCell>
                          <TableCell>
                            <div>
                              <p className="font-medium">{report.reason}</p>
                              {report.description && (
                                <p className="text-xs text-gray-500 max-w-xs truncate">
                                  {report.description}
                                </p>
                              )}
                            </div>
                          </TableCell>
                          <TableCell>
                            <Badge variant={getStatusVariant(report.status)}>
                              {report.status}
                            </Badge>
                          </TableCell>
                          <TableCell>
                            {format(new Date(report.createdAt), 'MMM d, yyyy')}
                          </TableCell>
                          <TableCell>
                            <div className="flex gap-1">
                              <Button size="sm" variant="ghost" title="View Details">
                                <EyeIcon className="h-4 w-4" />
                              </Button>
                              {(report.status === 'PENDING' ||
                                report.status === 'INVESTIGATING') && (
                                <>
                                  <Button
                                    size="sm"
                                    variant="ghost"
                                    title="Resolve"
                                    onClick={() => handleResolve(report.id)}
                                  >
                                    <CheckCircleIcon className="h-4 w-4 text-green-600" />
                                  </Button>
                                  <Button
                                    size="sm"
                                    variant="ghost"
                                    title="Dismiss"
                                    onClick={() => handleDismiss(report.id)}
                                  >
                                    <XCircleIcon className="h-4 w-4 text-gray-600" />
                                  </Button>
                                </>
                              )}
                            </div>
                          </TableCell>
                        </TableRow>
                      ))
                    ) : (
                      <TableRow>
                        <TableCell className="text-center py-12 text-gray-500" colSpan={6}>
                          No reports found
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
