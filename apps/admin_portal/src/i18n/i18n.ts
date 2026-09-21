import i18n from 'i18next';
import { initReactI18next } from 'react-i18next';

import en from './locales/en.json';
import ar from './locales/ar.json';
import bn from './locales/bn.json';

const savedLanguage = localStorage.getItem('deliveryos_admin_lang') || 'en';

export const updateHtmlDirection = (lng: string) => {
  document.documentElement.lang = lng;
  if (lng === 'ar') {
    document.documentElement.dir = 'rtl';
  } else {
    document.documentElement.dir = 'ltr';
  }
};

i18n
  .use(initReactI18next)
  .init({
    resources: {
      en: { translation: en },
      ar: { translation: ar },
      bn: { translation: bn },
    },
    lng: savedLanguage,
    fallbackLng: 'en',
    interpolation: {
      escapeValue: false,
    },
  });

// Set initial direction
updateHtmlDirection(savedLanguage);

// Update HTML tag direction on language change
i18n.on('languageChanged', (lng) => {
  localStorage.setItem('deliveryos_admin_lang', lng);
  updateHtmlDirection(lng);
});

export default i18n;
