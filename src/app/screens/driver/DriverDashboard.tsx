import { useState } from "react";
import { useNavigate } from "react-router";
import { motion } from "motion/react";
import { Power, MapPin, Users, Gauge, AlertCircle, Flag, User, History, Map } from "lucide-react";
import GoogleMapComponent from "../../components/GoogleMapComponent";

interface Stop {
  id: string;
  name: string;
  time: string;
  status: 'completed' | 'current' | 'upcoming';
}

export default function DriverDashboard() {
  const navigate = useNavigate();
  const [isOnline, setIsOnline] = useState(false);
  const [speed, setSpeed] = useState(45);
  const [passengerCount, setPassengerCount] = useState(23);

  const currentBus = {
    id: "driver-1",
    number: "45A",
    route: "Gulberg → DHA",
    lat: 31.5204,
    lng: 74.3587,
    eta: 3,
    status: 'active' as const,
  };

  const stops: Stop[] = [
    { id: "1", name: "Gulberg Main Boulevard", time: "9:15 AM", status: 'completed' },
    { id: "2", name: "Liberty Market", time: "9:22 AM", status: 'completed' },
    { id: "3", name: "MM Alam Road", time: "9:30 AM", status: 'current' },
    { id: "4", name: "Cavalry Ground", time: "9:38 AM", status: 'upcoming' },
    { id: "5", name: "DHA Phase 5", time: "9:45 AM", status: 'upcoming' },
  ];

  const completedStops = stops.filter(s => s.status === 'completed').length;
  const currentStop = stops.find(s => s.status === 'current');

  return (
    <div className="h-full w-full bg-gray-50 flex flex-col overflow-y-auto pb-20">
      {/* App bar */}
      <div className="bg-[#8B0000] px-6 py-4 shadow-md">
        <div className="flex items-center justify-between">
          <h2 className="text-white text-xl font-semibold" style={{ fontFamily: 'Poppins, sans-serif' }}>
            Driver Dashboard
          </h2>
          <button onClick={() => navigate('/driver/profile')} className="p-1">
            <User className="w-6 h-6 text-white" />
          </button>
        </div>
      </div>

      <div className="flex-1 px-6 py-6 space-y-4">
        {/* Status card */}
        <motion.div
          initial={{ y: -20, opacity: 0 }}
          animate={{ y: 0, opacity: 1 }}
          className="bg-white rounded-2xl p-6 shadow-lg"
        >
          <div className="flex items-center justify-between mb-4">
            <div>
              <h3 className="text-lg font-semibold text-[#1A1A1A] mb-1" style={{ fontFamily: 'Poppins, sans-serif' }}>
                Status
              </h3>
              <p className="text-sm text-[#6B7280]">
                {isOnline ? 'You are currently online' : 'You are offline'}
              </p>
            </div>
            <motion.button
              whileTap={{ scale: 0.95 }}
              onClick={() => setIsOnline(!isOnline)}
              className={`relative inline-flex h-14 w-28 items-center rounded-full transition-colors ${
                isOnline ? 'bg-green-500' : 'bg-gray-300'
              }`}
            >
              <motion.div
                animate={{ x: isOnline ? 56 : 4 }}
                transition={{ type: "spring", stiffness: 500, damping: 30 }}
                className="inline-flex h-12 w-12 items-center justify-center rounded-full bg-white shadow-lg"
              >
                <Power className={`w-6 h-6 ${isOnline ? 'text-green-500' : 'text-gray-400'}`} />
              </motion.div>
            </motion.button>
          </div>

          {isOnline && (
            <motion.div
              initial={{ opacity: 0, height: 0 }}
              animate={{ opacity: 1, height: 'auto' }}
              className="flex items-center gap-2 bg-green-50 text-green-700 px-4 py-2 rounded-lg"
            >
              <motion.div
                animate={{ scale: [1, 1.2, 1] }}
                transition={{ duration: 2, repeat: Infinity }}
                className="w-2 h-2 bg-green-500 rounded-full"
              />
              <span className="text-sm font-medium">Online and tracking</span>
            </motion.div>
          )}
        </motion.div>

        {/* Current route card */}
        <motion.div
          initial={{ y: -20, opacity: 0 }}
          animate={{ y: 0, opacity: 1 }}
          transition={{ delay: 0.1 }}
          className="bg-white rounded-2xl p-6 shadow-lg"
        >
          <h3 className="text-lg font-semibold text-[#1A1A1A] mb-4" style={{ fontFamily: 'Poppins, sans-serif' }}>
            Current Route
          </h3>
          <div className="flex items-start justify-between mb-4">
            <div>
              <div className="text-3xl font-bold text-[#8B0000] mb-2" style={{ fontFamily: 'Poppins, sans-serif' }}>
                Bus {currentBus.number}
              </div>
              <div className="text-sm text-[#6B7280] flex items-center gap-1">
                <MapPin className="w-4 h-4" />
                {currentBus.route}
              </div>
            </div>
          </div>

          <motion.button
            whileTap={{ scale: 0.98 }}
            onClick={() => navigate('/driver/route')}
            className="w-full bg-[#8B0000] text-white py-3 rounded-full font-semibold shadow-md hover:bg-[#6D0000] transition-colors"
            style={{ fontFamily: 'Poppins, sans-serif' }}
          >
            View Full Route
          </motion.button>
        </motion.div>

        {/* Stats */}
        <div className="grid grid-cols-3 gap-3">
          <motion.div
            initial={{ scale: 0.8, opacity: 0 }}
            animate={{ scale: 1, opacity: 1 }}
            transition={{ delay: 0.2 }}
            className="bg-white rounded-xl p-4 shadow-md text-center"
          >
            <Gauge className="w-8 h-8 text-[#8B0000] mx-auto mb-2" />
            <div className="text-2xl font-bold text-[#1A1A1A]" style={{ fontFamily: 'Poppins, sans-serif' }}>
              {speed}
            </div>
            <div className="text-xs text-[#6B7280]" style={{ fontFamily: 'Poppins, sans-serif' }}>
              km/h
            </div>
          </motion.div>

          <motion.div
            initial={{ scale: 0.8, opacity: 0 }}
            animate={{ scale: 1, opacity: 1 }}
            transition={{ delay: 0.25 }}
            className="bg-white rounded-xl p-4 shadow-md text-center"
          >
            <Flag className="w-8 h-8 text-[#F5C518] mx-auto mb-2" />
            <div className="text-2xl font-bold text-[#1A1A1A]" style={{ fontFamily: 'Poppins, sans-serif' }}>
              {completedStops}/{stops.length}
            </div>
            <div className="text-xs text-[#6B7280]" style={{ fontFamily: 'Poppins, sans-serif' }}>
              Stops
            </div>
          </motion.div>

          <motion.div
            initial={{ scale: 0.8, opacity: 0 }}
            animate={{ scale: 1, opacity: 1 }}
            transition={{ delay: 0.3 }}
            className="bg-white rounded-xl p-4 shadow-md text-center"
          >
            <Users className="w-8 h-8 text-green-500 mx-auto mb-2" />
            <div className="text-2xl font-bold text-[#1A1A1A]" style={{ fontFamily: 'Poppins, sans-serif' }}>
              {passengerCount}
            </div>
            <div className="text-xs text-[#6B7280]" style={{ fontFamily: 'Poppins, sans-serif' }}>
              Passengers
            </div>
          </motion.div>
        </div>

        {/* Mini map */}
        <motion.div
          initial={{ y: 20, opacity: 0 }}
          animate={{ y: 0, opacity: 1 }}
          transition={{ delay: 0.35 }}
          className="bg-white rounded-2xl p-4 shadow-lg"
        >
          <h3 className="text-lg font-semibold text-[#1A1A1A] mb-3" style={{ fontFamily: 'Poppins, sans-serif' }}>
            Current Location
          </h3>
          <div className="h-48 rounded-xl overflow-hidden">
            <GoogleMapComponent buses={[currentBus]} currentBus={currentBus} />
          </div>
        </motion.div>

        {/* Stops progress */}
        <motion.div
          initial={{ y: 20, opacity: 0 }}
          animate={{ y: 0, opacity: 1 }}
          transition={{ delay: 0.4 }}
          className="bg-white rounded-2xl p-6 shadow-lg"
        >
          <h3 className="text-lg font-semibold text-[#1A1A1A] mb-4" style={{ fontFamily: 'Poppins, sans-serif' }}>
            Next Stop
          </h3>

          {currentStop && (
            <div className="bg-[#8B0000]/5 border-2 border-[#8B0000] rounded-xl p-4 mb-4">
              <div className="flex items-center gap-2 mb-2">
                <motion.div
                  animate={{ scale: [1, 1.2, 1] }}
                  transition={{ duration: 1.5, repeat: Infinity }}
                  className="w-3 h-3 bg-[#8B0000] rounded-full"
                />
                <span className="text-xs font-bold text-[#8B0000]">NEXT STOP</span>
              </div>
              <div className="font-semibold text-[#1A1A1A]" style={{ fontFamily: 'Poppins, sans-serif' }}>
                {currentStop.name}
              </div>
              <div className="text-sm text-[#6B7280] mt-1">ETA: {currentStop.time}</div>
            </div>
          )}

          <div className="space-y-2">
            {stops.slice(0, 3).map((stop) => (
              <div key={stop.id} className="flex items-center gap-3 text-sm">
                <div
                  className={`w-3 h-3 rounded-full ${
                    stop.status === 'completed'
                      ? 'bg-[#8B0000]'
                      : stop.status === 'current'
                      ? 'bg-[#F5C518]'
                      : 'bg-gray-300'
                  }`}
                />
                <span className={stop.status === 'completed' ? 'text-[#6B7280] line-through' : 'text-[#1A1A1A]'}>
                  {stop.name}
                </span>
              </div>
            ))}
          </div>
        </motion.div>

        {/* Quick actions */}
        <div className="grid grid-cols-2 gap-3">
          <motion.button
            whileTap={{ scale: 0.95 }}
            className="bg-amber-500 text-white py-4 rounded-xl font-semibold shadow-md hover:bg-amber-600 transition-colors flex items-center justify-center gap-2"
            style={{ fontFamily: 'Poppins, sans-serif' }}
          >
            <AlertCircle className="w-5 h-5" />
            Report Delay
          </motion.button>

          <motion.button
            whileTap={{ scale: 0.95 }}
            className="bg-red-500 text-white py-4 rounded-xl font-semibold shadow-md hover:bg-red-600 transition-colors flex items-center justify-center gap-2"
            style={{ fontFamily: 'Poppins, sans-serif' }}
          >
            <AlertCircle className="w-5 h-5" />
            Report Issue
          </motion.button>
        </div>
      </div>

      {/* Bottom navigation */}
      <div className="fixed bottom-0 left-0 right-0 bg-white border-t border-gray-200 px-6 py-3 shadow-lg">
        <div className="flex items-center justify-around max-w-md mx-auto">
          <motion.button
            whileTap={{ scale: 0.9 }}
            onClick={() => navigate('/driver/dashboard')}
            className="flex flex-col items-center gap-1 py-2 px-4"
          >
            <Gauge className="w-6 h-6 text-[#8B0000]" />
            <span className="text-xs font-medium text-[#8B0000]" style={{ fontFamily: 'Poppins, sans-serif' }}>
              Dashboard
            </span>
            <motion.div className="w-full h-0.5 bg-[#8B0000] rounded-full" />
          </motion.button>

          <motion.button
            whileTap={{ scale: 0.9 }}
            onClick={() => navigate('/driver/route')}
            className="flex flex-col items-center gap-1 py-2 px-4"
          >
            <Map className="w-6 h-6 text-[#6B7280]" />
            <span className="text-xs font-medium text-[#6B7280]" style={{ fontFamily: 'Poppins, sans-serif' }}>
              Route
            </span>
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
