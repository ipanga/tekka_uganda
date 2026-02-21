'use client';

import { useState, useEffect, useRef } from 'react';
import { useParams, useRouter } from 'next/navigation';
import Link from 'next/link';
import Image from 'next/image';
import {
  ArrowLeftIcon,
  PaperAirplaneIcon,
  EllipsisVerticalIcon,
} from '@heroicons/react/24/outline';
import { api } from '@/lib/api';
import { authManager } from '@/lib/auth';
import { Chat, Message, User } from '@/types';

// API response types for chat endpoints (backend shape differs from frontend)
interface ChatApiResponse extends Omit<Chat, 'participants' | 'unreadCount'> {
  buyer?: User;
  seller?: User;
  buyerUnread?: number;
  sellerUnread?: number;
}

interface MessagesApiResponse {
  messages?: Message[];
  data?: Message[];
  nextCursor?: string;
}
import { formatMessageTime, formatPrice, cn } from '@/lib/utils';
import Header from '@/components/layout/Header';
import { Avatar } from '@/components/ui/Avatar';
import { Button } from '@/components/ui/Button';
import { PageLoader } from '@/components/ui/Spinner';
import { useAuthStore } from '@/stores/authStore';
import { useChatStore } from '@/stores/chatStore';

export default function ChatDetailPage() {
  const params = useParams();
  const router = useRouter();
  const chatId = params.chatId as string;

  const { user, isAuthenticated, isLoading: authLoading } = useAuthStore();
  const { messages: storedMessages, setMessages, addMessage, markChatAsRead } = useChatStore();

  const [chat, setChat] = useState<Chat | null>(null);
  const [loading, setLoading] = useState(true);
  const [sending, setSending] = useState(false);
  const [messageText, setMessageText] = useState('');
  const messagesEndRef = useRef<HTMLDivElement>(null);

  const messages = storedMessages[chatId] || [];

  useEffect(() => {
    if (!authLoading && !isAuthenticated) {
      router.push('/login');
      return;
    }

    if (isAuthenticated) {
      loadChat();
    }
  }, [authLoading, isAuthenticated, chatId]);

  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  const loadChat = async () => {
    // Ensure we have authentication before making API calls
    // authManager.isAuthenticated() also initializes and sets API token
    if (!authManager.isAuthenticated()) {
      setLoading(false);
      return;
    }

    try {
      setLoading(true);
      const [chatData, messagesData] = await Promise.all([
        api.getChat(chatId),
        api.getMessages(chatId),
      ]);

      // Transform chat data - backend returns buyer/seller, frontend expects participants
      const rawChat = chatData as ChatApiResponse;
      const transformedChat: Chat = {
        ...chatData,
        participants: [rawChat.buyer, rawChat.seller].filter((u): u is User => u !== undefined),
        unreadCount: rawChat.buyerUnread || rawChat.sellerUnread || 0,
      };
      setChat(transformedChat);

      // Backend returns { messages, nextCursor }, frontend expects { data }
      const rawMessages = messagesData as MessagesApiResponse;
      const messagesArray = rawMessages.messages || rawMessages.data || [];
      setMessages(chatId, messagesArray);

      // Mark as read
      if (transformedChat.unreadCount > 0) {
        await api.markChatAsRead(chatId);
        markChatAsRead(chatId);
      }
    } catch (error) {
      console.error('Error loading chat:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleSend = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!messageText.trim() || sending) return;

    setSending(true);
    const text = messageText.trim();
    setMessageText('');

    try {
      const newMessage = await api.sendMessage(chatId, {
        content: text,
        type: 'TEXT',
      });
      addMessage(chatId, newMessage);
    } catch (error) {
      console.error('Error sending message:', error);
      setMessageText(text); // Restore on error
    } finally {
      setSending(false);
    }
  };

  const getOtherParticipant = (): User | undefined => {
    return chat?.participants.find((p) => p.id !== user?.id);
  };

  if (authLoading || loading) {
    return (
      <div className="min-h-screen flex flex-col">
        <Header />
        <PageLoader message="Loading conversation..." />
      </div>
    );
  }

  if (!chat) {
    return (
      <div className="min-h-screen flex flex-col">
        <Header />
        <main className="flex-1 flex items-center justify-center">
          <div className="text-center">
            <h1 className="text-xl font-bold text-gray-900 mb-2">Conversation not found</h1>
            <Button onClick={() => router.push('/messages')}>Back to Messages</Button>
          </div>
        </main>
      </div>
    );
  }

  const otherUser = getOtherParticipant();
  const listing = chat.listing;

  return (
    <div className="min-h-screen flex flex-col bg-white">
      {/* Custom Header */}
      <header className="sticky top-0 z-40 bg-white border-b border-gray-200">
        <div className="max-w-3xl mx-auto px-4 py-3">
          <div className="flex items-center gap-4">
            <button
              onClick={() => router.push('/messages')}
              className="p-2 -ml-2 hover:bg-gray-100 rounded-lg"
            >
              <ArrowLeftIcon className="w-5 h-5" />
            </button>

            <Link href={`/profile/${otherUser?.id}`} className="flex items-center gap-3 flex-1">
              <Avatar
                src={otherUser?.photoUrl}
                name={otherUser?.displayName}
                size="md"
              />
              <div>
                <h1 className="font-semibold text-gray-900">
                  {otherUser?.displayName || 'Unknown'}
                </h1>
                {otherUser?.location && (
                  <p className="text-xs text-gray-500">{otherUser.location}</p>
                )}
              </div>
            </Link>

            <button className="p-2 hover:bg-gray-100 rounded-lg">
              <EllipsisVerticalIcon className="w-5 h-5" />
            </button>
          </div>

          {/* Listing Context */}
          {listing && (
            <Link
              href={`/listing/${listing.id}`}
              className="flex items-center gap-3 mt-3 p-2 bg-gray-50 rounded-lg hover:bg-gray-100"
            >
              <div className="relative w-12 h-12 rounded overflow-hidden flex-shrink-0">
                {listing.imageUrls[0] ? (
                  <Image
                    src={listing.imageUrls[0]}
                    alt={listing.title}
                    fill
                    className="object-cover"
                  />
                ) : (
                  <div className="w-full h-full bg-gray-200" />
                )}
              </div>
              <div className="flex-1 min-w-0">
                <p className="font-medium text-gray-900 truncate">{listing.title}</p>
                <p className="text-primary-500 font-bold">{formatPrice(listing.price)}</p>
              </div>
            </Link>
          )}
        </div>
      </header>

      {/* Messages */}
      <main className="flex-1 overflow-y-auto">
        <div className="max-w-3xl mx-auto px-4 py-4 space-y-4">
          {messages.map((message) => {
            const isOwn = message.senderId === user?.id;

            return (
              <div
                key={message.id}
                className={cn('flex', isOwn ? 'justify-end' : 'justify-start')}
              >
                <div
                  className={cn(
                    'max-w-[75%] rounded-2xl px-4 py-2',
                    isOwn
                      ? 'bg-primary-500 text-white rounded-br-md'
                      : 'bg-gray-100 text-gray-900 rounded-bl-md'
                  )}
                >
                  {message.type === 'TEXT' && <p>{message.content}</p>}

                  {message.type === 'SYSTEM' && (
                    <p className="italic">{message.content}</p>
                  )}

                  <p
                    className={cn(
                      'text-xs mt-1',
                      isOwn ? 'text-primary-100' : 'text-gray-500'
                    )}
                  >
                    {formatMessageTime(message.createdAt)}
                  </p>
                </div>
              </div>
            );
          })}
          <div ref={messagesEndRef} />
        </div>
      </main>

      {/* Message Input */}
      <footer className="sticky bottom-0 bg-white border-t border-gray-200">
        <div className="max-w-3xl mx-auto px-4 py-3">
          <form onSubmit={handleSend} className="flex items-center gap-2">
            <input
              type="text"
              value={messageText}
              onChange={(e) => setMessageText(e.target.value)}
              placeholder="Type a message..."
              className="flex-1 px-4 py-2 border border-gray-300 bg-white text-gray-900 rounded-full focus:outline-none focus:border-primary-500"
            />
            <button
              type="submit"
              disabled={!messageText.trim() || sending}
              className={cn(
                'p-2 rounded-full transition-colors',
                messageText.trim()
                  ? 'bg-primary-500 text-white hover:bg-primary-600'
                  : 'bg-gray-100 text-gray-400'
              )}
            >
              <PaperAirplaneIcon className="w-5 h-5" />
            </button>
          </form>
        </div>
      </footer>

    </div>
  );
}
