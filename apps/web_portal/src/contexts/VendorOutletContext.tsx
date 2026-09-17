import React, { createContext, useContext, useState, useEffect } from 'react';
import { useAuth } from './AuthContext';
import kdsApi from '../services/kdsApi';
import { UserRole, PermissionScope } from '../types/auth';

export interface AccessibleOutlet {
  id: string;
  name: string;
  addressText: string;
  isBusy: boolean;
  isActive: boolean;
  defaultPrepTimeMinutes: number;
  brandId?: string | null;
}

interface VendorOutletContextType {
  activeOutletId: string;
  setActiveOutletId: (id: string) => void;
  outlets: AccessibleOutlet[];
  activeOutlet: AccessibleOutlet | null;
  isMultiBranch: boolean;
  isLoading: boolean;
  refetchOutlets: () => Promise<void>;
}

const VendorOutletContext = createContext<VendorOutletContextType | undefined>(undefined);

export const VendorOutletProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const { user, isAuthenticated } = useAuth();
  const [outlets, setOutlets] = useState<AccessibleOutlet[]>([]);
  const [activeOutletId, setActiveOutletIdState] = useState<string>('ALL');
  const [isLoading, setIsLoading] = useState<boolean>(true);

  const isMultiBranch =
    user?.role === UserRole.SUPER_ADMIN ||
    user?.outletScope === PermissionScope.ALL_OUTLETS_MASTER;

  const fetchOutlets = async () => {
    if (!isAuthenticated) return;
    setIsLoading(true);
    try {
      const data = await kdsApi.getAccessibleOutlets();
      setOutlets(data);

      const savedOutlet = localStorage.getItem('deliveryos_active_outlet');

      if (!isMultiBranch && data.length > 0) {
        // Locked to single assigned outlet for PARTICULAR_OUTLET
        setActiveOutletIdState(data[0].id);
      } else if (savedOutlet && (savedOutlet === 'ALL' || data.some((o) => o.id === savedOutlet))) {
        setActiveOutletIdState(savedOutlet);
      } else if (data.length > 0) {
        setActiveOutletIdState(data[0].id);
      } else {
        setActiveOutletIdState('ALL');
      }
    } catch (err) {
      console.error('Failed to load accessible outlets:', err);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchOutlets();
  }, [user?.id, isAuthenticated, isMultiBranch]);

  const setActiveOutletId = (id: string) => {
    if (!isMultiBranch && outlets.length > 0 && id !== outlets[0].id) {
      // Reject switching for locked single-outlet managers
      return;
    }
    setActiveOutletIdState(id);
    localStorage.setItem('deliveryos_active_outlet', id);
  };

  const activeOutlet = outlets.find((o) => o.id === activeOutletId) || null;

  return (
    <VendorOutletContext.Provider
      value={{
        activeOutletId,
        setActiveOutletId,
        outlets,
        activeOutlet,
        isMultiBranch,
        isLoading,
        refetchOutlets: fetchOutlets,
      }}
    >
      {children}
    </VendorOutletContext.Provider>
  );
};

export const useVendorOutlet = () => {
  const context = useContext(VendorOutletContext);
  if (!context) {
    throw new Error('useVendorOutlet must be used within a VendorOutletProvider');
  }
  return context;
};
