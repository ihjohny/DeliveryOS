import React from 'react';
import { useTranslation } from 'react-i18next';
import { Utensils, Clock, CheckCircle, Bell, ArrowRight } from 'lucide-react';
import { useAuth } from '../../contexts/AuthContext';
import { Button } from '../../components/ui/Button';
import { Badge } from '../../components/ui/Badge';
import { soundEngine } from '../../utils/sound';

export const VendorDashboardPage: React.FC = () => {
  const { t } = useTranslation();
  const { user } = useAuth();

  const handleTestAlarm = () => {
    soundEngine.playChime();
  };

  return (
    <div className="space-y-6">
      <div className="flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h2 className="text-2xl font-bold tracking-tight text-slate-900 dark:text-slate-100">
            {t('kds.title')}
          </h2>
          <p className="text-sm text-slate-500 dark:text-slate-400">
            {user?.vendorName} &bull; {t('kds.subtitle')}
          </p>
        </div>
        <div className="flex items-center gap-2">
          <Button
            variant="outline"
            size="sm"
            onClick={handleTestAlarm}
            leftIcon={<Bell className="h-4 w-4 text-amber-500" />}
          >
            Test Chime
          </Button>
        </div>
      </div>

      {/* 3-Lane Kanban Scaffolding */}
      <div className="grid grid-cols-1 gap-6 md:grid-cols-3">
        {/* Lane 1: New Orders */}
        <div className="rounded-2xl border border-rose-200 bg-rose-50/30 p-4 dark:border-rose-900/50 dark:bg-rose-950/10">
          <div className="flex items-center justify-between border-b border-rose-200 pb-3 dark:border-rose-900/50">
            <div className="flex items-center gap-2">
              <span className="h-3 w-3 rounded-full bg-rose-500 animate-pulse" />
              <h3 className="font-bold text-rose-900 dark:text-rose-300">{t('kds.newOrders')}</h3>
            </div>
            <Badge variant="danger" size="sm">1</Badge>
          </div>

          <div className="mt-4 space-y-3">
            <div className="rounded-xl border border-rose-200 bg-white p-4 shadow-sm dark:border-rose-900/40 dark:bg-slate-900">
              <div className="flex items-center justify-between">
                <span className="font-bold text-slate-900 dark:text-slate-100">#ORD-20260917-8821</span>
                <span className="text-xs font-semibold text-rose-600 bg-rose-50 px-2 py-0.5 rounded-full dark:bg-rose-950/60">
                  Just now
                </span>
              </div>
              <div className="mt-2 space-y-1 text-xs text-slate-600 dark:text-slate-300">
                <p>2 &times; Classic Smoky Beef Burger</p>
                <p>1 &times; Crispy French Fries (L)</p>
              </div>
              <div className="mt-4 flex items-center justify-between gap-2 border-t border-slate-100 pt-3 dark:border-slate-800">
                <span className="text-xs text-slate-400">Est. 20 mins</span>
                <Button size="sm" variant="primary" rightIcon={<ArrowRight className="h-3.5 w-3.5" />}>
                  {t('kds.acceptOrder')}
                </Button>
              </div>
            </div>
          </div>
        </div>

        {/* Lane 2: Preparing */}
        <div className="rounded-2xl border border-amber-200 bg-amber-50/30 p-4 dark:border-amber-900/50 dark:bg-amber-950/10">
          <div className="flex items-center justify-between border-b border-amber-200 pb-3 dark:border-amber-900/50">
            <div className="flex items-center gap-2">
              <Utensils className="h-4 w-4 text-amber-600 dark:text-amber-400" />
              <h3 className="font-bold text-amber-900 dark:text-amber-300">{t('kds.preparing')}</h3>
            </div>
            <Badge variant="warning" size="sm">2</Badge>
          </div>

          <div className="mt-4 space-y-3">
            <div className="rounded-xl border border-amber-200 bg-white p-4 shadow-sm dark:border-amber-900/40 dark:bg-slate-900">
              <div className="flex items-center justify-between">
                <span className="font-bold text-slate-900 dark:text-slate-100">#ORD-20260917-7729</span>
                <span className="flex items-center text-xs font-semibold text-amber-600">
                  <Clock className="h-3 w-3 mr-1" />
                  12m left
                </span>
              </div>
              <div className="mt-2 text-xs text-slate-600 dark:text-slate-300">
                <p>1 &times; Double Cheeseburger Extra Bacon</p>
              </div>
              <div className="mt-4 flex justify-end border-t border-slate-100 pt-3 dark:border-slate-800">
                <Button size="sm" variant="secondary">
                  {t('kds.markReady')}
                </Button>
              </div>
            </div>
          </div>
        </div>

        {/* Lane 3: Ready for Pickup */}
        <div className="rounded-2xl border border-emerald-200 bg-emerald-50/30 p-4 dark:border-emerald-900/50 dark:bg-emerald-950/10">
          <div className="flex items-center justify-between border-b border-emerald-200 pb-3 dark:border-emerald-900/50">
            <div className="flex items-center gap-2">
              <CheckCircle className="h-4 w-4 text-emerald-600 dark:text-emerald-400" />
              <h3 className="font-bold text-emerald-900 dark:text-emerald-300">{t('kds.ready')}</h3>
            </div>
            <Badge variant="success" size="sm">1</Badge>
          </div>

          <div className="mt-4 space-y-3">
            <div className="rounded-xl border border-emerald-200 bg-white p-4 shadow-sm dark:border-emerald-900/40 dark:bg-slate-900">
              <div className="flex items-center justify-between">
                <span className="font-bold text-slate-900 dark:text-slate-100">#ORD-20260917-6410</span>
                <span className="text-xs text-emerald-600 font-semibold">Rider Nearby</span>
              </div>
              <div className="mt-2 text-xs text-slate-600 dark:text-slate-300">
                <p>1 &times; Chicken Patty Burger Meal</p>
              </div>
              <div className="mt-4 flex justify-end border-t border-slate-100 pt-3 dark:border-slate-800">
                <Button size="sm" variant="primary">
                  {t('kds.handover')}
                </Button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};
