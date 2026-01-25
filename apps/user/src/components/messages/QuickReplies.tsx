'use client';

import { useState, useEffect } from 'react';
import {
  ChatBubbleLeftRightIcon,
  PlusIcon,
  TrashIcon,
  PencilIcon,
} from '@heroicons/react/24/outline';
import { api } from '@/lib/api';
import { QuickReply } from '@/types';
import { Button } from '@/components/ui/Button';
import { Input } from '@/components/ui/Input';
import { Modal, ModalFooter } from '@/components/ui/Modal';

interface QuickRepliesProps {
  onSelect: (message: string) => void;
}

// Default quick replies if user hasn't created any
const DEFAULT_REPLIES = [
  'Hi! Is this item still available?',
  'What\'s your best price?',
  'Can you send more photos?',
  'Where can we meet?',
  'Is the price negotiable?',
  'What condition is it in?',
];

export function QuickReplies({ onSelect }: QuickRepliesProps) {
  const [quickReplies, setQuickReplies] = useState<QuickReply[]>([]);
  const [loading, setLoading] = useState(true);
  const [showManageModal, setShowManageModal] = useState(false);
  const [editingReply, setEditingReply] = useState<QuickReply | null>(null);
  const [newReplyText, setNewReplyText] = useState('');
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    loadQuickReplies();
  }, []);

  const loadQuickReplies = async () => {
    try {
      setLoading(true);
      const data = await api.getQuickReplies();
      setQuickReplies(data);
    } catch (error) {
      console.error('Error loading quick replies:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleCreateReply = async () => {
    if (!newReplyText.trim()) return;

    setSaving(true);
    try {
      const reply = await api.createQuickReply({ text: newReplyText.trim() });
      setQuickReplies([...quickReplies, reply]);
      setNewReplyText('');
    } catch (error) {
      console.error('Error creating quick reply:', error);
    } finally {
      setSaving(false);
    }
  };

  const handleUpdateReply = async () => {
    if (!editingReply || !newReplyText.trim()) return;

    setSaving(true);
    try {
      const updated = await api.updateQuickReply(editingReply.id, { text: newReplyText.trim() });
      setQuickReplies(quickReplies.map((r) => (r.id === updated.id ? updated : r)));
      setEditingReply(null);
      setNewReplyText('');
    } catch (error) {
      console.error('Error updating quick reply:', error);
    } finally {
      setSaving(false);
    }
  };

  const handleDeleteReply = async (id: string) => {
    try {
      await api.deleteQuickReply(id);
      setQuickReplies(quickReplies.filter((r) => r.id !== id));
    } catch (error) {
      console.error('Error deleting quick reply:', error);
    }
  };

  const startEditing = (reply: QuickReply) => {
    setEditingReply(reply);
    setNewReplyText(reply.text);
  };

  const cancelEditing = () => {
    setEditingReply(null);
    setNewReplyText('');
  };

  // Use custom replies if available, otherwise use defaults
  const displayReplies = quickReplies.length > 0 ? quickReplies : DEFAULT_REPLIES.map((text, i) => ({ id: `default-${i}`, text, userId: '', createdAt: '' }));

  if (loading) {
    return (
      <div className="flex gap-2 overflow-x-auto pb-2">
        {[1, 2, 3].map((i) => (
          <div key={i} className="h-8 w-32 bg-gray-100 rounded-full animate-pulse flex-shrink-0" />
        ))}
      </div>
    );
  }

  return (
    <>
      <div className="flex gap-2 overflow-x-auto pb-2 scrollbar-hide">
        {displayReplies.slice(0, 5).map((reply) => (
          <button
            key={reply.id}
            onClick={() => onSelect(reply.text)}
            className="px-3 py-1.5 bg-gray-100 hover:bg-gray-200 rounded-full text-sm text-gray-700 whitespace-nowrap flex-shrink-0 transition-colors"
          >
            {reply.text.length > 30 ? reply.text.slice(0, 30) + '...' : reply.text}
          </button>
        ))}

        <button
          onClick={() => setShowManageModal(true)}
          className="px-3 py-1.5 border border-gray-200 hover:bg-gray-50 rounded-full text-sm text-gray-500 whitespace-nowrap flex-shrink-0 flex items-center gap-1 transition-colors"
        >
          <PencilIcon className="w-4 h-4" />
          Manage
        </button>
      </div>

      {/* Manage Quick Replies Modal */}
      <Modal
        isOpen={showManageModal}
        onClose={() => {
          setShowManageModal(false);
          cancelEditing();
        }}
        title="Manage Quick Replies"
        size="md"
      >
        <div className="space-y-4">
          {/* Add/Edit Form */}
          <div className="flex gap-2">
            <Input
              value={newReplyText}
              onChange={(e) => setNewReplyText(e.target.value)}
              placeholder={editingReply ? 'Edit reply...' : 'Add new quick reply...'}
              className="flex-1"
              maxLength={100}
            />
            {editingReply ? (
              <div className="flex gap-1">
                <Button variant="outline" size="sm" onClick={cancelEditing}>
                  Cancel
                </Button>
                <Button
                  size="sm"
                  onClick={handleUpdateReply}
                  loading={saving}
                  disabled={!newReplyText.trim()}
                >
                  Save
                </Button>
              </div>
            ) : (
              <Button
                onClick={handleCreateReply}
                loading={saving}
                disabled={!newReplyText.trim()}
              >
                <PlusIcon className="w-4 h-4" />
              </Button>
            )}
          </div>

          {/* Quick Replies List */}
          <div className="space-y-2 max-h-64 overflow-y-auto">
            {quickReplies.length === 0 ? (
              <div className="text-center py-8">
                <ChatBubbleLeftRightIcon className="w-10 h-10 text-gray-300 mx-auto mb-2" />
                <p className="text-sm text-gray-500">No custom quick replies yet</p>
                <p className="text-xs text-gray-400 mt-1">
                  Add your own to speed up conversations
                </p>
              </div>
            ) : (
              quickReplies.map((reply) => (
                <div
                  key={reply.id}
                  className="flex items-center justify-between p-3 bg-gray-50 rounded-lg group"
                >
                  <span className="text-sm text-gray-700 truncate flex-1 mr-2">
                    {reply.text}
                  </span>
                  <div className="flex items-center gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
                    <button
                      onClick={() => startEditing(reply)}
                      className="p-1 hover:bg-gray-200 rounded text-gray-400 hover:text-gray-600"
                    >
                      <PencilIcon className="w-4 h-4" />
                    </button>
                    <button
                      onClick={() => handleDeleteReply(reply.id)}
                      className="p-1 hover:bg-red-100 rounded text-gray-400 hover:text-red-500"
                    >
                      <TrashIcon className="w-4 h-4" />
                    </button>
                  </div>
                </div>
              ))
            )}
          </div>

          {/* Default Replies Info */}
          {quickReplies.length === 0 && (
            <div className="p-3 bg-blue-50 rounded-lg">
              <p className="text-sm text-blue-700">
                We&apos;re showing default quick replies. Add your own to customize!
              </p>
            </div>
          )}
        </div>

        <ModalFooter>
          <Button
            variant="outline"
            onClick={() => {
              setShowManageModal(false);
              cancelEditing();
            }}
          >
            Done
          </Button>
        </ModalFooter>
      </Modal>
    </>
  );
}
