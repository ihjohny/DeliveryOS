import axios from 'axios';

export const apiClient = axios.create({
  baseURL: import.meta.env.VITE_API_URL || '',
  headers: {
    'Content-Type': 'application/json',
  },
});

// Attach JWT token to requests
apiClient.interceptors.request.use((config) => {
  const token = localStorage.getItem('deliveryos_token');
  if (token && config.headers) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

// Handle 401 Unauthorized
apiClient.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      // If we are not already on the login page, clear session and redirect
      if (!window.location.pathname.includes('/login')) {
        localStorage.removeItem('deliveryos_token');
        localStorage.removeItem('deliveryos_user');
        const loginPath = window.location.pathname.startsWith('/vendor') ? '/vendor/login' : '/login';
        window.location.href = loginPath;
      }
    }
    return Promise.reject(error);
  }
);

export default apiClient;
