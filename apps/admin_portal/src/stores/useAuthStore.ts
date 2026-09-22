import { create } from 'zustand';
import apiClient from '../services/apiClient';
import { User, UserRole, PermissionScope } from '../types/auth';
import { connectSocket, disconnectSocket } from '../services/socket';

export const ADMIN_TOKEN_KEY = 'deliveryos_admin_token';
export const ADMIN_USER_KEY = 'deliveryos_admin_user';

const getInitialAdminToken = (): string | null => {
  try {
    return localStorage.getItem(ADMIN_TOKEN_KEY);
  } catch {
    return null;
  }
};

const getInitialAdminUser = (): User | null => {
  try {
    const raw = localStorage.getItem(ADMIN_USER_KEY);
    if (!raw) return null;
    return JSON.parse(raw);
  } catch {
    return null;
  }
};

export interface AuthState {
  user: User | null;
  token: string | null;
  isAuthenticated: boolean;
  isLoading: boolean;
  login: (phone: string, password: string) => Promise<{ role: UserRole }>;
  logout: () => void;
  initialize: () => void;
}

const initialToken = getInitialAdminToken();
const initialUser = getInitialAdminUser();

export const useAuthStore = create<AuthState>((set, get) => ({
  user: initialUser,
  token: initialToken,
  isAuthenticated: !!initialToken && !!initialUser,
  isLoading: false,

  initialize: () => {
    const { token, user } = get();
    if (token && user) {
      connectSocket();
    }
  },

  login: async (phone: string, password: string) => {
    set({ isLoading: true });
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

      let vendorId = userData.vendorId;
      let vendorName = userData.vendorName;
      let outletScope = userData.outletScope;
      let managedVendorIds = userData.managedVendorIds;

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

      localStorage.setItem(ADMIN_TOKEN_KEY, accessToken);
      localStorage.setItem(ADMIN_USER_KEY, JSON.stringify(formattedUser));

      set({
        token: accessToken,
        user: formattedUser,
        isAuthenticated: true,
        isLoading: false,
      });

      connectSocket();

      return { role: formattedUser.role };
    } catch (error) {
      set({ isLoading: false });
      throw error;
    }
  },

  logout: () => {
    localStorage.removeItem(ADMIN_TOKEN_KEY);
    localStorage.removeItem(ADMIN_USER_KEY);
    disconnectSocket();
    set({
      token: null,
      user: null,
      isAuthenticated: false,
      isLoading: false,
    });
  },
}));

// Initialize socket if already logged in
const state = useAuthStore.getState();
if (state.token && state.user) {
  state.initialize();
}
