import React from 'react';
import { useNavigate } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { ShieldAlert, ArrowLeft, LogOut } from 'lucide-react';
import { useAuth } from '../../contexts/AuthContext';
import { Button } from '../../components/ui/Button';

export const UnauthorizedPage: React.FC = () => {
  const { t } = useTranslation();
  const { user, logout } = useAuth();
  const navigate = useNavigate();

  const handleReturn = () => {
    if (user?.role === 'SUPER_ADMIN') {
      navigate('/admin');
    } else if (user?.role === 'VENDOR_ADMIN') {
      navigate('/vendor');
    } else {
      logout();
      navigate('/login');
    }
  };

  return (
    <div className="flex min-h-screen flex-col items-center justify-center bg-slate-50 p-4 text-center dark:bg-slate-950">
      <div className="w-full max-w-md rounded-2xl border border-slate-200 bg-white p-8 shadow-xl dark:border-slate-800 dark:bg-slate-900">
        <div className="mx-auto mb-4 flex h-14 w-14 items-center justify-center rounded-2xl bg-rose-50 text-rose-600 dark:bg-rose-950/50 dark:text-rose-400">
          <ShieldAlert className="h-8 w-8" />
        </div>
        <h2 className="text-xl font-bold text-slate-900 dark:text-slate-100">{t('auth.unauthorizedTitle')}</h2>
        <p className="mt-2 text-sm text-slate-500 dark:text-slate-400">
          {t('auth.unauthorizedSubtitle')}
        </p>

        {user && (
          <div className="mt-4 rounded-lg bg-slate-50 p-3 text-xs text-slate-600 dark:bg-slate-800 dark:text-slate-300">
            <p>Signed in as: <strong className="font-semibold">{user.fullName}</strong> ({user.role})</p>
          </div>
        )}

        <div className="mt-6 flex flex-col gap-2.5">
          <Button
            variant="primary"
            onClick={handleReturn}
            leftIcon={<ArrowLeft className="h-4 w-4" />}
          >
            Return to Authorized Portal
          </Button>

          <Button
            variant="ghost"
            onClick={() => {
              logout();
              navigate('/login');
            }}
            leftIcon={<LogOut className="h-4 w-4" />}
          >
            {t('auth.switchAccount')}
          </Button>
        </div>
      </div>
    </div>
  );
};
