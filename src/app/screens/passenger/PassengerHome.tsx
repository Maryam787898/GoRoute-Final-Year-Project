import { useState, useEffect } from "react";
import { useNavigate } from "react-router";
import { motion, AnimatePresence } from "motion/react";
import { Search, MapPin, Navigation, Home, Route, Bell, User, AlertTriangle, Clock } from "lucide-react";
import GoogleMapComponent from "../../components/GoogleMapComponent";
import { useApp } from "../../contexts/AppContext";

interface Bus {
  id: string;
  number: string;
  route: string;
  lat: number;
  lng: number;
  eta: number;
  status: 'active' | 'delayed';
}

const demoRoutes = [
  "Gulberg → DHA",
  "Johar Town → Wapda Town",
  "Model Town → Bahria Town",
  "Garden Town → Cantt",
];

export default function PassengerHome() {
  const navigate = useNavigate();
  const { user } = useApp();
  const [searchQuery, setSearchQuery] = useState("");
  const [selectedTab, setSelectedTab] = useState('home');
  const [buses, setBuses] = useState<Bus[]>([
    { id: "1", number: "45A", route: "Gulberg → DHA", lat: 31.5204, lng: 74.3587, eta: 3, status: 'active' },
    { id: "2", number: "67B", route: "Johar Town → Wapda Town", lat: 31.4697, lng: 74.2728, eta: 8, status: 'active' },
    { id: "3", number: "12C", route: "Model Town → Bahria Town", lat: 31.4826, lng: 74.3236, eta: 15, status: 'active' },
    { id: "4", number: "89D", route: "Garden Town → Cantt", lat: 31.5080, lng: 74.3340, eta: 22, status: 'delayed' },
  ]);
  const [delayAlert, setDelayAlert] = useState(true);

  useEffect(() => {
    // Simulate bus movement
    const interval = setInterval(() => {
      setBuses(prev => prev.map(bus => ({
        ...bus,
        lat: bus.lat + (Math.random() - 0.5) * 0.001,
        lng: bus.lng + (Math.random() - 0.5) * 0.001,
        eta: Math.max(1, bus.eta + (Math.random() > 0.5 ? -1 : 0)),
      })));
    }, 3000);

    return () => clearInterval(interval);
  }, []);

  const getEtaBadgeColor = (eta: number) => {
    if (eta < 5) return 'bg-green-500';
    if (eta < 15) return 'bg-amber-500';
    return 'bg-gray-400';
  };

  return (
    <div className="h-full w-full bg-white flex flex-col relative">
      {/* Map background */}
      <div className="absolute inset-0">
        <GoogleMapComponent buses={buses} onBusClick={(busId) => navigate(`/passenger/track/${busId}`)} />
      </div>

      {/* Delay alert banner */}
      <AnimatePresence>
        {delayAlert && (
          <motion.div
            initial={{ y: -100 }}
            animate={{ y: 0 }}
            exit={{ y: -100 }}
            className="absolute top-0 left-0 right-0 bg-red-500 text-white px-6 py-3 flex items-center justify-between z-20 shadow-lg"
            style={{ fontFamily: 'Poppins, sans-serif' }}
          >
            <div className="flex items-center gap-3">
              <AlertTriangle className="w-5 h-5" />
              <span className="font-medium">Bus 89D delayed by 10 minutes</span>
            </div>
            <button onClick={() => setDelayAlert(false)} className="text-white">
              ✕
            </button>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Search bar */}
      <motion.div
        initial={{ y: -20, opacity: 0 }}
        animate={{ y: 0, opacity: 1 }}
        className="absolute top-4 left-4 right-4 z-10"
      >
        <div className="bg-white rounded-full shadow-xl px-5 py-3 flex items-center gap-3">
          <Search className="w-5 h-5 text-[#6B7280]" />
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Search routes or stops..."
            className="flex-1 outline-none text-[#1A1A1A]"
            style={{ fontFamily: 'Poppins, sans-serif' }}
          />
          <Navigation className="w-5 h-5 text-[#8B0000]" />
        </div>
      </motion.div>

      {/* Nearby buses bottom sheet */}
      <motion.div
        initial={{ y: 300 }}
        animate={{ y: 0 }}
        transition={{ delay: 0.3, type: "spring", stiffness: 200 }}
        className="absolute bottom-20 left-0 right-0 bg-white rounded-t-3xl shadow-2xl z-10"
      >
        <div className="px-6 py-4 border-b border-gray-100">
          <div className="w-12 h-1.5 bg-gray-300 rounded-full mx-auto mb-4" />
          <h3 className="text-xl font-bold text-[#1A1A1A]" style={{ fontFamily: 'Poppins, sans-serif' }}>
            Nearby Buses
          </h3>
        </div>

        <div className="overflow-x-auto px-6 py-4">
          <div className="flex gap-4 pb-2">
            {buses.map((bus) => (
              <motion.div
                key={bus.id}
                whileTap={{ scale: 0.95 }}
                onClick={() => navigate(`/passenger/track/${bus.id}`)}
                className="min-w-[280px] bg-white border-2 border-gray-100 rounded-2xl p-4 shadow-md hover:shadow-lg transition-shadow cursor-pointer"
              >
                <div className="flex items-start justify-between mb-3">
                  <div>
                    <div className="text-2xl font-bold text-[#8B0000] mb-1" style={{ fontFamily: 'Poppins, sans-serif' }}>
                      {bus.number}
                    </div>
                    <div className="text-sm text-[#6B7280] flex items-center gap-1">
                      <MapPin className="w-3.5 h-3.5" />
                      {bus.route}
                    </div>
                  </div>
                  <div className={`${getEtaBadgeColor(bus.eta)} text-white px-3 py-1 rounded-full text-xs font-semibold flex items-center gap-1`}>
                    <Clock className="w-3.5 h-3.5" />
                    {bus.eta}m
                  </div>
                </div>
                <div className="flex items-center gap-2 mt-3">
                  <div className={`w-2 h-2 rounded-full ${bus.status === 'active' ? 'bg-green-500' : 'bg-red-500'} animate-pulse`} />
                  <span className="text-xs text-[#6B7280] capitalize" style={{ fontFamily: 'Poppins, sans-serif' }}>
                    {bus.status}
                  </span>
                </div>
              </motion.div>
            ))}
          </div>
        </div>
      </motion.div>

      {/* Bottom navigation */}
      <div className="absolute bottom-0 left-0 right-0 bg-white border-t border-gray-200 px-6 py-3 z-20 shadow-lg">
        <div className="flex items-center justify-around">
          {[
            { id: 'home', icon: Home, label: 'Home', path: '/passenger/home' },
            { id: 'routes', icon: Route, label: 'Routes', path: '/passenger/routes' },
            { id: 'alerts', icon: Bell, label: 'Alerts', path: '/passenger/alerts' },
            { id: 'profile', icon: User, label: 'Profile', path: '/passenger/profile' },
          ].map((tab) => {
            const Icon = tab.icon;
            const isActive = selectedTab === tab.id;
            return (
              <motion.button
                key={tab.id}
                whileTap={{ scale: 0.9 }}
                onClick={() => {
                  setSelectedTab(tab.id);
                  navigate(tab.path);
                }}
                className="flex flex-col items-center gap-1 py-2 px-4"
              >
                <Icon className={`w-6 h-6 ${isActive ? 'text-[#8B0000]' : 'text-[#6B7280]'}`} />
                <span className={`text-xs font-medium ${isActive ? 'text-[#8B0000]' : 'text-[#6B7280]'}`} style={{ fontFamily: 'Poppins, sans-serif' }}>
                  {tab.label}
                </span>
                {isActive && <motion.div layoutId="activeTab" className="w-full h-0.5 bg-[#8B0000] rounded-full" />}
              </motion.button>
            );
          })}
        </div>
      </div>
    </div>
  );
}
