'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import Image from 'next/image';
import { MagnifyingGlassIcon } from '@heroicons/react/24/outline';
import { api } from '@/lib/api';
import { authManager } from '@/lib/auth';
import { Chat, User } from '@/types';

// API response type for chat (backend shape differs from frontend)
interface ChatApiResponse extends Omit<Chat, 'participants'> {
  buyer?: User;
  seller?: User;
}
import { formatChatDate, truncateText } from '@/lib/utils';
import Header from '@/components/layout/Header';
import Footer from '@/components/layout/Footer';
import { Input } from '@/components/ui/Input';
import { Avatar } from '@/components/ui/Avatar';
import { Card, CardContent } from '@/components/ui/Card';
import { PageLoader } from '@/components/ui/Spinner';
import { NoMessagesEmptyState } from '@/components/ui/EmptyState';
import { useAuthStore } from '@/stores/authStore';
import { useChatStore } from '@/stores/chatStore';

export default function MessagesPage() {
  const router = useRouter();
  const { user, isAuthenticated, isLoading: authLoading } = useAuthStore();
  const { chats, setChats } = useChatStore();

  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');

  useEffect(() => {
    if (!authLoading && !isAuthenticated) {
      router.push('/login');
      return;
    }

    if (isAuthenticated) {
      loadChats();
    }
  }, [authLoading, isAuthenticated]);

  const loadChats = async () => {
    // Ensure we have authentication before making API calls
    // authManager.isAuthenticated() also initializes and sets API token
    if (!authManager.isAuthenticated()) {
      setLoading(false);
      return;
    }

    try {
      setLoading(true);
      const data = await api.getChats();
      // Transform backend response to expected format
      // Backend returns buyer/seller/otherUser, frontend expects participants array
      const rawChats = Array.isArray(data) ? data : [];
      const transformedChats: Chat[] = rawChats.map((chat: ChatApiResponse) => ({
        ...chat,
        participants: [chat.buyer, chat.seller].filter((u): u is User => u !== undefined),
      }));
      setChats(transformedChats);
    } catch (error) {
      console.error('Error loading chats:', error);
    } finally {
      setLoading(false);
    }
  };

  const getOtherParticipant = (chat: Chat) => {
    return chat.participants.find((p) => p.id !== user?.id);
  };

  const filteredChats = chats.filter((chat) => {
    if (!searchQuery) return true;
    const otherUser = getOtherParticipant(chat);
    return (
      otherUser?.displayName?.toLowerCase().includes(searchQuery.toLowerCase()) ||
      chat.listing?.title.toLowerCase().includes(searchQuery.toLowerCase()) ||
      chat.lastMessage?.content.toLowerCase().includes(searchQuery.toLowerCase())
    );
  });

  if (authLoading || loading) {
    return (
      <div className="min-h-screen flex flex-col">
        <Header />
        <PageLoader message="Loading messages..." />
        <Footer />
      </div>
    );
  }

  return (
    <div className="min-h-screen flex flex-col bg-gray-50">
      <Header />

      <main className="flex-1 py-8">
        <div className="max-w-3xl mx-auto px-4">
          {/* Header */}
          <div className="mb-6">
            <h1 className="text-2xl font-bold text-gray-900">Messages</h1>
          </div>

          {/* Search */}
          <div className="mb-6">
            <Input
              placeholder="Search conversations..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              leftIcon={<MagnifyingGlassIcon className="w-5 h-5" />}
            />
          </div>

          {/* Chat List */}
          {filteredChats.length === 0 ? (
            searchQuery ? (
              <Card>
                <CardContent className="py-12 text-center">
                  <p className="text-gray-500">No conversations found</p>
                </CardContent>
              </Card>
            ) : (
              <NoMessagesEmptyState />
            )
          ) : (
            <div className="space-y-2">
              {filteredChats.map((chat) => {
                const otherUser = getOtherParticipant(chat);
                const lastMessage = chat.lastMessage;

                return (
                  <Link key={chat.id} href={`/messages/${chat.id}`}>
                    <Card hoverable>
                      <CardContent className="py-4">
                        <div className="flex items-center gap-4">
                          {/* Avatar */}
                          <div className="relative">
                            <Avatar
                              src={otherUser?.photoUrl}
                              name={otherUser?.displayName}
                              size="lg"
                            />
                            {chat.unreadCount > 0 && (
                              <span className="absolute -top-1 -right-1 w-5 h-5 bg-pink-600 text-white text-xs rounded-full flex items-center justify-center">
                                {chat.unreadCount > 9 ? '9+' : chat.unreadCount}
                              </span>
                            )}
                          </div>

                          {/* Content */}
                          <div className="flex-1 min-w-0">
                            <div className="flex items-center justify-between">
                              <span className="font-medium text-gray-900">
                                {otherUser?.displayName || 'Unknown'}
                              </span>
                              {lastMessage && (
                                <span className="text-xs text-gray-500">
                                  {formatChatDate(lastMessage.createdAt)}
                                </span>
                              )}
                            </div>

                            {/* Listing Reference */}
                            {chat.listing && (
                              <div className="flex items-center gap-2 mt-1">
                                <div className="relative w-6 h-6 rounded overflow-hidden flex-shrink-0">
                                  {chat.listing.imageUrls[0] ? (
                                    <Image
                                      src={chat.listing.imageUrls[0]}
                                      alt=""
                                      fill
                                      className="object-cover"
                                    />
                                  ) : (
                                    <div className="w-full h-full bg-gray-200" />
                                  )}
                                </div>
                                <span className="text-sm text-gray-600 truncate">
                                  {chat.listing.title}
                                </span>
                              </div>
                            )}

                            {/* Last Message */}
                            {lastMessage && (
                              <p
                                className={`text-sm mt-1 truncate ${
                                  chat.unreadCount > 0
                                    ? 'text-gray-900 font-medium'
                                    : 'text-gray-500'
                                }`}
                              >
                                {lastMessage.senderId === user?.id && 'You: '}
                                {lastMessage.type === 'IMAGE'
                                  ? 'Sent an image'
                                  : lastMessage.type === 'MEETUP'
                                  ? 'Proposed a meetup'
                                  : truncateText(lastMessage.content, 50)}
                              </p>
                            )}
                          </div>
                        </div>
                      </CardContent>
                    </Card>
                  </Link>
                );
              })}
            </div>
          )}
        </div>
      </main>

      <Footer />
    </div>
  );
}
