import { useNavigate } from "react-router";
import { motion } from "motion/react";
import { ArrowLeft, Calendar, MapPin, Clock, TrendingUp, Bus } from "lucide-react";
import { LineChart, Line, XAxis, YAxis, Tooltip, ResponsiveContainer } from "recharts";
import { useApp } from "../../contexts/AppContext";

const statsData = [
  { month: 'Jan', trips: 45 },
  { month: 'Feb', trips: 52 },
  { month: 'Mar', trips: 61 },
  { month: 'Apr', trips: 48 },
  { month: 'May', trips: 70 },
  { month: 'Jun', trips: 65 },
];

interface Trip {
  id: string;
  route: string;
  busNumber: string;
  date: string;
  time: string;
  status: 'completed' | 'cancelled';
  duration: string;
}

const trips: Trip[] = [
  {
    id: "1",
    route: "Gulberg → DHA",
    busNumber: "45A",
    date: "Apr 10, 2026",
    time: "9:15 AM",
    status: 'completed',
    duration: "35 min",
  },
  {
    id: "2",
    route: "Johar Town → Wapda Town",
    busNumber: "67B",
    date: "Apr 9, 2026",
    time: "2:30 PM",
    status: 'completed',
    duration: "42 min",
  },
  {
    id: "3",
    route: "Model Town → Bahria Town",
    busNumber: "12C",
    date: "Apr 8, 2026",
    time: "8:45 AM",
    status: 'completed',
    duration: "48 min",
  },
  {
    id: "4",
    route: "Garden Town → Cantt",
    busNumber: "89D",
    date: "Apr 7, 2026",
    time: "5:20 PM",
    status: 'cancelled',
    duration: "-",
  },
];

