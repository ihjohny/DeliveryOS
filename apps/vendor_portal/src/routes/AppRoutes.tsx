import React from 'react';
import { Routes, Route } from 'react-router-dom';
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
  return (
    <Routes>
      {/* Auth Public Pages */}
      <Route element={<AuthLayout />}>
        <Route path="/login" element={<LoginPage />} />
      </Route>

      {/* Access Denied */}
      <Route path="/unauthorized" element={<UnauthorizedPage />} />

      {/* Vendor Staff & Merchant Protected Routes (Strictly VENDOR_ADMIN) */}
      <Route
        element={
          <RoleGuard allowedRoles={[UserRole.VENDOR_ADMIN]}>
            <VendorLayout />
          </RoleGuard>
        }
      >
        <Route path="/" element={<VendorDashboardPage />} />
        <Route path="/kds" element={<VendorDashboardPage />} />
        <Route path="/catalog" element={<VendorCatalogPage />} />
        <Route path="/orders" element={<VendorOrdersPage />} />
        <Route path="/settings" element={<VendorSettingsPage />} />
      </Route>

      {/* 404 Fallback */}
      <Route path="*" element={<NotFoundPage />} />
    </Routes>
  );
};
