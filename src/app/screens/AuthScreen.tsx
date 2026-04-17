import { useState } from "react";
import { useNavigate } from "react-router";
import { motion } from "motion/react";
import { Mail, Lock, User as UserIcon, Eye, EyeOff } from "lucide-react";
import { useApp } from "../contexts/AppContext";

export default function AuthScreen() {
  const navigate = useNavigate();
  const { selectedRole, setUser } = useApp();
  const [isSignIn, setIsSignIn] = useState(true);
  const [showPassword, setShowPassword] = useState(false);
  const [loading, setLoading] = useState(false);

  const [formData, setFormData] = useState({
    name: "",
    email: "",
    password: "",
    confirmPassword: "",
  });

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);

    // Simulate authentication
    setTimeout(() => {
      setUser({
        id: "user-123",
        name: formData.name || "Demo User",
        email: formData.email,
        role: selectedRole,
      });
      setLoading(false);

      if (selectedRole === 'passenger') {
        navigate("/passenger/home");
      } else {
        navigate("/driver/dashboard");
      }
    }, 1500);
  };

  return (
    <div className="h-full w-full bg-white flex flex-col">
      {/* App bar */}
      <div className="bg-[#8B0000] px-6 py-4 shadow-md">
        <h2 className="text-white text-xl font-semibold" style={{ fontFamily: 'Poppins, sans-serif' }}>
          {isSignIn ? 'Sign In' : 'Create Account'}
        </h2>
      </div>

      <div className="flex-1 overflow-auto px-6 py-8">
        <div className="max-w-md mx-auto">
          {/* Tab toggle */}
          <div className="flex gap-2 bg-gray-100 p-1 rounded-full mb-8">
            <button
              onClick={() => setIsSignIn(true)}
              className={`flex-1 py-3 rounded-full font-semibold transition-all ${
                isSignIn ? 'bg-[#8B0000] text-white shadow-md' : 'text-[#6B7280]'
              }`}
              style={{ fontFamily: 'Poppins, sans-serif' }}
            >
              Sign In
            </button>
            <button
              onClick={() => setIsSignIn(false)}
              className={`flex-1 py-3 rounded-full font-semibold transition-all ${
                !isSignIn ? 'bg-[#8B0000] text-white shadow-md' : 'text-[#6B7280]'
              }`}
              style={{ fontFamily: 'Poppins, sans-serif' }}
            >
              Register
            </button>
          </div>

          <form onSubmit={handleSubmit} className="space-y-5">
            {!isSignIn && (
              <motion.div
                initial={{ opacity: 0, height: 0 }}
                animate={{ opacity: 1, height: 'auto' }}
                exit={{ opacity: 0, height: 0 }}
              >
                <label className="block text-sm font-medium text-[#1A1A1A] mb-2" style={{ fontFamily: 'Poppins, sans-serif' }}>
                  Full Name
                </label>
                <div className="relative">
                  <UserIcon className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-[#6B7280]" />
                  <input
                    type="text"
                    value={formData.name}
                    onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                    className="w-full pl-12 pr-4 py-3 border-2 border-gray-200 rounded-xl focus:border-[#8B0000] focus:outline-none transition-colors"
                    placeholder="Enter your name"
                    style={{ fontFamily: 'Poppins, sans-serif' }}
                    required={!isSignIn}
                  />
                </div>
              </motion.div>
            )}

            <div>
              <label className="block text-sm font-medium text-[#1A1A1A] mb-2" style={{ fontFamily: 'Poppins, sans-serif' }}>
                Email
              </label>
              <div className="relative">
                <Mail className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-[#6B7280]" />
                <input
                  type="email"
                  value={formData.email}
                  onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                  className="w-full pl-12 pr-4 py-3 border-2 border-gray-200 rounded-xl focus:border-[#8B0000] focus:outline-none transition-colors"
                  placeholder="Enter your email"
                  style={{ fontFamily: 'Poppins, sans-serif' }}
                  required
                />
              </div>
            </div>

            <div>
              <label className="block text-sm font-medium text-[#1A1A1A] mb-2" style={{ fontFamily: 'Poppins, sans-serif' }}>
                Password
              </label>
              <div className="relative">
                <Lock className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-[#6B7280]" />
                <input
                  type={showPassword ? "text" : "password"}
                  value={formData.password}
                  onChange={(e) => setFormData({ ...formData, password: e.target.value })}
                  className="w-full pl-12 pr-12 py-3 border-2 border-gray-200 rounded-xl focus:border-[#8B0000] focus:outline-none transition-colors"
                  placeholder="Enter your password"
                  style={{ fontFamily: 'Poppins, sans-serif' }}
                  required
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  className="absolute right-4 top-1/2 -translate-y-1/2 text-[#6B7280]"
                >
                  {showPassword ? <EyeOff className="w-5 h-5" /> : <Eye className="w-5 h-5" />}
                </button>
              </div>
            </div>

            {!isSignIn && (
              <motion.div
                initial={{ opacity: 0, height: 0 }}
                animate={{ opacity: 1, height: 'auto' }}
                exit={{ opacity: 0, height: 0 }}
              >
                <label className="block text-sm font-medium text-[#1A1A1A] mb-2" style={{ fontFamily: 'Poppins, sans-serif' }}>
                  Confirm Password
                </label>
                <div className="relative">
                  <Lock className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-[#6B7280]" />
                  <input
                    type="password"
                    value={formData.confirmPassword}
                    onChange={(e) => setFormData({ ...formData, confirmPassword: e.target.value })}
                    className="w-full pl-12 pr-4 py-3 border-2 border-gray-200 rounded-xl focus:border-[#8B0000] focus:outline-none transition-colors"
                    placeholder="Confirm your password"
                    style={{ fontFamily: 'Poppins, sans-serif' }}
                    required={!isSignIn}
                  />
                </div>
              </motion.div>
            )}

            <motion.button
              whileTap={{ scale: 0.98 }}
              type="submit"
              disabled={loading}
              className="w-full bg-[#8B0000] text-white py-4 rounded-full font-semibold shadow-lg hover:bg-[#6D0000] transition-colors disabled:opacity-50"
              style={{ fontFamily: 'Poppins, sans-serif' }}
            >
              {loading ? 'Loading...' : (isSignIn ? 'Sign In' : 'Create Account')}
            </motion.button>
          </form>

          {isSignIn && (
            <motion.div
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.2 }}
              className="mt-6"
            >
              <div className="relative my-6">
                <div className="absolute inset-0 flex items-center">
                  <div className="w-full border-t border-gray-200" />
                </div>
                <div className="relative flex justify-center text-sm">
                  <span className="px-4 bg-white text-[#6B7280]" style={{ fontFamily: 'Poppins, sans-serif' }}>
                    Or continue with
                  </span>
                </div>
              </div>

              <button
                type="button"
                className="w-full border-2 border-gray-200 py-3 rounded-full font-semibold hover:bg-gray-50 transition-colors flex items-center justify-center gap-3"
                style={{ fontFamily: 'Poppins, sans-serif' }}
              >
                <svg className="w-5 h-5" viewBox="0 0 24 24">
                  <path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"/>
                  <path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"/>
                  <path fill="#FBBC05" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"/>
                  <path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"/>
                </svg>
                Google Sign In
              </button>
            </motion.div>
          )}
        </div>
      </div>
    </div>
  );
}
