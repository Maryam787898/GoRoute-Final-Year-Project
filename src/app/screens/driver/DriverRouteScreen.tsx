import { useState } from "react";
import { useNavigate } from "react-router";
import { motion } from "motion/react";
import { ArrowLeft, MapPin, CheckCircle, Clock, Gauge, Map, History, User } from "lucide-react";
import GoogleMapComponent from "../../components/GoogleMapComponent";

interface Stop {
  id: string;
  name: string;
  time: string;
  passengers: number;
  status: 'completed' | 'current' | 'upcoming';
}

export default function DriverRouteScreen() {
  const navigate = useNavigate();
  const [selectedTab, setSelectedTab] = useState('route');

  const currentBus = {
    id: "driver-1",
    number: "45A",
    route: "Gulberg → DHA",
    lat: 31.5204,
    lng: 74.3587,
    eta: 3,
    status: 'active' as const,
  };

  const routePath = [
    { lat: 31.5204, lng: 74.3587 },
    { lat: 31.5104, lng: 74.3487 },
    { lat: 31.5004, lng: 74.3387 },
    { lat: 31.4904, lng: 74.3287 },
  ];

  const stops: Stop[] = [
    { id: "1", name: "Gulberg Main Boulevard", time: "9:15 AM", passengers: 12, status: 'completed' },
    { id: "2", name: "Liberty Market", time: "9:22 AM", passengers: 8, status: 'completed' },
    { id: "3", name: "MM Alam Road", time: "9:30 AM", passengers: 15, status: 'current' },
    { id: "4", name: "Cavalry Ground", time: "9:38 AM", passengers: 0, status: 'upcoming' },
    { id: "5", name: "DHA Phase 5", time: "9:45 AM", passengers: 0, status: 'upcoming' },
    { id: "6", name: "DHA Phase 6", time: "9:52 AM", passengers: 0, status: 'upcoming' },
  ];

  const currentStop = stops.find(s => s.status === 'current');

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

      {/* Top card */}
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
            <div className="text-center flex-1">
              <div className="text-2xl font-bold text-[#8B0000]" style={{ fontFamily: 'Poppins, sans-serif' }}>
                Bus {currentBus.number}
              </div>
              <div className="text-sm text-[#6B7280]">{currentBus.route}</div>
            </div>
            <div className="w-10" />
          </div>

          {currentStop && (
            <div className="bg-[#F5C518]/20 border-2 border-[#F5C518] rounded-xl p-3">
              <div className="flex items-center gap-2 mb-1">
                <motion.div
                  animate={{ scale: [1, 1.3, 1] }}
                  transition={{ duration: 1.5, repeat: Infinity }}
                  className="w-2.5 h-2.5 bg-[#8B0000] rounded-full"
                />
                <span className="text-xs font-bold text-[#8B0000]">NEXT STOP</span>
              </div>
              <div className="font-semibold text-[#1A1A1A]" style={{ fontFamily: 'Poppins, sans-serif' }}>
                {currentStop.name}
              </div>
              <div className="text-sm text-[#6B7280] flex items-center gap-1 mt-1">
                <Clock className="w-3.5 h-3.5" />
                {currentStop.time}
              </div>
            </div>
          )}
        </div>
      </motion.div>

      {/* Bottom sheet */}
      <motion.div
        initial={{ y: 500 }}
        animate={{ y: 0 }}
        transition={{ delay: 0.2, type: "spring", stiffness: 200 }}
        className="absolute bottom-20 left-0 right-0 bg-white rounded-t-3xl shadow-2xl z-10 max-h-[50vh]"
      >
        <div className="px-6 py-4 border-b border-gray-100">
          <div className="w-12 h-1.5 bg-gray-300 rounded-full mx-auto mb-4" />
          <h3 className="text-xl font-bold text-[#1A1A1A]" style={{ fontFamily: 'Poppins, sans-serif' }}>
            All Stops ({stops.length})
          </h3>
        </div>

        <div className="overflow-y-auto px-6 py-4 max-h-[calc(50vh-140px)]">
          <div className="space-y-4">
            {stops.map((stop, index) => (
              <motion.div
                key={stop.id}
                initial={{ x: -20, opacity: 0 }}
                animate={{ x: 0, opacity: 1 }}
                transition={{ delay: index * 0.05 }}
                className={`flex items-start gap-4 ${
                  stop.status === 'current' ? 'bg-[#F5C518]/10 -mx-6 px-6 py-3 rounded-lg' : ''
                }`}
              >
                {/* Timeline */}
                <div className="flex flex-col items-center">
                  <div
                    className={`w-6 h-6 rounded-full border-2 flex items-center justify-center ${
                      stop.status === 'completed'
                        ? 'bg-[#8B0000] border-[#8B0000]'
                        : stop.status === 'current'
                        ? 'bg-[#F5C518] border-[#F5C518]'
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
                      className={`w-0.5 h-16 ${
                        stop.status === 'completed' ? 'bg-[#8B0000]' : 'bg-gray-200'
                      }`}
                    />
                  )}
                </div>

                {/* Stop info */}
                <div className="flex-1">
                  <div className="font-semibold text-[#1A1A1A]" style={{ fontFamily: 'Poppins, sans-serif' }}>
                    {stop.name}
                  </div>
                  <div className="text-sm text-[#6B7280] flex items-center gap-3 mt-1">
                    <span className="flex items-center gap-1">
                      <Clock className="w-3.5 h-3.5" />
                      {stop.time}
                    </span>
                    {stop.status === 'completed' && stop.passengers > 0 && (
                      <span className="text-green-600">
                        +{stop.passengers} passengers
                      </span>
                    )}
                  </div>

                  {stop.status === 'current' && (
                    <motion.button
                      whileTap={{ scale: 0.95 }}
                      className="mt-3 bg-[#8B0000] text-white px-6 py-2 rounded-full text-sm font-semibold shadow-md hover:bg-[#6D0000] transition-colors"
                      style={{ fontFamily: 'Poppins, sans-serif' }}
                    >
                      Mark Arrived
                    </motion.button>
                  )}
                </div>
              </motion.div>
            ))}
          </div>
        </div>
      </motion.div>

      {/* Bottom navigation */}
      <div className="absolute bottom-0 left-0 right-0 bg-white border-t border-gray-200 px-6 py-3 z-20 shadow-lg">
        <div className="flex items-center justify-around max-w-md mx-auto">
          <motion.button
            whileTap={{ scale: 0.9 }}
            onClick={() => navigate('/driver/dashboard')}
            className="flex flex-col items-center gap-1 py-2 px-4"
          >
            <Gauge className="w-6 h-6 text-[#6B7280]" />
            <span className="text-xs font-medium text-[#6B7280]" style={{ fontFamily: 'Poppins, sans-serif' }}>
              Dashboard
            </span>
          </motion.button>

          <motion.button
            whileTap={{ scale: 0.9 }}
            onClick={() => navigate('/driver/route')}
            className="flex flex-col items-center gap-1 py-2 px-4"
          >
            <Map className="w-6 h-6 text-[#8B0000]" />
            <span className="text-xs font-medium text-[#8B0000]" style={{ fontFamily: 'Poppins, sans-serif' }}>
              Route
            </span>
            <motion.div className="w-full h-0.5 bg-[#8B0000] rounded-full" />
          </motion.button>

          <motion.button
            whileTap={{ scale: 0.9 }}
            onClick={() => navigate('/driver/history')}
            className="flex flex-col items-center gap-1 py-2 px-4"
          >
            <History className="w-6 h-6 text-[#6B7280]" />
            <span className="text-xs font-medium text-[#6B7280]" style={{ fontFamily: 'Poppins, sans-serif' }}>
              History
            </span>
          </motion.button>

          <motion.button
            whileTap={{ scale: 0.9 }}
            onClick={() => navigate('/driver/profile')}
            className="flex flex-col items-center gap-1 py-2 px-4"
          >
            <User className="w-6 h-6 text-[#6B7280]" />
            <span className="text-xs font-medium text-[#6B7280]" style={{ fontFamily: 'Poppins, sans-serif' }}>
              Profile
            </span>
          </motion.button>
        </div>
      </div>
    </div>
  );
}
