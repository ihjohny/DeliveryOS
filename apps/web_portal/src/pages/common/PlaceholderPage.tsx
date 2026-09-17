import React from 'react';
import { Badge } from '../../components/ui/Badge';

export const PlaceholderPage: React.FC<{ title: string; subtitle: string }> = ({
  title,
  subtitle,
}) => {
  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-bold tracking-tight text-slate-900 dark:text-slate-100">{title}</h2>
          <p className="text-sm text-slate-500 dark:text-slate-400">{subtitle}</p>
        </div>
        <Badge variant="purple">Under Active Development</Badge>
      </div>

      <div className="flex min-h-[350px] flex-col items-center justify-center rounded-2xl border border-dashed border-slate-300 bg-white p-8 text-center dark:border-slate-800 dark:bg-slate-900">
        <div className="h-12 w-12 rounded-xl bg-slate-100 dark:bg-slate-800 flex items-center justify-center text-slate-400 mb-3">
          📦
        </div>
        <h4 className="font-semibold text-slate-800 dark:text-slate-200">{title} Module</h4>
        <p className="mt-1 text-xs text-slate-500 max-w-sm">
          This feature module is scheduled in subsequent tasks of the delivery pipeline.
        </p>
      </div>
    </div>
  );
};
