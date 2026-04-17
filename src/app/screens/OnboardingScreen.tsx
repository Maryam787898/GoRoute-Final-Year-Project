import { useState } from "react";
import { useNavigate } from "react-router";
import { motion, AnimatePresence } from "motion/react";
import { MapPin, Clock, Bell, ChevronRight } from "lucide-react";

const slides = [
  {
    icon: MapPin,
    title: "Know Where Your Bus Is",
    description: "Track your bus in real-time on an interactive map",
    color: "#8B0000",
  },
  {
    icon: Clock,
    title: "Smart Arrival Predictions",
    description: "AI-powered ETA calculations for accurate timing",
    color: "#F5C518",
  },
  {
    icon: Bell,
    title: "Never Miss Your Bus",
    description: "Get instant notifications when your bus approaches",
    color: "#8B0000",
  },
];

export default function OnboardingScreen() {
  const navigate = useNavigate();
  const [currentSlide, setCurrentSlide] = useState(0);

  const handleNext = () => {
    if (currentSlide < slides.length - 1) {
      setCurrentSlide(currentSlide + 1);
    } else {
      navigate("/auth");
    }
  };

  const slide = slides[currentSlide];
  const Icon = slide.icon;

  return (
    <div className="h-full w-full bg-white flex flex-col items-center justify-between px-6 py-12">
      <div className="flex-1 flex flex-col items-center justify-center max-w-md">
        <AnimatePresence mode="wait">
          <motion.div
            key={currentSlide}
            initial={{ opacity: 0, x: 20 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: -20 }}
            transition={{ duration: 0.4 }}
            className="flex flex-col items-center text-center gap-8"
          >
            <motion.div
              initial={{ scale: 0.8 }}
              animate={{ scale: 1 }}
              transition={{ delay: 0.2, type: "spring", stiffness: 200 }}
              className="bg-[#8B0000] rounded-3xl p-12 shadow-2xl"
            >
              <Icon className="w-24 h-24 text-white" strokeWidth={1.5} />
            </motion.div>

            <div className="space-y-4">
              <h2 className="text-3xl font-bold text-[#1A1A1A]" style={{ fontFamily: 'Poppins, sans-serif' }}>
                {slide.title}
              </h2>
              <p className="text-[#6B7280] text-lg leading-relaxed" style={{ fontFamily: 'Poppins, sans-serif' }}>
                {slide.description}
              </p>
            </div>
          </motion.div>
        </AnimatePresence>
      </div>

      {/* Dot indicators */}
      <div className="flex gap-2 mb-8">
        {slides.map((_, index) => (
          <motion.div
            key={index}
            animate={{
              width: index === currentSlide ? 32 : 8,
              backgroundColor: index === currentSlide ? '#8B0000' : '#D1D5DB',
            }}
            className="h-2 rounded-full"
            transition={{ duration: 0.3 }}
          />
        ))}
      </div>

      {/* Next/Get Started button */}
      <motion.button
        whileTap={{ scale: 0.98 }}
        onClick={handleNext}
        className="w-full max-w-md bg-[#8B0000] text-white py-4 rounded-full font-semibold shadow-lg hover:bg-[#6D0000] transition-colors flex items-center justify-center gap-2"
        style={{ fontFamily: 'Poppins, sans-serif' }}
      >
        {currentSlide === slides.length - 1 ? 'Get Started' : 'Next'}
        <ChevronRight className="w-5 h-5" />
      </motion.button>
    </div>
  );
}
