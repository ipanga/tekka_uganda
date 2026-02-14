'use client';

import { useState, useEffect } from 'react';
import { Header } from '@/components/layout/Header';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/Card';
import { Badge } from '@/components/ui/Badge';
import { Button } from '@/components/ui/Button';
import {
  FolderIcon,
  ChevronRightIcon,
  ChevronDownIcon,
  PlusIcon,
  PencilIcon,
  TrashIcon,
  TagIcon,
} from '@heroicons/react/24/outline';
import { Modal, ModalFooter } from '@/components/ui/Modal';
import { ConfirmDialog } from '@/components/ui/ConfirmDialog';
import { api } from '@/lib/api';
import type { Category } from '@/types';

// Temporary mock data until API is connected
const mockCategories: Category[] = [
  {
    id: '1',
    name: 'Women',
    slug: 'women',
    level: 1,
    iconName: 'woman',
    sortOrder: 1,
    isActive: true,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
    children: [
      {
        id: '1-1',
        name: 'Clothing',
        slug: 'women-clothing',
        level: 2,
        parentId: '1',
        sortOrder: 1,
        isActive: true,
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
        children: [
          { id: '1-1-1', name: 'Dresses', slug: 'women-dresses', level: 3, parentId: '1-1', sortOrder: 1, isActive: true, createdAt: new Date().toISOString(), updatedAt: new Date().toISOString() },
          { id: '1-1-2', name: 'Tops', slug: 'women-tops', level: 3, parentId: '1-1', sortOrder: 2, isActive: true, createdAt: new Date().toISOString(), updatedAt: new Date().toISOString() },
          { id: '1-1-3', name: 'Bottoms', slug: 'women-bottoms', level: 3, parentId: '1-1', sortOrder: 3, isActive: true, createdAt: new Date().toISOString(), updatedAt: new Date().toISOString() },
        ],
      },
      {
        id: '1-2',
        name: 'Shoes',
        slug: 'women-shoes',
        level: 2,
        parentId: '1',
        sortOrder: 2,
        isActive: true,
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
        children: [
          { id: '1-2-1', name: 'Heels', slug: 'women-heels', level: 3, parentId: '1-2', sortOrder: 1, isActive: true, createdAt: new Date().toISOString(), updatedAt: new Date().toISOString() },
          { id: '1-2-2', name: 'Flats', slug: 'women-flats', level: 3, parentId: '1-2', sortOrder: 2, isActive: true, createdAt: new Date().toISOString(), updatedAt: new Date().toISOString() },
        ],
      },
    ],
  },
  {
    id: '2',
    name: 'Men',
    slug: 'men',
    level: 1,
    iconName: 'man',
    sortOrder: 2,
    isActive: true,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
    children: [
      {
        id: '2-1',
        name: 'Clothing',
        slug: 'men-clothing',
        level: 2,
        parentId: '2',
        sortOrder: 1,
        isActive: true,
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
        children: [
          { id: '2-1-1', name: 'Shirts', slug: 'men-shirts', level: 3, parentId: '2-1', sortOrder: 1, isActive: true, createdAt: new Date().toISOString(), updatedAt: new Date().toISOString() },
          { id: '2-1-2', name: 'T-Shirts', slug: 'men-tshirts', level: 3, parentId: '2-1', sortOrder: 2, isActive: true, createdAt: new Date().toISOString(), updatedAt: new Date().toISOString() },
        ],
      },
    ],
  },
  {
    id: '3',
    name: 'Kids',
    slug: 'kids',
    level: 1,
    iconName: 'child',
    sortOrder: 3,
    isActive: true,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
    children: [],
  },
  {
    id: '4',
    name: 'Home',
    slug: 'home',
    level: 1,
    iconName: 'home',
    sortOrder: 4,
    isActive: true,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
    children: [],
  },
  {
    id: '5',
    name: 'Electronics',
    slug: 'electronics',
    level: 1,
    iconName: 'devices',
    sortOrder: 5,
    isActive: true,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
    children: [],
  },
];

