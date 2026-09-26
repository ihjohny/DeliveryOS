import React from 'react';
import { Check, X } from 'lucide-react';
import { cn } from '../../utils/cn';

export interface StockToggleSwitchProps {
  isInStock: boolean;
  onToggle: (nextState: boolean) => void;
  isLoading?: boolean;
  size?: 'sm' | 'md';
  disabled?: boolean;
  className?: string;
  ariaLabel?: string;
}

export const StockToggleSwitch: React.FC<StockToggleSwitchProps> = ({
  isInStock,
  onToggle,
  isLoading = false,
  size = 'md',
  disabled = false,
  className,
  ariaLabel,
}) => {
  const isSm = size === 'sm';

  return (
    <button
      type="button"
      role="switch"
      aria-checked={isInStock}
      aria-label={ariaLabel || (isInStock ? 'Mark as Out of Stock' : 'Mark as In Stock')}
      disabled={disabled || isLoading}
      onClick={() => onToggle(!isInStock)}
      className={cn(
        'group relative inline-flex items-center justify-between rounded-full transition-colors focus:outline-none focus:ring-2 focus:ring-primary-500/30 select-none disabled:opacity-50 disabled:cursor-not-allowed',
        isSm
          ? 'h-7 min-w-[84px] px-1 text-[11px] font-semibold'
          : 'h-11 min-h-[44px] min-w-[114px] px-1.5 text-xs font-bold shadow-sm',
        isInStock
          ? 'bg-emerald-600 hover:bg-emerald-700 text-white'
          : 'bg-rose-600 hover:bg-rose-700 text-white',
        className
      )}
    >
      <span
        className={cn(
          'inline-flex items-center justify-center rounded-full bg-white shadow-md transition-transform duration-200 ease-in-out',
          isSm ? 'h-5 w-5' : 'h-8 w-8',
          isInStock
            ? isSm
              ? 'translate-x-[56px] text-emerald-600'
              : 'translate-x-[72px] text-emerald-600'
            : 'translate-x-0 text-rose-600'
        )}
      >
        {isLoading ? (
          <span
            className={cn(
              'animate-spin rounded-full border-2 border-slate-300 border-t-slate-700',
              isSm ? 'h-3 w-3' : 'h-4 w-4'
            )}
          />
        ) : isInStock ? (
          <Check className={cn(isSm ? 'h-3 w-3' : 'h-4 w-4')} />
        ) : (
          <X className={cn(isSm ? 'h-3 w-3' : 'h-4 w-4')} />
        )}
      </span>

      <span
        className={cn(
          'absolute transition-opacity duration-150',
          isInStock
            ? isSm
              ? 'left-2.5 text-white'
              : 'left-3 text-white'
            : isSm
            ? 'right-2 text-white'
            : 'right-3 text-white'
        )}
      >
        {isInStock ? 'In Stock' : 'Sold Out'}
      </span>
    </button>
  );
};
