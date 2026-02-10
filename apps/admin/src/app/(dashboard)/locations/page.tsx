'use client';

import React, { useState, useEffect } from 'react';
import { Header } from '@/components/layout/Header';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/Card';
import { Badge } from '@/components/ui/Badge';
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
  MapPinIcon,
  PlusIcon,
  PencilIcon,
  TrashIcon,
  ChevronDownIcon,
  ChevronRightIcon,
  BuildingOfficeIcon,
} from '@heroicons/react/24/outline';
import { api } from '@/lib/api';
import { ConfirmDialog } from '@/components/ui/ConfirmDialog';
import type { City } from '@/types';

const mockCities: City[] = [
  {
    id: '1',
    name: 'Kampala',
    isActive: true,
    sortOrder: 1,
    divisions: [
      { id: '1-1', cityId: '1', name: 'Central Division', isActive: true, sortOrder: 1 },
      { id: '1-2', cityId: '1', name: 'Kawempe Division', isActive: true, sortOrder: 2 },
      { id: '1-3', cityId: '1', name: 'Makindye Division', isActive: true, sortOrder: 3 },
      { id: '1-4', cityId: '1', name: 'Nakawa Division', isActive: true, sortOrder: 4 },
      { id: '1-5', cityId: '1', name: 'Rubaga Division', isActive: true, sortOrder: 5 },
      { id: '1-6', cityId: '1', name: 'Bugolobi', isActive: true, sortOrder: 6 },
      { id: '1-7', cityId: '1', name: 'Kololo', isActive: true, sortOrder: 7 },
      { id: '1-8', cityId: '1', name: 'Ntinda', isActive: true, sortOrder: 8 },
      { id: '1-9', cityId: '1', name: 'Naalya', isActive: true, sortOrder: 9 },
      { id: '1-10', cityId: '1', name: 'Muyenga', isActive: true, sortOrder: 10 },
    ],
  },
  {
    id: '2',
    name: 'Entebbe',
    isActive: true,
    sortOrder: 2,
    divisions: [
      { id: '2-1', cityId: '2', name: 'Entebbe Town', isActive: true, sortOrder: 1 },
      { id: '2-2', cityId: '2', name: 'Katabi', isActive: true, sortOrder: 2 },
      { id: '2-3', cityId: '2', name: 'Ssisa', isActive: true, sortOrder: 3 },
      { id: '2-4', cityId: '2', name: 'Abayita Ababiri', isActive: true, sortOrder: 4 },
    ],
  },
];

