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
import { AdminDispatchPage } from '../pages/admin/AdminDispatchPage';
import { AdminOrdersPage } from '../pages/admin/AdminOrdersPage';
import { AdminPromotionsPage } from '../pages/admin/AdminPromotionsPage';
import { AdminVendorsPage } from '../pages/admin/AdminVendorsPage';
import { AdminSettingsPage } from '../pages/admin/AdminSettingsPage';
import { VendorDashboardPage } from '../pages/vendor/VendorDashboardPage';
import { VendorCatalogPage } from '../pages/vendor/VendorCatalogPage';
import { VendorSettingsPage } from '../pages/vendor/VendorSettingsPage';
import { VendorOrdersPage } from '../pages/vendor/VendorOrdersPage';

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
        <Route path="vendors" element={<AdminVendorsPage />} />
        <Route path="dispatch" element={<AdminDispatchPage />} />
        <Route path="orders" element={<AdminOrdersPage />} />
        <Route path="promotions" element={<AdminPromotionsPage />} />
        <Route path="settings" element={<AdminSettingsPage />} />
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
        <Route path="orders" element={<VendorOrdersPage />} />
        <Route path="settings" element={<VendorSettingsPage />} />
      </Route>

      {/* 404 Fallback */}
      <Route path="*" element={<NotFoundPage />} />
    </Routes>
  );
};
