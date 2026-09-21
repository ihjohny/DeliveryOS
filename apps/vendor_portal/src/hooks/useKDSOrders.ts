import { useEffect, useMemo } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import kdsApi from '../services/kdsApi';
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

    const handleNewOrder = (newOrder: KDSOrder) => {
      // Start persistent looped audio alarm
      soundEngine.startOrderAlarm();

      // Update query cache
      queryClient.setQueryData<KDSOrder[]>(queryKey, (old = []) => {
        const exists = old.some((o) => o.id === newOrder.id);
        if (exists) {
          return old.map((o) => (o.id === newOrder.id ? { ...o, ...newOrder } : o));
        }
        return [newOrder, ...old];
      });
    };

    const handleStatusChanged = (payload: { orderId: string; newStatus: string; prepTime?: number }) => {
      queryClient.setQueryData<KDSOrder[]>(queryKey, (old = []) => {
        return old.map((o) => {
          if (o.id === payload.orderId) {
            return {
              ...o,
              status: payload.newStatus as KDSOrder['status'],
              prepTimeMinutes: payload.prepTime ?? o.prepTimeMinutes,
              acceptedAt: payload.newStatus === 'PREPARING' ? new Date().toISOString() : o.acceptedAt,
            };
          }
          return o;
        });
      });

      // Check if any unaccepted new orders remain; if none, silence alarm
      const currentOrders = queryClient.getQueryData<KDSOrder[]>(queryKey) || [];
      const hasUnaccepted = currentOrders.some(
        (o) => (o.status === 'PLACED' || o.status === 'RIDER_ASSIGNED') && o.id !== payload.orderId
      );
      if (!hasUnaccepted) {
        soundEngine.stopOrderAlarm();
      }
    };

    socket.on('order:new', handleNewOrder);
    socket.on('order:status:changed', handleStatusChanged);

    return () => {
      socket.off('order:new', handleNewOrder);
      socket.off('order:status:changed', handleStatusChanged);
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
  const newOrders = useMemo(
    () => orders.filter((o) => o.status === 'PLACED' || o.status === 'RIDER_ASSIGNED'),
    [orders]
  );

  const inPreparationOrders = useMemo(
    () => orders.filter((o) => o.status === 'ACCEPTED' || o.status === 'PREPARING'),
    [orders]
  );

  const readyOrders = useMemo(
    () => orders.filter((o) => o.status === 'READY_FOR_PICKUP'),
    [orders]
  );

  return {
    orders,
    isLoading,
    refetch,
    newOrders,
    inPreparationOrders,
    readyOrders,
    acceptOrder: (orderId: string, prepTimeMinutes?: number) =>
      acceptMutation.mutateAsync({ orderId, prepTimeMinutes }),
    markOrderReady: (orderId: string) => readyMutation.mutateAsync(orderId),
    handoverOrder: (orderId: string) => handoverMutation.mutateAsync(orderId),
    isAccepting: acceptMutation.isPending,
    isMarkingReady: readyMutation.isPending,
    isHandingOver: handoverMutation.isPending,
  };
};
