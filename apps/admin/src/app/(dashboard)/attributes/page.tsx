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
  TagIcon,
  PlusIcon,
  PencilIcon,
  TrashIcon,
  ChevronDownIcon,
  ChevronRightIcon,
} from '@heroicons/react/24/outline';
import { Modal, ModalFooter } from '@/components/ui/Modal';
import { api } from '@/lib/api';
import type { AttributeDefinition, AttributeType } from '@/types';

const mockAttributes: AttributeDefinition[] = [
  {
    id: '1',
    name: 'Clothing Size',
    slug: 'size-clothing',
    type: 'SINGLE_SELECT',
    isRequired: true,
    sortOrder: 1,
    isActive: true,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
    values: [
      { id: '1-1', attributeId: '1', value: 'XS', sortOrder: 1, isActive: true },
      { id: '1-2', attributeId: '1', value: 'S', sortOrder: 2, isActive: true },
      { id: '1-3', attributeId: '1', value: 'M', sortOrder: 3, isActive: true },
      { id: '1-4', attributeId: '1', value: 'L', sortOrder: 4, isActive: true },
      { id: '1-5', attributeId: '1', value: 'XL', sortOrder: 5, isActive: true },
      { id: '1-6', attributeId: '1', value: 'XXL', sortOrder: 6, isActive: true },
    ],
  },
  {
    id: '2',
    name: 'Shoe Size (EU)',
    slug: 'size-shoes-eu',
    type: 'SINGLE_SELECT',
    isRequired: true,
    sortOrder: 2,
    isActive: true,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
    values: [
      { id: '2-1', attributeId: '2', value: '36', sortOrder: 1, isActive: true },
      { id: '2-2', attributeId: '2', value: '37', sortOrder: 2, isActive: true },
      { id: '2-3', attributeId: '2', value: '38', sortOrder: 3, isActive: true },
      { id: '2-4', attributeId: '2', value: '39', sortOrder: 4, isActive: true },
      { id: '2-5', attributeId: '2', value: '40', sortOrder: 5, isActive: true },
    ],
  },
  {
    id: '3',
    name: 'Fashion Brand',
    slug: 'brand-fashion',
    type: 'SINGLE_SELECT',
    isRequired: false,
    sortOrder: 3,
    isActive: true,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
    values: [
      { id: '3-1', attributeId: '3', value: 'Zara', sortOrder: 1, isActive: true },
      { id: '3-2', attributeId: '3', value: 'H&M', sortOrder: 2, isActive: true },
      { id: '3-3', attributeId: '3', value: 'Nike', sortOrder: 3, isActive: true },
      { id: '3-4', attributeId: '3', value: 'Adidas', sortOrder: 4, isActive: true },
      { id: '3-5', attributeId: '3', value: 'Other', sortOrder: 5, isActive: true },
    ],
  },
  {
    id: '4',
    name: 'Color',
    slug: 'color',
    type: 'MULTI_SELECT',
    isRequired: false,
    sortOrder: 4,
    isActive: true,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
    values: [
      { id: '4-1', attributeId: '4', value: 'Black', sortOrder: 1, isActive: true, metadata: { hex: '#000000' } },
      { id: '4-2', attributeId: '4', value: 'White', sortOrder: 2, isActive: true, metadata: { hex: '#FFFFFF' } },
      { id: '4-3', attributeId: '4', value: 'Red', sortOrder: 3, isActive: true, metadata: { hex: '#FF0000' } },
      { id: '4-4', attributeId: '4', value: 'Blue', sortOrder: 4, isActive: true, metadata: { hex: '#0000FF' } },
    ],
  },
];

const typeLabels: Record<AttributeType, string> = {
  SINGLE_SELECT: 'Single Select',
  MULTI_SELECT: 'Multi Select',
  TEXT: 'Text Input',
  NUMBER: 'Number Input',
};

const typeColors: Record<AttributeType, 'default' | 'success' | 'warning' | 'danger'> = {
  SINGLE_SELECT: 'default',
  MULTI_SELECT: 'success',
  TEXT: 'warning',
  NUMBER: 'danger',
};

