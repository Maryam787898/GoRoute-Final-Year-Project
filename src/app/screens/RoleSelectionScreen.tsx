import { useState } from "react";
import { useNavigate } from "react-router";
import { motion } from "motion/react";
import { Bus, User, UserCircle } from "lucide-react";
import { useApp } from "../contexts/AppContext";

export default function RoleSelectionScreen() {
  const navigate = useNavigate();
  const { setSelectedRole } = useApp();
  const [selected, setSelected] = useState<'passenger' | 'driver'>('passenger');

  const handleContinue = () => {
    setSelectedRole(selected);
    navigate("/onboarding");
  };

  return (
    <div className="h-full w-full bg-white flex flex-col">
      {/* App bar */}
      <div className="bg-[#8B0000] px-6 py-4 shadow-md">
        <h2 className="text-white text-xl font-semibold" style={{ fontFamily: 'Poppins, sans-serif' }}>
          Choose Role
        </h2>
      </div>

      <div className="flex-1 flex flex-col items-center justify-between px-6 py-12">
        {/* Logo */}
        <motion.div
          initial={{ scale: 0.8, opacity: 0 }}
          animate={{ scale: 1, opacity: 1 }}
          transition={{ duration: 0.5 }}
          className="flex flex-col items-center gap-4 mt-8"
        >
          <div className="bg-[#8B0000] rounded-2xl p-6 shadow-lg">
            <Bus className="w-16 h-16 text-white" strokeWidth={2} />
          </div>
        </motion.div>

        {/* Content */}
        <motion.div
          initial={{ y: 20, opacity: 0 }}
          animate={{ y: 0, opacity: 1 }}
          transition={{ delay: 0.2, duration: 0.5 }}
          className="flex flex-col items-center gap-8 w-full max-w-md"
        >
          <div className="text-center">
            <h1 className="text-3xl font-bold text-[#1A1A1A] mb-2" style={{ fontFamily: 'Poppins, sans-serif' }}>
              Get Started
            </h1>
            <p className="text-[#6B7280] text-lg" style={{ fontFamily: 'Poppins, sans-serif' }}>
              I am a...
            </p>
          </div>

          {/* Role buttons */}
          <div className="flex gap-4 w-full">
            <motion.button
              whileTap={{ scale: 0.95 }}
              onClick={() => setSelected('passenger')}
              className={`flex-1 py-4 px-6 rounded-full border-2 transition-all ${
                selected === 'passenger'
                  ? 'bg-[#8B0000] border-[#8B0000] text-white shadow-lg'
                  : 'bg-white border-[#8B0000] text-[#8B0000]'
              }`}
              style={{ fontFamily: 'Poppins, sans-serif' }}
            >
              <div className="flex flex-col items-center gap-2">
                <User className="w-6 h-6" />
                <span className="font-semibold">Passenger</span>
              </div>
            </motion.button>

            <motion.button
              whileTap={{ scale: 0.95 }}
              onClick={() => setSelected('driver')}
              className={`flex-1 py-4 px-6 rounded-full border-2 transition-all ${
                selected === 'driver'
                  ? 'bg-[#8B0000] border-[#8B0000] text-white shadow-lg'
                  : 'bg-white border-[#8B0000] text-[#8B0000]'
              }`}
              style={{ fontFamily: 'Poppins, sans-serif' }}
            >
              <div className="flex flex-col items-center gap-2">
                <UserCircle className="w-6 h-6" />
                <span className="font-semibold">Driver</span>
              </div>
            </motion.button>
          </div>
        </motion.div>

        {/* Continue button */}
        <motion.button
          initial={{ y: 20, opacity: 0 }}
          animate={{ y: 0, opacity: 1 }}
          transition={{ delay: 0.4, duration: 0.5 }}
          whileTap={{ scale: 0.98 }}
          onClick={handleContinue}
          className="w-full max-w-md bg-[#8B0000] text-white py-4 rounded-full font-semibold shadow-lg hover:bg-[#6D0000] transition-colors"
          style={{ fontFamily: 'Poppins, sans-serif' }}
        >
          Continue as {selected === 'passenger' ? 'Passenger' : 'Driver'}
        </motion.button>
      </div>
    </div>
  );
}
