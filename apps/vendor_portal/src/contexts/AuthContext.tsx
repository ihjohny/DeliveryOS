import React, { createContext, useContext, useState, useEffect } from 'react';
import apiClient from '../services/apiClient';
import { User, UserRole, PermissionScope } from '../types/auth';
import { connectSocket, disconnectSocket } from '../services/socket';

interface AuthContextType {
  user: User | null;
  token: string | null;
  isAuthenticated: boolean;
  isLoading: boolean;
  login: (phone: string, password: string) => Promise<{ role: UserRole }>;
  logout: () => void;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [user, setUser] = useState<User | null>(null);
  const [token, setToken] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState<boolean>(true);

  useEffect(() => {
    // Rehydrate session from localStorage
    const storedToken = localStorage.getItem('deliveryos_token');
    const storedUser = localStorage.getItem('deliveryos_user');

    if (storedToken && storedUser) {
      try {
        setToken(storedToken);
        setUser(JSON.parse(storedUser));
        connectSocket();
      } catch (err) {
        console.error('Error hydrating auth state:', err);
        localStorage.removeItem('deliveryos_token');
        localStorage.removeItem('deliveryos_user');
      }
    }
    setIsLoading(false);
  }, []);

  const login = async (phone: string, password: string) => {
    setIsLoading(true);
    try {
      const response = await apiClient.post('/api/v1/auth/otp/verify', {
        phone,
        otp: password,
      });

      const payload = response.data?.data || response.data;
      const accessToken = payload.accessToken || payload.token;
      const userData = payload.user;

      if (!accessToken || !userData) {
        throw new Error('Invalid authentication response structure');
      }

      // Check if user is staff with outlet info
      let vendorId = userData.vendorId;
      let vendorName = userData.vendorName;
      let outletScope = userData.outletScope;
      let managedVendorIds = userData.managedVendorIds;

      // If user is VENDOR_ADMIN, check staff profile
      if (userData.role === UserRole.VENDOR_ADMIN && !outletScope) {
        try {
          const staffProfileRes = await apiClient.get('/api/v1/vendor/me', {
            headers: { Authorization: `Bearer ${accessToken}` },
          });
          const staffProfile = staffProfileRes.data?.data || staffProfileRes.data;
          if (staffProfile) {
            outletScope = staffProfile.outlet_scope || staffProfile.outletScope || PermissionScope.PARTICULAR_OUTLET;
            vendorId = staffProfile.vendor_id || staffProfile.vendorId;
            vendorName = staffProfile.vendor?.name || staffProfile.vendorName;
            managedVendorIds = staffProfile.managedVendorIds || (vendorId ? [vendorId] : []);
          }
        } catch {
          // If /api/staff/me is not queried, default to PARTICULAR_OUTLET
          outletScope = PermissionScope.PARTICULAR_OUTLET;
        }
      }

      const formattedUser: User = {
        id: userData.id,
        phone: userData.phone,
        email: userData.email,
        fullName: userData.full_name || userData.fullName,
        role: userData.role,
        vendorId,
        vendorName,
        outletScope,
        managedVendorIds,
      };

      localStorage.setItem('deliveryos_token', accessToken);
      localStorage.setItem('deliveryos_user', JSON.stringify(formattedUser));

      setToken(accessToken);
      setUser(formattedUser);
      connectSocket();

      return { role: formattedUser.role };
    } finally {
      setIsLoading(false);
    }
  };

  const logout = () => {
    localStorage.removeItem('deliveryos_token');
    localStorage.removeItem('deliveryos_user');
    disconnectSocket();
    setToken(null);
    setUser(null);
  };

  return (
    <AuthContext.Provider
      value={{
        user,
        token,
        isAuthenticated: !!token && !!user,
        isLoading,
        login,
        logout,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};
