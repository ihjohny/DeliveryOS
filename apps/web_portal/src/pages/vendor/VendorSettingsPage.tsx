import React, { useState, useEffect } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import {
  Clock,
  PauseCircle,
  PlayCircle,
  Calendar,
  Save,
  CheckCircle2,
  Store,
  AlertTriangle,
} from 'lucide-react';
import { useVendorOutlet } from '../../contexts/VendorOutletContext';
import kdsApi from '../../services/kdsApi';
import { Button } from '../../components/ui/Button';
import { Badge } from '../../components/ui/Badge';
import { Alert } from '../../components/ui/Alert';
import { LoadingSpinner } from '../../components/ui/LoadingSpinner';

const DAY_NAMES = [
  'Sunday',
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
];

export const VendorSettingsPage: React.FC = () => {
  const queryClient = useQueryClient();
  const { activeOutletId, activeOutlet, outlets, refetchOutlets } = useVendorOutlet();

  // If ALL selected, default to first outlet for settings
  const targetVendorId =
    activeOutletId !== 'ALL' ? activeOutletId : outlets[0]?.id || '';

  const { data: settings, isLoading } = useQuery({
    queryKey: ['vendor-settings', targetVendorId],
    queryFn: () => kdsApi.getOutletSettings(targetVendorId),
    enabled: !!targetVendorId,
  });

  const [defaultPrepTime, setDefaultPrepTime] = useState<number>(20);
  const [operatingHours, setOperatingHours] = useState<
    Array<{
      dayOfWeek: number;
      openTime: string;
      closeTime: string;
      isClosed: boolean;
    }>
  >([]);
  const [feedbackMsg, setFeedbackMsg] = useState<{
    type: 'success' | 'error';
    text: string;
  } | null>(null);

  useEffect(() => {
    if (settings) {
      setDefaultPrepTime(settings.defaultPrepTimeMinutes || 20);

      // Pre-fill full 7-day schedule
      const hoursMap = new Map(
        settings.operatingHours?.map((h) => [h.dayOfWeek, h]) || []
      );
      const fullWeek = [0, 1, 2, 3, 4, 5, 6].map((day) => {
        const existing = hoursMap.get(day);
        return {
          dayOfWeek: day,
          openTime: existing?.openTime || '09:00:00',
          closeTime: existing?.closeTime || '22:00:00',
          isClosed: existing ? existing.isClosed : false,
        };
      });
      setOperatingHours(fullWeek);
    }
  }, [settings]);

  // Mutations
  const updateSettingsMutation = useMutation({
    mutationFn: (data: { defaultPrepTimeMinutes?: number; isBusy?: boolean }) =>
      kdsApi.updateOutletSettings(targetVendorId, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['vendor-settings', targetVendorId] });
      refetchOutlets();
      setFeedbackMsg({
        type: 'success',
        text: 'Outlet settings updated successfully.',
      });
    },
    onError: () => {
      setFeedbackMsg({
        type: 'error',
        text: 'Failed to update outlet settings. Please try again.',
      });
    },
  });

  const updateHoursMutation = useMutation({
    mutationFn: (hours: typeof operatingHours) =>
      kdsApi.updateOperatingHours(targetVendorId, hours),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['vendor-settings', targetVendorId] });
      setFeedbackMsg({
        type: 'success',
        text: 'Weekly operating schedule saved successfully.',
      });
    },
    onError: () => {
      setFeedbackMsg({
        type: 'error',
        text: 'Failed to save operating schedule.',
      });
    },
  });

  const handleToggleRushPause = (isBusy: boolean) => {
    updateSettingsMutation.mutate({ isBusy });
  };

  const handleSavePrepTime = () => {
    updateSettingsMutation.mutate({ defaultPrepTimeMinutes: defaultPrepTime });
  };

  const handleSaveHours = () => {
    updateHoursMutation.mutate(operatingHours);
  };

  if (isLoading) {
    return (
      <div className="py-20">
        <LoadingSpinner size="lg" label="Loading store operations & schedule..." />
      </div>
    );
  }

  const currentOutletName = activeOutlet?.name || settings?.name || 'Store Outlet';
  const isBusy = settings?.isBusy ?? false;

  return (
    <div className="max-w-4xl space-y-8">
      {/* Page Header */}
      <div className="border-b border-slate-200 pb-4 dark:border-slate-800">
        <div className="flex items-center gap-2.5">
          <Store className="h-6 w-6 text-amber-500" />
          <h2 className="text-2xl font-extrabold tracking-tight text-slate-900 dark:text-slate-100">
            Outlet Operations & Schedule
          </h2>
        </div>
        <p className="mt-1 text-xs text-slate-500 dark:text-slate-400">
          Configuring operating status, rush hour pauses, and preparation duration for{' '}
          <strong className="font-semibold text-slate-700 dark:text-slate-200">
            {currentOutletName}
          </strong>
        </p>
      </div>

      {feedbackMsg && (
        <Alert
          type={feedbackMsg.type}
          message={feedbackMsg.text}
          onDismiss={() => setFeedbackMsg(null)}
        />
      )}

      {/* 1. Emergency Rush Pause Controls */}
      <div className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm dark:border-slate-800 dark:bg-slate-900">
        <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between border-b border-slate-100 pb-4 dark:border-slate-800">
          <div>
            <div className="flex items-center gap-2">
              <h3 className="text-base font-bold text-slate-900 dark:text-slate-100">
                Emergency Rush Hour Pause
              </h3>
              {isBusy ? (
                <Badge variant="danger" size="sm">
                  PAUSED (Rush Mode)
                </Badge>
              ) : (
                <Badge variant="success" size="sm">
                  OPERATIONAL (Open)
                </Badge>
              )}
            </div>
            <p className="mt-1 text-xs text-slate-500 dark:text-slate-400">
              Instantly block incoming customer checkout requests during extreme kitchen rush or prayer breaks.
            </p>
          </div>

          <div>
            {isBusy ? (
              <Button
                variant="primary"
                className="bg-emerald-600 hover:bg-emerald-700 text-white font-bold"
                onClick={() => handleToggleRushPause(false)}
                isLoading={updateSettingsMutation.isPending}
                leftIcon={<PlayCircle className="h-4 w-4" />}
              >
                Resume Store Operations
              </Button>
            ) : (
              <div className="flex flex-wrap items-center gap-2">
                <Button
                  variant="danger"
                  size="sm"
                  onClick={() => handleToggleRushPause(true)}
                  isLoading={updateSettingsMutation.isPending}
                  leftIcon={<PauseCircle className="h-4 w-4" />}
                >
                  Pause 30 Mins
                </Button>
                <Button
                  variant="outline"
                  size="sm"
                  onClick={() => handleToggleRushPause(true)}
                  isLoading={updateSettingsMutation.isPending}
                >
                  Pause 1 Hour
                </Button>
                <Button
                  variant="outline"
                  size="sm"
                  onClick={() => handleToggleRushPause(true)}
                  isLoading={updateSettingsMutation.isPending}
                >
                  Rest of Day
                </Button>
              </div>
            )}
          </div>
        </div>

        {isBusy && (
          <div className="mt-4 flex items-center gap-2 rounded-xl bg-amber-50 p-3 text-xs text-amber-800 dark:bg-amber-950/40 dark:text-amber-300">
            <AlertTriangle className="h-4 w-4 shrink-0 text-amber-600" />
            <span>
              Orders are currently halted for this branch. Customer cart checkout displays
              &ldquo;Store currently busy&rdquo;. Tap <strong>Resume Store Operations</strong> to start receiving orders again.
            </span>
          </div>
        )}
      </div>

      {/* 2. Default Preparation Time Duration */}
      <div className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm dark:border-slate-800 dark:bg-slate-900">
        <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
          <div>
            <div className="flex items-center gap-2">
              <Clock className="h-4 w-4 text-primary-600" />
              <h3 className="text-base font-bold text-slate-900 dark:text-slate-100">
                Default Preparation Duration
              </h3>
            </div>
            <p className="mt-1 text-xs text-slate-500 dark:text-slate-400">
              Standard prep time allocated when staff taps the one-touch accept button on the KDS console.
            </p>
          </div>

          <div className="flex items-center gap-3">
            <select
              value={defaultPrepTime}
              onChange={(e) => setDefaultPrepTime(Number(e.target.value))}
              className="rounded-lg border border-slate-300 bg-white px-3.5 py-2 text-sm font-semibold text-slate-800 shadow-sm focus:border-primary-500 focus:outline-none dark:border-slate-700 dark:bg-slate-800 dark:text-slate-200"
            >
              {[15, 20, 25, 30, 45].map((m) => (
                <option key={m} value={m}>
                  {m} minutes
                </option>
              ))}
            </select>

            <Button
              variant="primary"
              size="md"
              onClick={handleSavePrepTime}
              isLoading={updateSettingsMutation.isPending}
              leftIcon={<Save className="h-4 w-4" />}
            >
              Save Prep Time
            </Button>
          </div>
        </div>
      </div>

      {/* 3. Weekly Operating Schedule */}
      <div className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm dark:border-slate-800 dark:bg-slate-900">
        <div className="flex items-center justify-between border-b border-slate-100 pb-4 dark:border-slate-800">
          <div>
            <div className="flex items-center gap-2">
              <Calendar className="h-4 w-4 text-primary-600" />
              <h3 className="text-base font-bold text-slate-900 dark:text-slate-100">
                Weekly Operating Schedule
              </h3>
            </div>
            <p className="mt-1 text-xs text-slate-500 dark:text-slate-400">
              Store doors open and closing hours for each day of the week.
            </p>
          </div>

          <Button
            variant="primary"
            size="sm"
            onClick={handleSaveHours}
            isLoading={updateHoursMutation.isPending}
            leftIcon={<Save className="h-4 w-4" />}
          >
            Save Schedule
          </Button>
        </div>

        <div className="mt-4 divide-y divide-slate-100 dark:divide-slate-800/80">
          {operatingHours.map((h, index) => (
            <div
              key={h.dayOfWeek}
              className="flex flex-col sm:flex-row sm:items-center justify-between py-3 text-xs gap-3"
            >
              <span className="w-28 font-bold text-slate-900 dark:text-slate-100">
                {DAY_NAMES[h.dayOfWeek]}
              </span>

              <div className="flex items-center gap-4">
                <div className="flex items-center gap-2">
                  <span className="text-slate-500">Opens:</span>
                  <input
                    type="time"
                    value={h.openTime.slice(0, 5)}
                    disabled={h.isClosed}
                    onChange={(e) => {
                      const newHours = [...operatingHours];
                      newHours[index].openTime = `${e.target.value}:00`;
                      setOperatingHours(newHours);
                    }}
                    className="rounded border border-slate-300 px-2 py-1 text-xs text-slate-800 dark:border-slate-700 dark:bg-slate-800 dark:text-slate-200 disabled:opacity-40"
                  />
                </div>

                <div className="flex items-center gap-2">
                  <span className="text-slate-500">Closes:</span>
                  <input
                    type="time"
                    value={h.closeTime.slice(0, 5)}
                    disabled={h.isClosed}
                    onChange={(e) => {
                      const newHours = [...operatingHours];
                      newHours[index].closeTime = `${e.target.value}:00`;
                      setOperatingHours(newHours);
                    }}
                    className="rounded border border-slate-300 px-2 py-1 text-xs text-slate-800 dark:border-slate-700 dark:bg-slate-800 dark:text-slate-200 disabled:opacity-40"
                  />
                </div>

                <label className="flex items-center gap-1.5 cursor-pointer select-none">
                  <input
                    type="checkbox"
                    checked={h.isClosed}
                    onChange={(e) => {
                      const newHours = [...operatingHours];
                      newHours[index].isClosed = e.target.checked;
                      setOperatingHours(newHours);
                    }}
                    className="rounded border-slate-300 text-rose-600 focus:ring-rose-500"
                  />
                  <span
                    className={
                      h.isClosed
                        ? 'font-bold text-rose-600'
                        : 'text-slate-600 dark:text-slate-400'
                    }
                  >
                    Closed
                  </span>
                </label>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};
