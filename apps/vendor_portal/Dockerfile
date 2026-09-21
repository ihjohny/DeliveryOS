# Multi-stage Dockerfile for DeliveryOS Web Portal (Vite + Nginx)
FROM node:20-alpine AS builder

WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY . ./
RUN npm run build

# ------------------------------------------------------------------------------
# Production Nginx Static Serving Stage
# ------------------------------------------------------------------------------
FROM nginx:1.25-alpine AS runner

COPY --from=builder /app/dist /usr/share/nginx/html
RUN ln -s /usr/share/nginx/html /usr/share/nginx/html/vendor
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

HEALTHCHECK --interval=10s --timeout=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:80/ || exit 1

CMD ["nginx", "-g", "daemon off;"]
