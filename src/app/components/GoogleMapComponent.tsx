import { useEffect, useRef, useState } from "react";
import { motion } from "motion/react";
import { MapPin, Navigation } from "lucide-react";

interface Bus {
  id: string;
  number: string;
  route: string;
  lat: number;
  lng: number;
  eta: number;
  status: 'active' | 'delayed';
}

interface GoogleMapComponentProps {
  buses: Bus[];
  onBusClick?: (busId: string) => void;
  routePath?: { lat: number; lng: number }[];
  currentBus?: Bus;
  showControls?: boolean;
}

export default function GoogleMapComponent({
  buses,
  onBusClick,
  routePath,
  currentBus,
  showControls = false,
}: GoogleMapComponentProps) {
  const mapRef = useRef<HTMLDivElement>(null);
  const [selectedBus, setSelectedBus] = useState<Bus | null>(null);

  // Demo map background using OpenStreetMap tiles style
  return (
    <div className="relative w-full h-full bg-gray-100">
      {/* Map background - simulated with a pattern */}
      <div
        ref={mapRef}
        className="absolute inset-0 bg-gradient-to-br from-gray-200 via-gray-100 to-gray-200"
        style={{
          backgroundImage: `
            linear-gradient(to right, #e5e7eb 1px, transparent 1px),
            linear-gradient(to bottom, #e5e7eb 1px, transparent 1px)
          `,
          backgroundSize: '40px 40px',
        }}
      >
        {/* Road overlay */}
        <svg className="absolute inset-0 w-full h-full opacity-20">
          <line x1="0" y1="30%" x2="100%" y2="40%" stroke="#9CA3AF" strokeWidth="8" />
          <line x1="0" y1="60%" x2="100%" y2="70%" stroke="#9CA3AF" strokeWidth="8" />
          <line x1="30%" y1="0" x2="40%" y2="100%" stroke="#9CA3AF" strokeWidth="8" />
          <line x1="70%" y1="0" x2="60%" y2="100%" stroke="#9CA3AF" strokeWidth="8" />
        </svg>

        {/* Route path if provided */}
        {routePath && routePath.length > 1 && (
          <svg className="absolute inset-0 w-full h-full pointer-events-none">
            <path
              d={`M ${routePath.map((point, i) =>
                `${(point.lng - 74.2) * 5000} ${(point.lat - 31.4) * 5000}`
              ).join(' L ')}`}
              stroke="#8B0000"
              strokeWidth="4"
              fill="none"
              opacity="0.6"
            />
          </svg>
        )}

        {/* Bus markers */}
        {buses.map((bus, index) => {
          const x = ((bus.lng - 74.2) * 5000) % 100;
          const y = ((bus.lat - 31.4) * 5000) % 100;

          return (
            <motion.div
              key={bus.id}
              initial={{ scale: 0, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              transition={{
                delay: index * 0.1,
                type: "spring",
                stiffness: 200,
              }}
              className="absolute cursor-pointer"
              style={{
                left: `${20 + (index * 20) % 60}%`,
                top: `${30 + (index * 15) % 40}%`,
                transform: 'translate(-50%, -50%)',
              }}
              onClick={() => {
                setSelectedBus(bus);
                onBusClick?.(bus.id);
              }}
            >
              {/* Pulsing ring */}
              <motion.div
                animate={{
                  scale: [1, 1.5, 1],
                  opacity: [0.5, 0, 0.5],
                }}
                transition={{
                  duration: 2,
                  repeat: Infinity,
                  ease: "easeInOut",
                }}
                className="absolute inset-0 bg-[#F5C518] rounded-full w-16 h-16 -translate-x-1/2 -translate-y-1/2 left-1/2 top-1/2"
              />

              {/* Bus marker */}
              <div className="relative bg-[#F5C518] rounded-full p-3 shadow-lg border-4 border-white">
                <Navigation className="w-6 h-6 text-[#8B0000]" fill="#8B0000" />
                <div className="absolute -top-2 -right-2 bg-[#8B0000] text-white text-xs font-bold rounded-full w-6 h-6 flex items-center justify-center">
                  {bus.number.slice(-2)}
                </div>
              </div>
            </motion.div>
          );
        })}

        {/* Current bus marker (larger, animated) */}
        {currentBus && (
          <motion.div
            animate={{
              y: [0, -10, 0],
            }}
            transition={{
              duration: 2,
              repeat: Infinity,
              ease: "easeInOut",
            }}
            className="absolute"
            style={{
              left: '50%',
              top: '45%',
              transform: 'translate(-50%, -50%)',
            }}
          >
            <motion.div
              animate={{
                scale: [1, 1.3, 1],
                opacity: [0.3, 0, 0.3],
              }}
              transition={{
                duration: 1.5,
                repeat: Infinity,
              }}
              className="absolute inset-0 bg-[#F5C518] rounded-full w-24 h-24 -translate-x-1/2 -translate-y-1/2 left-1/2 top-1/2"
            />
            <div className="relative bg-[#F5C518] rounded-full p-5 shadow-2xl border-4 border-white">
              <Navigation className="w-10 h-10 text-[#8B0000]" fill="#8B0000" />
              <div className="absolute -top-3 -right-3 bg-green-500 text-white text-sm font-bold rounded-full px-2 py-1 flex items-center gap-1">
                LIVE
              </div>
            </div>
          </motion.div>
        )}

        {/* Stop markers for route */}
        {routePath && (
          <>
            {[20, 40, 60, 80].map((pos, idx) => (
              <div
                key={idx}
                className="absolute"
                style={{
                  left: `${pos}%`,
                  top: `${35 + idx * 10}%`,
                  transform: 'translate(-50%, -50%)',
                }}
              >
                <div className="bg-white rounded-full p-2 shadow-md border-2 border-[#8B0000]">
                  <MapPin className="w-4 h-4 text-[#8B0000]" fill="#8B0000" />
                </div>
              </div>
            ))}
          </>
        )}
      </div>

      {/* Map controls */}
      {showControls && (
        <div className="absolute right-4 top-20 flex flex-col gap-2 z-10">
          <button className="bg-white rounded-full p-3 shadow-lg hover:bg-gray-50 transition-colors">
            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" />
            </svg>
          </button>
          <button className="bg-white rounded-full p-3 shadow-lg hover:bg-gray-50 transition-colors">
            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M20 12H4" />
            </svg>
          </button>
          <button className="bg-white rounded-full p-3 shadow-lg hover:bg-gray-50 transition-colors">
            <Navigation className="w-5 h-5 text-[#8B0000]" />
          </button>
        </div>
      )}

      {/* Location attribution (like Google Maps) */}
      <div className="absolute bottom-2 left-2 bg-white/90 px-2 py-1 rounded text-xs text-gray-600">
        Lahore, Pakistan
      </div>
    </div>
  );
}
