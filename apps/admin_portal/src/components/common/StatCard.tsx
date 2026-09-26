import React from 'react';
import { LucideIcon } from 'lucide-react';
import { cn } from '../../utils/cn';

export interface StatCardProps {
  title: string;
  value: string | number;
  subtitle?: React.ReactNode;
  icon?: LucideIcon;
  iconColorClass?: string;
  onClick?: () => void;
  active?: boolean;
  isLoading?: boolean;
  className?: string;
}

export const StatCard: React.FC<StatCardProps> = ({
  title,
  value,
  subtitle,
  icon: Icon,
  iconColorClass = 'text-primary-600 bg-primary-50 dark:bg-primary-950/50',
  onClick,
  active,
  isLoading,
  className,
}) => {
  return (
    <div
      onClick={onClick}
      className={cn(
        'rounded-xl border border-slate-200 bg-white p-4 sm:p-5 shadow-sm transition-all dark:border-slate-800 dark:bg-slate-900',
        onClick && 'cursor-pointer hover:border-slate-300 dark:hover:border-slate-700',
        active && 'border-primary-500 bg-primary-50/20 ring-1 ring-primary-500',
        className
      )}
    >
      <div className="flex items-center justify-between">
        <span className="text-xs font-semibold uppercase tracking-wider text-slate-500">
          {title}
        </span>
        {Icon && (
          <div className={cn('rounded-lg p-2', iconColorClass)}>
            <Icon className="h-4 w-4 sm:h-5 sm:w-5" />
          </div>
        )}
      </div>
      <div className="mt-2.5">
        <div className="text-2xl font-bold tracking-tight text-slate-900 dark:text-slate-100">
          {isLoading ? '...' : value}
        </div>
        {subtitle && (
          <div className="mt-1 text-xs text-slate-500">
            {subtitle}
          </div>
        )}
      </div>
    </div>
  );
};