export default function LocationsPage() {
  const [cities, setCities] = useState<City[]>([]);
  const [loading, setLoading] = useState(true);
  const [expandedCities, setExpandedCities] = useState<Set<string>>(new Set(['1']));
  const [deleteTarget, setDeleteTarget] = useState<{ id: string; name: string } | null>(null);

  useEffect(() => {
    loadLocations();
  }, []);

  const loadLocations = async () => {
    setLoading(true);
    try {
      const data = await api.getLocations();
      if (Array.isArray(data)) {
        setCities(data);
      } else {
        // Fall back to mock data if API returns unexpected format
        setCities(mockCities);
      }
    } catch (error) {
      console.error('Failed to load locations:', error);
      // Fall back to mock data on error
      setCities(mockCities);
    } finally {
      setLoading(false);
    }
  };

  const toggleCity = (id: string) => {
    setExpandedCities((prev) => {
      const next = new Set(prev);
      if (next.has(id)) {
        next.delete(id);
      } else {
        next.add(id);
      }
      return next;
    });
  };

  const handleEditCity = (city: City) => {
    console.log('Edit city:', city);
    // TODO: Open edit modal
  };

  const handleDeleteCity = (city: City) => {
    setDeleteTarget({ id: city.id, name: city.name });
  };

  const handleConfirmDelete = async () => {
    if (!deleteTarget) return;
    console.log('Delete city:', deleteTarget.id);
    // TODO: Call API when available
    setDeleteTarget(null);
  };

  const handleAddCity = () => {
    console.log('Add new city');
    // TODO: Open add modal
  };

  const handleAddDivision = (city: City) => {
    console.log('Add division to city:', city.name);
    // TODO: Open add modal
  };

  const totalDivisions = cities.reduce((count, city) => count + (city.divisions?.length || 0), 0);

  return (
    <div>
      <Header title="Locations" />

      <div className="p-6">
        {/* Stats */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
          <Card>
            <CardContent className="py-4">
              <div className="flex items-center gap-3">
                <div className="p-2 bg-blue-100 rounded-lg">
                  <BuildingOfficeIcon className="h-6 w-6 text-blue-600" />
                </div>
                <div>
                  <p className="text-2xl font-bold">{cities.length}</p>
                  <p className="text-sm text-gray-500">Cities</p>
                </div>
              </div>
            </CardContent>
          </Card>
          <Card>
            <CardContent className="py-4">
              <div className="flex items-center gap-3">
                <div className="p-2 bg-green-100 rounded-lg">
                  <MapPinIcon className="h-6 w-6 text-green-600" />
                </div>
                <div>
                  <p className="text-2xl font-bold">{totalDivisions}</p>
                  <p className="text-sm text-gray-500">Divisions / Areas</p>
                </div>
              </div>
            </CardContent>
          </Card>
          <Card>
            <CardContent className="py-4">
              <div className="flex items-center gap-3">
                <div className="p-2 bg-orange-100 rounded-lg">
                  <MapPinIcon className="h-6 w-6 text-orange-600" />
                </div>
                <div>
                  <p className="text-2xl font-bold">
                    {cities.filter((c) => c.isActive).length}
                  </p>
                  <p className="text-sm text-gray-500">Active Cities</p>
                </div>
              </div>
            </CardContent>
          </Card>
        </div>

        {/* Locations Table */}
        <Card>
          <CardHeader className="flex flex-row items-center justify-between">
            <CardTitle>Cities & Divisions</CardTitle>
            <Button onClick={handleAddCity}>
              <PlusIcon className="h-4 w-4 mr-2" />
              Add City
            </Button>
          </CardHeader>
          <CardContent className="p-0">
            {loading ? (
              <div className="flex items-center justify-center py-12">
                <div className="h-8 w-8 animate-spin rounded-full border-4 border-blue-600 border-t-transparent" />
              </div>
            ) : (
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead className="w-10"></TableHead>
                    <TableHead>Name</TableHead>
                    <TableHead>Divisions</TableHead>
                    <TableHead>Status</TableHead>
                    <TableHead>Actions</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {cities.map((city) => (
                    <React.Fragment key={city.id}>
                      <TableRow className="bg-gray-50">
                        <TableCell>
                          <button
                            onClick={() => toggleCity(city.id)}
                            className="p-1 hover:bg-gray-200 rounded"
                          >
                            {expandedCities.has(city.id) ? (
                              <ChevronDownIcon className="h-4 w-4" />
                            ) : (
                              <ChevronRightIcon className="h-4 w-4" />
                            )}
                          </button>
                        </TableCell>
                        <TableCell>
                          <div className="flex items-center gap-2">
                            <BuildingOfficeIcon className="h-5 w-5 text-blue-600" />
                            <span className="font-medium">{city.name}</span>
                          </div>
                        </TableCell>
                        <TableCell>{city.divisions?.length || 0}</TableCell>
                        <TableCell>
                          {city.isActive ? (
                            <Badge variant="success">Active</Badge>
                          ) : (
                            <Badge variant="danger">Inactive</Badge>
                          )}
                        </TableCell>
                        <TableCell>
                          <div className="flex gap-1">
                            <Button
                              size="sm"
                              variant="ghost"
                              title="Add Division"
                              onClick={() => handleAddDivision(city)}
                            >
                              <PlusIcon className="h-4 w-4 text-green-600" />
                            </Button>
                            <Button
                              size="sm"
                              variant="ghost"
                              title="Edit"
                              onClick={() => handleEditCity(city)}
                            >
                              <PencilIcon className="h-4 w-4 text-blue-600" />
                            </Button>
                            <Button
                              size="sm"
                              variant="ghost"
                              title="Delete"
                              onClick={() => handleDeleteCity(city)}
                            >
                              <TrashIcon className="h-4 w-4 text-red-600" />
                            </Button>
                          </div>
                        </TableCell>
                      </TableRow>
                      {expandedCities.has(city.id) && city.divisions && city.divisions.map((division) => (
                        <TableRow key={division.id}>
                          <TableCell></TableCell>
                          <TableCell>
                            <div className="flex items-center gap-2 pl-6">
                              <MapPinIcon className="h-4 w-4 text-gray-400" />
                              <span>{division.name}</span>
                            </div>
                          </TableCell>
                          <TableCell></TableCell>
                          <TableCell>
                            {division.isActive ? (
                              <Badge variant="success">Active</Badge>
                            ) : (
                              <Badge variant="danger">Inactive</Badge>
                            )}
                          </TableCell>
                          <TableCell>
                            <div className="flex gap-1">
                              <Button size="sm" variant="ghost" title="Edit">
                                <PencilIcon className="h-4 w-4 text-blue-600" />
                              </Button>
                              <Button size="sm" variant="ghost" title="Delete">
                                <TrashIcon className="h-4 w-4 text-red-600" />
                              </Button>
                            </div>
                          </TableCell>
                        </TableRow>
                      ))}
                    </React.Fragment>
                  ))}
                </TableBody>
              </Table>
            )}
          </CardContent>
        </Card>

        {/* Delete Confirmation */}
        <ConfirmDialog
          isOpen={!!deleteTarget}
          onClose={() => setDeleteTarget(null)}
          onConfirm={handleConfirmDelete}
          title="Delete City?"
          message={`Are you sure you want to delete "${deleteTarget?.name}"? This will also delete all divisions. This action cannot be undone.`}
        />

        {/* Info */}
        <div className="mt-4 p-4 bg-blue-50 rounded-lg text-sm text-blue-700">
          <p className="font-medium">Location Coverage</p>
          <p className="mt-1">
            Currently serving Kampala and Entebbe. More cities will be added based on demand.
          </p>
        </div>
      </div>
    </div>
  );
}
