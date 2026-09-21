import React from 'react';
import { useNavigate } from 'react-router-dom';
import { FileQuestion, ArrowLeft } from 'lucide-react';
import { Button } from '../../components/ui/Button';

export const NotFoundPage: React.FC = () => {
  const navigate = useNavigate();

  return (
    <div className="flex min-h-screen flex-col items-center justify-center bg-slate-50 p-4 text-center dark:bg-slate-950">
      <div className="w-full max-w-md rounded-2xl border border-slate-200 bg-white p-8 shadow-xl dark:border-slate-800 dark:bg-slate-900">
        <div className="mx-auto mb-4 flex h-14 w-14 items-center justify-center rounded-2xl bg-amber-50 text-amber-600 dark:bg-amber-950/50 dark:text-amber-400">
          <FileQuestion className="h-8 w-8" />
        </div>
        <h2 className="text-xl font-bold text-slate-900 dark:text-slate-100">Page Not Found</h2>
        <p className="mt-2 text-sm text-slate-500 dark:text-slate-400">
          The page or route you are looking for does not exist.
        </p>

        <div className="mt-6">
          <Button
            variant="primary"
            onClick={() => navigate('/')}
            leftIcon={<ArrowLeft className="h-4 w-4" />}
          >
            Go Home
          </Button>
        </div>
      </div>
    </div>
  );
};
