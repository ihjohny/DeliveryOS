import React, { useState } from 'react';
import {
  Clock,
  Bike,
  CreditCard,
  Banknote,
  CheckCircle,
  ArrowRight,
  UserCheck,
  ChevronDown,
} from 'lucide-react';
import { KDSOrder } from '../../types/kds';
import { CountdownTimer } from './CountdownTimer';
import { Button } from '../ui/Button';
import { Badge } from '../ui/Badge';
import { cn } from '../../utils/cn';

interface KDSOrderCardProps {
  order: KDSOrder;
  defaultPrepTimeMinutes?: number;
  onAccept?: (orderId: string, prepTimeMinutes?: number) => void;
  onMarkReady?: (orderId: string) => void;
  onHandover?: (orderId: string) => void;
  isActionLoading?: boolean;
}

export const KDSOrderCard: React.FC<KDSOrderCardProps> = ({
  order,
  defaultPrepTimeMinutes = 20,
  onAccept,
  onMarkReady,
  onHandover,
  isActionLoading = false,
}) => {
  const [selectedCustomTime, setSelectedCustomTime] = useState<number>(defaultPrepTimeMinutes);
  const [showTimePicker, setShowTimePicker] = useState(false);

  // Time elapsed since creation
  const getElapsedMins = () => {
    const timeVal = order.createdAt || (order as any).placedAt;
    const created = timeVal ? new Date(timeVal).getTime() : Date.now();
    const diffMins = Math.max(0, Math.floor((Date.now() - created) / (1000 * 60)));
    return diffMins === 0 ? 'Just now' : `${diffMins}m ago`;
  };

  const isNew = order.status === 'PLACED' || order.status === 'RIDER_ASSIGNED';
  const isPreparing = order.status === 'ACCEPTED' || order.status === 'PREPARING';
  const isReady = order.status === 'READY_FOR_PICKUP';

  const customerName =
    order.customer?.fullName || (order as any).customerPhoneSnapshot || 'Customer';
  const riderName =
    order.rider?.fullName || (order.rider as any)?.user?.fullName;
  const riderPhone =
    order.rider?.phone || (order.rider as any)?.user?.phone;
  const items = order.items || (order as any).orderItems || [];

  return (
    <div
      className={cn(
        'flex flex-col rounded-2xl border bg-white p-4 shadow-sm transition-all dark:bg-slate-900',
        isNew && 'border-rose-300 ring-2 ring-rose-400/30 dark:border-rose-800 dark:ring-rose-950',
        isPreparing && 'border-amber-200 dark:border-amber-900/60',
        isReady && 'border-emerald-200 dark:border-emerald-900/60'
      )}
    >
      {/* Header: Order Number, elapsed time, payment */}
      <div className="flex items-start justify-between border-b border-slate-100 pb-3 dark:border-slate-800">
        <div>
          <div className="flex items-center gap-2">
            <span className="font-extrabold text-base text-slate-900 dark:text-slate-100">
              #{order.orderNumber}
            </span>
            <span className="flex items-center text-xs text-slate-500 font-medium">
              <Clock className="h-3 w-3 mr-1" />
              {getElapsedMins()}
            </span>
          </div>
          <p className="text-xs text-slate-500 dark:text-slate-400 mt-0.5">
            Customer: <strong className="font-medium text-slate-700 dark:text-slate-200">{customerName}</strong>
          </p>
        </div>

        <div className="flex flex-col items-end">
          <span className="text-sm font-extrabold text-slate-900 dark:text-slate-100">
            ৳ {order.totalAmount}
          </span>
          <div className="mt-1 flex items-center gap-1">
            {order.paymentMethod === 'CASH_ON_DELIVERY' ? (
              <Badge variant="warning" size="sm">
                <Banknote className="h-2.5 w-2.5 mr-0.5" /> COD
              </Badge>
            ) : (
              <Badge variant="success" size="sm">
                <CreditCard className="h-2.5 w-2.5 mr-0.5" /> Paid Online
              </Badge>
            )}
          </div>
        </div>
      </div>

      {/* Rider Status Strip */}
      <div className="mt-2.5 flex items-center justify-between rounded-lg bg-slate-50 px-3 py-1.5 text-xs dark:bg-slate-800/60">
        {order.rider ? (
          <div className="flex items-center gap-1.5 text-slate-700 dark:text-slate-200 font-medium">
            <UserCheck className="h-3.5 w-3.5 text-emerald-600 dark:text-emerald-400" />
            <span>Rider: <strong>{riderName || 'Assigned'}</strong></span>
          </div>
        ) : (
          <div className="flex items-center gap-1.5 text-amber-700 dark:text-amber-400">
            <Bike className="h-3.5 w-3.5" />
            <span>Awaiting Rider Assignment</span>
          </div>
        )}
        {riderPhone && (
          <span className="text-[11px] text-slate-500">{riderPhone}</span>
        )}
      </div>

      {/* Dishes / Items List */}
      <div className="my-3 flex-1 space-y-2.5">
        {items.map((item: any) => {
          const productName = item.productName || item.productNameSnapshot || 'Item';
          const subtotal = item.subtotal ?? item.totalPrice ?? 0;
          const variantName = item.variant?.name || item.variantSnapshot?.name;
          const toppings = item.toppings || item.addonsSnapshot || [];

          return (
            <div key={item.id} className="text-xs">
              <div className="flex items-start justify-between font-semibold text-slate-800 dark:text-slate-200">
                <span>
                  <span className="inline-block w-5 font-bold text-primary-600 dark:text-primary-400">
                    {item.quantity}&times;
                  </span>
                  {productName}
                </span>
                <span className="text-slate-500">৳ {subtotal}</span>
              </div>

              {/* Variant */}
              {variantName && (
                <div className="ml-5 text-[11px] text-slate-500 dark:text-slate-400">
                  Option: {variantName}
                </div>
              )}

              {/* Toppings */}
              {toppings.length > 0 && (
                <div className="ml-5 text-[11px] text-slate-500 dark:text-slate-400">
                  Extras: {toppings.map((t: any) => t.name).join(', ')}
                </div>
              )}

              {/* Cooking Notes */}
              {item.instructions && (
                <div className="ml-5 mt-0.5 rounded bg-amber-50 px-2 py-0.5 text-[11px] text-amber-800 italic dark:bg-amber-950/40 dark:text-amber-300">
                  &ldquo;{item.instructions}&rdquo;
                </div>
              )}
            </div>
          );
        })}

        {order.customerNotes && (
          <div className="mt-2 rounded-lg border border-slate-200 bg-slate-50/70 p-2 text-xs text-slate-600 dark:border-slate-800 dark:bg-slate-800/40 dark:text-slate-300">
            <span className="font-semibold text-slate-700 dark:text-slate-200">Customer Note: </span>
            {order.customerNotes}
          </div>
        )}
      </div>

      {/* Action Area by Lane */}
      <div className="mt-auto border-t border-slate-100 pt-3 dark:border-slate-800">
        {/* Lane 1: New Orders -> Accept Controls */}
        {isNew && (
          <div className="space-y-2">
            <div className="flex items-center gap-2">
              <Button
                variant="primary"
                size="sm"
                className="flex-1 bg-emerald-600 hover:bg-emerald-700 text-white font-bold"
                onClick={() => onAccept && onAccept(order.id, selectedCustomTime)}
                isLoading={isActionLoading}
                leftIcon={<CheckCircle className="h-4 w-4" />}
              >
                Accept ({selectedCustomTime}m)
              </Button>

              <button
                type="button"
                onClick={() => setShowTimePicker(!showTimePicker)}
                className="rounded-lg border border-slate-200 p-2 text-slate-600 hover:bg-slate-100 dark:border-slate-700 dark:text-slate-300"
                title="Custom prep time"
              >
                <ChevronDown className="h-4 w-4" />
              </button>
            </div>

            {/* Custom Prep Time Dropdown */}
            {showTimePicker && (
              <div className="flex items-center justify-between rounded-lg border border-slate-200 bg-slate-50 p-2 text-xs dark:border-slate-700 dark:bg-slate-800">
                <span className="text-slate-600 dark:text-slate-300 font-medium">Prep Time:</span>
                <div className="flex gap-1">
                  {[15, 20, 25, 35, 45].map((mins) => (
                    <button
                      key={mins}
                      type="button"
                      onClick={() => {
                        setSelectedCustomTime(mins);
                        setShowTimePicker(false);
                      }}
                      className={cn(
                        'rounded px-2 py-1 font-semibold transition-colors',
                        selectedCustomTime === mins
                          ? 'bg-primary-600 text-white'
                          : 'bg-white text-slate-700 hover:bg-slate-200 dark:bg-slate-700 dark:text-slate-200'
                      )}
                    >
                      {mins}m
                    </button>
                  ))}
                </div>
              </div>
            )}
          </div>
        )}

        {/* Lane 2: In Preparation -> Countdown Timer & Ready Button */}
        {isPreparing && (
          <div className="flex items-center justify-between gap-2">
            <CountdownTimer
              acceptedAt={order.acceptedAt || order.updatedAt || (order as any).placedAt}
              prepTimeMinutes={order.prepTimeMinutes || defaultPrepTimeMinutes}
            />
            <Button
              variant="primary"
              size="sm"
              className="bg-amber-600 hover:bg-amber-700 text-white"
              onClick={() => onMarkReady && onMarkReady(order.id)}
              isLoading={isActionLoading}
              rightIcon={<ArrowRight className="h-3.5 w-3.5" />}
            >
              Ready for Pickup
            </Button>
          </div>
        )}

        {/* Lane 3: Ready for Pickup -> Handover to Rider Button */}
        {isReady && (
          <div className="flex items-center justify-between gap-2">
            <Badge variant="purple" size="sm">
              Waiting at Counter
            </Badge>
            <Button
              variant="primary"
              size="sm"
              className="bg-primary-600 hover:bg-primary-700 text-white"
              onClick={() => onHandover && onHandover(order.id)}
              isLoading={isActionLoading}
              leftIcon={<CheckCircle className="h-4 w-4" />}
            >
              Hand to Rider
            </Button>
          </div>
        )}
      </div>
    </div>
  );
};
