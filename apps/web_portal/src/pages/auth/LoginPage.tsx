import React, { useState } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { LogIn, Lock, Phone, KeyRound, Sparkles } from 'lucide-react';
import { useAuth } from '../../contexts/AuthContext';
import { UserRole } from '../../types/auth';
import { Button } from '../../components/ui/Button';
import { Input } from '../../components/ui/Input';
import { Alert } from '../../components/ui/Alert';

export const LoginPage: React.FC = () => {
  const { t } = useTranslation();
  const { login } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();

  const [phone, setPhone] = useState('');
  const [password, setPassword] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [errorMsg, setErrorMsg] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!phone || !password) return;

    setErrorMsg(null);
    setIsLoading(true);

    try {
      const result = await login(phone, password);

      // Determine redirect path
      const from = (location.state as { from?: { pathname: string } })?.from?.pathname;

      if (from && from !== '/login') {
        navigate(from, { replace: true });
      } else if (result.role === UserRole.SUPER_ADMIN) {
        navigate('/admin', { replace: true });
      } else if (result.role === UserRole.VENDOR_ADMIN) {
        navigate('/vendor', { replace: true });
      } else {
        navigate('/unauthorized', { replace: true });
      }
    } catch (err: unknown) {
      console.error('Login error:', err);
      const responseError = (err as { response?: { data?: { message?: string } } })?.response?.data?.message;
      setErrorMsg(responseError || t('auth.loginFailed'));
    } finally {
      setIsLoading(false);
    }
  };

  const handleQuickFill = (demoPhone: string) => {
    setPhone(demoPhone);
    setPassword('123456');
    setErrorMsg(null);
  };

  return (
    <div className="rounded-2xl border border-slate-800 bg-slate-900/90 p-6 sm:p-8 shadow-2xl backdrop-blur-xl">
      <div className="mb-6 text-center">
        <div className="inline-flex h-12 w-12 items-center justify-center rounded-xl bg-primary-600/20 text-primary-400 mb-3 border border-primary-500/30">
          <KeyRound className="h-6 w-6" />
        </div>
        <h2 className="text-2xl font-bold tracking-tight text-white">{t('auth.title')}</h2>
        <p className="mt-1 text-xs text-slate-400">{t('auth.subtitle')}</p>
      </div>

      {errorMsg && (
        <Alert
          type="error"
          message={errorMsg}
          className="mb-5 bg-rose-950/50 border-rose-800 text-rose-200"
          onDismiss={() => setErrorMsg(null)}
        />
      )}

      <form onSubmit={handleSubmit} className="space-y-4">
        <div>
          <Input
            label={t('auth.phoneLabel')}
            type="tel"
            placeholder={t('auth.phonePlaceholder')}
            value={phone}
            onChange={(e) => setPhone(e.target.value)}
            leftIcon={<Phone className="h-4 w-4" />}
            required
            className="bg-slate-800/80 border-slate-700 text-white placeholder-slate-500"
          />
        </div>

        <div>
          <Input
            label={t('auth.passwordLabel')}
            type="password"
            placeholder={t('auth.passwordPlaceholder')}
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            leftIcon={<Lock className="h-4 w-4" />}
            required
            className="bg-slate-800/80 border-slate-700 text-white placeholder-slate-500"
          />
        </div>

        <Button
          type="submit"
          variant="primary"
          className="w-full mt-2"
          isLoading={isLoading}
          rightIcon={<LogIn className="h-4 w-4" />}
        >
          {isLoading ? t('auth.signingIn') : t('auth.loginButton')}
        </Button>
      </form>

      {/* Demo Credentials Quick-Fill Buttons */}
      <div className="mt-6 border-t border-slate-800/80 pt-5">
        <div className="flex items-center gap-1.5 text-xs font-semibold text-slate-400 mb-3">
          <Sparkles className="h-3.5 w-3.5 text-amber-400" />
          <span>{t('auth.quickFillTitle')}</span>
        </div>
        <div className="grid grid-cols-1 gap-2">
          <button
            type="button"
            onClick={() => handleQuickFill('+8801700000001')}
            className="flex items-center justify-between rounded-lg border border-slate-800 bg-slate-800/50 px-3 py-2 text-left text-xs transition-colors hover:border-primary-500/50 hover:bg-slate-800 text-slate-300"
          >
            <span className="font-semibold text-primary-400">{t('auth.superAdmin')}</span>
            <span className="text-[11px] text-slate-500">+8801700000001</span>
          </button>

          <button
            type="button"
            onClick={() => handleQuickFill('+8801700000002')}
            className="flex items-center justify-between rounded-lg border border-slate-800 bg-slate-800/50 px-3 py-2 text-left text-xs transition-colors hover:border-amber-500/50 hover:bg-slate-800 text-slate-300"
          >
            <span className="font-semibold text-amber-400">{t('auth.branchManager')}</span>
            <span className="text-[11px] text-slate-500">+8801700000002</span>
          </button>

          <button
            type="button"
            onClick={() => handleQuickFill('+8801700000003')}
            className="flex items-center justify-between rounded-lg border border-slate-800 bg-slate-800/50 px-3 py-2 text-left text-xs transition-colors hover:border-purple-500/50 hover:bg-slate-800 text-slate-300"
          >
            <span className="font-semibold text-purple-400">{t('auth.brandOwner')}</span>
            <span className="text-[11px] text-slate-500">+8801700000003</span>
          </button>
        </div>
      </div>
    </div>
  );
};
