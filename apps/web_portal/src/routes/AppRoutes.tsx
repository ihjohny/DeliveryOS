import React from 'react';
import { Routes, Route, Navigate } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';
import { UserRole } from '../types/auth';
import { RoleGuard } from './RoleGuard';

// Layouts
import { AdminLayout } from '../layouts/AdminLayout';
import { VendorLayout } from '../layouts/VendorLayout';
import { AuthLayout } from '../layouts/AuthLayout';

// Pages
import { LoginPage } from '../pages/auth/LoginPage';
import { UnauthorizedPage } from '../pages/common/UnauthorizedPage';
import { NotFoundPage } from '../pages/common/NotFoundPage';
import { PlaceholderPage } from '../pages/common/PlaceholderPage';
import { AdminDashboardPage } from '../pages/admin/AdminDashboardPage';
import { VendorDashboardPage } from '../pages/vendor/VendorDashboardPage';
import { VendorCatalogPage } from '../pages/vendor/VendorCatalogPage';

export const AppRoutes: React.FC = () => {
  const { user, isAuthenticated, isLoading } = useAuth();

  const getRootRedirect = () => {
    if (isLoading) return null;
    if (!isAuthenticated || !user) return <Navigate to="/login" replace />;
    if (user.role === UserRole.SUPER_ADMIN) return <Navigate to="/admin" replace />;
    if (user.role === UserRole.VENDOR_ADMIN) return <Navigate to="/vendor" replace />;
    return <Navigate to="/unauthorized" replace />;
  };

  return (
    <Routes>
      {/* Root redirection based on user role */}
      <Route path="/" element={getRootRedirect()} />

      {/* Auth Public Pages */}
      <Route element={<AuthLayout />}>
        <Route path="/login" element={<LoginPage />} />
      </Route>

      {/* Access Denied */}
      <Route path="/unauthorized" element={<UnauthorizedPage />} />

      {/* Super Admin Protected Routes */}
      <Route
        path="/admin"
        element={
          <RoleGuard allowedRoles={[UserRole.SUPER_ADMIN]}>
            <AdminLayout />
          </RoleGuard>
        }
      >
        <Route index element={<AdminDashboardPage />} />
        <Route
          path="vendors"
          element={<PlaceholderPage title="Merchants & Outlets" subtitle="Manage vendor branches and outlet onboardings" />}
        />
        <Route
          path="dispatch"
          element={<PlaceholderPage title="Live Dispatch & Fleet Map" subtitle="Real-time rider fleet oversight and active order routes" />}
        />
        <Route
          path="orders"
          element={<PlaceholderPage title="Master Order Ledger" subtitle="Complete historical orders and financial ledgers" />}
        />
        <Route
          path="promotions"
          element={<PlaceholderPage title="Promotions & Coupons" subtitle="Discount campaigns and billboard banners" />}
        />
        <Route
          path="settings"
          element={<PlaceholderPage title="System Settings" subtitle="Platform configuration and order flow mode" />}
        />
      </Route>

      {/* Vendor Staff & Merchant Protected Routes */}
      <Route
        path="/vendor"
        element={
          <RoleGuard allowedRoles={[UserRole.VENDOR_ADMIN, UserRole.SUPER_ADMIN]}>
            <VendorLayout />
          </RoleGuard>
        }
      >
        <Route index element={<VendorDashboardPage />} />
        <Route path="catalog" element={<VendorCatalogPage />} />
        <Route
          path="orders"
          element={<PlaceholderPage title="Order History" subtitle="Completed and past fulfilled kitchen orders" />}
        />
        <Route
          path="settings"
          element={<PlaceholderPage title="Outlet Settings" subtitle="Preparation times, store hours, and operational status" />}
        />
      </Route>

      {/* 404 Fallback */}
      <Route path="*" element={<NotFoundPage />} />
    </Routes>
  );
};
