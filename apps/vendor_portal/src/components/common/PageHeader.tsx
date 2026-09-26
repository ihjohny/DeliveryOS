import React from 'react';
import { cn } from '../../utils/cn';

export interface PageHeaderProps {
  title: string;
  description?: React.ReactNode;
  icon?: React.ReactNode;
  badge?: React.ReactNode;
  actions?: React.ReactNode;
  children?: React.ReactNode;
  className?: string;
}

export const PageHeader: React.FC<PageHeaderProps> = ({
  title,
  description,
  icon,
  badge,
  actions,
  children,
  className,
}) => {
  const actionSlot = actions || children;

  return (
    <div
      className={cn(
        'flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between border-b border-slate-200 pb-4 dark:border-slate-800',
        className
      )}
    >
      <div className="min-w-0">
        <div className="flex flex-wrap items-center gap-2.5">
          {icon && <div className="shrink-0">{icon}</div>}
          <h2 className="text-xl sm:text-2xl font-extrabold tracking-tight text-slate-900 dark:text-slate-100 truncate">
            {title}
          </h2>
          {badge && <div className="shrink-0">{badge}</div>}
        </div>
        {description && (
          <div className="mt-1 text-xs text-slate-500 dark:text-slate-400">
            {description}
          </div>
        )}
      </div>

      {actionSlot && (
        <div className="flex flex-wrap items-center gap-2 sm:gap-2.5 shrink-0">
          {actionSlot}
        </div>
      )}
    </div>
  );
};
