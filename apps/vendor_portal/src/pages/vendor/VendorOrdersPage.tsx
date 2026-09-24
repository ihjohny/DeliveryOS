import React, { useState, useMemo } from 'react';
import { useQuery } from '@tanstack/react-query';
import {
  TrendingUp,
  DollarSign,
  Receipt,
  FileCheck2,
  Search,
  RefreshCw,
  Eye,
  Calendar,
  CalendarDays,
  Phone,
  MapPin,
  FileText,
} from 'lucide-react';
import { useVendorOutlet } from '../../contexts/VendorOutletContext';
import kdsApi from '../../services/kdsApi';
import { Table, Column } from '../../components/ui/Table';
import { Badge } from '../../components/ui/Badge';
import { Button } from '../../components/ui/Button';
import { Input } from '../../components/ui/Input';
import { LoadingSpinner } from '../../components/ui/LoadingSpinner';
import { Modal } from '../../components/ui/Modal';

interface LedgerItem {
  id: string;
  orderId: string;
  orderNumber: string;
  vendorId: string;
  vendorName: string;
  customerName: string;
  customerPhone?: string;
  customerNotes?: string | null;
  deliveryAddress?: { addressLine: string; label?: string } | null;
  items?: Array<{
    productName: string;
    quantity: number;
    unitPrice: number;
    totalPrice: number;
    instructions?: string | null;
    variant?: { name: string; priceDelta: number } | null;
    addons?: Array<{ name: string; price: number }>;
  }>;
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
  const [dateFilter, setDateFilter] = useState<'TODAY' | 'ALL_TIME'>('TODAY');
  const [selectedOrderForModal, setSelectedOrderForModal] = useState<LedgerItem | null>(null);

  const { data: salesData, isLoading, refetch } = useQuery({
    queryKey: ['vendor-sales-ledger', activeOutletId],
    queryFn: () => kdsApi.getSalesLedger(activeOutletId),
  });

  const rawLedgers: LedgerItem[] = salesData?.ledgers || [];

  // Filter by date range (Today vs All Time)
  const isToday = (dateStr: string) => {
    const itemDate = new Date(dateStr);
    const today = new Date();
    return (
      itemDate.getDate() === today.getDate() &&
      itemDate.getMonth() === today.getMonth() &&
      itemDate.getFullYear() === today.getFullYear()
    );
  };

  const dateScopedLedgers = useMemo(() => {
    if (dateFilter === 'TODAY') {
      return rawLedgers.filter((l) => isToday(l.createdAt));
    }
    return rawLedgers;
  }, [rawLedgers, dateFilter]);

  // Dynamically recalculate metric summary based on active date range
  const summary = useMemo(() => {
    if (dateFilter === 'ALL_TIME' && salesData?.summary) {
      return salesData.summary;
    }
    const totalOrders = dateScopedLedgers.length;
    const grossSales = dateScopedLedgers.reduce((acc, l) => acc + Number(l.grossAmount || 0), 0);
    const commissionDeducted =
      Math.round(dateScopedLedgers.reduce((acc, l) => acc + Number(l.commissionAmount || 0), 0) * 100) / 100;
    const netVendorPayable =
      Math.round(dateScopedLedgers.reduce((acc, l) => acc + Number(l.netVendorPayable || 0), 0) * 100) / 100;

    return {
      totalOrders,
      grossSales,
      commissionDeducted,
      netVendorPayable,
    };
  }, [salesData, dateScopedLedgers, dateFilter]);

