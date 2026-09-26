import React, { useState } from 'react';
import { Link, Outlet, useLocation } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import {
  LayoutDashboard,
  Store,
  Navigation,
  FileText,
  Tag,
  Settings,
  LogOut,
  Menu,
  X,
  ShieldCheck,
} from 'lucide-react';
import { useAuth } from '../contexts/AuthContext';
import { LanguageSelector } from '../components/LanguageSelector';
import { Badge } from '../components/ui/Badge';

export const AdminLayout: React.FC = () => {
  const { t } = useTranslation();
  const { user, logout } = useAuth();
  const location = useLocation();
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);

  const navItems = [
    { label: t('nav.admin.dashboard'), href: '/', icon: LayoutDashboard },
    { label: t('nav.admin.vendors'), href: '/vendors', icon: Store },
    { label: t('nav.admin.dispatch'), href: '/dispatch', icon: Navigation },
    { label: t('nav.admin.orders'), href: '/orders', icon: FileText },
    { label: t('nav.admin.promotions'), href: '/promotions', icon: Tag },
    { label: t('nav.admin.settings'), href: '/settings', icon: Settings },
  ];

  const isActive = (href: string) => {
    if (href === '/') return location.pathname === '/' || location.pathname === '/admin' || location.pathname === '/dashboard';
    return location.pathname === href || location.pathname.startsWith(`${href}/`) || location.pathname.startsWith(`/admin${href}`);
  };

  return (
    <div className="flex min-h-screen bg-slate-50 dark:bg-slate-950">
      <aside className="hidden w-64 flex-col border-r border-slate-200 bg-white dark:border-slate-800 dark:bg-slate-900 lg:flex shrink-0">
        <div className="flex h-16 items-center gap-3 border-b border-slate-100 px-6 dark:border-slate-800">
          <div className="flex h-9 w-9 items-center justify-center rounded-xl bg-primary-600 text-white shadow-md">
            <ShieldCheck className="h-5 w-5" />
          </div>
          <div>
            <h1 className="text-base font-bold tracking-tight text-slate-900 dark:text-slate-100">DeliveryOS</h1>
            <span className="text-[10px] font-semibold uppercase tracking-wider text-primary-600 dark:text-primary-400">
              Admin Console
            </span>
          </div>
        </div>

        <nav className="flex-1 space-y-1 p-4 overflow-y-auto">
          {navItems.map((item) => {
            const Icon = item.icon;
            const active = isActive(item.href);
            return (
              <Link
                key={item.href}
                to={item.href}
                className={`flex items-center gap-3 rounded-lg px-3.5 py-2.5 text-sm font-medium transition-all ${
                  active
                    ? 'bg-primary-50 text-primary-700 shadow-sm dark:bg-primary-950/50 dark:text-primary-400 font-semibold'
                    : 'text-slate-600 hover:bg-slate-50 hover:text-slate-900 dark:text-slate-400 dark:hover:bg-slate-800 dark:hover:text-slate-100'
                }`}
              >
                <Icon className={`h-4 w-4 ${active ? 'text-primary-600 dark:text-primary-400' : 'text-slate-400'}`} />
                <span>{item.label}</span>
              </Link>
            );
          })}
        </nav>

        <div className="border-t border-slate-100 p-4 dark:border-slate-800 shrink-0">
          <div className="flex items-center gap-3 mb-3">
            <div className="h-8 w-8 rounded-full bg-primary-100 text-primary-700 flex items-center justify-center font-bold text-xs shrink-0">
              {user?.fullName?.charAt(0) || 'A'}
            </div>
            <div className="flex-1 min-w-0">
              <p className="text-xs font-semibold text-slate-900 dark:text-slate-100 truncate">{user?.fullName}</p>
              <p className="text-[11px] text-slate-500 truncate">{user?.role}</p>
            </div>
          </div>
          <button
            onClick={logout}
            className="flex w-full items-center gap-2 rounded-lg px-3 py-2 text-xs font-medium text-rose-600 hover:bg-rose-50 dark:text-rose-400 dark:hover:bg-rose-950/30 transition-colors"
          >
            <LogOut className="h-4 w-4 shrink-0" />
            <span>{t('common.logout')}</span>
          </button>
        </div>
      </aside>

      <div className="flex flex-1 flex-col min-w-0 overflow-hidden">
        <header className="flex h-16 items-center justify-between border-b border-slate-200 bg-white px-4 shadow-sm dark:border-slate-800 dark:bg-slate-900 sm:px-6 shrink-0">
          <div className="flex items-center gap-2.5 sm:gap-3">
            <button
              onClick={() => setIsMobileMenuOpen(true)}
              className="rounded-lg p-2 text-slate-600 hover:bg-slate-100 dark:text-slate-300 dark:hover:bg-slate-800 lg:hidden"
              aria-label="Open mobile menu"
            >
              <Menu className="h-5 w-5" />
            </button>
            <div className="flex items-center gap-2">
              <span className="text-sm font-bold text-slate-900 dark:text-slate-100 lg:hidden">DeliveryOS</span>
              <Badge variant="purple" size="sm">Super Admin Portal</Badge>
            </div>
          </div>

          <div className="flex items-center gap-3">
            <LanguageSelector />
          </div>
        </header>

        {isMobileMenuOpen && (
          <div className="fixed inset-0 z-50 lg:hidden">
            <div
              className="fixed inset-0 bg-slate-900/60 backdrop-blur-sm transition-opacity"
              onClick={() => setIsMobileMenuOpen(false)}
              aria-hidden="true"
            />
            <div className="fixed inset-y-0 left-0 w-72 max-w-[85vw] bg-white dark:bg-slate-900 border-r border-slate-200 dark:border-slate-800 shadow-2xl flex flex-col z-10">
              <div className="flex h-16 items-center justify-between border-b border-slate-100 px-5 dark:border-slate-800">
                <div className="flex items-center gap-2.5">
                  <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-primary-600 text-white shadow-sm">
                    <ShieldCheck className="h-4 w-4" />
                  </div>
                  <div>
                    <h2 className="text-sm font-bold text-slate-900 dark:text-slate-100">DeliveryOS</h2>
                    <span className="text-[10px] font-semibold uppercase tracking-wider text-primary-600 dark:text-primary-400">
                      Admin Console
                    </span>
                  </div>
                </div>
                <button
                  onClick={() => setIsMobileMenuOpen(false)}
                  className="rounded-lg p-1.5 text-slate-400 hover:bg-slate-100 hover:text-slate-600 dark:hover:bg-slate-800 dark:hover:text-slate-300"
                  aria-label="Close menu"
                >
                  <X className="h-5 w-5" />
                </button>
              </div>

              <nav className="flex-1 space-y-1 p-4 overflow-y-auto">
                {navItems.map((item) => {
                  const Icon = item.icon;
                  const active = isActive(item.href);
                  return (
                    <Link
                      key={item.href}
                      to={item.href}
                      onClick={() => setIsMobileMenuOpen(false)}
                      className={`flex items-center gap-3 rounded-lg px-3.5 py-2.5 text-sm font-medium transition-colors ${
                        active
                          ? 'bg-primary-50 text-primary-700 dark:bg-primary-950/50 dark:text-primary-400 font-semibold'
                          : 'text-slate-600 hover:bg-slate-50 dark:text-slate-300 dark:hover:bg-slate-800'
                      }`}
                    >
                      <Icon className="h-4 w-4 shrink-0" />
                      <span>{item.label}</span>
                    </Link>
                  );
                })}
              </nav>

              <div className="border-t border-slate-100 p-4 dark:border-slate-800 shrink-0">
                <div className="flex items-center gap-3 mb-3">
                  <div className="h-8 w-8 rounded-full bg-primary-100 text-primary-700 flex items-center justify-center font-bold text-xs shrink-0">
                    {user?.fullName?.charAt(0) || 'A'}
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="text-xs font-semibold text-slate-900 dark:text-slate-100 truncate">{user?.fullName}</p>
                    <p className="text-[11px] text-slate-500 truncate">{user?.role}</p>
                  </div>
                </div>
                <button
                  onClick={() => {
                    setIsMobileMenuOpen(false);
                    logout();
                  }}
                  className="flex w-full items-center gap-2 rounded-lg px-3 py-2 text-xs font-medium text-rose-600 hover:bg-rose-50 dark:text-rose-400 dark:hover:bg-rose-950/30 transition-colors"
                >
                  <LogOut className="h-4 w-4 shrink-0" />
                  <span>{t('common.logout')}</span>
                </button>
              </div>
            </div>
          </div>
        )}

        <main className="flex-1 overflow-y-auto p-4 sm:p-6 lg:p-8">
          <Outlet />
        </main>
      </div>
    </div>
  );
};
