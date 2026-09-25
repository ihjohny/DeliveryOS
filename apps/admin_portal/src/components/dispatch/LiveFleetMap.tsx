import React, { useEffect, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import L from 'leaflet';
import { FleetRider, AdminOrder } from '../../services/adminApi';

interface LiveFleetMapProps {
  fleet: FleetRider[];
  unassignedOrders: AdminOrder[];
  selectedRiderId?: string | null;
  onSelectRider?: (riderId: string) => void;
}

export const LiveFleetMap: React.FC<LiveFleetMapProps> = ({
  fleet,
  unassignedOrders,
  selectedRiderId,
  onSelectRider,
}) => {
  const navigate = useNavigate();
  const mapContainerRef = useRef<HTMLDivElement>(null);
  const mapInstanceRef = useRef<L.Map | null>(null);
  const markersLayerRef = useRef<L.LayerGroup | null>(null);

  // Default Pilot coordinates: Gulshan / Banani, Dhaka
  const defaultCenter: [number, number] = [23.7925, 90.4078];

  useEffect(() => {
    if (!mapContainerRef.current || mapInstanceRef.current) return;

    // Initialize Leaflet map instance
    const map = L.map(mapContainerRef.current, {
      center: defaultCenter,
      zoom: 13,
      zoomControl: true,
    });

    // Free OpenStreetMap tile layer (zero API key required)
    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors',
      maxZoom: 19,
    }).addTo(map);

    const layerGroup = L.layerGroup().addTo(map);
    markersLayerRef.current = layerGroup;
    mapInstanceRef.current = map;

    return () => {
      map.remove();
      mapInstanceRef.current = null;
    };
  }, []);

  // Update Markers whenever fleet or unassigned orders change
  useEffect(() => {
    const map = mapInstanceRef.current;
    const layer = markersLayerRef.current;
    if (!map || !layer) return;

    layer.clearLayers();
    const bounds: L.LatLngExpression[] = [];

    // 1. Render Courier Markers
    fleet.forEach((rider) => {
      // Default to Banani/Gulshan offset if no GPS coordinates
      const lat = rider.latitude || 23.7937;
      const lng = rider.longitude || 90.4066;
      bounds.push([lat, lng]);

      const isWarning = (rider.cashInHand || 0) >= (rider.maxCashLimit || 5000);
      const isTrip = rider.status === 'ON_TRIP';
      const isOnline = rider.status === 'ONLINE';

      const colorBg = isWarning
        ? '#ea580c'
        : isTrip
          ? '#0284c7'
          : isOnline
            ? '#10b981'
            : '#64748b';

      const customIcon = L.divIcon({
        className: 'custom-courier-pin',
        html: `
          <div style="
            position: relative;
            width: 32px;
            height: 32px;
            background-color: ${colorBg};
            border: 2px solid white;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            box-shadow: 0 4px 6px -1px rgba(0,0,0,0.3);
            cursor: pointer;
          ">
            <span style="font-size: 14px;">🛵</span>
            ${isTrip ? `<span style="position: absolute; top: -2px; right: -2px; width: 10px; height: 10px; background-color: #38bdf8; border: 2px solid white; border-radius: 50%; animate: pulse;"></span>` : ''}
          </div>
        `,
        iconSize: [32, 32],
        iconAnchor: [16, 16],
      });

      const marker = L.marker([lat, lng], { icon: customIcon });

      const popupContent = `
        <div style="font-family: sans-serif; font-size: 12px; padding: 4px; min-width: 160px;">
          <div style="font-weight: bold; font-size: 13px; margin-bottom: 2px; color: #0f172a;">${rider.riderName}</div>
          <div style="color: #64748b; margin-bottom: 6px;">${rider.phone} • ${rider.vehicleType}</div>
          <div style="display: flex; justify-content: space-between; margin-bottom: 4px;">
            <span>Status:</span>
            <strong style="color: ${colorBg};">${rider.status.replace('_', ' ')}</strong>
          </div>
          <div style="display: flex; justify-content: space-between;">
            <span>Cash in Hand:</span>
            <strong>৳${(rider.cashInHand || 0).toFixed(0)}</strong>
          </div>
        </div>
      `;

      marker.bindPopup(popupContent);
      marker.on('click', () => {
        if (onSelectRider) onSelectRider(rider.id);
      });

      marker.addTo(layer);
    });

    // 2. Render Unassigned Order Pickup Targets
    unassignedOrders.forEach((order) => {
      // Default to restaurant cluster coordinates if snapshot coords absent
      const lat = 23.7915;
      const lng = 90.4042;
      bounds.push([lat, lng]);

      const orderIcon = L.divIcon({
        className: 'custom-order-pin',
        html: `
          <div style="
            position: relative;
            width: 28px;
            height: 28px;
            background-color: #f59e0b;
            border: 2px solid white;
            border-radius: 6px;
            display: flex;
            align-items: center;
            justify-content: center;
            box-shadow: 0 4px 6px -1px rgba(0,0,0,0.3);
            animation: bounce 1.5s infinite;
          ">
            <span style="font-size: 13px;">📦</span>
          </div>
        `,
        iconSize: [28, 28],
        iconAnchor: [14, 14],
      });

      const marker = L.marker([lat, lng], { icon: orderIcon });
      const popupDiv = document.createElement('div');
      popupDiv.style.fontFamily = 'sans-serif';
      popupDiv.style.fontSize = '12px';
      popupDiv.style.padding = '4px';
      popupDiv.style.minWidth = '170px';
      popupDiv.innerHTML = `
        <div style="font-weight: bold; color: #b45309; margin-bottom: 2px;">Waiting for Courier</div>
        <div style="font-weight: 600; font-size: 13px;">${order.orderNumber}</div>
        <div style="color: #64748b; margin-bottom: 4px;">${order.vendorName}</div>
        <div style="color: #0f172a; font-weight: bold; margin-bottom: 6px;">৳${order.totalAmount}</div>
      `;
      const openBtn = document.createElement('button');
      openBtn.textContent = 'Open Order →';
      openBtn.style.color = '#4f46e5';
      openBtn.style.textDecoration = 'underline';
      openBtn.style.fontWeight = '600';
      openBtn.style.background = 'none';
      openBtn.style.border = 'none';
      openBtn.style.padding = '0';
      openBtn.style.cursor = 'pointer';
      openBtn.onclick = (e) => {
        e.preventDefault();
        navigate(`/orders?orderNumber=${encodeURIComponent(order.orderNumber)}`);
      };
      popupDiv.appendChild(openBtn);

      marker.bindPopup(popupDiv);
      marker.addTo(layer);
    });

    // Fit bounds if multiple points exist
    if (bounds.length > 1 && !selectedRiderId) {
      map.fitBounds(L.latLngBounds(bounds), { padding: [40, 40], maxZoom: 15 });
    }
  }, [fleet, unassignedOrders, selectedRiderId, onSelectRider, navigate]);

  return (
    <div className="relative w-full h-[400px] rounded-xl overflow-hidden border border-slate-200 dark:border-slate-800 shadow-inner">
      <div ref={mapContainerRef} className="w-full h-full z-0" />
      {/* Map Legend Overlay */}
      <div className="absolute bottom-3 left-3 z-10 bg-white/90 backdrop-blur-sm dark:bg-slate-900/90 border border-slate-200 dark:border-slate-800 rounded-lg p-2.5 shadow-sm text-[11px] space-y-1.5">
        <div className="font-semibold text-slate-700 dark:text-slate-300">Fleet Legend</div>
        <div className="flex items-center gap-2">
          <span className="w-2.5 h-2.5 rounded-full bg-emerald-500 inline-block" />
          <span className="text-slate-600 dark:text-slate-400">Idle & Ready</span>
        </div>
        <div className="flex items-center gap-2">
          <span className="w-2.5 h-2.5 rounded-full bg-sky-500 inline-block" />
          <span className="text-slate-600 dark:text-slate-400">On Active Trip</span>
        </div>
        <div className="flex items-center gap-2">
          <span className="w-2.5 h-2.5 rounded-full bg-amber-500 inline-block" />
          <span className="text-slate-600 dark:text-slate-400">Unassigned Order</span>
        </div>
      </div>
    </div>
  );
};