  const filteredLedgers = dateScopedLedgers.filter((l) => {
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
    {
      key: 'actions',
      header: 'Details',
      render: (item) => (
        <Button
          variant="outline"
          size="sm"
          onClick={() => setSelectedOrderForModal(item)}
          leftIcon={<Eye className="h-3.5 w-3.5 text-primary-600" />}
        >
          View Items ({item.items?.length || 0})
        </Button>
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
          {/* Today vs All Time Toggle */}
          <div className="flex rounded-lg border border-slate-200 bg-slate-100 p-0.5 dark:border-slate-800 dark:bg-slate-800">
            <button
              type="button"
              onClick={() => setDateFilter('TODAY')}
              className={`flex items-center gap-1.5 rounded-md px-3 py-1.5 text-xs font-semibold transition-all ${
                dateFilter === 'TODAY'
                  ? 'bg-white text-slate-900 shadow-sm dark:bg-slate-700 dark:text-slate-100'
                  : 'text-slate-600 hover:text-slate-900 dark:text-slate-400 dark:hover:text-slate-200'
              }`}
            >
              <Calendar className="h-3.5 w-3.5" />
              <span>Today</span>
            </button>
            <button
              type="button"
              onClick={() => setDateFilter('ALL_TIME')}
              className={`flex items-center gap-1.5 rounded-md px-3 py-1.5 text-xs font-semibold transition-all ${
                dateFilter === 'ALL_TIME'
                  ? 'bg-white text-slate-900 shadow-sm dark:bg-slate-700 dark:text-slate-100'
                  : 'text-slate-600 hover:text-slate-900 dark:text-slate-400 dark:hover:text-slate-200'
              }`}
            >
              <CalendarDays className="h-3.5 w-3.5" />
              <span>All Time</span>
            </button>
          </div>

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

      {/* Order Line Items & Customer Notes Modal */}
      {selectedOrderForModal && (
        <Modal
          isOpen={!!selectedOrderForModal}
          onClose={() => setSelectedOrderForModal(null)}
          title={`Order #${selectedOrderForModal.orderNumber} Details`}
          description={`Placed ${new Date(selectedOrderForModal.createdAt).toLocaleString()} • ${selectedOrderForModal.vendorName}`}
          size="lg"
          footer={
            <div className="flex justify-end w-full">
              <Button
                variant="outline"
                size="sm"
                onClick={() => setSelectedOrderForModal(null)}
              >
                Close
              </Button>
            </div>
          }
        >
          <div className="space-y-5">
            {/* Customer & Delivery Context Banner */}
            <div className="rounded-xl border border-slate-200 bg-slate-50 p-3.5 dark:border-slate-800 dark:bg-slate-800/50">
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 text-xs">
                <div>
                  <span className="font-semibold text-slate-500 uppercase tracking-wider block text-[10px]">
                    Customer & Contact
                  </span>
                  <p className="font-bold text-slate-900 dark:text-slate-100 mt-0.5">
                    {selectedOrderForModal.customerName}
                  </p>
                  {selectedOrderForModal.customerPhone && (
                    <p className="text-slate-600 dark:text-slate-400 flex items-center gap-1 mt-0.5">
                      <Phone className="h-3 w-3 text-primary-500" />
                      {selectedOrderForModal.customerPhone}
                    </p>
                  )}
                </div>

                <div>
                  <span className="font-semibold text-slate-500 uppercase tracking-wider block text-[10px]">
                    Delivery Destination
                  </span>
                  <p className="text-slate-700 dark:text-slate-300 flex items-start gap-1 mt-0.5">
                    <MapPin className="h-3 w-3 text-rose-500 mt-0.5 shrink-0" />
                    <span>
                      {selectedOrderForModal.deliveryAddress?.addressLine || 'Address snapshot unavailable'}
                    </span>
                  </p>
                </div>
              </div>

              {/* Cooking / Preparation Notes from Customer */}
              {selectedOrderForModal.customerNotes && (
                <div className="mt-3 pt-3 border-t border-slate-200 dark:border-slate-700/60">
                  <div className="flex items-start gap-1.5 text-xs text-amber-700 dark:text-amber-400 bg-amber-50 dark:bg-amber-950/30 p-2.5 rounded-lg border border-amber-200 dark:border-amber-800/50">
                    <FileText className="h-4 w-4 shrink-0 mt-0.5" />
                    <div>
                      <span className="font-bold block">Customer Cooking Note:</span>
                      <p className="italic">{selectedOrderForModal.customerNotes}</p>
                    </div>
                  </div>
                </div>
              )}
            </div>

            {/* Line Items List */}
            <div>
              <h4 className="text-xs font-bold uppercase tracking-wider text-slate-600 dark:text-slate-300 mb-2">
                Ordered Items ({selectedOrderForModal.items?.length || 0})
              </h4>
              {selectedOrderForModal.items && selectedOrderForModal.items.length > 0 ? (
                <div className="border border-slate-200 dark:border-slate-800 rounded-xl overflow-hidden divide-y divide-slate-100 dark:divide-slate-800">
                  {selectedOrderForModal.items.map((item, idx) => (
                    <div key={idx} className="p-3 bg-white dark:bg-slate-900 flex items-center justify-between text-xs">
                      <div className="space-y-1">
                        <div className="flex items-center gap-2">
                          <span className="font-bold text-slate-900 dark:text-slate-100">
                            {item.quantity}x
                          </span>
                          <span className="font-semibold text-slate-800 dark:text-slate-200">
                            {item.productName}
                          </span>
                          {item.variant && (
                            <Badge variant="purple" size="sm">
                              {item.variant.name} (+৳{item.variant.priceDelta})
                            </Badge>
                          )}
                        </div>

                        {item.addons && item.addons.length > 0 && (
                          <div className="flex flex-wrap gap-1">
                            {item.addons.map((ad, aIdx) => (
                              <span
                                key={aIdx}
                                className="inline-flex items-center px-1.5 py-0.5 rounded text-[10px] font-medium bg-slate-100 text-slate-700 dark:bg-slate-800 dark:text-slate-300"
                              >
                                + {ad.name} (৳{ad.price})
                              </span>
                            ))}
                          </div>
                        )}

                        {item.instructions && (
                          <p className="text-[11px] text-amber-600 dark:text-amber-400 italic">
                            Special request: {item.instructions}
                          </p>
                        )}
                      </div>

                      <div className="text-right">
                        <span className="font-bold text-slate-900 dark:text-slate-100">
                          ৳ {item.totalPrice}
                        </span>
                        <span className="block text-[10px] text-slate-400">
                          ৳ {item.unitPrice} each
                        </span>
                      </div>
                    </div>
                  ))}
                </div>
              ) : (
                <div className="py-6 text-center text-xs text-slate-400 bg-slate-50 dark:bg-slate-800/40 rounded-xl border border-slate-200 dark:border-slate-800">
                  Line items breakdown not recorded for legacy order
                </div>
              )}
            </div>

            {/* Financial Ledger Breakdown */}
            <div className="rounded-xl border border-slate-200 bg-slate-50/70 p-3.5 dark:border-slate-800 dark:bg-slate-800/30 space-y-2 text-xs">
              <div className="flex justify-between text-slate-600 dark:text-slate-400">
                <span>Order Gross Subtotal</span>
                <span className="font-bold text-slate-900 dark:text-slate-100">
                  ৳ {selectedOrderForModal.grossAmount}
                </span>
              </div>
              <div className="flex justify-between text-rose-600 dark:text-rose-400">
                <span>Platform Commission ({selectedOrderForModal.commissionRate}%)</span>
                <span className="font-semibold">-৳ {selectedOrderForModal.commissionAmount}</span>
              </div>
              <div className="pt-2 border-t border-slate-200 dark:border-slate-700 flex justify-between text-sm font-extrabold text-emerald-600 dark:text-emerald-400">
                <span>Net Vendor Payable</span>
                <span>৳ {selectedOrderForModal.netVendorPayable}</span>
              </div>
              <div className="flex justify-between items-center pt-1 text-[11px] text-slate-500">
                <span>Payment Mode: {selectedOrderForModal.paymentMethod}</span>
                <span>
                  Settlement:{' '}
                  <strong className={selectedOrderForModal.settlementStatus === 'SETTLED' ? 'text-emerald-600' : 'text-amber-600'}>
                    {selectedOrderForModal.settlementStatus}
                  </strong>
                </span>
              </div>
            </div>
          </div>
        </Modal>
      )}
    </div>
  );
};
