'use client';

import { createContext, useContext, useEffect, ReactNode } from 'react';
import { authManager, AuthUser } from '@/lib/auth';
import { useAuthStore } from '@/stores/authStore';
import { User } from '@/types';

interface AuthContextType {
  user: User | null;
  isAuthenticated: boolean;
  isLoading: boolean;
}

const AuthContext = createContext<AuthContextType>({
  user: null,
  isAuthenticated: false,
  isLoading: true,
});

export function useAuthContext() {
  return useContext(AuthContext);
}

interface AuthProviderProps {
  children: ReactNode;
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

export function AuthProvider({ children }: AuthProviderProps) {
  const { user, isAuthenticated, isLoading, setUser, setLoading } = useAuthStore();

  useEffect(() => {
    // Initialize auth state from authManager (localStorage)
    setLoading(true);

    // Ensure authManager is initialized (handles SSR)
    authManager.ensureInitialized();

    if (authManager.isAuthenticated()) {
      const authUser = authManager.getUser();
      if (authUser) {
        setUser(toStoreUser(authUser));
      } else {
        setUser(null);
      }
    } else {
      setUser(null);
    }
  }, [setUser, setLoading]);

  // Set up token refresh using authManager
  useEffect(() => {
    if (!isAuthenticated) return;

    const refreshToken = async () => {
      try {
        await authManager.refreshTokens();
      } catch (error) {
        console.error('Error refreshing token:', error);
      }
    };

    // Refresh token every 50 minutes (tokens expire after 1 hour)
    const interval = setInterval(refreshToken, 50 * 60 * 1000);

    return () => clearInterval(interval);
  }, [isAuthenticated]);

  const value: AuthContextType = {
    user,
    isAuthenticated,
    isLoading,
  };

  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  );
}

// Hook for protected routes
export function useRequireAuth(redirectTo: string = '/login') {
  const { isAuthenticated, isLoading } = useAuthContext();

  useEffect(() => {
    if (!isLoading && !isAuthenticated) {
      window.location.href = redirectTo;
    }
  }, [isAuthenticated, isLoading, redirectTo]);

  return { isAuthenticated, isLoading };
}
