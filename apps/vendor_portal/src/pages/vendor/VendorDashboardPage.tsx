import React from 'react';
import { useTranslation } from 'react-i18next';
import {
  UtensilsCrossed,
  Clock,
  CheckCircle2,
  RefreshCw,
  Bell,
  VolumeX,
  Volume2,
  Sparkles,
} from 'lucide-react';
import { useAuth } from '../../contexts/AuthContext';
import { useVendorOutlet } from '../../contexts/VendorOutletContext';
import { useKDSOrders } from '../../hooks/useKDSOrders';
import { KDSOrderCard } from '../../components/kds/KDSOrderCard';
import { Button } from '../../components/ui/Button';
import { Badge } from '../../components/ui/Badge';
import { LoadingSpinner } from '../../components/ui/LoadingSpinner';
import { soundEngine } from '../../utils/sound';

export const VendorDashboardPage: React.FC = () => {
  const { t } = useTranslation();
  const { user } = useAuth();
  const { activeOutletId, activeOutlet } = useVendorOutlet();

  const targetVendorId =
    activeOutletId && activeOutletId !== 'ALL'
      ? activeOutletId
      : user?.vendorId || undefined;

  const {
    isLoading,
    refetch,
    newOrders,
    inPreparationOrders,
    readyOrders,
    acceptOrder,
    rejectOrder,
    markOrderReady,
    handoverOrder,
    isAccepting,
    isRejecting,
    isMarkingReady,
    isHandingOver,
  } = useKDSOrders(targetVendorId);

  const totalActive = newOrders.length + inPreparationOrders.length + readyOrders.length;
  const isMuted = soundEngine.getIsMuted();
  const outletDisplayName = activeOutlet?.name || user?.vendorName || 'Consolidated Kitchen Operations';

  return (
    <div className="space-y-6">
      {/* Top Action Bar */}
      <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between border-b border-slate-200 pb-4 dark:border-slate-800">
        <div>
          <div className="flex items-center gap-2.5">
            <h2 className="text-2xl font-extrabold tracking-tight text-slate-900 dark:text-slate-100">
              {t('kds.title')}
            </h2>
            <Badge variant="purple" size="md">
              {totalActive} Active
            </Badge>
          </div>
          <p className="text-xs text-slate-500 dark:text-slate-400 mt-1">
            {outletDisplayName} &bull; Real-time kitchen order board & preparation dispatcher
          </p>
        </div>

        <div className="flex items-center gap-2.5">
          <Button
            variant="outline"
            size="sm"
            onClick={() => soundEngine.playChime()}
            leftIcon={<Bell className="h-4 w-4 text-amber-500" />}
          >
            Test Chime
          </Button>

          <Button
            variant="outline"
            size="sm"
            onClick={() => refetch()}
            leftIcon={<RefreshCw className="h-4 w-4" />}
          >
            {t('common.refresh')}
          </Button>
        </div>
      </div>

      {/* Loading state */}
      {isLoading ? (
        <div className="py-20">
          <LoadingSpinner size="lg" label="Synchronizing kitchen board..." />
        </div>
      ) : (
        /* 3-Lane Kanban View */
        <div className="grid grid-cols-1 gap-6 lg:grid-cols-3">
          {/* LANE 1: NEW ORDERS */}
          <div className="flex flex-col rounded-2xl border border-rose-200 bg-rose-50/25 p-4 dark:border-rose-950/60 dark:bg-rose-950/10 shadow-sm">
            <div className="flex items-center justify-between border-b border-rose-200/80 pb-3 dark:border-rose-900/40">
              <div className="flex items-center gap-2">
                <span className="relative flex h-3 w-3">
                  {newOrders.length > 0 && (
                    <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-rose-400 opacity-75" />
                  )}
                  <span className="relative inline-flex rounded-full h-3 w-3 bg-rose-500" />
                </span>
                <h3 className="font-bold text-rose-950 dark:text-rose-200">
                  {t('kds.newOrders')}
                </h3>
              </div>
              <Badge variant="danger" size="sm">
                {newOrders.length}
              </Badge>
            </div>

            <div className="mt-4 flex-1 space-y-4 overflow-y-auto max-h-[calc(100vh-280px)]">
              {newOrders.length === 0 ? (
                <div className="flex flex-col items-center justify-center py-12 text-center text-slate-400">
                  <div className="h-10 w-10 rounded-full bg-rose-100 dark:bg-rose-950/50 flex items-center justify-center mb-2 text-rose-500">
                    <Sparkles className="h-5 w-5" />
                  </div>
                  <p className="text-xs font-semibold">No incoming orders</p>
                  <span className="text-[11px] text-slate-400">Chime will sound when customer orders</span>
                </div>
              ) : (
                newOrders.map((order) => (
                  <KDSOrderCard
                    key={order.id}
                    order={order}
                    onAccept={acceptOrder}
                    onReject={rejectOrder}
                    isActionLoading={isAccepting}
                    isRejecting={isRejecting}
                  />
                ))
              )}
            </div>
          </div>

          {/* LANE 2: IN PREPARATION */}
          <div className="flex flex-col rounded-2xl border border-amber-200 bg-amber-50/25 p-4 dark:border-amber-950/60 dark:bg-amber-950/10 shadow-sm">
            <div className="flex items-center justify-between border-b border-amber-200/80 pb-3 dark:border-amber-900/40">
              <div className="flex items-center gap-2">
                <UtensilsCrossed className="h-4 w-4 text-amber-600 dark:text-amber-400" />
                <h3 className="font-bold text-amber-950 dark:text-amber-200">
                  {t('kds.preparing')}
                </h3>
              </div>
              <Badge variant="warning" size="sm">
                {inPreparationOrders.length}
              </Badge>
            </div>

            <div className="mt-4 flex-1 space-y-4 overflow-y-auto max-h-[calc(100vh-280px)]">
              {inPreparationOrders.length === 0 ? (
                <div className="flex flex-col items-center justify-center py-12 text-center text-slate-400">
                  <div className="h-10 w-10 rounded-full bg-amber-100 dark:bg-amber-950/50 flex items-center justify-center mb-2 text-amber-600">
                    <Clock className="h-5 w-5" />
                  </div>
                  <p className="text-xs font-semibold">Kitchen queue is clear</p>
                  <span className="text-[11px] text-slate-400">Accepted orders will appear here</span>
                </div>
              ) : (
                inPreparationOrders.map((order) => (
                  <KDSOrderCard
                    key={order.id}
                    order={order}
                    onMarkReady={markOrderReady}
                    isActionLoading={isMarkingReady}
                  />
                ))
              )}
            </div>
          </div>

          {/* LANE 3: READY FOR PICKUP */}
          <div className="flex flex-col rounded-2xl border border-emerald-200 bg-emerald-50/25 p-4 dark:border-emerald-950/60 dark:bg-emerald-950/10 shadow-sm">
            <div className="flex items-center justify-between border-b border-emerald-200/80 pb-3 dark:border-emerald-900/40">
              <div className="flex items-center gap-2">
                <CheckCircle2 className="h-4 w-4 text-emerald-600 dark:text-emerald-400" />
                <h3 className="font-bold text-emerald-950 dark:text-emerald-200">
                  {t('kds.ready')}
                </h3>
              </div>
              <Badge variant="success" size="sm">
                {readyOrders.length}
              </Badge>
            </div>

            <div className="mt-4 flex-1 space-y-4 overflow-y-auto max-h-[calc(100vh-280px)]">
              {readyOrders.length === 0 ? (
                <div className="flex flex-col items-center justify-center py-12 text-center text-slate-400">
                  <div className="h-10 w-10 rounded-full bg-emerald-100 dark:bg-emerald-950/50 flex items-center justify-center mb-2 text-emerald-600">
                    <CheckCircle2 className="h-5 w-5" />
                  </div>
                  <p className="text-xs font-semibold">Counter is clear</p>
                  <span className="text-[11px] text-slate-400">Packaged food awaiting riders will appear here</span>
                </div>
              ) : (
                readyOrders.map((order) => (
                  <KDSOrderCard
                    key={order.id}
                    order={order}
                    onHandover={handoverOrder}
                    isActionLoading={isHandingOver}
                  />
                ))
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