interface EditableAttribute {
  id: string;
  name: string;
  slug: string;
  type: AttributeType;
  isRequired: boolean;
  isActive: boolean;
  sortOrder: number;
  values: string; // Comma-separated for editing
}

const emptyAttribute: EditableAttribute = {
  id: '',
  name: '',
  slug: '',
  type: 'SINGLE_SELECT',
  isRequired: false,
  isActive: true,
  sortOrder: 0,
  values: '',
};

export default function AttributesPage() {
  const [attributes, setAttributes] = useState<AttributeDefinition[]>([]);
  const [loading, setLoading] = useState(true);
  const [expandedRows, setExpandedRows] = useState<Set<string>>(new Set());
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [selectedAttribute, setSelectedAttribute] = useState<EditableAttribute | null>(null);
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    loadAttributes();
  }, []);

  const loadAttributes = async () => {
    setLoading(true);
    try {
      const response = await api.getAttributes();
      if (Array.isArray(response)) {
        setAttributes(response);
      } else {
        setAttributes(mockAttributes);
      }
    } catch (error) {
      console.error('Failed to load attributes:', error);
      setAttributes(mockAttributes);
    } finally {
      setLoading(false);
    }
  };

  const toggleRow = (id: string) => {
    setExpandedRows((prev) => {
      const next = new Set(prev);
      if (next.has(id)) {
        next.delete(id);
      } else {
        next.add(id);
      }
      return next;
    });
  };

  const handleEdit = (attribute: AttributeDefinition) => {
    console.log('handleEdit called - opening modal for:', attribute.name);
    setSelectedAttribute({
      id: attribute.id,
      name: attribute.name,
      slug: attribute.slug,
      type: attribute.type,
      isRequired: attribute.isRequired,
      isActive: attribute.isActive,
      sortOrder: attribute.sortOrder,
      values: attribute.values?.map(v => v.value).join(', ') || '',
    });
    setIsModalOpen(true);
  };

  const handleDelete = async (attribute: AttributeDefinition) => {
    if (confirm(`Are you sure you want to delete "${attribute.name}"? This will remove it from all linked categories.`)) {
      try {
        await api.deleteAttribute(attribute.id);
        await loadAttributes();
      } catch (error: any) {
        alert(error.message || 'Failed to delete attribute');
      }
    }
  };

  const handleAddAttribute = () => {
    console.log('handleAddAttribute called - opening modal');
    setSelectedAttribute({ ...emptyAttribute });
    setIsModalOpen(true);
  };

  const handleSave = async () => {
    if (!selectedAttribute || !selectedAttribute.name.trim()) {
      alert('Attribute name is required');
      return;
    }

    const slug = selectedAttribute.slug.trim() ||
      selectedAttribute.name.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)/g, '');

    // Parse values from comma-separated string into proper format
    const valuesArray = selectedAttribute.values
      .split(',')
      .map(v => v.trim())
      .filter(v => v.length > 0)
      .map((v, index) => ({ value: v, sortOrder: index + 1 }));

    setSaving(true);
    try {
      if (selectedAttribute.id) {
        // Update existing (type cannot be changed)
        await api.updateAttribute(selectedAttribute.id, {
          name: selectedAttribute.name,
          isRequired: selectedAttribute.isRequired,
          isActive: selectedAttribute.isActive,
        });
      } else {
        // Create new
        await api.createAttribute({
          name: selectedAttribute.name,
          slug,
          type: selectedAttribute.type,
          isRequired: selectedAttribute.isRequired,
          values: valuesArray,
        });
      }
      setIsModalOpen(false);
      setSelectedAttribute(null);
      await loadAttributes();
    } catch (error: any) {
      alert(error.message || 'Failed to save attribute');
    } finally {
      setSaving(false);
    }
  };

  const closeModal = () => {
    setIsModalOpen(false);
    setSelectedAttribute(null);
  };

  return (
    <div>
      <Header title="Attributes" />

      <div className="p-6">
        {/* Stats */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6">
          <Card>
            <CardContent className="py-4">
              <div className="flex items-center gap-3">
                <div className="p-2 bg-blue-100 rounded-lg">
                  <TagIcon className="h-6 w-6 text-blue-600" />
                </div>
                <div>
                  <p className="text-2xl font-bold">{attributes.length}</p>
                  <p className="text-sm text-gray-500">Attributes</p>
                </div>
              </div>
            </CardContent>
          </Card>
          <Card>
            <CardContent className="py-4">
              <div className="flex items-center gap-3">
                <div className="p-2 bg-green-100 rounded-lg">
                  <TagIcon className="h-6 w-6 text-green-600" />
                </div>
                <div>
                  <p className="text-2xl font-bold">
                    {attributes.reduce((count, attr) => count + (attr.values?.length || 0), 0)}
                  </p>
                  <p className="text-sm text-gray-500">Total Values</p>
                </div>
              </div>
            </CardContent>
          </Card>
          <Card>
            <CardContent className="py-4">
              <div className="flex items-center gap-3">
                <div className="p-2 bg-orange-100 rounded-lg">
                  <TagIcon className="h-6 w-6 text-orange-600" />
                </div>
                <div>
                  <p className="text-2xl font-bold">
                    {attributes.filter((a) => a.isRequired).length}
                  </p>
                  <p className="text-sm text-gray-500">Required</p>
                </div>
              </div>
            </CardContent>
          </Card>
          <Card>
            <CardContent className="py-4">
              <div className="flex items-center gap-3">
                <div className="p-2 bg-purple-100 rounded-lg">
                  <TagIcon className="h-6 w-6 text-purple-600" />
                </div>
                <div>
                  <p className="text-2xl font-bold">
                    {attributes.filter((a) => a.type === 'MULTI_SELECT').length}
                  </p>
                  <p className="text-sm text-gray-500">Multi-Select</p>
                </div>
              </div>
            </CardContent>
          </Card>
        </div>

        {/* Attributes Table */}
        <Card>
          <CardHeader className="flex flex-row items-center justify-between">
            <CardTitle>Attribute Definitions</CardTitle>
            <Button onClick={handleAddAttribute}>
              <PlusIcon className="h-4 w-4 mr-2" />
              Add Attribute
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
                    <TableHead>Slug</TableHead>
                    <TableHead>Type</TableHead>
                    <TableHead>Values</TableHead>
                    <TableHead>Required</TableHead>
                    <TableHead>Actions</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {attributes.map((attribute) => (
                    <React.Fragment key={attribute.id}>
                      <TableRow>
                        <TableCell>
                          <button
                            onClick={() => toggleRow(attribute.id)}
                            className="p-1 hover:bg-gray-100 rounded"
                          >
                            {expandedRows.has(attribute.id) ? (
                              <ChevronDownIcon className="h-4 w-4" />
                            ) : (
                              <ChevronRightIcon className="h-4 w-4" />
                            )}
                          </button>
                        </TableCell>
                        <TableCell className="font-medium">{attribute.name}</TableCell>
                        <TableCell className="text-gray-500">{attribute.slug}</TableCell>
                        <TableCell>
                          <Badge variant={typeColors[attribute.type]}>
                            {typeLabels[attribute.type]}
                          </Badge>
                        </TableCell>
                        <TableCell>{attribute.values?.length || 0}</TableCell>
                        <TableCell>
                          {attribute.isRequired ? (
                            <Badge variant="warning">Required</Badge>
                          ) : (
                            <span className="text-gray-400">Optional</span>
                          )}
                        </TableCell>
                        <TableCell>
                          <div className="flex gap-1">
                            <Button
                              size="sm"
                              variant="ghost"
                              title="Edit"
                              onClick={() => handleEdit(attribute)}
                            >
                              <PencilIcon className="h-4 w-4 text-blue-600" />
                            </Button>
                            <Button
                              size="sm"
                              variant="ghost"
                              title="Delete"
                              onClick={() => handleDelete(attribute)}
                            >
                              <TrashIcon className="h-4 w-4 text-red-600" />
                            </Button>
                          </div>
                        </TableCell>
                      </TableRow>
                      {expandedRows.has(attribute.id) && attribute.values && (
                        <TableRow>
                          <TableCell colSpan={7} className="bg-gray-50">
                            <div className="py-2 px-4">
                              <p className="text-sm font-medium mb-2">Values:</p>
                              <div className="flex flex-wrap gap-2">
                                {attribute.values.map((value) => (
                                  <Badge key={value.id} variant="default">
                                    {value.value}
                                  </Badge>
                                ))}
                              </div>
                            </div>
                          </TableCell>
                        </TableRow>
                      )}
                    </React.Fragment>
                  ))}
                </TableBody>
              </Table>
            )}
          </CardContent>
        </Card>
      </div>

      {/* Create/Edit Modal */}
      <Modal
        isOpen={isModalOpen}
        onClose={closeModal}
        title={selectedAttribute?.id ? 'Edit Attribute' : 'Add Attribute'}
        size="md"
      >
        {selectedAttribute && (
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Name *</label>
              <input
                type="text"
                value={selectedAttribute.name}
                onChange={(e) => setSelectedAttribute({ ...selectedAttribute, name: e.target.value })}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                placeholder="e.g. Clothing Size, Color, Brand"
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Slug</label>
              <input
                type="text"
                value={selectedAttribute.slug || selectedAttribute.name.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)/g, '')}
                onChange={(e) => setSelectedAttribute({ ...selectedAttribute, slug: e.target.value })}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                placeholder="auto-generated-from-name"
                disabled={!!selectedAttribute.id}
              />
              {!selectedAttribute.id && (
                <p className="text-xs text-gray-400 mt-1">Auto-generated from name if left empty</p>
              )}
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Type *</label>
              <select
                value={selectedAttribute.type}
                onChange={(e) => setSelectedAttribute({ ...selectedAttribute, type: e.target.value as AttributeType })}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                disabled={!!selectedAttribute.id}
              >
                <option value="SINGLE_SELECT">Single Select (dropdown)</option>
                <option value="MULTI_SELECT">Multi Select (checkboxes)</option>
                <option value="TEXT">Text Input</option>
                <option value="NUMBER">Number Input</option>
              </select>
              {selectedAttribute.id && (
                <p className="text-xs text-gray-400 mt-1">Type cannot be changed after creation</p>
              )}
            </div>

            {!selectedAttribute.id && (selectedAttribute.type === 'SINGLE_SELECT' || selectedAttribute.type === 'MULTI_SELECT') && (
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Values (comma-separated)</label>
                <textarea
                  value={selectedAttribute.values}
                  onChange={(e) => setSelectedAttribute({ ...selectedAttribute, values: e.target.value })}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                  rows={3}
                  placeholder="e.g. XS, S, M, L, XL, XXL"
                />
                <p className="text-xs text-gray-400 mt-1">
                  Enter values separated by commas. You can add more values later.
                </p>
              </div>
            )}

            <div className="flex items-center gap-4">
              <div className="flex items-center gap-2">
                <input
                  type="checkbox"
                  id="isRequired"
                  checked={selectedAttribute.isRequired}
                  onChange={(e) => setSelectedAttribute({ ...selectedAttribute, isRequired: e.target.checked })}
                  className="h-4 w-4 text-blue-600 rounded border-gray-300"
                />
                <label htmlFor="isRequired" className="text-sm text-gray-700">Required</label>
              </div>
              <div className="flex items-center gap-2">
                <input
                  type="checkbox"
                  id="isActive"
                  checked={selectedAttribute.isActive}
                  onChange={(e) => setSelectedAttribute({ ...selectedAttribute, isActive: e.target.checked })}
                  className="h-4 w-4 text-blue-600 rounded border-gray-300"
                />
                <label htmlFor="isActive" className="text-sm text-gray-700">Active</label>
              </div>
            </div>

            <ModalFooter>
              <Button variant="secondary" onClick={closeModal} disabled={saving}>
                Cancel
              </Button>
              <Button onClick={handleSave} disabled={saving}>
                {saving ? 'Saving...' : selectedAttribute.id ? 'Update' : 'Create'}
              </Button>
            </ModalFooter>
          </div>
        )}
      </Modal>
    </div>
  );
}