export default function TripHistoryScreen() {
  const navigate = useNavigate();
  const { selectedRole } = useApp();

  return (
    <div className="h-full w-full bg-gray-50 flex flex-col overflow-y-auto pb-20">
      {/* App bar */}
      <div className="bg-[#8B0000] px-6 py-4 shadow-md">
        <div className="flex items-center gap-4">
          <button
            onClick={() => navigate(selectedRole === 'passenger' ? '/passenger/profile' : '/driver/profile')}
            className="p-1"
          >
            <ArrowLeft className="w-6 h-6 text-white" />
          </button>
          <h2 className="text-white text-xl font-semibold" style={{ fontFamily: 'Poppins, sans-serif' }}>
            Trip History
          </h2>
        </div>
      </div>

      <div className="flex-1 px-6 py-6 space-y-6">
        {/* Stats cards */}
        <div className="overflow-x-auto -mx-6 px-6">
          <div className="flex gap-4 pb-2">
            <motion.div
              initial={{ scale: 0.9, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              className="min-w-[160px] bg-gradient-to-br from-[#8B0000] to-[#6D0000] rounded-2xl p-5 shadow-lg text-white"
            >
              <Bus className="w-8 h-8 mb-3 opacity-80" />
              <div className="text-3xl font-bold mb-1" style={{ fontFamily: 'Poppins, sans-serif' }}>
                341
              </div>
              <div className="text-sm opacity-90" style={{ fontFamily: 'Poppins, sans-serif' }}>
                Total Trips
              </div>
            </motion.div>

            <motion.div
              initial={{ scale: 0.9, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              transition={{ delay: 0.05 }}
              className="min-w-[160px] bg-white rounded-2xl p-5 shadow-lg border-2 border-gray-100"
            >
              <Calendar className="w-8 h-8 mb-3 text-[#8B0000]" />
              <div className="text-3xl font-bold text-[#1A1A1A] mb-1" style={{ fontFamily: 'Poppins, sans-serif' }}>
                24
              </div>
              <div className="text-sm text-[#6B7280]" style={{ fontFamily: 'Poppins, sans-serif' }}>
                This Month
              </div>
            </motion.div>

            <motion.div
              initial={{ scale: 0.9, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              transition={{ delay: 0.1 }}
              className="min-w-[160px] bg-white rounded-2xl p-5 shadow-lg border-2 border-gray-100"
            >
              <Clock className="w-8 h-8 mb-3 text-[#F5C518]" />
              <div className="text-3xl font-bold text-[#1A1A1A] mb-1" style={{ fontFamily: 'Poppins, sans-serif' }}>
                38m
              </div>
              <div className="text-sm text-[#6B7280]" style={{ fontFamily: 'Poppins, sans-serif' }}>
                Avg Duration
              </div>
            </motion.div>
          </div>
        </div>

        {/* Chart */}
        <motion.div
          initial={{ y: -20, opacity: 0 }}
          animate={{ y: 0, opacity: 1 }}
          transition={{ delay: 0.15 }}
          className="bg-white rounded-2xl p-6 shadow-lg"
        >
          <div className="flex items-center gap-2 mb-4">
            <TrendingUp className="w-5 h-5 text-[#8B0000]" />
            <h3 className="text-lg font-semibold text-[#1A1A1A]" style={{ fontFamily: 'Poppins, sans-serif' }}>
              Trip Trends
            </h3>
          </div>

          <div className="h-48">
            <ResponsiveContainer width="100%" height="100%">
              <LineChart data={statsData}>
                <XAxis
                  dataKey="month"
                  stroke="#6B7280"
                  style={{ fontFamily: 'Poppins, sans-serif', fontSize: '12px' }}
                />
                <YAxis
                  stroke="#6B7280"
                  style={{ fontFamily: 'Poppins, sans-serif', fontSize: '12px' }}
                />
                <Tooltip
                  contentStyle={{
                    backgroundColor: 'white',
                    border: '2px solid #8B0000',
                    borderRadius: '12px',
                    fontFamily: 'Poppins, sans-serif',
                  }}
                />
                <Line
                  type="monotone"
                  dataKey="trips"
                  stroke="#8B0000"
                  strokeWidth={3}
                  dot={{ fill: '#8B0000', r: 5 }}
                  activeDot={{ r: 7 }}
                />
              </LineChart>
            </ResponsiveContainer>
          </div>
        </motion.div>

        {/* Trip history list */}
        <motion.div
          initial={{ y: -20, opacity: 0 }}
          animate={{ y: 0, opacity: 1 }}
          transition={{ delay: 0.2 }}
          className="bg-white rounded-2xl shadow-lg overflow-hidden"
        >
          <div className="px-6 py-4 border-b border-gray-100">
            <h3 className="text-lg font-semibold text-[#1A1A1A]" style={{ fontFamily: 'Poppins, sans-serif' }}>
              Recent Trips
            </h3>
          </div>

          <div className="divide-y divide-gray-100">
            {trips.map((trip, index) => (
              <motion.div
                key={trip.id}
                initial={{ x: -20, opacity: 0 }}
                animate={{ x: 0, opacity: 1 }}
                transition={{ delay: 0.25 + index * 0.05 }}
                className="px-6 py-4 hover:bg-gray-50 transition-colors cursor-pointer"
              >
                <div className="flex items-start justify-between mb-2">
                  <div className="flex-1">
                    <div className="flex items-center gap-3 mb-2">
                      <div className="bg-[#8B0000] text-white text-sm font-bold px-3 py-1 rounded-lg">
                        {trip.busNumber}
                      </div>
                      <span className="font-semibold text-[#1A1A1A]" style={{ fontFamily: 'Poppins, sans-serif' }}>
                        {trip.route}
                      </span>
                    </div>

                    <div className="flex items-center gap-4 text-sm text-[#6B7280]">
                      <span className="flex items-center gap-1">
                        <Calendar className="w-3.5 h-3.5" />
                        {trip.date}
                      </span>
                      <span className="flex items-center gap-1">
                        <Clock className="w-3.5 h-3.5" />
                        {trip.time}
                      </span>
                    </div>
                  </div>

                  <div className="flex flex-col items-end gap-2">
                    <span
                      className={`text-xs font-semibold px-3 py-1 rounded-full ${
                        trip.status === 'completed'
                          ? 'bg-green-100 text-green-700'
                          : 'bg-red-100 text-red-700'
                      }`}
                    >
                      {trip.status === 'completed' ? 'Completed' : 'Cancelled'}
                    </span>
                    {trip.status === 'completed' && (
                      <span className="text-sm text-[#6B7280]">{trip.duration}</span>
                    )}
                  </div>
                </div>
              </motion.div>
            ))}
          </div>
        </motion.div>
      </div>
    </div>
  );
}
