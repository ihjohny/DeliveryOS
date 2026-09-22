import React, { useState, useEffect } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import {
  FileText,
  Search,
  Filter,
  RefreshCw,
  UserCheck,
  Bike,
  Clock,
  MapPin,
  Phone,
  CheckCircle2,
  AlertCircle,
} from 'lucide-react';
import adminApi, { AdminOrder, FleetRider } from '../../services/adminApi';
import { getSocket } from '../../services/socket';
import { Table, Column } from '../../components/ui/Table';
import { Badge, OrderStatusBadge } from '../../components/ui/Badge';
import { Button } from '../../components/ui/Button';
import { Input } from '../../components/ui/Input';
import { Modal } from '../../components/ui/Modal';
import { Alert } from '../../components/ui/Alert';
import { LoadingSpinner } from '../../components/ui/LoadingSpinner';

export const AdminOrdersPage: React.FC = () => {
  const queryClient = useQueryClient();
  const [selectedStatus, setSelectedStatus] = useState<string>('ALL');
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedOrder, setSelectedOrder] = useState<AdminOrder | null>(null);
  const [isAssignModalOpen, setIsAssignModalOpen] = useState(false);
  const [selectedRiderId, setSelectedRiderId] = useState<string>('');

  const { data: orders = [], isLoading, refetch } = useQuery({
    queryKey: ['admin-orders', selectedStatus],
    queryFn: () => adminApi.getOrders(selectedStatus),
    refetchInterval: 30000,
  });

  // Real-time WebSocket Order Invalidation
  useEffect(() => {
    const socket = getSocket();

    const handleOrderUpdate = () => {
      queryClient.invalidateQueries({ queryKey: ['admin-orders'] });
    };

    socket.on('order:new', handleOrderUpdate);
    socket.on('order:status:changed', handleOrderUpdate);

    return () => {
      socket.off('order:new', handleOrderUpdate);
      socket.off('order:status:changed', handleOrderUpdate);
    };
  }, [queryClient]);


  const { data: fleet = [] } = useQuery({
    queryKey: ['admin-fleet-assignable'],
    queryFn: adminApi.getFleet,
  });

  const forceAssignMutation = useMutation({
    mutationFn: ({ orderId, riderId }: { orderId: string; riderId: string }) =>
      adminApi.forceAssignRider(orderId, riderId),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin-orders'] });
      queryClient.invalidateQueries({ queryKey: ['admin-fleet'] });
      setIsAssignModalOpen(false);
      setSelectedOrder(null);
      setSelectedRiderId('');
    },
  });

  const filteredOrders = orders.filter((o) => {
    const matchesSearch =
      o.orderNumber.toLowerCase().includes(searchQuery.toLowerCase()) ||
      o.customerName.toLowerCase().includes(searchQuery.toLowerCase()) ||
      o.vendorName.toLowerCase().includes(searchQuery.toLowerCase()) ||
      (o.riderName && o.riderName.toLowerCase().includes(searchQuery.toLowerCase()));
    return matchesSearch;
  });

  const availableRiders = fleet.filter((r) => r.isOnline);

  const columns: Column<AdminOrder>[] = [
    {
      key: 'orderNumber',
      header: 'Order #',
      render: (order) => (
        <div>
          <span className="font-semibold text-slate-900 dark:text-slate-100">{order.orderNumber}</span>
          <div className="text-[11px] text-slate-500">
            {new Date(order.placedAt).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
          </div>
        </div>
      ),
    },
    {
      key: 'vendorName',
      header: 'Store Outlet',
      render: (order) => (
        <div>
          <div className="font-medium text-slate-900 dark:text-slate-100">{order.vendorName}</div>
          <div className="text-[11px] text-slate-500 truncate max-w-[150px]">{order.vendorAddress}</div>
        </div>
      ),
    },
    {
      key: 'customerName',
      header: 'Customer',
      render: (order) => (
        <div>
          <div className="font-medium text-slate-900 dark:text-slate-100">{order.customerName}</div>
          <div className="text-[11px] text-slate-500">{order.customerPhone}</div>
        </div>
      ),
    },
    {
      key: 'status',
      header: 'Status',
      render: (order) => <OrderStatusBadge status={order.status} />,
    },
    {
      key: 'riderName',
      header: 'Assigned Courier',
      render: (order) =>
        order.riderName ? (
          <div className="flex items-center gap-1.5 text-xs text-slate-700 dark:text-slate-300">
            <Bike className="h-3.5 w-3.5 text-primary-600" />
            <div>
              <span className="font-medium">{order.riderName}</span>
              <div className="text-[10px] text-slate-400">{order.riderPhone}</div>
            </div>
          </div>
        ) : (
          <span className="text-amber-600 dark:text-amber-400 font-medium text-[11px] italic">
            Unassigned
          </span>
        ),
    },
    {
      key: 'totalAmount',
      header: 'Total',
      render: (order) => (
        <div className="text-right">
          <span className="font-semibold text-slate-900 dark:text-slate-100">৳{order.totalAmount}</span>
          <div className="text-[10px] text-slate-400">{order.paymentMethod}</div>
        </div>
      ),
    },
    {
      key: 'id',
      header: 'Action',
      render: (order) => (
        <div className="text-right">
          {order.status !== 'DELIVERED' && order.status !== 'CANCELLED' ? (
            <Button
              variant="outline"
              size="sm"
              className="text-xs h-7 px-2.5 gap-1"
              onClick={() => {
                setSelectedOrder(order);
                setSelectedRiderId(order.riderId || (availableRiders[0]?.id ?? ''));
                setIsAssignModalOpen(true);
              }}
            >
              <UserCheck className="h-3.5 w-3.5 text-primary-600" />
              {order.riderId ? 'Reassign' : 'Force Assign'}
            </Button>
          ) : (
            <span className="text-slate-400 text-xs">—</span>
          )}
        </div>
      ),
    },
  ];

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold tracking-tight text-slate-900 dark:text-slate-100 flex items-center gap-2.5">
            <FileText className="h-6 w-6 text-primary-600 dark:text-primary-400" />
            Live Order Lifecycle Monitor
          </h1>
          <p className="text-sm text-slate-500 dark:text-slate-400">
            Real-time multi-stage order tracking with manual dispatch force-assignment override
          </p>
        </div>
        <div className="flex items-center gap-2">
          <Button variant="outline" size="sm" onClick={() => refetch()} className="gap-2">
            <RefreshCw className="h-4 w-4" />
            Refresh Queue
          </Button>
        </div>
      </div>

      {/* Stage Filter Buttons */}
      <div className="flex items-center gap-1.5 overflow-x-auto pb-2">
        {[
          { id: 'ALL', label: 'All Orders' },
          { id: 'PLACED', label: '1. Placed' },
          { id: 'RIDER_ASSIGNED', label: '2. Courier Assigned' },
          { id: 'ACCEPTED', label: '3. Accepted' },
          { id: 'PREPARING', label: '4. Preparing' },
          { id: 'READY_FOR_PICKUP', label: '5. Ready for Pickup' },
          { id: 'DISPATCHED', label: '6. On Delivery' },
          { id: 'DELIVERED', label: '7. Delivered' },
        ].map((stage) => (
          <button
            key={stage.id}
            onClick={() => setSelectedStatus(stage.id)}
            className={`whitespace-nowrap rounded-lg px-3 py-1.5 text-xs font-medium transition-colors ${
              selectedStatus === stage.id
                ? 'bg-primary-600 text-white font-semibold shadow-sm'
                : 'bg-white border border-slate-200 text-slate-600 hover:bg-slate-50 dark:bg-slate-900 dark:border-slate-800 dark:text-slate-400 dark:hover:bg-slate-800'
            }`}
          >
            {stage.label}
          </button>
        ))}
      </div>

      {/* Table Container */}
      <div className="rounded-xl border border-slate-200 bg-white shadow-sm dark:border-slate-800 dark:bg-slate-900">
        <div className="p-4 border-b border-slate-100 dark:border-slate-800 flex flex-col sm:flex-row sm:items-center justify-between gap-3">
          <div className="relative w-full sm:w-80">
            <Search className="absolute left-3 top-2.5 h-4 w-4 text-slate-400" />
            <input
              type="text"
              placeholder="Filter by Order #, Store, Customer, Courier..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full rounded-lg border border-slate-200 bg-white pl-9 pr-3 py-1.5 text-xs text-slate-900 focus:border-primary-500 focus:outline-none dark:border-slate-700 dark:bg-slate-800 dark:text-slate-100"
            />
          </div>
          <div className="text-xs text-slate-500">
            Showing <span className="font-semibold text-slate-900 dark:text-slate-100">{filteredOrders.length}</span> live orders
          </div>
        </div>

        {isLoading ? (
          <div className="py-16 text-center">
            <LoadingSpinner size="lg" />
            <p className="mt-2 text-xs text-slate-500">Synchronizing order lifecycle stream...</p>
          </div>
        ) : filteredOrders.length === 0 ? (
          <div className="py-16 text-center text-slate-500 text-xs">
            No orders match the selected lifecycle criteria.
          </div>
        ) : (
          <Table data={filteredOrders} columns={columns} keyExtractor={(o) => o.id} />
        )}
      </div>

      {/* Manual Force-Assign Rider Modal */}
      {selectedOrder && (
        <Modal
          isOpen={isAssignModalOpen}
          onClose={() => setIsAssignModalOpen(false)}
          title={`Manual Dispatch Override — #${selectedOrder.orderNumber}`}
        >
          <div className="space-y-4">
            <Alert
              type="warning"
              message="Manual assignment forces this order to the designated courier and transmits real-time telemetry updates to the customer app and store kitchen console."
            />

            <div className="rounded-lg border border-slate-100 bg-slate-50 p-3 text-xs space-y-1 dark:border-slate-800 dark:bg-slate-800/50">
              <div className="flex justify-between">
                <span className="text-slate-500">Store Outlet:</span>
                <span className="font-semibold text-slate-900 dark:text-slate-100">{selectedOrder.vendorName}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-slate-500">Customer Drop-off:</span>
                <span className="font-medium text-slate-700 dark:text-slate-300">{selectedOrder.deliveryAddress}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-slate-500">Gross Total:</span>
                <span className="font-semibold text-primary-600">৳{selectedOrder.totalAmount}</span>
              </div>
            </div>

            <div>
              <label className="block text-xs font-semibold text-slate-700 dark:text-slate-300 mb-1.5">
                Select Active Courier
              </label>
              {availableRiders.length === 0 ? (
                <div className="rounded-lg border border-rose-200 bg-rose-50 p-3 text-xs text-rose-700 dark:border-rose-900/50 dark:bg-rose-950/20">
                  No couriers are currently online in the pilot zone.
                </div>
              ) : (
                <div className="space-y-2 max-h-52 overflow-y-auto pr-1">
                  {availableRiders.map((rider) => (
                    <label
                      key={rider.id}
                      className={`flex items-center justify-between p-2.5 rounded-lg border cursor-pointer transition-all ${
                        selectedRiderId === rider.id
                          ? 'border-primary-500 bg-primary-50/50 dark:bg-primary-950/20'
                          : 'border-slate-200 hover:bg-slate-50 dark:border-slate-800 dark:hover:bg-slate-800'
                      }`}
                    >
                      <div className="flex items-center gap-2.5">
                        <input
                          type="radio"
                          name="dispatch_rider"
                          value={rider.id}
                          checked={selectedRiderId === rider.id}
                          onChange={() => setSelectedRiderId(rider.id)}
                          className="text-primary-600 focus:ring-primary-500"
                        />
                        <div>
                          <div className="text-xs font-semibold text-slate-900 dark:text-slate-100">
                            {rider.riderName}
                          </div>
                          <div className="text-[11px] text-slate-500">
                            {rider.phone} • {rider.vehicleType}
                          </div>
                        </div>
                      </div>
                      <div className="text-right text-[11px]">
                        {rider.status === 'ONLINE' ? (
                          <Badge variant="success">Idle</Badge>
                        ) : (
                          <Badge variant="info">On Trip</Badge>
                        )}
                        <div className="text-slate-400 mt-0.5">৳{rider.cashInHand} COD</div>
                      </div>
                    </label>
                  ))}
                </div>
              )}
            </div>

            <div className="flex justify-end gap-2 pt-2 border-t border-slate-100 dark:border-slate-800">
              <Button variant="outline" size="sm" onClick={() => setIsAssignModalOpen(false)}>
                Cancel
              </Button>
              <Button
                size="sm"
                disabled={!selectedRiderId}
                isLoading={forceAssignMutation.isPending}
                onClick={() => {
                  if (selectedOrder && selectedRiderId) {
                    forceAssignMutation.mutate({
                      orderId: selectedOrder.id,
                      riderId: selectedRiderId,
                    });
                  }
                }}
              >
                Confirm Dispatch Override
              </Button>
            </div>
          </div>
        </Modal>
      )}
    </div>
  );
};
