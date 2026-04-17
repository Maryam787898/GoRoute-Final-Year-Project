import { useState, useEffect } from "react";
import { useParams, useNavigate } from "react-router";
import { motion } from "motion/react";
import { ArrowLeft, Bell, Share2, MapPin, Clock, CheckCircle } from "lucide-react";
import GoogleMapComponent from "../../components/GoogleMapComponent";

interface Stop {
  id: string;
  name: string;
  time: string;
  status: 'completed' | 'current' | 'upcoming';
}

export default function BusTrackingScreen() {
  const { busId } = useParams();
  const navigate = useNavigate();
  const [eta, setEta] = useState(3);
  const [notifyEnabled, setNotifyEnabled] = useState(false);

  const currentBus = {
    id: busId || "1",
    number: "45A",
    route: "Gulberg → DHA",
    lat: 31.5204,
    lng: 74.3587,
    eta: eta,
    status: 'active' as const,
  };

  const routePath = [
    { lat: 31.5204, lng: 74.3587 },
    { lat: 31.5104, lng: 74.3487 },
    { lat: 31.5004, lng: 74.3387 },
    { lat: 31.4904, lng: 74.3287 },
  ];

  const stops: Stop[] = [
    { id: "1", name: "Gulberg Main Boulevard", time: "9:15 AM", status: 'completed' },
    { id: "2", name: "Liberty Market", time: "9:22 AM", status: 'completed' },
    { id: "3", name: "MM Alam Road", time: "9:30 AM", status: 'current' },
    { id: "4", name: "Cavalry Ground", time: "9:38 AM", status: 'upcoming' },
    { id: "5", name: "DHA Phase 5", time: "9:45 AM", status: 'upcoming' },
  ];

  useEffect(() => {
    const interval = setInterval(() => {
      setEta(prev => Math.max(1, prev - 0.2));
    }, 3000);
    return () => clearInterval(interval);
  }, []);

  return (
    <div className="h-full w-full bg-white flex flex-col relative">
      {/* Map background */}
      <div className="absolute inset-0">
        <GoogleMapComponent
          buses={[currentBus]}
          routePath={routePath}
          currentBus={currentBus}
          showControls={true}
        />
      </div>

      {/* Top floating card */}
      <motion.div
        initial={{ y: -100 }}
        animate={{ y: 0 }}
        transition={{ type: "spring", stiffness: 200 }}
        className="absolute top-4 left-4 right-4 z-10"
      >
        <div className="bg-white rounded-2xl shadow-xl p-4">
          <div className="flex items-center justify-between mb-3">
            <button
              onClick={() => navigate(-1)}
              className="p-2 hover:bg-gray-100 rounded-full transition-colors"
            >
              <ArrowLeft className="w-6 h-6 text-[#1A1A1A]" />
            </button>
            <div className="flex items-center gap-2">
              <div className="text-2xl font-bold text-[#8B0000]" style={{ fontFamily: 'Poppins, sans-serif' }}>
                Bus {currentBus.number}
              </div>
              <motion.div
                animate={{ scale: [1, 1.2, 1] }}
                transition={{ duration: 2, repeat: Infinity }}
                className="bg-green-500 text-white text-xs font-bold px-3 py-1 rounded-full"
              >
                LIVE
              </motion.div>
            </div>
            <button
              onClick={() => {}}
              className="p-2 hover:bg-gray-100 rounded-full transition-colors"
            >
              <Share2 className="w-5 h-5 text-[#8B0000]" />
            </button>
          </div>
          <div className="text-sm text-[#6B7280] flex items-center gap-1">
            <MapPin className="w-4 h-4" />
            {currentBus.route}
          </div>
        </div>
      </motion.div>

      {/* Center ETA card */}
      <motion.div
        initial={{ scale: 0.8, opacity: 0 }}
        animate={{ scale: 1, opacity: 1 }}
        transition={{ delay: 0.3, type: "spring", stiffness: 200 }}
        className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 z-10"
      >
        <div className="bg-white rounded-3xl shadow-2xl p-8 text-center">
          <div className="flex items-center justify-center gap-2 mb-2">
            <Clock className="w-6 h-6 text-[#8B0000]" />
            <span className="text-[#6B7280] font-medium" style={{ fontFamily: 'Poppins, sans-serif' }}>
              Arrives in
            </span>
          </div>
          <motion.div
            key={Math.floor(eta)}
            initial={{ scale: 1.2, opacity: 0 }}
            animate={{ scale: 1, opacity: 1 }}
            className="text-7xl font-bold text-[#8B0000] mb-1"
            style={{ fontFamily: 'Poppins, sans-serif' }}
          >
            {Math.ceil(eta)}
          </motion.div>
          <div className="text-xl text-[#6B7280]" style={{ fontFamily: 'Poppins, sans-serif' }}>
            minutes away
          </div>
        </div>
      </motion.div>

      {/* Bottom sheet with stops */}
      <motion.div
        initial={{ y: 500 }}
        animate={{ y: 0 }}
        transition={{ delay: 0.2, type: "spring", stiffness: 200 }}
        className="absolute bottom-0 left-0 right-0 bg-white rounded-t-3xl shadow-2xl z-10 max-h-[45vh]"
      >
        <div className="px-6 py-4 border-b border-gray-100">
          <div className="w-12 h-1.5 bg-gray-300 rounded-full mx-auto mb-4" />
          <h3 className="text-xl font-bold text-[#1A1A1A] mb-4" style={{ fontFamily: 'Poppins, sans-serif' }}>
            Route Stops
          </h3>

          {/* Notify toggle */}
          <motion.button
            whileTap={{ scale: 0.95 }}
            onClick={() => setNotifyEnabled(!notifyEnabled)}
            className={`w-full py-3 rounded-full font-semibold flex items-center justify-center gap-2 transition-colors ${
              notifyEnabled
                ? 'bg-[#8B0000] text-white'
                : 'bg-gray-100 text-[#1A1A1A]'
            }`}
            style={{ fontFamily: 'Poppins, sans-serif' }}
          >
            <Bell className="w-5 h-5" />
            {notifyEnabled ? 'Notifications On (2 stops before)' : 'Notify me 2 stops before'}
          </motion.button>
        </div>

        <div className="overflow-y-auto px-6 py-4 max-h-[calc(45vh-140px)]">
          <div className="space-y-4">
            {stops.map((stop, index) => (
              <motion.div
                key={stop.id}
                initial={{ x: -20, opacity: 0 }}
                animate={{ x: 0, opacity: 1 }}
                transition={{ delay: index * 0.1 }}
                className="flex items-start gap-4"
              >
                {/* Timeline */}
                <div className="flex flex-col items-center">
                  <div
                    className={`w-6 h-6 rounded-full border-2 flex items-center justify-center ${
                      stop.status === 'completed'
                        ? 'bg-[#8B0000] border-[#8B0000]'
                        : stop.status === 'current'
                        ? 'bg-[#F5C518] border-[#F5C518] animate-pulse'
                        : 'bg-white border-gray-300'
                    }`}
                  >
                    {stop.status === 'completed' && (
                      <CheckCircle className="w-4 h-4 text-white" />
                    )}
                    {stop.status === 'current' && (
                      <motion.div
                        animate={{ scale: [1, 1.2, 1] }}
                        transition={{ duration: 1, repeat: Infinity }}
                        className="w-3 h-3 bg-[#8B0000] rounded-full"
                      />
                    )}
                  </div>
                  {index < stops.length - 1 && (
                    <div
                      className={`w-0.5 h-12 ${
                        stop.status === 'completed' ? 'bg-[#8B0000]' : 'bg-gray-200'
                      }`}
                    />
                  )}
                </div>

                {/* Stop info */}
                <div className="flex-1 pb-4">
                  <div className="font-semibold text-[#1A1A1A]" style={{ fontFamily: 'Poppins, sans-serif' }}>
                    {stop.name}
                  </div>
                  <div className="text-sm text-[#6B7280] flex items-center gap-1 mt-1">
                    <Clock className="w-3.5 h-3.5" />
                    {stop.time}
                  </div>
                  {stop.status === 'current' && (
                    <div className="mt-2 text-xs font-semibold text-[#8B0000] bg-[#8B0000]/10 px-2 py-1 rounded-full inline-block">
                      NEXT STOP
                    </div>
                  )}
                </div>
              </motion.div>
            ))}
          </div>
        </div>

        <div className="px-6 py-4 border-t border-gray-100">
          <motion.button
            whileTap={{ scale: 0.98 }}
            className="w-full bg-[#8B0000] text-white py-4 rounded-full font-semibold shadow-lg hover:bg-[#6D0000] transition-colors flex items-center justify-center gap-2"
            style={{ fontFamily: 'Poppins, sans-serif' }}
          >
            <Share2 className="w-5 h-5" />
            Share ETA
          </motion.button>
        </div>
      </motion.div>
    </div>
  );
}
