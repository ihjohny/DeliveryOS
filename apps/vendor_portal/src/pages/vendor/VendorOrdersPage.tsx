import React, { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import {
  TrendingUp,
  DollarSign,
  Receipt,
  FileCheck2,
  Search,
  RefreshCw,
} from 'lucide-react';
import { useVendorOutlet } from '../../contexts/VendorOutletContext';
import kdsApi from '../../services/kdsApi';
import { Table, Column } from '../../components/ui/Table';
import { Badge } from '../../components/ui/Badge';
import { Button } from '../../components/ui/Button';
import { Input } from '../../components/ui/Input';
import { LoadingSpinner } from '../../components/ui/LoadingSpinner';

interface LedgerItem {
  id: string;
  orderId: string;
  orderNumber: string;
  vendorId: string;
  vendorName: string;
  customerName: string;
  paymentMethod: string;
  orderStatus: string;
  grossAmount: number;
  commissionRate: number;
  commissionAmount: number;
  netVendorPayable: number;
  settlementStatus: string;
  settledAt?: string | null;
  createdAt: string;
}

export const VendorOrdersPage: React.FC = () => {
  const { activeOutletId, activeOutlet, outlets } = useVendorOutlet();
  const [searchQuery, setSearchQuery] = useState('');
  const [statusFilter, setStatusFilter] = useState<string>('ALL');

  const { data: salesData, isLoading, refetch } = useQuery({
    queryKey: ['vendor-sales-ledger', activeOutletId],
    queryFn: () => kdsApi.getSalesLedger(activeOutletId),
  });

  const summary = salesData?.summary || {
    totalOrders: 0,
    grossSales: 0,
    commissionDeducted: 0,
    netVendorPayable: 0,
  };

  const ledgers = salesData?.ledgers || [];

  const filteredLedgers = ledgers.filter((l) => {
    const matchesSearch =
      l.orderNumber.toLowerCase().includes(searchQuery.toLowerCase()) ||
      l.customerName.toLowerCase().includes(searchQuery.toLowerCase()) ||
      l.vendorName.toLowerCase().includes(searchQuery.toLowerCase());
    const matchesStatus =
      statusFilter === 'ALL' || l.settlementStatus === statusFilter;
    return matchesSearch && matchesStatus;
  });

  const columns: Column<LedgerItem>[] = [
    {
      key: 'orderNumber',
      header: 'Order #',
      render: (item) => (
        <span className="font-bold text-slate-900 dark:text-slate-100">
          #{item.orderNumber}
        </span>
      ),
    },
    {
      key: 'createdAt',
      header: 'Date & Time',
      render: (item) => (
        <span className="text-xs text-slate-500">
          {new Date(item.createdAt).toLocaleDateString()} &bull;{' '}
          {new Date(item.createdAt).toLocaleTimeString([], {
            hour: '2-digit',
            minute: '2-digit',
          })}
        </span>
      ),
    },
    {
      key: 'vendorName',
      header: 'Outlet Branch',
      render: (item) => <span className="text-xs font-medium">{item.vendorName}</span>,
    },
    {
      key: 'customerName',
      header: 'Customer',
      render: (item) => <span className="text-xs">{item.customerName}</span>,
    },
    {
      key: 'grossAmount',
      header: 'Gross Total',
      render: (item) => (
        <span className="font-bold text-slate-900 dark:text-slate-100">
          ৳ {item.grossAmount}
        </span>
      ),
    },
    {
      key: 'commissionAmount',
      header: 'Platform Fee (15%)',
      render: (item) => (
        <span className="text-xs font-semibold text-rose-600 dark:text-rose-400">
          -৳ {item.commissionAmount}
        </span>
      ),
    },
    {
      key: 'netVendorPayable',
      header: 'Net Payable',
      render: (item) => (
        <span className="font-bold text-emerald-600 dark:text-emerald-400">
          ৳ {item.netVendorPayable}
        </span>
      ),
    },
    {
      key: 'settlementStatus',
      header: 'Settlement',
      render: (item) =>
        item.settlementStatus === 'SETTLED' ? (
          <Badge variant="success" size="sm">
            Settled
          </Badge>
        ) : (
          <Badge variant="warning" size="sm">
            Pending Payout
          </Badge>
        ),
    },
  ];

  const currentScopeTitle =
    activeOutletId === 'ALL'
      ? `All Outlets (Brand Consolidated — ${outlets.length} Branches)`
      : activeOutlet?.name || 'Store Branch';

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between border-b border-slate-200 pb-4 dark:border-slate-800">
        <div>
          <div className="flex items-center gap-2.5">
            <Receipt className="h-6 w-6 text-emerald-600 dark:text-emerald-400" />
            <h2 className="text-2xl font-extrabold tracking-tight text-slate-900 dark:text-slate-100">
              Sales Ledgers & Settlement
            </h2>
          </div>
          <p className="mt-1 text-xs text-slate-500 dark:text-slate-400">
            Financial auditing and commission records for{' '}
            <strong className="font-semibold text-slate-700 dark:text-slate-200">
              {currentScopeTitle}
            </strong>
          </p>
        </div>

        <div className="flex items-center gap-2.5">
          <Button
            variant="outline"
            size="sm"
            onClick={() => refetch()}
            leftIcon={<RefreshCw className="h-4 w-4" />}
          >
            Refresh
          </Button>
        </div>
      </div>

      {/* Financial Summary Metric Cards */}
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
        {/* Card 1: Total Orders */}
        <div className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm dark:border-slate-800 dark:bg-slate-900">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold uppercase tracking-wider text-slate-500">
              Completed Orders
            </span>
            <div className="rounded-xl bg-primary-50 p-2.5 text-primary-600 dark:bg-primary-950/50">
              <TrendingUp className="h-5 w-5" />
            </div>
          </div>
          <div className="mt-3">
            <span className="text-2xl font-extrabold text-slate-900 dark:text-slate-100">
              {summary.totalOrders}
            </span>
            <p className="mt-1 text-xs text-slate-500">Audited completed orders</p>
          </div>
        </div>

        {/* Card 2: Gross Sales Volume */}
        <div className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm dark:border-slate-800 dark:bg-slate-900">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold uppercase tracking-wider text-slate-500">
              Gross Volume
            </span>
            <div className="rounded-xl bg-amber-50 p-2.5 text-amber-600 dark:bg-amber-950/50">
              <DollarSign className="h-5 w-5" />
            </div>
          </div>
          <div className="mt-3">
            <span className="text-2xl font-extrabold text-slate-900 dark:text-slate-100">
              ৳ {summary.grossSales.toLocaleString()}
            </span>
            <p className="mt-1 text-xs text-slate-500">Before platform commissions</p>
          </div>
        </div>

        {/* Card 3: Platform Commission Deducted */}
        <div className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm dark:border-slate-800 dark:bg-slate-900">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold uppercase tracking-wider text-slate-500">
              Platform Fee (15%)
            </span>
            <div className="rounded-xl bg-rose-50 p-2.5 text-rose-600 dark:bg-rose-950/50">
              <Receipt className="h-5 w-5" />
            </div>
          </div>
          <div className="mt-3">
            <span className="text-2xl font-extrabold text-rose-600 dark:text-rose-400">
              -৳ {summary.commissionDeducted.toLocaleString()}
            </span>
            <p className="mt-1 text-xs text-slate-500">Platform revenue share</p>
          </div>
        </div>

        {/* Card 4: Net Vendor Payable */}
        <div className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm dark:border-slate-800 dark:bg-slate-900">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold uppercase tracking-wider text-slate-500">
              Net Vendor Payable
            </span>
            <div className="rounded-xl bg-emerald-50 p-2.5 text-emerald-600 dark:bg-emerald-950/50">
              <FileCheck2 className="h-5 w-5" />
            </div>
          </div>
          <div className="mt-3">
            <span className="text-2xl font-extrabold text-emerald-600 dark:text-emerald-400">
              ৳ {summary.netVendorPayable.toLocaleString()}
            </span>
            <p className="mt-1 text-xs text-slate-500">Net merchant earnings</p>
          </div>
        </div>
      </div>

      {/* Filter and Search Bar */}
      <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <div className="w-full sm:w-72">
          <Input
            placeholder="Search by order #, branch, or customer..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            leftIcon={<Search className="h-4 w-4" />}
          />
        </div>

        <div className="flex items-center gap-2">
          {['ALL', 'PENDING', 'SETTLED'].map((st) => (
            <button
              key={st}
              type="button"
              onClick={() => setStatusFilter(st)}
              className={`rounded-lg px-3 py-1.5 text-xs font-semibold transition-colors ${
                statusFilter === st
                  ? 'bg-primary-600 text-white shadow-sm'
                  : 'bg-slate-100 text-slate-600 hover:bg-slate-200 dark:bg-slate-800 dark:text-slate-300'
              }`}
            >
              {st === 'ALL' ? 'All Settlements' : st}
            </button>
          ))}
        </div>
      </div>

      {/* Table */}
      {isLoading ? (
        <div className="py-20">
          <LoadingSpinner size="lg" label="Loading sales ledgers..." />
        </div>
      ) : (
        <Table
          columns={columns}
          data={filteredLedgers}
          keyExtractor={(item) => item.id}
          emptyMessage="No sales ledger records found for this selection"
        />
      )}
    </div>
  );
};
