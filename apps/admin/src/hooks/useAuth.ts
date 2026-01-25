'use client';

import { useState, useEffect, useCallback } from 'react';
import { api, AdminUser } from '@/lib/api';

interface AuthState {
  user: AdminUser | null;
  loading: boolean;
  error: string | null;
}

export function useAuth() {
  const [state, setState] = useState<AuthState>({
    user: null,
    loading: true,
    error: null,
  });

  useEffect(() => {
    // Check if user is already authenticated
    const initAuth = async () => {
      if (api.isAuthenticated()) {
        const storedUser = api.getStoredUser();
        if (storedUser) {
          // Validate the token by trying to refresh
          const result = await api.refreshTokens();
          if (result) {
            setState({ user: result.user, loading: false, error: null });
          } else {
            setState({ user: null, loading: false, error: null });
          }
        } else {
          setState({ user: null, loading: false, error: null });
        }
      } else {
        setState({ user: null, loading: false, error: null });
      }
    };

    initAuth();
  }, []);

  const signIn = useCallback(async (email: string, password: string) => {
    setState((prev) => ({ ...prev, loading: true, error: null }));
    try {
      const result = await api.adminLogin(email, password);
      setState({ user: result.user, loading: false, error: null });
      return result.user;
    } catch (error: unknown) {
      const message = error instanceof Error ? error.message : 'Failed to sign in';
      setState((prev) => ({ ...prev, loading: false, error: message }));
      throw error;
    }
  }, []);

  const signOut = useCallback(async () => {
    api.clearToken();
    setState({ user: null, loading: false, error: null });
  }, []);

  const refreshToken = useCallback(async () => {
    const result = await api.refreshTokens();
    if (result) {
      setState((prev) => ({ ...prev, user: result.user }));
    }
  }, []);

  return {
    user: state.user,
    loading: state.loading,
    error: state.error,
    signIn,
    signOut,
    refreshToken,
    isAuthenticated: !!state.user,
  };
}
