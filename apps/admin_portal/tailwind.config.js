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
        // Enterprise Indigo palette for Admin Governance Console
        primary: {
          50: '#eef2ff',
          100: '#e0e7ff',
          200: '#c7d2fe',
          300: '#a5b4fc',
          400: '#818cf8',
          500: '#6366f1',
          600: '#4f46e5',
          700: '#4338ca',
          800: '#3730a3',
          900: '#312e81',
          950: '#1e1b4b',
        },
        brand: {
          emerald: '#10b981',
          amber: '#f59e0b',
          rose: '#f43f5e',
          indigo: '#6366f1',
          orange: '#ea580c',
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
