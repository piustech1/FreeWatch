import React, { useState } from "react";
import { X, Mail, Lock, Phone, ArrowRight, CheckCircle2 } from "lucide-react";
import { FWLogo } from "./SplashScreen";

interface AuthModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSuccess: (userEmail: string) => void;
  initialMode?: "login" | "signup";
}

export const AuthModal: React.FC<AuthModalProps> = ({
  isOpen,
  onClose,
  onSuccess,
  initialMode = "login",
}) => {
  const [mode, setMode] = useState<"login" | "signup">(initialMode);
  const [authMethod, setAuthMethod] = useState<"email" | "phone">("phone");
  const [identifier, setIdentifier] = useState("");
  const [password, setPassword] = useState("");
  const [isLoading, setIsLoading] = useState(false);

  if (!isOpen) return null;

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    setTimeout(() => {
      setIsLoading(false);
      onSuccess(identifier || (authMethod === "phone" ? "+256 700 123 456" : "user@example.com"));
    }, 600);
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/80 backdrop-blur-md animate-in fade-in">
      <div className="absolute inset-0" onClick={onClose} />

      <div className="relative z-10 w-full max-w-md rounded-3xl bg-neutral-900 border border-neutral-800 p-6 sm:p-8 shadow-2xl shadow-black text-white">
        {/* Close Button */}
        <button
          onClick={onClose}
          className="absolute top-5 right-5 p-2 rounded-full bg-white/10 hover:bg-white/20 text-neutral-300 hover:text-white transition-colors"
        >
          <X className="w-4 h-4" />
        </button>

        {/* Brand & Heading */}
        <div className="text-center space-y-2 mb-6">
          <div className="flex justify-center mb-1">
            <FWLogo size="md" />
          </div>
          <h3 className="text-xl sm:text-2xl font-extrabold text-white">
            {mode === "login" ? "Welcome Back" : "Create Account"}
          </h3>
          <p className="text-xs text-neutral-400">
            {mode === "login"
              ? "Sign in to continue watching Ugandan VJ translated movies"
              : "Get unlimited access to thousands of translated blockbusters"}
          </p>
        </div>

        {/* Phone vs Email Toggle */}
        <div className="flex rounded-xl bg-neutral-800/80 p-1 mb-5">
          <button
            type="button"
            onClick={() => setAuthMethod("phone")}
            className={`flex-1 py-1.5 rounded-lg text-xs font-semibold transition-all flex items-center justify-center gap-1.5 ${
              authMethod === "phone"
                ? "bg-[#00E676] text-black shadow-sm"
                : "text-neutral-400 hover:text-white"
            }`}
          >
            <Phone className="w-3.5 h-3.5" />
            <span>Phone Number</span>
          </button>
          <button
            type="button"
            onClick={() => setAuthMethod("email")}
            className={`flex-1 py-1.5 rounded-lg text-xs font-semibold transition-all flex items-center justify-center gap-1.5 ${
              authMethod === "email"
                ? "bg-[#00E676] text-black shadow-sm"
                : "text-neutral-400 hover:text-white"
            }`}
          >
            <Mail className="w-3.5 h-3.5" />
            <span>Email</span>
          </button>
        </div>

        {/* Auth Form */}
        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-xs font-medium text-neutral-300 mb-1.5">
              {authMethod === "phone" ? "Mobile Number (MTN / Airtel)" : "Email Address"}
            </label>
            <div className="relative">
              <input
                type={authMethod === "phone" ? "tel" : "email"}
                value={identifier}
                onChange={(e) => setIdentifier(e.target.value)}
                placeholder={authMethod === "phone" ? "+256 701 234 567" : "name@example.com"}
                className="w-full h-11 px-4 rounded-xl bg-neutral-800/90 border border-neutral-700 focus:border-[#00E676] focus:outline-none text-sm text-white placeholder-neutral-500 transition-colors"
                required
              />
            </div>
          </div>

          <div>
            <div className="flex items-center justify-between mb-1.5">
              <label className="block text-xs font-medium text-neutral-300">Password</label>
              {mode === "login" && (
                <a href="#" className="text-[11px] text-[#00E676] hover:underline">
                  Forgot Password?
                </a>
              )}
            </div>
            <div className="relative">
              <input
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="Enter password"
                className="w-full h-11 px-4 rounded-xl bg-neutral-800/90 border border-neutral-700 focus:border-[#00E676] focus:outline-none text-sm text-white placeholder-neutral-500 transition-colors"
                required
              />
            </div>
          </div>

          <button
            type="submit"
            disabled={isLoading}
            className="w-full h-12 rounded-full bg-[#00E676] hover:bg-[#00c853] text-black font-extrabold text-sm flex items-center justify-center gap-2 transition-all shadow-lg shadow-[#00E676]/20 active:scale-[0.98] disabled:opacity-50 mt-2"
          >
            {isLoading ? (
              <span className="inline-block w-4 h-4 border-2 border-black border-t-transparent rounded-full animate-spin" />
            ) : (
              <>
                <span>{mode === "login" ? "Sign In" : "Create Account"}</span>
                <ArrowRight className="w-4 h-4" />
              </>
            )}
          </button>
        </form>

        {/* Toggle Mode Footer */}
        <div className="text-center mt-5 text-xs text-neutral-400">
          {mode === "login" ? (
            <span>
              Don't have an account?{" "}
              <button
                type="button"
                onClick={() => setMode("signup")}
                className="text-[#00E676] font-semibold hover:underline"
              >
                Sign Up
              </button>
            </span>
          ) : (
            <span>
              Already have an account?{" "}
              <button
                type="button"
                onClick={() => setMode("login")}
                className="text-[#00E676] font-semibold hover:underline"
              >
                Log In
              </button>
            </span>
          )}
        </div>
      </div>
    </div>
  );
};
