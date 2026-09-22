import React from 'react';
import { useAuthStore } from '../stores/useAuthStore';
import { User, UserRole } from '../types/auth';

export { ADMIN_TOKEN_KEY, ADMIN_USER_KEY } from '../stores/useAuthStore';

interface AuthContextType {
  user: User | null;
  token: string | null;
  isAuthenticated: boolean;
  isLoading: boolean;
  login: (phone: string, password: string) => Promise<{ role: UserRole }>;
  logout: () => void;
}

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  return <>{children}</>;
};

export const useAuth = (): AuthContextType => {
  const user = useAuthStore((s) => s.user);
  const token = useAuthStore((s) => s.token);
  const isAuthenticated = useAuthStore((s) => s.isAuthenticated);
  const isLoading = useAuthStore((s) => s.isLoading);
  const login = useAuthStore((s) => s.login);
  const logout = useAuthStore((s) => s.logout);

  return {
    user,
    token,
    isAuthenticated,
    isLoading,
    login,
    logout,
  };
};

