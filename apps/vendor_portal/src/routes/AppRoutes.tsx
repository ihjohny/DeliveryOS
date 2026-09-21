import React from 'react';
import { Routes, Route, Navigate } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';
import { UserRole } from '../types/auth';
import { RoleGuard } from './RoleGuard';

// Layouts
import { VendorLayout } from '../layouts/VendorLayout';
import { AuthLayout } from '../layouts/AuthLayout';

// Pages
import { LoginPage } from '../pages/auth/LoginPage';
import { UnauthorizedPage } from '../pages/common/UnauthorizedPage';
import { NotFoundPage } from '../pages/common/NotFoundPage';
import { VendorDashboardPage } from '../pages/vendor/VendorDashboardPage';
import { VendorCatalogPage } from '../pages/vendor/VendorCatalogPage';
import { VendorSettingsPage } from '../pages/vendor/VendorSettingsPage';
import { VendorOrdersPage } from '../pages/vendor/VendorOrdersPage';

export const AppRoutes: React.FC = () => {
  const { user, isAuthenticated, isLoading } = useAuth();

  const getRootRedirect = () => {
    if (isLoading) return null;
    if (!isAuthenticated || !user) return <Navigate to="/login" replace />;
    if (user.role === UserRole.VENDOR_ADMIN || user.role === UserRole.SUPER_ADMIN) {
      return <VendorLayout />;
    }
    return <Navigate to="/unauthorized" replace />;
  };

  return (
    <Routes>
      {/* Auth Public Pages */}
      <Route element={<AuthLayout />}>
        <Route path="/login" element={<LoginPage />} />
      </Route>

      {/* Access Denied */}
      <Route path="/unauthorized" element={<UnauthorizedPage />} />

      {/* Vendor Staff & Merchant Protected Routes */}
      <Route
        element={
          <RoleGuard allowedRoles={[UserRole.VENDOR_ADMIN, UserRole.SUPER_ADMIN]}>
            <VendorLayout />
          </RoleGuard>
        }
      >
        <Route path="/" element={<VendorDashboardPage />} />
        <Route path="/kds" element={<VendorDashboardPage />} />
        <Route path="/catalog" element={<VendorCatalogPage />} />
        <Route path="/orders" element={<VendorOrdersPage />} />
        <Route path="/settings" element={<VendorSettingsPage />} />

        {/* Backward-compatibility redirects for /vendor prefixes */}
        <Route path="/vendor" element={<Navigate to="/" replace />} />
        <Route path="/vendor/catalog" element={<Navigate to="/catalog" replace />} />
        <Route path="/vendor/orders" element={<Navigate to="/orders" replace />} />
        <Route path="/vendor/settings" element={<Navigate to="/settings" replace />} />
      </Route>

      {/* 404 Fallback */}
      <Route path="*" element={<NotFoundPage />} />
    </Routes>
  );
};