interface CategoryTreeItemProps {
  category: Category;
  level?: number;
  onEdit: (category: Category) => void;
  onDelete: (category: Category) => void;
  onAddChild: (parent: Category) => void;
  onManageAttributes: (category: Category) => void;
}

function CategoryTreeItem({ category, level = 0, onEdit, onDelete, onAddChild, onManageAttributes }: CategoryTreeItemProps) {
  const [expanded, setExpanded] = useState(level < 2);
  const hasChildren = category.children && category.children.length > 0;
  const canHaveChildren = category.level < 3;

  return (
    <div>
      <div
        className={`flex items-center gap-2 py-2 px-3 hover:bg-gray-50 rounded-md group ${
          level > 0 ? 'ml-6' : ''
        }`}
      >
        {/* Expand/Collapse button */}
        <button
          onClick={() => setExpanded(!expanded)}
          className={`p-1 rounded hover:bg-gray-200 ${!hasChildren && 'invisible'}`}
        >
          {expanded ? (
            <ChevronDownIcon className="h-4 w-4 text-gray-500" />
          ) : (
            <ChevronRightIcon className="h-4 w-4 text-gray-500" />
          )}
        </button>

        {/* Icon */}
        <FolderIcon className={`h-5 w-5 ${category.level === 1 ? 'text-primary-500' : category.level === 2 ? 'text-green-500' : 'text-orange-500'}`} />

        {/* Name and slug */}
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-2">
            <span className="font-medium truncate">{category.name}</span>
            <span className="text-xs text-gray-400">({category.slug})</span>
          </div>
        </div>

        {/* Level badge */}
        <Badge variant={category.level === 1 ? 'default' : category.level === 2 ? 'success' : 'warning'}>
          L{category.level}
        </Badge>

        {/* Status badge */}
        {!category.isActive && <Badge variant="danger">Inactive</Badge>}

        {/* Actions */}
        <div className="flex items-center gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
          <Button size="sm" variant="ghost" title="Manage attributes" onClick={() => onManageAttributes(category)}>
            <TagIcon className="h-4 w-4 text-purple-600" />
          </Button>
          {canHaveChildren && (
            <Button size="sm" variant="ghost" title="Add child" onClick={() => onAddChild(category)}>
              <PlusIcon className="h-4 w-4 text-green-600" />
            </Button>
          )}
          <Button size="sm" variant="ghost" title="Edit" onClick={() => onEdit(category)}>
            <PencilIcon className="h-4 w-4 text-primary-500" />
          </Button>
          <Button size="sm" variant="ghost" title="Delete" onClick={() => onDelete(category)}>
            <TrashIcon className="h-4 w-4 text-red-600" />
          </Button>
        </div>
      </div>

      {/* Children */}
      {expanded && hasChildren && (
        <div className="border-l border-gray-200 ml-6">
          {category.children!.map((child) => (
            <CategoryTreeItem
              key={child.id}
              category={child}
              level={level + 1}
              onEdit={onEdit}
              onDelete={onDelete}
              onAddChild={onAddChild}
              onManageAttributes={onManageAttributes}
            />
          ))}
        </div>
      )}
    </div>
  );
}

