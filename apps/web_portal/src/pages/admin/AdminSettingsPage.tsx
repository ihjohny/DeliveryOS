import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import {
  Settings,
  Shuffle,
  DollarSign,
  FileSpreadsheet,
  Download,
  CheckCircle2,
  AlertCircle,
  Truck,
  Store,
  Layers,
} from 'lucide-react';
import adminApi, { SettlementStatement } from '../../services/adminApi';
import { Badge } from '../../components/ui/Badge';
import { Button } from '../../components/ui/Button';
import { Input } from '../../components/ui/Input';
import { Alert } from '../../components/ui/Alert';
import { LoadingSpinner } from '../../components/ui/LoadingSpinner';

export const AdminSettingsPage: React.FC = () => {
  const queryClient = useQueryClient();
  const [isExporting, setIsExporting] = useState(false);

  // Queries
  const { data: settings, isLoading: isLoadingSettings } = useQuery({
    queryKey: ['admin-settings'],
    queryFn: adminApi.getSettings,
  });

  const { data: settlements = [], isLoading: isLoadingSettlements } = useQuery({
    queryKey: ['admin-settlements'],
    queryFn: adminApi.getSettlementStatements,
  });

  // Mutations
  const updateOrderFlowMutation = useMutation({
    mutationFn: ({ mode, timeout }: { mode: 'RIDER_FIRST' | 'VENDOR_FIRST'; timeout?: number }) =>
      adminApi.updateOrderFlow(mode, timeout),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin-settings'] });
    },
  });

  const updateDeliveryFeeMutation = useMutation({
    mutationFn: (data: { mode: 'FIXED_FLAT' | 'DISTANCE_TIERED'; flatFee?: number }) =>
      adminApi.updateDeliveryFeeMode(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin-settings'] });
    },
  });

  const handleExportCsv = async () => {
    try {
      setIsExporting(true);
      const blob = await adminApi.exportSettlementCsv();
      const url = window.URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `vendor-settlements-${new Date().toISOString().slice(0, 10)}.csv`;
      document.body.appendChild(a);
      a.click();
      a.remove();
      window.URL.revokeObjectURL(url);
    } catch (err) {
      console.error('Failed to download settlement CSV:', err);
      alert('Failed to download settlement statement CSV.');
    } finally {
      setIsExporting(false);
    }
  };

  const currentFlowMode = settings?.orderFlow?.mode || 'RIDER_FIRST';
  const currentFeeMode = settings?.deliveryFee?.mode || 'FIXED_FLAT';

  // Settlement totals
  const totalGross = settlements.reduce((acc, s) => acc + s.grossSales, 0);
  const totalCommission = settlements.reduce((acc, s) => acc + s.platformCommission, 0);
  const totalPayable = settlements.reduce((acc, s) => acc + s.netVendorPayable, 0);
  const totalOrders = settlements.reduce((acc, s) => acc + s.totalOrders, 0);

  return (
    <div className="space-y-8">
      {/* Header */}
      <div>
        <h1 className="text-2xl font-bold tracking-tight text-slate-900 dark:text-slate-100 flex items-center gap-2.5">
          <Settings className="h-6 w-6 text-primary-600 dark:text-primary-400" />
          System Settings & Financial Settlements
        </h1>
        <p className="text-sm text-slate-500 dark:text-slate-400">
          Configure real-time dispatch state machines, pricing pipelines, and export vendor payout statements
        </p>
      </div>

      {/* Section 1: Order Flow State Machine */}
      <div className="rounded-xl border border-slate-200 bg-white p-6 shadow-sm dark:border-slate-800 dark:bg-slate-900 space-y-4">
        <div>
          <h2 className="text-base font-bold text-slate-900 dark:text-slate-100 flex items-center gap-2">
            <Shuffle className="h-5 w-5 text-primary-600" />
            Order Fulfillment Pipeline Mode
          </h2>
          <p className="text-xs text-slate-500">
            DeliveryOS dynamic FSM switches the coordination sequence between kitchen prep and courier dispatch.
          </p>
        </div>

        <div className="grid grid-cols-1 gap-4 md:grid-cols-2">
          {/* RIDER_FIRST */}
          <div
            onClick={() => updateOrderFlowMutation.mutate({ mode: 'RIDER_FIRST' })}
            className={`cursor-pointer rounded-xl border p-5 transition-all ${
              currentFlowMode === 'RIDER_FIRST'
                ? 'border-primary-600 bg-primary-50/50 dark:border-primary-500 dark:bg-primary-950/20 ring-2 ring-primary-500/20'
                : 'border-slate-200 hover:border-slate-300 dark:border-slate-800 dark:hover:border-slate-700'
            }`}
          >
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2">
                <Truck className="h-5 w-5 text-primary-600" />
                <span className="font-bold text-sm text-slate-900 dark:text-slate-100">
                  RIDER_FIRST (Zero Food Waste Mode)
                </span>
              </div>
              {currentFlowMode === 'RIDER_FIRST' && <Badge variant="success">Active</Badge>}
            </div>
            <p className="mt-2 text-xs text-slate-600 dark:text-slate-400">
              When an order is placed, it is first broadcast to nearby riders. The kitchen chime is withheld until a courier accepts the delivery, ensuring food is never prepped for a missing driver.
            </p>
            <div className="mt-3 text-[11px] font-semibold text-primary-700 dark:text-primary-400">
              ✓ Recommended for Cloud Kitchens & High-Value Restaurants
            </div>
          </div>

          {/* VENDOR_FIRST */}
          <div
            onClick={() => updateOrderFlowMutation.mutate({ mode: 'VENDOR_FIRST' })}
            className={`cursor-pointer rounded-xl border p-5 transition-all ${
              currentFlowMode === 'VENDOR_FIRST'
                ? 'border-primary-600 bg-primary-50/50 dark:border-primary-500 dark:bg-primary-950/20 ring-2 ring-primary-500/20'
                : 'border-slate-200 hover:border-slate-300 dark:border-slate-800 dark:hover:border-slate-700'
            }`}
          >
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2">
                <Store className="h-5 w-5 text-emerald-600" />
                <span className="font-bold text-sm text-slate-900 dark:text-slate-100">
                  VENDOR_FIRST (Traditional Retail Mode)
                </span>
              </div>
              {currentFlowMode === 'VENDOR_FIRST' && <Badge variant="success">Active</Badge>}
            </div>
            <p className="mt-2 text-xs text-slate-600 dark:text-slate-400">
              Store receives order and begins cooking immediately. Courier broadcast is initiated when the store marks food as "Ready for Pickup" to minimize driver idle wait times at the counter.
            </p>
            <div className="mt-3 text-[11px] font-semibold text-emerald-700 dark:text-emerald-400">
              ✓ Recommended for Fast-Food Chains & Quick-Serve Bakeries
            </div>
          </div>
        </div>
      </div>

      {/* Section 2: Financial Settlements & CSV Statement Export */}
      <div className="rounded-xl border border-slate-200 bg-white p-6 shadow-sm dark:border-slate-800 dark:bg-slate-900 space-y-6">
        <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
          <div>
            <h2 className="text-base font-bold text-slate-900 dark:text-slate-100 flex items-center gap-2">
              <FileSpreadsheet className="h-5 w-5 text-primary-600" />
              Vendor Payout Settlements & Statements
            </h2>
            <p className="text-xs text-slate-500">
              Platform commission ledger reconciliations (15% rate) and net payable calculations
            </p>
          </div>
          <Button
            size="sm"
            className="gap-2"
            isLoading={isExporting}
            onClick={handleExportCsv}
          >
            <Download className="h-4 w-4" />
            Export Settlement CSV
          </Button>
        </div>

        {/* Financial KPI Cards */}
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-4">
          <div className="rounded-lg bg-slate-50 p-4 dark:bg-slate-800/50">
            <span className="text-[11px] font-semibold text-slate-500 uppercase tracking-wider">Settled Orders</span>
            <div className="mt-1 text-2xl font-bold text-slate-900 dark:text-slate-100">{totalOrders}</div>
          </div>
          <div className="rounded-lg bg-slate-50 p-4 dark:bg-slate-800/50">
            <span className="text-[11px] font-semibold text-slate-500 uppercase tracking-wider">Gross Sales Volume</span>
            <div className="mt-1 text-2xl font-bold text-slate-900 dark:text-slate-100">৳{totalGross.toFixed(2)}</div>
          </div>
          <div className="rounded-lg bg-slate-50 p-4 dark:bg-slate-800/50">
            <span className="text-[11px] font-semibold text-slate-500 uppercase tracking-wider">Platform Cut (15%)</span>
            <div className="mt-1 text-2xl font-bold text-primary-600 dark:text-primary-400">৳{totalCommission.toFixed(2)}</div>
          </div>
          <div className="rounded-lg bg-slate-50 p-4 dark:bg-slate-800/50">
            <span className="text-[11px] font-semibold text-slate-500 uppercase tracking-wider">Net Vendor Payable</span>
            <div className="mt-1 text-2xl font-bold text-emerald-600 dark:text-emerald-400">৳{totalPayable.toFixed(2)}</div>
          </div>
        </div>

        {/* Settlements Table */}
        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs">
            <thead className="border-b border-slate-100 bg-slate-50 text-slate-600 dark:border-slate-800 dark:bg-slate-800/50 dark:text-slate-400">
              <tr>
                <th className="py-3 px-3 font-semibold">Store Outlet</th>
                <th className="py-3 px-3 font-semibold">Brand</th>
                <th className="py-3 px-3 font-semibold text-center">Orders</th>
                <th className="py-3 px-3 font-semibold text-right">Gross Sales</th>
                <th className="py-3 px-3 font-semibold text-right">Commission (15%)</th>
                <th className="py-3 px-3 font-semibold text-right">Net Payable</th>
                <th className="py-3 px-3 font-semibold text-center">Status</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100 dark:divide-slate-800">
              {settlements.length === 0 ? (
                <tr>
                  <td colSpan={7} className="py-8 text-center text-slate-400 italic">
                    No ledger transactions recorded yet.
                  </td>
                </tr>
              ) : (
                settlements.map((statement) => (
                  <tr key={statement.vendorId} className="hover:bg-slate-50/50 dark:hover:bg-slate-800/50">
                    <td className="py-3.5 px-3 font-semibold text-slate-900 dark:text-slate-100">
                      {statement.vendorName}
                    </td>
                    <td className="py-3.5 px-3 text-slate-600 dark:text-slate-400">
                      {statement.brandName}
                    </td>
                    <td className="py-3.5 px-3 text-center font-medium">
                      {statement.totalOrders}
                    </td>
                    <td className="py-3.5 px-3 text-right font-medium text-slate-900 dark:text-slate-100">
                      ৳{statement.grossSales.toFixed(2)}
                    </td>
                    <td className="py-3.5 px-3 text-right text-rose-600 dark:text-rose-400 font-medium">
                      -৳{statement.platformCommission.toFixed(2)}
                    </td>
                    <td className="py-3.5 px-3 text-right font-bold text-emerald-600 dark:text-emerald-400">
                      ৳{statement.netVendorPayable.toFixed(2)}
                    </td>
                    <td className="py-3.5 px-3 text-center">
                      <Badge variant="success">Reconciled</Badge>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};
