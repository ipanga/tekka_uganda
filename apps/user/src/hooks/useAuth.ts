'use client';

import { useState, useEffect, useCallback } from 'react';
import { authManager, AuthUser } from '@/lib/auth';
import { useAuthStore } from '@/stores/authStore';
import { User } from '@/types';

interface AuthState {
  user: AuthUser | null;
  loading: boolean;
  error: string | null;
}

// Convert AuthUser to User type for the store
function toStoreUser(authUser: AuthUser): User {
  return {
    id: authUser.id,
    firebaseUid: '', // Not available from authManager
    phoneNumber: authUser.phoneNumber,
    email: authUser.email ?? undefined,
    displayName: authUser.displayName ?? undefined,
    photoUrl: authUser.photoUrl ?? undefined,
    bio: authUser.bio ?? undefined,
    location: authUser.location ?? undefined,
    isOnboardingComplete: authUser.isOnboardingComplete,
    isVerified: authUser.isVerified,
    createdAt: new Date().toISOString(),
  };
}

export function useAuth() {
  const [state, setState] = useState<AuthState>({
    user: null,
    loading: true,
    error: null,
  });
  const [phoneNumber, setPhoneNumber] = useState<string>('');
  const { setUser: setStoreUser, logout: storeLogout } = useAuthStore();

  useEffect(() => {
    // Check if user is already authenticated with a valid token
    if (authManager.isAuthenticated()) {
      const user = authManager.getUser();
      setState({ user, loading: false, error: null });
      // Sync with store
      if (user) {
        setStoreUser(toStoreUser(user));
      }
    } else {
      // No valid auth, just update local state (don't call storeLogout to avoid loops)
      setState({ user: null, loading: false, error: null });
    }
    // Only run once on mount
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const sendOTP = useCallback(async (phone: string) => {
    setState((prev) => ({ ...prev, loading: true, error: null }));
    try {
      // Store phone number for later verification
      setPhoneNumber(phone);
      await authManager.sendOTP(phone);
      setState((prev) => ({ ...prev, loading: false }));
      return true;
    } catch (error: unknown) {
      const message = error instanceof Error ? error.message : 'Failed to send OTP';
      setState((prev) => ({ ...prev, loading: false, error: message }));
      throw error;
    }
  }, []);

  const verifyOTP = useCallback(
    async (code: string) => {
      if (!phoneNumber) {
        throw new Error('Phone number not set. Please send OTP first.');
      }
      setState((prev) => ({ ...prev, loading: true, error: null }));
      try {
        const result = await authManager.verifyOTP(phoneNumber, code);
        setState({ user: result.user, loading: false, error: null });
        // Sync with store
        setStoreUser(toStoreUser(result.user));
        return result.user;
      } catch (error: unknown) {
        const message = error instanceof Error ? error.message : 'Invalid OTP';
        setState((prev) => ({ ...prev, loading: false, error: message }));
        throw error;
      }
    },
    [phoneNumber, setStoreUser]
  );

  const completeProfile = useCallback(
    async (data: { displayName: string; location?: string; bio?: string }) => {
      setState((prev) => ({ ...prev, loading: true, error: null }));
      try {
        const user = await authManager.completeProfile(data);
        setState({ user, loading: false, error: null });
        // Sync with store
        setStoreUser(toStoreUser(user));
        return user;
      } catch (error: unknown) {
        const message = error instanceof Error ? error.message : 'Failed to save profile';
        setState((prev) => ({ ...prev, loading: false, error: message }));
        throw error;
      }
    },
    [setStoreUser]
  );

  const signOut = useCallback(async () => {
    try {
      authManager.signOut();
      setState({ user: null, loading: false, error: null });
      // Sync with store
      storeLogout();
    } catch (error: unknown) {
      const message = error instanceof Error ? error.message : 'Failed to sign out';
      setState((prev) => ({ ...prev, error: message }));
    }
  }, [storeLogout]);

  const refreshToken = useCallback(async () => {
    const result = await authManager.refreshTokens();
    if (result) {
      setState((prev) => ({ ...prev, user: result.user }));
      // Sync with store
      setStoreUser(toStoreUser(result.user));
    }
  }, [setStoreUser]);

  return {
    user: state.user,
    loading: state.loading,
    error: state.error,
    isAuthenticated: !!state.user,
    sendOTP,
    verifyOTP,
    completeProfile,
    signOut,
    refreshToken,
  };
}
