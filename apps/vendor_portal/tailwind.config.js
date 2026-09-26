/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        // Warm culinary Amber & Flame Orange for Vendor / Kitchen operations
        primary: {
          50: '#fffbeb',
          100: '#fef3c7',
          200: '#fde68a',
          300: '#fcd34d',
          400: '#fbbf24',
          500: '#f59e0b',
          600: '#d97706',
          700: '#b45309',
          800: '#92400e',
          900: '#78350f',
          950: '#451a03',
        },
        culinary: {
          50: '#fff7ed',
          100: '#ffedd5',
          200: '#fed7aa',
          500: '#f97316',
          600: '#ea580c',
          700: '#c2410c',
        },
        brand: {
          emerald: '#10b981',
          amber: '#f59e0b',
          orange: '#ea580c',
          rose: '#f43f5e',
          indigo: '#6366f1',
          slate: '#475569',
        },
        surface: {
          50: '#f8fafc',
          100: '#f1f5f9',
          200: '#e2e8f0',
          300: '#cbd5e1',
          400: '#94a3b8',
          500: '#64748b',
          600: '#475569',
          700: '#334155',
          800: '#1e293b',
          900: '#0f172a',
          950: '#020617',
        },
        status: {
          success: {
            light: '#ecfdf5',
            DEFAULT: '#10b981',
            dark: '#047857',
            border: '#a7f3d0',
          },
          warning: {
            light: '#fffbeb',
            DEFAULT: '#f59e0b',
            dark: '#b45309',
            border: '#fde68a',
          },
          danger: {
            light: '#fff1f2',
            DEFAULT: '#f43f5e',
            dark: '#be123c',
            border: '#fecdd3',
          },
          info: {
            light: '#f0f9ff',
            DEFAULT: '#0ea5e9',
            dark: '#0369a1',
            border: '#bae6fd',
          },
        },
      },
    },
  },
  plugins: [],
}
