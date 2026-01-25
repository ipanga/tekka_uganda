import { create } from 'zustand';
import { Chat, Message } from '@/types';

interface ChatState {
  chats: Chat[];
  activeChat: Chat | null;
  messages: Record<string, Message[]>; // chatId -> messages
  unreadCount: number;
  isLoading: boolean;

  // Actions
  setChats: (chats: Chat[]) => void;
  setActiveChat: (chat: Chat | null) => void;
  addChat: (chat: Chat) => void;
  updateChat: (chatId: string, updates: Partial<Chat>) => void;
  setMessages: (chatId: string, messages: Message[]) => void;
  addMessage: (chatId: string, message: Message) => void;
  updateMessage: (chatId: string, messageId: string, updates: Partial<Message>) => void;
  removeMessage: (chatId: string, messageId: string) => void;
  setUnreadCount: (count: number) => void;
  markChatAsRead: (chatId: string) => void;
  setLoading: (loading: boolean) => void;
}

export const useChatStore = create<ChatState>((set) => ({
  chats: [],
  activeChat: null,
  messages: {},
  unreadCount: 0,
  isLoading: false,

  setChats: (chats) =>
    set({
      chats,
      unreadCount: chats.reduce((sum, chat) => sum + chat.unreadCount, 0),
    }),

  setActiveChat: (activeChat) =>
    set({ activeChat }),

  addChat: (chat) =>
    set((state) => ({
      chats: [chat, ...state.chats.filter((c) => c.id !== chat.id)],
      unreadCount: state.unreadCount + chat.unreadCount,
    })),

  updateChat: (chatId, updates) =>
    set((state) => ({
      chats: state.chats.map((chat) =>
        chat.id === chatId ? { ...chat, ...updates } : chat
      ),
      activeChat:
        state.activeChat?.id === chatId
          ? { ...state.activeChat, ...updates }
          : state.activeChat,
    })),

  setMessages: (chatId, messages) =>
    set((state) => ({
      messages: { ...state.messages, [chatId]: messages },
    })),

  addMessage: (chatId, message) =>
    set((state) => {
      const existingMessages = state.messages[chatId] || [];
      // Check if message already exists to prevent duplicates
      if (existingMessages.some((m) => m.id === message.id)) {
        return state;
      }
      return {
        messages: {
          ...state.messages,
          [chatId]: [...existingMessages, message],
        },
        chats: state.chats.map((chat) =>
          chat.id === chatId
            ? { ...chat, lastMessage: message, updatedAt: message.createdAt }
            : chat
        ),
      };
    }),

  updateMessage: (chatId, messageId, updates) =>
    set((state) => ({
      messages: {
        ...state.messages,
        [chatId]: (state.messages[chatId] || []).map((msg) =>
          msg.id === messageId ? { ...msg, ...updates } : msg
        ),
      },
    })),

  removeMessage: (chatId, messageId) =>
    set((state) => ({
      messages: {
        ...state.messages,
        [chatId]: (state.messages[chatId] || []).filter((msg) => msg.id !== messageId),
      },
    })),

  setUnreadCount: (unreadCount) =>
    set({ unreadCount }),

  markChatAsRead: (chatId) =>
    set((state) => {
      const chat = state.chats.find((c) => c.id === chatId);
      const unreadDiff = chat?.unreadCount || 0;
      return {
        chats: state.chats.map((c) =>
          c.id === chatId ? { ...c, unreadCount: 0 } : c
        ),
        unreadCount: Math.max(0, state.unreadCount - unreadDiff),
      };
    }),

  setLoading: (isLoading) =>
    set({ isLoading }),
}));
