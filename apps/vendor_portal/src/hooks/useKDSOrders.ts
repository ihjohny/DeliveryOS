import { useEffect, useMemo } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import kdsApi, { normalizeKDSOrder } from '../services/kdsApi';
import { getSocket } from '../services/socket';
import { KDSOrder } from '../types/kds';
import { soundEngine } from '../utils/sound';

export const useKDSOrders = (vendorId?: string) => {
  const queryClient = useQueryClient();
  const queryKey = useMemo(() => ['kds-live-orders', vendorId], [vendorId]);

  // 1. Fetch live orders
  const { data: orders = [], isLoading, refetch } = useQuery<KDSOrder[]>({
    queryKey,
    queryFn: () => kdsApi.getLiveOrders(vendorId),
    refetchInterval: 15000, // Background poll every 15s as fallback
  });

  // 2. Real-time WebSocket Listeners
  useEffect(() => {
    const socket = getSocket();

    const handleNewOrder = (incoming: any) => {
      // Start persistent looped audio alarm
      soundEngine.startOrderAlarm();

      const raw = incoming?.data || incoming;
      const newOrder = normalizeKDSOrder(raw);
      if (!newOrder || !newOrder.id) return;

      // Update query cache
      queryClient.setQueryData<KDSOrder[]>(queryKey, (old = []) => {
        const safeOld = Array.isArray(old) ? old : [];
        const exists = safeOld.some((o) => o.id === newOrder.id);
        if (exists) {
          return safeOld.map((o) => (o.id === newOrder.id ? { ...o, ...newOrder } : o));
        }
        return [newOrder, ...safeOld];
      });
    };

    const handleStatusChanged = (payload: any) => {
      const data = payload?.data || payload;
      const orderId = data?.orderId || data?.id;
      const newStatus = data?.newStatus || data?.status;
      const prepTime = data?.prepTime ?? data?.prepTimeMinutes;

      if (!orderId) return;

      if (newStatus === 'CANCELLED') {
        queryClient.setQueryData<KDSOrder[]>(queryKey, (old = []) => {
          const safeOld = Array.isArray(old) ? old : [];
          return safeOld.filter((o) => o.id !== orderId);
        });
      } else {
        queryClient.setQueryData<KDSOrder[]>(queryKey, (old = []) => {
          const safeOld = Array.isArray(old) ? old : [];
          return safeOld.map((o) => {
            if (o.id === orderId) {
              return {
                ...o,
                status: (newStatus || o.status) as KDSOrder['status'],
                prepTimeMinutes: prepTime ?? o.prepTimeMinutes,
                acceptedAt: newStatus === 'PREPARING' ? new Date().toISOString() : o.acceptedAt,
              };
            }
            return o;
          });
        });
      }

      // Check if any unaccepted new orders remain; if none, silence alarm
      const currentOrders = queryClient.getQueryData<KDSOrder[]>(queryKey) || [];
      const hasUnaccepted = Array.isArray(currentOrders) && currentOrders.some(
        (o) => (o.status === 'PLACED' || o.status === 'RIDER_ASSIGNED') && o.id !== orderId
      );
      if (!hasUnaccepted) {
        soundEngine.stopOrderAlarm();
      }
    };

    const handleOrderCancelled = (payload: any) => {
      const data = payload?.data || payload;
      const orderId = data?.orderId || data?.id;
      if (!orderId) return;

      queryClient.setQueryData<KDSOrder[]>(queryKey, (old = []) => {
        const safeOld = Array.isArray(old) ? old : [];
        return safeOld.filter((o) => o.id !== orderId);
      });

      const currentOrders = queryClient.getQueryData<KDSOrder[]>(queryKey) || [];
      const hasUnaccepted = Array.isArray(currentOrders) && currentOrders.some(
        (o) => (o.status === 'PLACED' || o.status === 'RIDER_ASSIGNED') && o.id !== orderId
      );
      if (!hasUnaccepted) {
        soundEngine.stopOrderAlarm();
      }
    };

    socket.on('order:new', handleNewOrder);
    socket.on('order:status:changed', handleStatusChanged);
    socket.on('order:cancelled', handleOrderCancelled);

    return () => {
      socket.off('order:new', handleNewOrder);
      socket.off('order:status:changed', handleStatusChanged);
      socket.off('order:cancelled', handleOrderCancelled);
    };
  }, [queryClient, queryKey]);

  // 3. Order Action Mutations
  const acceptMutation = useMutation({
    mutationFn: ({ orderId, prepTimeMinutes }: { orderId: string; prepTimeMinutes?: number }) =>
      kdsApi.acceptOrder(orderId, prepTimeMinutes),
    onSuccess: (updatedOrder) => {
      soundEngine.stopOrderAlarm();
      queryClient.setQueryData<KDSOrder[]>(queryKey, (old = []) =>
        old.map((o) => (o.id === updatedOrder.id ? { ...o, ...updatedOrder, status: 'PREPARING' } : o))
      );
    },
  });

  const rejectMutation = useMutation({
    mutationFn: ({
      orderId,
      reasonCode,
      reasonNotes,
    }: {
      orderId: string;
      reasonCode: string;
      reasonNotes?: string;
    }) => kdsApi.rejectOrder(orderId, reasonCode, reasonNotes),
    onSuccess: (updatedOrder) => {
      soundEngine.stopOrderAlarm();
      queryClient.setQueryData<KDSOrder[]>(queryKey, (old = []) =>
        old.filter((o) => o.id !== updatedOrder.id)
      );
    },
  });

  const readyMutation = useMutation({
    mutationFn: (orderId: string) => kdsApi.markOrderReady(orderId),
    onSuccess: (updatedOrder) => {
      queryClient.setQueryData<KDSOrder[]>(queryKey, (old = []) =>
        old.map((o) => (o.id === updatedOrder.id ? { ...o, ...updatedOrder, status: 'READY_FOR_PICKUP' } : o))
      );
    },
  });

  const handoverMutation = useMutation({
    mutationFn: (orderId: string) => kdsApi.handoverOrder(orderId),
    onSuccess: (updatedOrder) => {
      queryClient.setQueryData<KDSOrder[]>(queryKey, (old = []) =>
        old.filter((o) => o.id !== updatedOrder.id)
      );
    },
  });

  // 4. Categorize Orders into 3 Kanban Lanes
  const safeOrders = useMemo(() => (Array.isArray(orders) ? orders : []), [orders]);

  const newOrders = useMemo(
    () => safeOrders.filter((o) => o && (o.status === 'PLACED' || o.status === 'RIDER_ASSIGNED')),
    [safeOrders]
  );

  const inPreparationOrders = useMemo(
    () => safeOrders.filter((o) => o && (o.status === 'ACCEPTED' || o.status === 'PREPARING')),
    [safeOrders]
  );

  const readyOrders = useMemo(
    () => safeOrders.filter((o) => o && o.status === 'READY_FOR_PICKUP'),
    [safeOrders]
  );

  return {
    orders: safeOrders,
    isLoading,
    refetch,
    newOrders,
    inPreparationOrders,
    readyOrders,
    acceptOrder: (orderId: string, prepTimeMinutes?: number) =>
      acceptMutation.mutateAsync({ orderId, prepTimeMinutes }),
    rejectOrder: (orderId: string, reasonCode: string, reasonNotes?: string) =>
      rejectMutation.mutateAsync({ orderId, reasonCode, reasonNotes }),
    markOrderReady: (orderId: string) => readyMutation.mutateAsync(orderId),
    handoverOrder: (orderId: string) => handoverMutation.mutateAsync(orderId),
    isAccepting: acceptMutation.isPending,
    isRejecting: rejectMutation.isPending,
    isMarkingReady: readyMutation.isPending,
    isHandingOver: handoverMutation.isPending,
  };
};
