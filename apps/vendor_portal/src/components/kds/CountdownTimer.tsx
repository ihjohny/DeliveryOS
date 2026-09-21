import React, { useState, useEffect } from 'react';
import { Clock, AlertTriangle } from 'lucide-react';
import { cn } from '../../utils/cn';

interface CountdownTimerProps {
  acceptedAt?: string | null;
  prepTimeMinutes?: number | null;
  className?: string;
}

export const CountdownTimer: React.FC<CountdownTimerProps> = ({
  acceptedAt,
  prepTimeMinutes = 20,
  className,
}) => {
  const [remainingSeconds, setRemainingSeconds] = useState<number>(() => {
    if (!acceptedAt || !prepTimeMinutes) return (prepTimeMinutes || 20) * 60;
    const start = new Date(acceptedAt).getTime();
    const target = start + prepTimeMinutes * 60 * 1000;
    return Math.floor((target - Date.now()) / 1000);
  });

  useEffect(() => {
    if (!acceptedAt) return;

    const interval = setInterval(() => {
      const start = new Date(acceptedAt).getTime();
      const target = start + (prepTimeMinutes || 20) * 60 * 1000;
      const diff = Math.floor((target - Date.now()) / 1000);
      setRemainingSeconds(diff);
    }, 1000);

    return () => clearInterval(interval);
  }, [acceptedAt, prepTimeMinutes]);

  const isOverdue = remainingSeconds < 0;
  const isUrgent = remainingSeconds <= 180 && !isOverdue; // Under 3 mins

  const formatTime = (seconds: number) => {
    const absSec = Math.abs(seconds);
    const mins = Math.floor(absSec / 60);
    const secs = absSec % 60;
    return `${mins}:${secs < 10 ? '0' : ''}${secs}`;
  };

  return (
    <div
      className={cn(
        'inline-flex items-center gap-1.5 rounded-lg px-2.5 py-1 text-xs font-semibold tracking-wider transition-colors',
        isOverdue
          ? 'bg-rose-100 text-rose-700 border border-rose-300 dark:bg-rose-950/60 dark:text-rose-400 dark:border-rose-800 animate-pulse'
          : isUrgent
          ? 'bg-amber-100 text-amber-800 border border-amber-300 dark:bg-amber-950/60 dark:text-amber-400 dark:border-amber-800'
          : 'bg-emerald-50 text-emerald-700 border border-emerald-200 dark:bg-emerald-950/50 dark:text-emerald-400 dark:border-emerald-800',
        className
      )}
    >
      {isOverdue ? (
        <AlertTriangle className="h-3.5 w-3.5 text-rose-600 dark:text-rose-400" />
      ) : (
        <Clock className="h-3.5 w-3.5" />
      )}
      <span>
        {isOverdue
          ? `+${formatTime(remainingSeconds)} Overdue`
          : `${formatTime(remainingSeconds)} left`}
      </span>
    </div>
  );
};
