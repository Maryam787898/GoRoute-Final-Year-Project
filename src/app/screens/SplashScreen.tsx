import { useEffect } from "react";
import { useNavigate } from "react-router";
import { motion } from "motion/react";
import { Bus } from "lucide-react";

export default function SplashScreen() {
  const navigate = useNavigate();

  useEffect(() => {
    const timer = setTimeout(() => {
      navigate("/role-selection");
    }, 2500);
    return () => clearTimeout(timer);
  }, [navigate]);

  return (
    <div className="h-full w-full bg-white flex flex-col items-center justify-center px-6">
      <motion.div
        initial={{ scale: 0.5, opacity: 0 }}
        animate={{ scale: 1, opacity: 1 }}
        transition={{ duration: 0.6, ease: "easeOut" }}
        className="flex flex-col items-center gap-6"
      >
        <div className="bg-[#8B0000] rounded-3xl p-8 shadow-2xl">
          <Bus className="w-20 h-20 text-white" strokeWidth={2} />
        </div>

        <motion.div
          initial={{ y: 20, opacity: 0 }}
          animate={{ y: 0, opacity: 1 }}
          transition={{ delay: 0.3, duration: 0.6 }}
          className="text-center"
        >
          <h1 className="text-5xl font-bold text-[#8B0000] mb-2" style={{ fontFamily: 'Poppins, sans-serif' }}>
            GoRoute
          </h1>
          <p className="text-[#6B7280] text-lg" style={{ fontFamily: 'Poppins, sans-serif' }}>
            Live Tracking. Live Routing.
          </p>
        </motion.div>
      </motion.div>

      <motion.div
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 0.8, duration: 0.6 }}
        className="absolute bottom-24 w-64"
      >
        <div className="w-full bg-gray-200 rounded-full h-1.5 overflow-hidden">
          <motion.div
            initial={{ width: "0%" }}
            animate={{ width: "100%" }}
            transition={{ duration: 2.5, ease: "linear" }}
            className="h-full bg-[#8B0000]"
          />
        </div>
      </motion.div>
    </div>
  );
}
