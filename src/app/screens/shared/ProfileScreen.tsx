import { useNavigate } from "react-router";
import { motion } from "motion/react";
import { ArrowLeft, User, Mail, Phone, MapPin, Bell, Settings, LogOut, Star, History as HistoryIcon } from "lucide-react";
import { useApp } from "../../contexts/AppContext";

export default function ProfileScreen() {
  const navigate = useNavigate();
  const { user, selectedRole } = useApp();

  const savedRoutes = [
    { id: "1", number: "45A", name: "Gulberg → DHA" },
    { id: "2", number: "12C", name: "Model Town → Bahria Town" },
  ];

  const handleSignOut = () => {
    navigate('/');
  };

  return (
    <div className="h-full w-full bg-gray-50 flex flex-col overflow-y-auto pb-20">
      {/* App bar */}
      <div className="bg-[#8B0000] px-6 py-4 shadow-md">
        <div className="flex items-center gap-4">
          <button
            onClick={() => navigate(selectedRole === 'passenger' ? '/passenger/home' : '/driver/dashboard')}
            className="p-1"
          >
            <ArrowLeft className="w-6 h-6 text-white" />
          </button>
          <h2 className="text-white text-xl font-semibold" style={{ fontFamily: 'Poppins, sans-serif' }}>
            Profile
          </h2>
        </div>
      </div>

      <div className="flex-1 px-6 py-6 space-y-6">
        {/* Profile header */}
        <motion.div
          initial={{ y: -20, opacity: 0 }}
          animate={{ y: 0, opacity: 1 }}
          className="bg-white rounded-2xl p-6 shadow-lg text-center"
        >
          <motion.div
            whileHover={{ scale: 1.05 }}
            className="relative inline-block mb-4"
          >
            <div className="w-24 h-24 bg-gradient-to-br from-[#8B0000] to-[#6D0000] rounded-full flex items-center justify-center ring-4 ring-[#8B0000]/20">
              <User className="w-12 h-12 text-white" />
            </div>
            <div className="absolute -bottom-1 -right-1 bg-[#F5C518] text-[#8B0000] text-xs font-bold px-3 py-1 rounded-full capitalize border-2 border-white">
              {selectedRole}
            </div>
          </motion.div>

          <h3 className="text-2xl font-bold text-[#1A1A1A] mb-1" style={{ fontFamily: 'Poppins, sans-serif' }}>
            {user?.name || 'Demo User'}
          </h3>
          <p className="text-[#6B7280]" style={{ fontFamily: 'Poppins, sans-serif' }}>
            {user?.email || 'demo@goroute.com'}
          </p>
        </motion.div>

        {/* Account info */}
        <motion.div
          initial={{ y: -20, opacity: 0 }}
          animate={{ y: 0, opacity: 1 }}
          transition={{ delay: 0.1 }}
          className="bg-white rounded-2xl p-6 shadow-lg space-y-4"
        >
          <h4 className="text-lg font-semibold text-[#1A1A1A] mb-3" style={{ fontFamily: 'Poppins, sans-serif' }}>
            Account Information
          </h4>

          <div className="space-y-3">
            <div className="flex items-center gap-3 text-[#6B7280]">
              <Mail className="w-5 h-5 text-[#8B0000]" />
              <span style={{ fontFamily: 'Poppins, sans-serif' }}>
                {user?.email || 'demo@goroute.com'}
              </span>
            </div>
            <div className="flex items-center gap-3 text-[#6B7280]">
              <Phone className="w-5 h-5 text-[#8B0000]" />
              <span style={{ fontFamily: 'Poppins, sans-serif' }}>
                +92 300 1234567
              </span>
            </div>
            <div className="flex items-center gap-3 text-[#6B7280]">
              <MapPin className="w-5 h-5 text-[#8B0000]" />
              <span style={{ fontFamily: 'Poppins, sans-serif' }}>
                Lahore, Pakistan
              </span>
            </div>
          </div>
        </motion.div>

        {/* Saved routes (passenger only) */}
        {selectedRole === 'passenger' && (
          <motion.div
            initial={{ y: -20, opacity: 0 }}
            animate={{ y: 0, opacity: 1 }}
            transition={{ delay: 0.2 }}
            className="bg-white rounded-2xl p-6 shadow-lg"
          >
            <div className="flex items-center gap-2 mb-4">
              <Star className="w-5 h-5 text-[#F5C518]" fill="#F5C518" />
              <h4 className="text-lg font-semibold text-[#1A1A1A]" style={{ fontFamily: 'Poppins, sans-serif' }}>
                Saved Routes
              </h4>
            </div>

            <div className="space-y-3">
              {savedRoutes.map((route) => (
                <div
                  key={route.id}
                  className="flex items-center justify-between py-3 border-b border-gray-100 last:border-0"
                >
                  <div className="flex items-center gap-3">
                    <div className="bg-[#8B0000] text-white text-sm font-bold px-3 py-1 rounded-lg">
                      {route.number}
                    </div>
                    <span className="text-[#1A1A1A]" style={{ fontFamily: 'Poppins, sans-serif' }}>
                      {route.name}
                    </span>
                  </div>
                </div>
              ))}
            </div>
          </motion.div>
        )}

        {/* Settings */}
        <motion.div
          initial={{ y: -20, opacity: 0 }}
          animate={{ y: 0, opacity: 1 }}
          transition={{ delay: 0.3 }}
          className="bg-white rounded-2xl shadow-lg overflow-hidden"
        >
          <button className="w-full flex items-center justify-between p-5 hover:bg-gray-50 transition-colors border-b border-gray-100">
            <div className="flex items-center gap-3">
              <Bell className="w-5 h-5 text-[#8B0000]" />
              <span className="font-medium text-[#1A1A1A]" style={{ fontFamily: 'Poppins, sans-serif' }}>
                Notifications
              </span>
            </div>
            <div className="text-[#6B7280]">›</div>
          </button>

          <button
            onClick={() => navigate(selectedRole === 'passenger' ? '/passenger/history' : '/driver/history')}
            className="w-full flex items-center justify-between p-5 hover:bg-gray-50 transition-colors border-b border-gray-100"
          >
            <div className="flex items-center gap-3">
              <HistoryIcon className="w-5 h-5 text-[#8B0000]" />
              <span className="font-medium text-[#1A1A1A]" style={{ fontFamily: 'Poppins, sans-serif' }}>
                Trip History
              </span>
            </div>
            <div className="text-[#6B7280]">›</div>
          </button>

          <button className="w-full flex items-center justify-between p-5 hover:bg-gray-50 transition-colors">
            <div className="flex items-center gap-3">
              <Settings className="w-5 h-5 text-[#8B0000]" />
              <span className="font-medium text-[#1A1A1A]" style={{ fontFamily: 'Poppins, sans-serif' }}>
                Settings
              </span>
            </div>
            <div className="text-[#6B7280]">›</div>
          </button>
        </motion.div>

        {/* Sign out */}
        <motion.button
          whileTap={{ scale: 0.98 }}
          onClick={handleSignOut}
          className="w-full bg-red-500 text-white py-4 rounded-full font-semibold shadow-lg hover:bg-red-600 transition-colors flex items-center justify-center gap-2"
          style={{ fontFamily: 'Poppins, sans-serif' }}
        >
          <LogOut className="w-5 h-5" />
          Sign Out
        </motion.button>
      </div>
    </div>
  );
}
