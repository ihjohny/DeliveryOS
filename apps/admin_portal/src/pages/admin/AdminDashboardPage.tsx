import React, { useState } from 'react';
import { useTranslation } from 'react-i18next';
import {
  TrendingUp,
  Users,
  Store,
  DollarSign,
  Shuffle,
  Eye,
  Plus,
} from 'lucide-react';
import { Badge, OrderStatusBadge } from '../../components/ui/Badge';
import { Button } from '../../components/ui/Button';
import { Alert } from '../../components/ui/Alert';
import { Modal } from '../../components/ui/Modal';
import { Table, Column } from '../../components/ui/Table';

interface SampleOrder {
  id: string;
  orderNumber: string;
  customerName: string;
  outletName: string;
  status: string;
  amount: number;
}

export const AdminDashboardPage: React.FC = () => {
  const { t } = useTranslation();
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [selectedOrder, setSelectedOrder] = useState<SampleOrder | null>(null);

  const stats = [
    { title: t('admin.totalOrders'), value: '1,428', icon: TrendingUp, change: '+12.4%', color: 'text-primary-600 bg-primary-50 dark:bg-primary-950/50' },
    { title: t('admin.activeRiders'), value: '42', icon: Users, change: '8 on trip', color: 'text-sky-600 bg-sky-50 dark:bg-sky-950/50' },
    { title: t('admin.onlineVendors'), value: '18 / 20', icon: Store, change: '90% live', color: 'text-emerald-600 bg-emerald-50 dark:bg-emerald-950/50' },
    { title: t('admin.todayVolume'), value: '৳ 384,200', icon: DollarSign, change: '+8.1%', color: 'text-amber-600 bg-amber-50 dark:bg-amber-950/50' },
  ];

  const sampleOrders: SampleOrder[] = [
    { id: '1', orderNumber: 'ORD-20260917-1001', customerName: 'Rahim Chowdhury', outletName: 'Burger Point — Gulshan Branch', status: 'PREPARING', amount: 820 },
    { id: '2', orderNumber: 'ORD-20260917-1002', customerName: 'Ayesha Siddiqua', outletName: 'FreshMart — Dhanmondi Branch', status: 'DISPATCHED', amount: 1450 },
    { id: '3', orderNumber: 'ORD-20260917-1003', customerName: 'Fahim Hasan', outletName: 'Burger Point — Dhanmondi Branch', status: 'READY_FOR_PICKUP', amount: 450 },
    { id: '4', orderNumber: 'ORD-20260917-1004', customerName: 'Farhana Akter', outletName: 'Burger Point — Gulshan Branch', status: 'DELIVERED', amount: 980 },
    { id: '5', orderNumber: 'ORD-20260917-1005', customerName: 'Tanvir Ahmed', outletName: 'Burger Point — Gulshan Branch', status: 'RIDER_ASSIGNED', amount: 620 },
  ];

  const columns: Column<SampleOrder>[] = [
    {
      key: 'orderNumber',
      header: 'Order #',
      render: (order) => <span className="font-semibold text-slate-900 dark:text-slate-100">{order.orderNumber}</span>,
    },
    {
      key: 'customerName',
      header: 'Customer',
    },
    {
      key: 'outletName',
      header: 'Store Outlet',
    },
    {
      key: 'status',
      header: 'Status',
      render: (order) => <OrderStatusBadge status={order.status} />,
    },
    {
      key: 'amount',
      header: 'Amount',
      render: (order) => <span className="font-medium">৳ {order.amount}</span>,
    },
    {
      key: 'actions',
      header: 'Actions',
      render: (order) => (
        <Button
          variant="outline"
          size="sm"
          onClick={() => {
            setSelectedOrder(order);
            setIsModalOpen(true);
          }}
          leftIcon={<Eye className="h-3.5 w-3.5" />}
        >
          View
        </Button>
      ),
    },
  ];

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h2 className="text-2xl font-bold tracking-tight text-slate-900 dark:text-slate-100">
            {t('admin.title')}
          </h2>
          <p className="text-sm text-slate-500 dark:text-slate-400">
            {t('admin.subtitle')}
          </p>
        </div>
        <div className="flex items-center gap-2">
          <Badge variant="purple" size="md">
            <Shuffle className="h-3 w-3 mr-1" />
            Dispatch: RIDER_FIRST
          </Badge>
        </div>
      </div>

      <Alert
        type="info"
        title="DeliveryOS Operational Readiness"
        message="Active multi-tenant cluster operating across Dhaka central zones. Redis Geospatial indexing and WebSocket tracking gateway active."
      />

      {/* Metrics Cards */}
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
        {stats.map((stat) => {
          const Icon = stat.icon;
          return (
            <div
              key={stat.title}
              className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm dark:border-slate-800 dark:bg-slate-900"
            >
              <div className="flex items-center justify-between">
                <span className="text-xs font-semibold uppercase tracking-wider text-slate-500">
                  {stat.title}
                </span>
                <div className={`rounded-xl p-2.5 ${stat.color}`}>
                  <Icon className="h-5 w-5" />
                </div>
              </div>
              <div className="mt-3">
                <span className="text-2xl font-extrabold text-slate-900 dark:text-slate-100">
                  {stat.value}
                </span>
                <p className="mt-1 text-xs text-slate-500">{stat.change}</p>
              </div>
            </div>
          );
        })}
      </div>

      {/* Orders Table */}
      <div className="space-y-3">
        <div className="flex items-center justify-between">
          <h3 className="text-lg font-bold text-slate-900 dark:text-slate-100">Recent Live Orders</h3>
          <Button size="sm" leftIcon={<Plus className="h-4 w-4" />}>
            Create Outgoing Order
          </Button>
        </div>

        <Table
          columns={columns}
          data={sampleOrders}
          keyExtractor={(item) => item.id}
          page={1}
          totalPages={3}
          totalItems={15}
        />
      </div>

      {/* Details Modal */}
      <Modal
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        title={selectedOrder?.orderNumber || 'Order Details'}
        description={`Audit record for ${selectedOrder?.customerName}`}
        footer={
          <>
            <Button variant="outline" onClick={() => setIsModalOpen(false)}>
              Close
            </Button>
            <Button variant="primary" onClick={() => setIsModalOpen(false)}>
              Re-sync Telemetry
            </Button>
          </>
        }
      >
        {selectedOrder && (
          <div className="space-y-4 text-sm">
            <div className="grid grid-cols-2 gap-4">
              <div>
                <span className="text-xs text-slate-500">Outlet</span>
                <p className="font-semibold text-slate-900 dark:text-slate-100">{selectedOrder.outletName}</p>
              </div>
              <div>
                <span className="text-xs text-slate-500">Status</span>
                <div>
                  <OrderStatusBadge status={selectedOrder.status} />
                </div>
              </div>
              <div>
                <span className="text-xs text-slate-500">Gross Total</span>
                <p className="font-semibold text-slate-900 dark:text-slate-100">৳ {selectedOrder.amount}</p>
              </div>
              <div>
                <span className="text-xs text-slate-500">Settlement</span>
                <p className="font-semibold text-slate-900 dark:text-slate-100">CASH_ON_DELIVERY</p>
              </div>
            </div>
          </div>
        )}
      </Modal>
    </div>
  );
};
