import React from 'react';
import { cn } from '../../utils/cn';

export interface StatCardProps {
  title: string;
  value: string | number;
  subtitle?: string;
  icon: React.ReactNode;
  iconBgColor?: string;
  iconTextColor?: string;
  valueColor?: string;
  className?: string;
}

export const StatCard: React.FC<StatCardProps> = ({
  title,
  value,
  subtitle,
  icon,
  iconBgColor = 'bg-primary-50 dark:bg-primary-950/50',
  iconTextColor = 'text-primary-600 dark:text-primary-400',
  valueColor = 'text-slate-900 dark:text-slate-100',
  className,
}) => {
  return (
    <div
      className={cn(
        'rounded-2xl border border-slate-200 bg-white p-5 shadow-sm dark:border-slate-800 dark:bg-slate-900 transition-all hover:border-slate-300 dark:hover:border-slate-700',
        className
      )}
    >
      <div className="flex items-center justify-between">
        <span className="text-xs font-semibold uppercase tracking-wider text-slate-500">
          {title}
        </span>
        <div className={cn('rounded-xl p-2.5 shrink-0', iconBgColor, iconTextColor)}>
          {icon}
        </div>
      </div>
      <div className="mt-3">
        <span className={cn('text-2xl font-extrabold tracking-tight', valueColor)}>
          {value}
        </span>
        {subtitle && <p className="mt-1 text-xs text-slate-500">{subtitle}</p>}
      </div>
    </div>
  );
};