export default function CategoriesPage() {
  const [categories, setCategories] = useState<Category[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedCategory, setSelectedCategory] = useState<Category | null>(null);
  const [isEditModalOpen, setIsEditModalOpen] = useState(false);

  // Attribute management state
  const [attrCategory, setAttrCategory] = useState<Category | null>(null);
  const [isAttrModalOpen, setIsAttrModalOpen] = useState(false);
  const [linkedAttributes, setLinkedAttributes] = useState<any[]>([]);
  const [allAttributes, setAllAttributes] = useState<any[]>([]);
  const [attrLoading, setAttrLoading] = useState(false);
  const [selectedAttrId, setSelectedAttrId] = useState('');
  const [attrRequired, setAttrRequired] = useState(false);
  const [attrSortOrder, setAttrSortOrder] = useState(0);
  const [deleteTarget, setDeleteTarget] = useState<{ id: string; name: string } | null>(null);
  const [deleteLoading, setDeleteLoading] = useState(false);
  const [unlinkTarget, setUnlinkTarget] = useState<{ attributeId: string; name: string } | null>(null);

  useEffect(() => {
    loadCategories();
  }, []);

  const loadCategories = async () => {
    setLoading(true);
    try {
      const response = await api.getCategories();
      if (Array.isArray(response)) {
        // Build tree from flat list
        const categoryMap = new Map<string, Category>();
        const roots: Category[] = [];

        // First pass: create map
        response.forEach((cat: Category) => {
          categoryMap.set(cat.id, { ...cat, children: [] });
        });

        // Second pass: build tree
        response.forEach((cat: Category) => {
          const node = categoryMap.get(cat.id)!;
          if (cat.parentId && categoryMap.has(cat.parentId)) {
            const parent = categoryMap.get(cat.parentId)!;
            parent.children = parent.children || [];
            parent.children.push(node);
          } else if (cat.level === 1) {
            roots.push(node);
          }
        });

        setCategories(roots);
      } else {
        setCategories(mockCategories);
      }
    } catch (error) {
      console.error('Failed to load categories:', error);
      setCategories(mockCategories);
    } finally {
      setLoading(false);
    }
  };

  const handleEdit = (category: Category) => {
    setSelectedCategory(category);
    setIsEditModalOpen(true);
  };

  const handleDelete = (category: Category) => {
    setDeleteTarget({ id: category.id, name: category.name });
  };

  const handleConfirmDelete = async () => {
    if (!deleteTarget) return;
    setDeleteLoading(true);
    try {
      await api.deleteCategory(deleteTarget.id);
      setDeleteTarget(null);
      await loadCategories();
    } catch (error: any) {
      alert(error.message || 'Failed to delete category');
    } finally {
      setDeleteLoading(false);
    }
  };

  const handleSave = async () => {
    if (!selectedCategory || !selectedCategory.name.trim()) {
      alert('Category name is required');
      return;
    }

    const slug = selectedCategory.slug.trim() || selectedCategory.name.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)/g, '');

    try {
      if (selectedCategory.id) {
        // Update existing
        await api.updateCategory(selectedCategory.id, {
          name: selectedCategory.name,
          iconName: selectedCategory.iconName || undefined,
          isActive: selectedCategory.isActive,
          sortOrder: selectedCategory.sortOrder,
        });
      } else {
        // Create new
        await api.createCategory({
          name: selectedCategory.name,
          slug,
          level: selectedCategory.level,
          parentId: selectedCategory.parentId || undefined,
          iconName: selectedCategory.iconName || undefined,
          sortOrder: selectedCategory.sortOrder,
        });
      }
      setIsEditModalOpen(false);
      setSelectedCategory(null);
      await loadCategories();
    } catch (error: any) {
      alert(error.message || 'Failed to save category');
    }
  };

  const handleAddChild = (parent: Category) => {
    setSelectedCategory({
      id: '',
      name: '',
      slug: '',
      level: parent.level + 1,
      parentId: parent.id,
      sortOrder: (parent.children?.length || 0) + 1,
      isActive: true,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    });
    setIsEditModalOpen(true);
  };

  const handleAddMainCategory = () => {
    setSelectedCategory({
      id: '',
      name: '',
      slug: '',
      level: 1,
      sortOrder: categories.length + 1,
      isActive: true,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    });
    setIsEditModalOpen(true);
  };

  const handleManageAttributes = async (category: Category) => {
    setAttrCategory(category);
    setIsAttrModalOpen(true);
    setAttrLoading(true);
    setSelectedAttrId('');
    setAttrRequired(false);
    setAttrSortOrder(0);
    try {
      const [linked, all] = await Promise.all([
        api.getCategoryAttributes(category.id),
        api.getAttributes(),
      ]);
      setLinkedAttributes(linked);
      setAllAttributes(all.filter((a: any) => a.isActive));
    } catch (error: any) {
      console.error('Failed to load attributes:', error);
    } finally {
      setAttrLoading(false);
    }
  };

  const handleLinkAttribute = async () => {
    if (!attrCategory || !selectedAttrId) return;
    try {
      await api.linkAttributeToCategory(attrCategory.id, {
        attributeId: selectedAttrId,
        isRequired: attrRequired,
        sortOrder: attrSortOrder,
      });
      const linked = await api.getCategoryAttributes(attrCategory.id);
      setLinkedAttributes(linked);
      setSelectedAttrId('');
      setAttrRequired(false);
      setAttrSortOrder(0);
    } catch (error: any) {
      alert(error.message || 'Failed to link attribute');
    }
  };

  const handleUnlinkAttribute = (attributeId: string, name: string) => {
    setUnlinkTarget({ attributeId, name });
  };

  const handleConfirmUnlink = async () => {
    if (!attrCategory || !unlinkTarget) return;
    try {
      await api.unlinkAttributeFromCategory(attrCategory.id, unlinkTarget.attributeId);
      setLinkedAttributes(linkedAttributes.filter((la: any) => la.attributeId !== unlinkTarget.attributeId));
      setUnlinkTarget(null);
    } catch (error: any) {
      alert(error.message || 'Failed to unlink attribute');
    }
  };

  const countAllCategories = (cats: Category[]): number => {
    return cats.reduce((count, cat) => {
      return count + 1 + (cat.children ? countAllCategories(cat.children) : 0);
    }, 0);
  };

  return (
    <div>
      <Header title="Categories" />

      <div className="p-6">
        {/* Stats */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6">
          <Card>
            <CardContent className="py-4">
              <div className="flex items-center gap-3">
                <div className="p-2 bg-primary-100 rounded-lg">
                  <FolderIcon className="h-6 w-6 text-primary-500" />
                </div>
                <div>
                  <p className="text-2xl font-bold">{categories.length}</p>
                  <p className="text-sm text-gray-500">Main Categories</p>
                </div>
              </div>
            </CardContent>
          </Card>
          <Card>
            <CardContent className="py-4">
              <div className="flex items-center gap-3">
                <div className="p-2 bg-green-100 rounded-lg">
                  <FolderIcon className="h-6 w-6 text-green-600" />
                </div>
                <div>
                  <p className="text-2xl font-bold">
                    {categories.reduce((count, cat) => count + (cat.children?.length || 0), 0)}
                  </p>
                  <p className="text-sm text-gray-500">Sub-Categories</p>
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
                  <p className="text-2xl font-bold">{countAllCategories(categories)}</p>
                  <p className="text-sm text-gray-500">Total Categories</p>
                </div>
              </div>
            </CardContent>
          </Card>
          <Card>
            <CardContent className="py-4">
              <div className="flex items-center gap-3">
                <div className="p-2 bg-purple-100 rounded-lg">
                  <FolderIcon className="h-6 w-6 text-purple-600" />
                </div>
                <div>
                  <p className="text-2xl font-bold">3</p>
                  <p className="text-sm text-gray-500">Levels</p>
                </div>
              </div>
            </CardContent>
          </Card>
        </div>

        {/* Category Tree */}
        <Card>
          <CardHeader className="flex flex-row items-center justify-between">
            <CardTitle>Category Hierarchy</CardTitle>
            <Button onClick={handleAddMainCategory}>
              <PlusIcon className="h-4 w-4 mr-2" />
              Add Main Category
            </Button>
          </CardHeader>
          <CardContent>
            {loading ? (
              <div className="flex items-center justify-center py-12">
                <div className="h-8 w-8 animate-spin rounded-full border-4 border-primary-500 border-t-transparent" />
              </div>
            ) : categories.length > 0 ? (
              <div className="space-y-1">
                {categories.map((category) => (
                  <CategoryTreeItem
                    key={category.id}
                    category={category}
                    onEdit={handleEdit}
                    onDelete={handleDelete}
                    onAddChild={handleAddChild}
                    onManageAttributes={handleManageAttributes}
                  />
                ))}
              </div>
            ) : (
              <div className="text-center py-12 text-gray-500">
                <FolderIcon className="h-12 w-12 mx-auto mb-4 text-gray-300" />
                <p>No categories found</p>
                <Button className="mt-4" onClick={handleAddMainCategory}>
                  Add your first category
                </Button>
              </div>
            )}
          </CardContent>
        </Card>

        {/* Legend */}
        <div className="mt-4 flex items-center gap-4 text-sm text-gray-500">
          <span className="flex items-center gap-1">
            <Badge variant="default">L1</Badge> Main Category
          </span>
          <span className="flex items-center gap-1">
            <Badge variant="success">L2</Badge> Sub-Category
          </span>
          <span className="flex items-center gap-1">
            <Badge variant="warning">L3</Badge> Product Type
          </span>
        </div>
      </div>

      {/* Delete Confirmation */}
      <ConfirmDialog
        isOpen={!!deleteTarget}
        onClose={() => setDeleteTarget(null)}
        onConfirm={handleConfirmDelete}
        title="Delete Category?"
        message={`Are you sure you want to delete "${deleteTarget?.name}"? This will also delete all child categories. This action cannot be undone.`}
        loading={deleteLoading}
      />

      {/* Unlink Attribute Confirmation */}
      <ConfirmDialog
        isOpen={!!unlinkTarget}
        onClose={() => setUnlinkTarget(null)}
        onConfirm={handleConfirmUnlink}
        title="Remove Attribute?"
        message={`Are you sure you want to remove "${unlinkTarget?.name}" from this category?`}
        confirmLabel="Remove"
      />

      {/* Attribute Management Modal */}
      <Modal
        isOpen={isAttrModalOpen}
        onClose={() => { setIsAttrModalOpen(false); setAttrCategory(null); }}
        title={`Attributes: ${attrCategory?.name || ''}`}
        size="lg"
      >
        {attrLoading ? (
          <div className="flex items-center justify-center py-12">
            <div className="h-8 w-8 animate-spin rounded-full border-4 border-primary-500 border-t-transparent" />
          </div>
        ) : (
          <div className="space-y-6">
            {/* Currently linked attributes */}
            <div>
              <h4 className="text-sm font-medium text-gray-700 mb-3">Linked Attributes</h4>
              {linkedAttributes.length > 0 ? (
                <div className="space-y-2">
                  {linkedAttributes.map((la: any) => (
                    <div key={la.id} className="flex items-center justify-between py-2 px-3 bg-gray-50 rounded-lg">
                      <div className="flex items-center gap-3">
                        <TagIcon className="h-4 w-4 text-purple-500" />
                        <div>
                          <span className="font-medium text-sm">{la.attribute.name}</span>
                          <span className="text-xs text-gray-400 ml-2">({la.attribute.slug})</span>
                        </div>
                        {la.isRequired && <Badge variant="danger">Required</Badge>}
                        <Badge variant="default">Order: {la.sortOrder}</Badge>
                      </div>
                      <Button size="sm" variant="ghost" onClick={() => handleUnlinkAttribute(la.attributeId, la.attribute.name)}>
                        <TrashIcon className="h-4 w-4 text-red-500" />
                      </Button>
                    </div>
                  ))}
                </div>
              ) : (
                <p className="text-sm text-gray-400 py-4 text-center">No attributes linked to this category</p>
              )}
            </div>

            {/* Add attribute form */}
            <div className="border-t pt-4">
              <h4 className="text-sm font-medium text-gray-700 mb-3">Link an Attribute</h4>
              <div className="flex items-end gap-3">
                <div className="flex-1">
                  <label className="block text-xs text-gray-500 mb-1">Attribute</label>
                  <select
                    value={selectedAttrId}
                    onChange={(e) => setSelectedAttrId(e.target.value)}
                    className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm"
                  >
                    <option value="">Select attribute...</option>
                    {allAttributes
                      .filter((a: any) => !linkedAttributes.some((la: any) => la.attributeId === a.id))
                      .map((a: any) => (
                        <option key={a.id} value={a.id}>{a.name} ({a.slug})</option>
                      ))}
                  </select>
                </div>
                <div className="w-20">
                  <label className="block text-xs text-gray-500 mb-1">Order</label>
                  <input
                    type="number"
                    value={attrSortOrder}
                    onChange={(e) => setAttrSortOrder(parseInt(e.target.value) || 0)}
                    className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm"
                    min={0}
                  />
                </div>
                <label className="flex items-center gap-1 text-sm whitespace-nowrap pb-2">
                  <input
                    type="checkbox"
                    checked={attrRequired}
                    onChange={(e) => setAttrRequired(e.target.checked)}
                    className="h-4 w-4 text-primary-500 rounded border-gray-300"
                  />
                  Required
                </label>
                <Button onClick={handleLinkAttribute} disabled={!selectedAttrId}>
                  <PlusIcon className="h-4 w-4 mr-1" />
                  Link
                </Button>
              </div>
            </div>

            <ModalFooter>
              <Button variant="secondary" onClick={() => { setIsAttrModalOpen(false); setAttrCategory(null); }}>
                Close
              </Button>
            </ModalFooter>
          </div>
        )}
      </Modal>

      {/* Create/Edit Modal */}
      <Modal
        isOpen={isEditModalOpen}
        onClose={() => { setIsEditModalOpen(false); setSelectedCategory(null); }}
        title={selectedCategory?.id ? 'Edit Category' : 'Add Category'}
        size="md"
      >
        {selectedCategory && (
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Name</label>
              <input
                type="text"
                value={selectedCategory.name}
                onChange={(e) => setSelectedCategory({ ...selectedCategory, name: e.target.value })}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
                placeholder="e.g. Women, Clothing, Dresses"
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Slug</label>
              <input
                type="text"
                value={selectedCategory.slug || selectedCategory.name.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)/g, '')}
                onChange={(e) => setSelectedCategory({ ...selectedCategory, slug: e.target.value })}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
                placeholder="auto-generated-from-name"
                disabled={!!selectedCategory.id}
              />
              {!selectedCategory.id && (
                <p className="text-xs text-gray-400 mt-1">Auto-generated from name if left empty</p>
              )}
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Level</label>
              <input
                type="text"
                value={`Level ${selectedCategory.level} - ${selectedCategory.level === 1 ? 'Main Category' : selectedCategory.level === 2 ? 'Sub-Category' : 'Product Type'}`}
                disabled
                className="w-full px-3 py-2 border border-gray-200 rounded-lg bg-gray-50 text-gray-500"
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Icon Name (optional)</label>
              <input
                type="text"
                value={selectedCategory.iconName || ''}
                onChange={(e) => setSelectedCategory({ ...selectedCategory, iconName: e.target.value })}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
                placeholder="e.g. woman, man, shirt"
              />
            </div>

            <div className="flex items-center gap-2">
              <input
                type="checkbox"
                id="isActive"
                checked={selectedCategory.isActive}
                onChange={(e) => setSelectedCategory({ ...selectedCategory, isActive: e.target.checked })}
                className="h-4 w-4 text-primary-500 rounded border-gray-300"
              />
              <label htmlFor="isActive" className="text-sm text-gray-700">Active</label>
            </div>

            <ModalFooter>
              <Button variant="secondary" onClick={() => { setIsEditModalOpen(false); setSelectedCategory(null); }}>
                Cancel
              </Button>
              <Button onClick={handleSave}>
                {selectedCategory.id ? 'Update' : 'Create'}
              </Button>
            </ModalFooter>
          </div>
        )}
      </Modal>
    </div>
  );
}
