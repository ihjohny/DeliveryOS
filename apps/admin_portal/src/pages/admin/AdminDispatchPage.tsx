import React, { useState, useEffect } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Link } from 'react-router-dom';
import {
  Navigation,
  Users,
  AlertTriangle,
  CheckCircle2,
  DollarSign,
  Bike,
  RefreshCw,
  Search,
  Filter,
  ArrowRight,
  ShieldAlert,
  Clock,
} from 'lucide-react';
import adminApi, { FleetRider } from '../../services/adminApi';
import { getSocket } from '../../services/socket';
import { Badge } from '../../components/ui/Badge';
import { Button } from '../../components/ui/Button';
import { Input } from '../../components/ui/Input';
import { Modal } from '../../components/ui/Modal';
import { Alert } from '../../components/ui/Alert';
import { LoadingSpinner } from '../../components/ui/LoadingSpinner';

export const AdminDispatchPage: React.FC = () => {
  const queryClient = useQueryClient();
  const [statusFilter, setStatusFilter] = useState<'ALL' | 'ONLINE' | 'ON_TRIP' | 'OFFLINE'>('ALL');
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedRider, setSelectedRider] = useState<FleetRider | null>(null);
  const [newCashLimit, setNewCashLimit] = useState<string>('5000');
  const [isCashModalOpen, setIsCashModalOpen] = useState(false);

  const { data: fleet = [], isLoading, refetch } = useQuery({
    queryKey: ['admin-fleet'],
    queryFn: adminApi.getFleet,
    refetchInterval: 30000,
  });

  const { data: unassignedOrders = [] } = useQuery({
    queryKey: ['admin-unassigned-orders'],
    queryFn: () => adminApi.getOrders('PLACED'),
    refetchInterval: 30000,
  });

  // Real-time WebSocket Listeners for Dispatch and Fleet Updates
  useEffect(() => {
    const socket = getSocket();

    const handleFleetAndOrderEvent = () => {
      queryClient.invalidateQueries({ queryKey: ['admin-fleet'] });
      queryClient.invalidateQueries({ queryKey: ['admin-unassigned-orders'] });
    };

    socket.on('order:new', handleFleetAndOrderEvent);
    socket.on('order:status:changed', handleFleetAndOrderEvent);
    socket.on('dispatch:broadcast', handleFleetAndOrderEvent);

    return () => {
      socket.off('order:new', handleFleetAndOrderEvent);
      socket.off('order:status:changed', handleFleetAndOrderEvent);
      socket.off('dispatch:broadcast', handleFleetAndOrderEvent);
    };
  }, [queryClient]);


  const updateCashLimitMutation = useMutation({
    mutationFn: ({ id, limit }: { id: string; limit: number }) =>
      adminApi.updateRiderCashLimit(id, limit),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin-fleet'] });
      setIsCashModalOpen(false);
      setSelectedRider(null);
    },
  });

  const filteredFleet = fleet.filter((r) => {
    const matchesStatus = statusFilter === 'ALL' || r.status === statusFilter;
    const matchesSearch =
      r.riderName.toLowerCase().includes(searchQuery.toLowerCase()) ||
      r.phone.includes(searchQuery) ||
      r.vehicleType.toLowerCase().includes(searchQuery.toLowerCase());
    return matchesStatus && matchesSearch;
  });

  const onlineCount = fleet.filter((r) => r.isOnline).length;
  const onTripCount = fleet.filter((r) => r.status === 'ON_TRIP').length;
  const idleCount = fleet.filter((r) => r.status === 'ONLINE').length;
  const safetyWarningsCount = fleet.filter((r) => r.cashSafetyWarning).length;

  const maxAgingMinutes = unassignedOrders.length > 0
    ? Math.max(...unassignedOrders.map((o) => Math.max(0, Math.floor((Date.now() - new Date(o.placedAt).getTime()) / 60000))))
    : 0;
  const totalPoolVolume = unassignedOrders.reduce((sum, o) => sum + (o.totalAmount || 0), 0);

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold tracking-tight text-slate-900 dark:text-slate-100 flex items-center gap-2.5">
            <Navigation className="h-6 w-6 text-primary-600 dark:text-primary-400" />
            Live Fleet Radar & Dispatch
          </h1>
          <p className="text-sm text-slate-500 dark:text-slate-400">
            Real-time courier GPS oversight, active trips, and COD cash safety thresholds
          </p>
        </div>
        <div className="flex items-center gap-2">
          <Button variant="outline" size="sm" onClick={() => refetch()} className="gap-2">
            <RefreshCw className="h-4 w-4" />
            Refresh Fleet
          </Button>
        </div>
      </div>

      {/* Metric Cards */}
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <div className="rounded-xl border border-slate-200 bg-white p-5 shadow-sm dark:border-slate-800 dark:bg-slate-900">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold text-slate-500 uppercase tracking-wider">Online Riders</span>
            <span className="flex h-2 w-2 rounded-full bg-emerald-500 animate-pulse" />
          </div>
          <div className="mt-2 flex items-baseline gap-2">
            <span className="text-3xl font-bold text-slate-900 dark:text-slate-100">{onlineCount}</span>
            <span className="text-xs text-slate-500">/ {fleet.length} registered</span>
          </div>
        </div>

        <div className="rounded-xl border border-slate-200 bg-white p-5 shadow-sm dark:border-slate-800 dark:bg-slate-900">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold text-slate-500 uppercase tracking-wider">On Active Delivery</span>
            <Bike className="h-4 w-4 text-sky-500" />
          </div>
          <div className="mt-2 flex items-baseline gap-2">
            <span className="text-3xl font-bold text-sky-600 dark:text-sky-400">{onTripCount}</span>
            <span className="text-xs text-slate-500">riders currently moving orders</span>
          </div>
        </div>

        <div className="rounded-xl border border-slate-200 bg-white p-5 shadow-sm dark:border-slate-800 dark:bg-slate-900">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold text-slate-500 uppercase tracking-wider">Idle & Available</span>
            <CheckCircle2 className="h-4 w-4 text-emerald-500" />
          </div>
          <div className="mt-2 flex items-baseline gap-2">
            <span className="text-3xl font-bold text-emerald-600 dark:text-emerald-400">{idleCount}</span>
            <span className="text-xs text-slate-500">ready for dispatch</span>
          </div>
        </div>

        <div className="rounded-xl border border-slate-200 bg-white p-5 shadow-sm dark:border-slate-800 dark:bg-slate-900">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold text-slate-500 uppercase tracking-wider">Cash Warnings</span>
            <AlertTriangle className={`h-4 w-4 ${safetyWarningsCount > 0 ? 'text-amber-500 animate-bounce' : 'text-slate-400'}`} />
          </div>
          <div className="mt-2 flex items-baseline gap-2">
            <span className={`text-3xl font-bold ${safetyWarningsCount > 0 ? 'text-amber-600 dark:text-amber-400' : 'text-slate-900 dark:text-slate-100'}`}>
              {safetyWarningsCount}
            </span>
            <span className="text-xs text-slate-500">approaching COD limit</span>
          </div>
        </div>
      </div>

      {/* Main Grid: Interactive Map Radar & Telemetry Table */}
      <div className="grid grid-cols-1 gap-6 lg:grid-cols-3">
        {/* Left 2 Cols: Live Fleet List & Telemetry */}
        <div className="lg:col-span-2 space-y-4">
          <div className="rounded-xl border border-slate-200 bg-white p-4 shadow-sm dark:border-slate-800 dark:bg-slate-900">
            {/* Filter Bar */}
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 mb-4">
              <div className="flex items-center gap-1.5 overflow-x-auto pb-1 sm:pb-0">
                {(['ALL', 'ONLINE', 'ON_TRIP', 'OFFLINE'] as const).map((s) => (
                  <button
                    key={s}
                    onClick={() => setStatusFilter(s)}
                    className={`rounded-lg px-3 py-1.5 text-xs font-medium transition-colors ${
                      statusFilter === s
                        ? 'bg-primary-600 text-white font-semibold'
                        : 'bg-slate-100 text-slate-600 hover:bg-slate-200 dark:bg-slate-800 dark:text-slate-400 dark:hover:bg-slate-700'
                    }`}
                  >
                    {s === 'ALL' ? 'All Couriers' : s.replace('_', ' ')}
                  </button>
                ))}
              </div>

              <div className="relative w-full sm:w-64">
                <Search className="absolute left-3 top-2.5 h-4 w-4 text-slate-400" />
                <input
                  type="text"
                  placeholder="Search name, phone, vehicle..."
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  className="w-full rounded-lg border border-slate-200 bg-white pl-9 pr-3 py-1.5 text-xs text-slate-900 focus:border-primary-500 focus:outline-none dark:border-slate-700 dark:bg-slate-800 dark:text-slate-100"
                />
              </div>
            </div>

            {isLoading ? (
              <div className="py-16 text-center">
                <LoadingSpinner size="lg" />
                <p className="mt-2 text-xs text-slate-500">Contacting fleet satellites...</p>
              </div>
            ) : filteredFleet.length === 0 ? (
              <div className="py-12 text-center text-slate-500 text-xs">
                No couriers match the current filter criteria.
              </div>
            ) : (
              <div className="overflow-x-auto">
                <table className="w-full text-left text-xs">
                  <thead className="border-b border-slate-100 bg-slate-50 text-slate-600 dark:border-slate-800 dark:bg-slate-800/50 dark:text-slate-400">
                    <tr>
                      <th className="py-2.5 px-3 font-semibold">Courier</th>
                      <th className="py-2.5 px-3 font-semibold">Vehicle</th>
                      <th className="py-2.5 px-3 font-semibold">Status</th>
                      <th className="py-2.5 px-3 font-semibold">Active Trip</th>
                      <th className="py-2.5 px-3 font-semibold">Cash in Hand</th>
                      <th className="py-2.5 px-3 font-semibold text-right">Actions</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-100 dark:divide-slate-800">
                    {filteredFleet.map((rider) => (
                      <tr key={rider.id} className="hover:bg-slate-50/50 dark:hover:bg-slate-800/50 transition-colors">
                        <td className="py-3 px-3">
                          <div className="font-semibold text-slate-900 dark:text-slate-100">{rider.riderName}</div>
                          <div className="text-[11px] text-slate-500">{rider.phone}</div>
                        </td>
                        <td className="py-3 px-3 capitalize">
                          <div className="flex items-center gap-1.5">
                            <Bike className="h-3.5 w-3.5 text-slate-400" />
                            <span>{rider.vehicleType}</span>
                          </div>
                        </td>
                        <td className="py-3 px-3">
                          {rider.status === 'ONLINE' && (
                            <Badge variant="success">Idle & Ready</Badge>
                          )}
                          {rider.status === 'ON_TRIP' && (
                            <Badge variant="info">On Delivery</Badge>
                          )}
                          {rider.status === 'OFFLINE' && (
                            <Badge variant="default">Offline</Badge>
                          )}
                        </td>
                        <td className="py-3 px-3">
                          {rider.activeOrder ? (
                            <div className="text-[11px]">
                              <span className="font-semibold text-primary-600 dark:text-primary-400">
                                {rider.activeOrder.orderNumber}
                              </span>
                              <div className="text-slate-500 truncate max-w-[120px]">{rider.activeOrder.vendorName}</div>
                            </div>
                          ) : (
                            <span className="text-slate-400 italic">None</span>
                          )}
                        </td>
                        <td className="py-3 px-3">
                          <div className="flex items-center gap-1">
                            <span className={`font-semibold ${rider.cashSafetyWarning ? 'text-amber-600 dark:text-amber-400' : 'text-slate-700 dark:text-slate-300'}`}>
                              ৳{rider.cashInHand}
                            </span>
                            <span className="text-[11px] text-slate-400">/ ৳{rider.maxCashLimit}</span>
                          </div>
                          {rider.cashSafetyWarning && (
                            <span className="text-[10px] text-amber-500 font-medium">Near Limit</span>
                          )}
                        </td>
                        <td className="py-3 px-3 text-right">
                          <Button
                            variant="ghost"
                            size="sm"
                            className="text-xs h-7 px-2"
                            onClick={() => {
                              setSelectedRider(rider);
                              setNewCashLimit(rider.maxCashLimit.toString());
                              setIsCashModalOpen(true);
                            }}
                          >
                            Set Limit
                          </Button>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </div>
        </div>

        {/* Right Col: Unassigned Orders & Quick Dispatch Feed */}
        <div className="space-y-4">
          <div className="rounded-xl border border-slate-200 bg-white p-5 shadow-sm dark:border-slate-800 dark:bg-slate-900">
            <h2 className="text-base font-bold text-slate-900 dark:text-slate-100 flex items-center justify-between mb-3">
              <span>Unassigned Order Pool</span>
              <Badge variant="warning">{unassignedOrders.length} Waiting</Badge>
            </h2>
            <p className="text-xs text-slate-500 mb-4">
              Orders requiring courier pickup. Click to jump to the Order Lifecycle Monitor to force-assign.
            </p>

            {unassignedOrders.length === 0 ? (
              <div className="rounded-lg border border-dashed border-slate-200 p-6 text-center text-xs text-slate-500 dark:border-slate-800">
                <CheckCircle2 className="mx-auto h-8 w-8 text-emerald-500 mb-2" />
                All placed orders are currently secured by delivery riders!
              </div>
            ) : (
              <div className="space-y-3">
                {unassignedOrders.map((order) => (
                  <div
                    key={order.id}
                    className="rounded-lg border border-amber-200 bg-amber-50/50 p-3 text-xs dark:border-amber-900/50 dark:bg-amber-950/20"
                  >
                    <div className="flex items-center justify-between font-semibold text-slate-900 dark:text-slate-100 mb-1">
                      <span>{order.orderNumber}</span>
                      <span className="text-primary-600 dark:text-primary-400">৳{order.totalAmount}</span>
                    </div>
                    <div className="text-slate-600 dark:text-slate-400 truncate mb-1">{order.vendorName}</div>
                    <div className="text-[11px] text-slate-500 truncate mb-2">To: {order.deliveryAddress}</div>
                    <Link
                      to={`/orders?orderNumber=${order.orderNumber}`}
                      className="inline-flex items-center gap-1 text-[11px] font-semibold text-amber-700 hover:text-amber-800 dark:text-amber-400"
                    >
                      Assign Rider Now <ArrowRight className="h-3 w-3" />
                    </Link>
                  </div>
                ))}
              </div>
            )}
          </div>

          {/* Unassigned Dispatch Radar Card */}
          <div className="rounded-xl border border-slate-200 bg-white p-5 shadow-sm dark:border-slate-800 dark:bg-slate-900">
            <h3 className="text-sm font-bold text-slate-900 dark:text-slate-100 mb-2 flex items-center gap-2">
              <Clock className="h-4 w-4 text-amber-500" />
              Unassigned Dispatch Radar
            </h3>
            <div className="space-y-2 text-xs text-slate-600 dark:text-slate-400">
              <div className="flex justify-between">
                <span>Waiting Orders:</span>
                <span className="font-semibold text-slate-900 dark:text-slate-100">{unassignedOrders.length} orders</span>
              </div>
              <div className="flex justify-between">
                <span>Pool Volume:</span>
                <span className="font-semibold text-primary-600 dark:text-primary-400">৳{totalPoolVolume.toFixed(2)}</span>
              </div>
              <div className="flex justify-between">
                <span>Max Order Wait:</span>
                <span className={`font-semibold ${maxAgingMinutes >= 15 ? 'text-rose-600 font-bold animate-pulse' : 'text-slate-900 dark:text-slate-100'}`}>
                  {unassignedOrders.length > 0 ? `${maxAgingMinutes} mins` : '0 mins'}
                </span>
              </div>
              <div className="flex justify-between">
                <span>Available Couriers:</span>
                <span className="font-semibold text-emerald-600">{idleCount} idle ({onlineCount} online)</span>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Adjust Cash Safety Limit Modal */}
      {selectedRider && (
        <Modal
          isOpen={isCashModalOpen}
          onClose={() => setIsCashModalOpen(false)}
          title={`Adjust Cash Safety Limit — ${selectedRider.riderName}`}
        >
          <div className="space-y-4">
            <p className="text-xs text-slate-500">
              Set the maximum Cash on Delivery (COD) threshold this rider can hold before automated dispatch holds orders.
            </p>

            <div>
              <label className="block text-xs font-semibold text-slate-700 dark:text-slate-300 mb-1">
                Current Cash in Hand
              </label>
              <div className="text-base font-bold text-slate-900 dark:text-slate-100">
                ৳{selectedRider.cashInHand}
              </div>
            </div>

            <div>
              <label className="block text-xs font-semibold text-slate-700 dark:text-slate-300 mb-1">
                New Maximum Cash Limit (BDT)
              </label>
              <Input
                type="number"
                value={newCashLimit}
                onChange={(e) => setNewCashLimit(e.target.value)}
                placeholder="5000"
              />
            </div>

            <div className="flex justify-end gap-2 pt-2">
              <Button variant="outline" size="sm" onClick={() => setIsCashModalOpen(false)}>
                Cancel
              </Button>
              <Button
                size="sm"
                isLoading={updateCashLimitMutation.isPending}
                onClick={() => {
                  const limit = parseFloat(newCashLimit);
                  if (!isNaN(limit) && limit > 0) {
                    updateCashLimitMutation.mutate({ id: selectedRider.id, limit });
                  }
                }}
              >
                Save Threshold
              </Button>
            </div>
          </div>
        </Modal>
      )}
    </div>
  );
};
