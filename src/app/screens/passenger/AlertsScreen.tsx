import { useState } from "react";
import { useNavigate } from "react-router";
import { motion } from "motion/react";
import { ArrowLeft, AlertTriangle, Bell, Clock, Info, Home, Route, User } from "lucide-react";

interface Alert {
  id: string;
  type: 'delay' | 'arrival' | 'change';
  title: string;
  message: string;
  time: string;
  isRead: boolean;
}

const alerts: Alert[] = [
  {
    id: "1",
    type: 'delay',
    title: "Bus 89D Delayed",
    message: "Your bus is running 10 minutes late due to heavy traffic on Main Boulevard",
    time: "5 mins ago",
    isRead: false,
  },
  {
    id: "2",
    type: 'arrival',
    title: "Bus 45A Arriving Soon",
    message: "Your bus will arrive at Gulberg Main Boulevard in 2 minutes",
    time: "12 mins ago",
    isRead: false,
  },
  {
    id: "3",
    type: 'change',
    title: "Route Change Alert",
    message: "Bus 67B will take alternate route via Ferozepur Road due to construction",
    time: "1 hour ago",
    isRead: true,
  },
  {
    id: "4",
    type: 'arrival',
    title: "Bus 12C On Time",
    message: "Your tracked bus is arriving at Model Town in 5 minutes",
    time: "2 hours ago",
    isRead: true,
  },
];

export default function AlertsScreen() {
  const navigate = useNavigate();
  const [selectedTab, setSelectedTab] = useState('alerts');

  const getAlertIcon = (type: string) => {
    switch (type) {
      case 'delay':
        return AlertTriangle;
      case 'arrival':
        return Bell;
      case 'change':
        return Info;
      default:
        return Bell;
    }
  };

  const getAlertColor = (type: string) => {
    switch (type) {
      case 'delay':
        return 'bg-red-500';
      case 'arrival':
        return 'bg-green-500';
      case 'change':
        return 'bg-amber-500';
      default:
        return 'bg-gray-500';
    }
  };

  const unreadCount = alerts.filter(a => !a.isRead).length;

  return (
    <div className="h-full w-full bg-white flex flex-col">
      {/* App bar */}
      <div className="bg-[#8B0000] px-6 py-4 shadow-md">
        <div className="flex items-center gap-4">
          <button onClick={() => navigate('/passenger/home')} className="p-1">
            <ArrowLeft className="w-6 h-6 text-white" />
          </button>
          <h2 className="text-white text-xl font-semibold flex-1" style={{ fontFamily: 'Poppins, sans-serif' }}>
            Notifications
          </h2>
          {unreadCount > 0 && (
            <div className="bg-[#F5C518] text-[#8B0000] text-sm font-bold px-3 py-1 rounded-full">
              {unreadCount} new
            </div>
          )}
        </div>
      </div>

      {/* Alerts list */}
      <div className="flex-1 overflow-y-auto pb-20">
        {alerts.length === 0 ? (
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            className="flex flex-col items-center justify-center h-full px-6 text-center"
          >
            <div className="bg-gray-100 rounded-full p-8 mb-6">
              <Bell className="w-16 h-16 text-gray-400" />
            </div>
            <h3 className="text-2xl font-bold text-[#1A1A1A] mb-2" style={{ fontFamily: 'Poppins, sans-serif' }}>
              No Notifications
            </h3>
            <p className="text-[#6B7280]" style={{ fontFamily: 'Poppins, sans-serif' }}>
              You're all caught up! We'll notify you when there are updates.
            </p>
          </motion.div>
        ) : (
          <div className="divide-y divide-gray-100">
            {alerts.map((alert, index) => {
              const Icon = getAlertIcon(alert.type);
              const colorClass = getAlertColor(alert.type);

              return (
                <motion.div
                  key={alert.id}
                  initial={{ x: -20, opacity: 0 }}
                  animate={{ x: 0, opacity: 1 }}
                  transition={{ delay: index * 0.05 }}
                  className={`px-6 py-4 hover:bg-gray-50 transition-colors cursor-pointer ${
                    !alert.isRead ? 'bg-[#8B0000]/5' : ''
                  }`}
                >
                  <div className="flex gap-4">
                    <div className={`${colorClass} rounded-full p-3 h-fit`}>
                      <Icon className="w-5 h-5 text-white" />
                    </div>

                    <div className="flex-1">
                      <div className="flex items-start justify-between mb-1">
                        <h4 className="font-semibold text-[#1A1A1A]" style={{ fontFamily: 'Poppins, sans-serif' }}>
                          {alert.title}
                        </h4>
                        {!alert.isRead && (
                          <div className="w-2.5 h-2.5 bg-[#8B0000] rounded-full flex-shrink-0 mt-1.5" />
                        )}
                      </div>
                      <p className="text-sm text-[#6B7280] leading-relaxed mb-2" style={{ fontFamily: 'Poppins, sans-serif' }}>
                        {alert.message}
                      </p>
                      <div className="text-xs text-[#6B7280] flex items-center gap-1">
                        <Clock className="w-3.5 h-3.5" />
                        {alert.time}
                      </div>
                    </div>
                  </div>
                </motion.div>
              );
            })}
          </div>
        )}
      </div>

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
