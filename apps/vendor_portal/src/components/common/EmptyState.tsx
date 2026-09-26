import React from 'react';
import { LucideIcon } from 'lucide-react';
import { cn } from '../../utils/cn';

export interface EmptyStateProps {
  title?: string;
  message: string;
  icon?: LucideIcon | React.ReactNode;
  action?: React.ReactNode;
  className?: string;
}

export const EmptyState: React.FC<EmptyStateProps> = ({
  title,
  message,
  icon,
  action,
  className,
}) => {
  const renderIcon = () => {
    if (!icon) return null;
    if (React.isValidElement(icon)) {
      return icon;
    }
    const IconComp = icon as LucideIcon;
    return <IconComp className="h-5 w-5" />;
  };

  return (
    <div
      className={cn(
        'rounded-xl border border-dashed border-slate-200 p-8 sm:p-12 text-center dark:border-slate-800',
        className
      )}
    >
      {icon && (
        <div className="mx-auto mb-3 flex h-10 w-10 items-center justify-center rounded-full bg-slate-100 text-slate-500 dark:bg-slate-800 dark:text-slate-400">
          {renderIcon()}
        </div>
      )}
      {title && (
        <h4 className="text-sm font-semibold text-slate-900 dark:text-slate-100 mb-1">
          {title}
        </h4>
      )}
      <p className="text-xs text-slate-500 dark:text-slate-400 max-w-sm mx-auto">
        {message}
      </p>
      {action && <div className="mt-4">{action}</div>}
    </div>
  );
};
