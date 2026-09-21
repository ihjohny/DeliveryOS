import React from 'react';
import { Routes, Route } from 'react-router-dom';
import { UserRole } from '../types/auth';
import { RoleGuard } from './RoleGuard';

// Layouts
import { AdminLayout } from '../layouts/AdminLayout';
import { AuthLayout } from '../layouts/AuthLayout';

// Pages
import { LoginPage } from '../pages/auth/LoginPage';
import { UnauthorizedPage } from '../pages/common/UnauthorizedPage';
import { NotFoundPage } from '../pages/common/NotFoundPage';
import { AdminDashboardPage } from '../pages/admin/AdminDashboardPage';
import { AdminDispatchPage } from '../pages/admin/AdminDispatchPage';
import { AdminOrdersPage } from '../pages/admin/AdminOrdersPage';
import { AdminPromotionsPage } from '../pages/admin/AdminPromotionsPage';
import { AdminVendorsPage } from '../pages/admin/AdminVendorsPage';
import { AdminSettingsPage } from '../pages/admin/AdminSettingsPage';

export const AppRoutes: React.FC = () => {
  return (
    <Routes>
      {/* Auth Public Pages */}
      <Route element={<AuthLayout />}>
        <Route path="/login" element={<LoginPage />} />
      </Route>

      {/* Access Denied */}
      <Route path="/unauthorized" element={<UnauthorizedPage />} />

      {/* Super Admin Protected Routes */}
      <Route
        element={
          <RoleGuard allowedRoles={[UserRole.SUPER_ADMIN]}>
            <AdminLayout />
          </RoleGuard>
        }
      >
        <Route path="/" element={<AdminDashboardPage />} />
        <Route path="/dashboard" element={<AdminDashboardPage />} />
        <Route path="/vendors" element={<AdminVendorsPage />} />
        <Route path="/dispatch" element={<AdminDispatchPage />} />
        <Route path="/orders" element={<AdminOrdersPage />} />
        <Route path="/promotions" element={<AdminPromotionsPage />} />
        <Route path="/settings" element={<AdminSettingsPage />} />
      </Route>

      {/* 404 Fallback */}
      <Route path="*" element={<NotFoundPage />} />
    </Routes>
  );
};
