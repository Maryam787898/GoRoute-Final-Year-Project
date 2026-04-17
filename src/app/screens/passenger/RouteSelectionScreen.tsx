import { useState } from "react";
import { useNavigate } from "react-router";
import { motion } from "motion/react";
import { Search, ArrowLeft, MapPin, Star, Clock, Navigation, Home, Route as RouteIcon, Bell, User } from "lucide-react";

interface RouteData {
  id: string;
  number: string;
  name: string;
  stops: number;
  isActive: boolean;
  isFavorite: boolean;
}

const routes: RouteData[] = [
  { id: "1", number: "45A", name: "Gulberg → DHA", stops: 12, isActive: true, isFavorite: true },
  { id: "2", number: "67B", name: "Johar Town → Wapda Town", stops: 15, isActive: true, isFavorite: false },
  { id: "3", number: "12C", name: "Model Town → Bahria Town", stops: 18, isActive: true, isFavorite: true },
  { id: "4", number: "89D", name: "Garden Town → Cantt", stops: 10, isActive: false, isFavorite: false },
  { id: "5", number: "23E", name: "Liberty → Mall Road", stops: 8, isActive: true, isFavorite: false },
  { id: "6", number: "56F", name: "Cavalry → Kalma Chowk", stops: 14, isActive: true, isFavorite: false },
];

export default function RouteSelectionScreen() {
  const navigate = useNavigate();
  const [searchQuery, setSearchQuery] = useState("");
  const [selectedFilter, setSelectedFilter] = useState<'all' | 'area' | 'favorites' | 'active'>('all');
  const [selectedTab, setSelectedTab] = useState('routes');

  const filteredRoutes = routes.filter(route => {
    const matchesSearch = route.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
                         route.number.toLowerCase().includes(searchQuery.toLowerCase());
    const matchesFilter =
      selectedFilter === 'all' ||
      (selectedFilter === 'favorites' && route.isFavorite) ||
      (selectedFilter === 'active' && route.isActive) ||
      (selectedFilter === 'area' && route.name.includes('Gulberg'));

    return matchesSearch && matchesFilter;
  });

  return (
    <div className="h-full w-full bg-white flex flex-col">
      {/* App bar */}
      <div className="bg-[#8B0000] px-6 py-4 shadow-md">
        <div className="flex items-center gap-4 mb-4">
          <button onClick={() => navigate('/passenger/home')} className="p-1">
            <ArrowLeft className="w-6 h-6 text-white" />
          </button>
          <h2 className="text-white text-xl font-semibold flex-1" style={{ fontFamily: 'Poppins, sans-serif' }}>
            Routes
          </h2>
        </div>

        {/* Search bar */}
        <div className="bg-white rounded-full px-4 py-3 flex items-center gap-3">
          <Search className="w-5 h-5 text-[#6B7280]" />
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Search routes..."
            className="flex-1 outline-none text-[#1A1A1A]"
            style={{ fontFamily: 'Poppins, sans-serif' }}
          />
        </div>
      </div>

      {/* Filter chips */}
      <div className="px-6 py-4 border-b border-gray-100 overflow-x-auto">
        <div className="flex gap-2">
          {[
            { id: 'all', label: 'All Routes' },
            { id: 'area', label: 'My Area' },
            { id: 'favorites', label: 'Favorites' },
            { id: 'active', label: 'Active Now' },
          ].map((filter) => (
            <motion.button
              key={filter.id}
              whileTap={{ scale: 0.95 }}
              onClick={() => setSelectedFilter(filter.id as any)}
              className={`px-4 py-2 rounded-full whitespace-nowrap font-medium transition-all ${
                selectedFilter === filter.id
                  ? 'bg-[#8B0000] text-white shadow-md'
                  : 'bg-gray-100 text-[#6B7280]'
              }`}
              style={{ fontFamily: 'Poppins, sans-serif' }}
            >
              {filter.label}
            </motion.button>
          ))}
        </div>
      </div>

      {/* Routes list */}
      <div className="flex-1 overflow-y-auto px-6 py-4">
        <div className="space-y-3 pb-20">
          {filteredRoutes.map((route, index) => (
            <motion.div
              key={route.id}
              initial={{ x: -20, opacity: 0 }}
              animate={{ x: 0, opacity: 1 }}
              transition={{ delay: index * 0.05 }}
              whileTap={{ scale: 0.98 }}
              onClick={() => navigate(`/passenger/track/${route.id}`)}
              className="bg-white border-2 border-gray-100 rounded-2xl p-4 hover:shadow-lg transition-shadow cursor-pointer"
            >
              <div className="flex items-start justify-between">
                <div className="flex-1">
                  <div className="flex items-center gap-3 mb-2">
                    <div className="bg-[#8B0000] text-white text-lg font-bold px-4 py-2 rounded-lg" style={{ fontFamily: 'Poppins, sans-serif' }}>
                      {route.number}
                    </div>
                    <div>
                      <div className="font-semibold text-[#1A1A1A]" style={{ fontFamily: 'Poppins, sans-serif' }}>
                        {route.name}
                      </div>
                      <div className="text-sm text-[#6B7280] flex items-center gap-1 mt-1">
                        <MapPin className="w-3.5 h-3.5" />
                        {route.stops} stops
                      </div>
                    </div>
                  </div>

                  <div className="flex items-center gap-3 mt-3">
                    <div className={`flex items-center gap-1 ${route.isActive ? 'text-green-600' : 'text-gray-400'}`}>
                      <div className={`w-2 h-2 rounded-full ${route.isActive ? 'bg-green-500 animate-pulse' : 'bg-gray-400'}`} />
                      <span className="text-xs font-medium">
                        {route.isActive ? 'Active' : 'Offline'}
                      </span>
                    </div>
                    {route.isActive && (
                      <div className="text-xs text-[#6B7280] flex items-center gap-1">
                        <Clock className="w-3.5 h-3.5" />
                        Next in 5 min
                      </div>
                    )}
                  </div>
                </div>

                <button
                  onClick={(e) => {
                    e.stopPropagation();
                  }}
                  className="p-2"
                >
                  <Star
                    className={`w-6 h-6 ${
                      route.isFavorite ? 'text-[#F5C518] fill-[#F5C518]' : 'text-gray-300'
                    }`}
                  />
                </button>
              </div>
            </motion.div>
          ))}
        </div>
      </div>

      {/* Bottom navigation */}
      <div className="absolute bottom-0 left-0 right-0 bg-white border-t border-gray-200 px-6 py-3 z-20 shadow-lg">
        <div className="flex items-center justify-around">
          {[
            { id: 'home', icon: Home, label: 'Home', path: '/passenger/home' },
            { id: 'routes', icon: RouteIcon, label: 'Routes', path: '/passenger/routes' },
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
