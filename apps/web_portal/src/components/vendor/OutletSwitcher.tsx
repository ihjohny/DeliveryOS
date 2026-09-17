import React from 'react';
import { Store, Lock, Building2 } from 'lucide-react';
import { useVendorOutlet } from '../../contexts/VendorOutletContext';

export const OutletSwitcher: React.FC<{ className?: string }> = ({ className }) => {
  const { outlets, activeOutletId, setActiveOutletId, isMultiBranch, activeOutlet } =
    useVendorOutlet();

  if (outlets.length === 0) return null;

  if (!isMultiBranch) {
    // Locked single-outlet view for PARTICULAR_OUTLET
    return (
      <div
        className={`inline-flex items-center gap-2 rounded-lg border border-slate-200 bg-slate-50 px-3 py-1.5 text-xs font-semibold text-slate-700 dark:border-slate-800 dark:bg-slate-800/80 dark:text-slate-200 ${
          className || ''
        }`}
        title="Access strictly locked to this physical branch location"
      >
        <Store className="h-3.5 w-3.5 text-amber-500" />
        <span className="truncate max-w-[180px]">{activeOutlet?.name || outlets[0]?.name}</span>
        <Lock className="h-3 w-3 text-slate-400" />
      </div>
    );
  }

  // Multi-branch Brand Owner switcher
  return (
    <div className={`relative inline-flex items-center gap-2 ${className || ''}`}>
      <div className="flex items-center gap-1.5 text-xs font-bold text-slate-500 dark:text-slate-400">
        <Building2 className="h-4 w-4 text-purple-600 dark:text-purple-400" />
        <span className="hidden md:inline">Branch:</span>
      </div>

      <select
        value={activeOutletId}
        onChange={(e) => setActiveOutletId(e.target.value)}
        className="rounded-lg border border-purple-200 bg-purple-50/70 px-3 py-1.5 text-xs font-bold text-purple-900 shadow-sm transition-colors hover:border-purple-300 focus:border-purple-500 focus:outline-none dark:border-purple-900/60 dark:bg-purple-950/40 dark:text-purple-300 cursor-pointer"
        aria-label="Select Outlet Branch"
      >
        <option value="ALL">🏢 All Outlets (Consolidated Brand)</option>
        {outlets.map((outlet) => (
          <option key={outlet.id} value={outlet.id}>
            {outlet.name} {outlet.isBusy ? '(Paused)' : '(Open)'}
          </option>
        ))}
      </select>
    </div>
  );
};
