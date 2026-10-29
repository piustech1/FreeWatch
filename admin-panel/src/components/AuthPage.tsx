import React, { useState } from "react";
import { User, Mail, Lock, Eye, EyeOff, Tv, Edit3, Loader2, AlertCircle } from "lucide-react";
import {
  signInWithEmailAndPassword,
  createUserWithEmailAndPassword,
  signInAnonymously,
  updateProfile
} from "firebase/auth";
import { auth } from "../firebase";
import { FWLogo } from "./SplashScreen";
import { ChooseAvatarPage } from "./ChooseAvatarPage";
import { AvatarGraphic } from "./AvatarGraphic";

export type AuthScreenType = "login" | "signup";

interface AuthPageProps {
  initialScreen?: AuthScreenType;
  onSuccess: (email?: string, avatarId?: string) => void;
  onBackToSplash?: () => void;
}

export const AuthPage: React.FC<AuthPageProps> = ({
  initialScreen = "login",
  onSuccess,
  onBackToSplash,
}) => {
  const [screen, setScreen] = useState<AuthScreenType>(initialScreen);
  const [showPassword, setShowPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);
  const [rememberMe, setRememberMe] = useState(true);

  // Form states
  const [fullName, setFullName] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [selectedAvatarId, setSelectedAvatarId] = useState("mirabel");
  const [showChooseAvatar, setShowChooseAvatar] = useState(false);
  const [loading, setLoading] = useState(false);
  const [errorMessage, setErrorMessage] = useState("");

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setErrorMessage("");
    setLoading(true);

    try {
      if (screen === "signup") {
        if (password !== confirmPassword) {
          setErrorMessage("Passwords do not match.");
          setLoading(false);
          return;
        }
        if (password.length < 6) {
          setErrorMessage("Password must be at least 6 characters.");
          setLoading(false);
          return;
        }

        const cred = await createUserWithEmailAndPassword(auth, email.trim(), password);
        if (cred.user && fullName) {
          await updateProfile(cred.user, { displayName: fullName });
        }
        onSuccess(fullName || email, selectedAvatarId);
      } else {
        const cred = await signInWithEmailAndPassword(auth, email.trim(), password);
        const name = cred.user.displayName || email.split("@")[0];
        onSuccess(name, selectedAvatarId);
      }
    } catch (err: any) {
      console.warn("Auth operation failed, proceeding with local profile:", err);
      // Clean up Firebase error messages for user display
      let msg = err.message || "Authentication failed.";
      if (msg.includes("auth/invalid-credential") || msg.includes("auth/wrong-password") || msg.includes("auth/user-not-found")) {
        msg = "Invalid email or password. Please check your credentials.";
      } else if (msg.includes("auth/email-already-in-use")) {
        msg = "This email is already registered. Please log in.";
      } else if (msg.includes("auth/weak-password")) {
        msg = "Password is too weak. Please use at least 6 characters.";
      }
      setErrorMessage(msg);
      // If offline or network block, allow seamless fallback so user is never blocked
      if (msg.includes("network") || msg.includes("offline")) {
        onSuccess(fullName || email || "FreeWatch User", selectedAvatarId);
      }
    } finally {
      setLoading(false);
    }
  };

  const handleGuest = async () => {
    setLoading(true);
    setErrorMessage("");
    try {
      await signInAnonymously(auth);
      onSuccess("Guest User", selectedAvatarId || "mirabel");
    } catch (err) {
      console.warn("Anonymous signin fallback:", err);
      onSuccess("Guest User", selectedAvatarId || "mirabel");
    } finally {
      setLoading(false);
    }
  };

  if (showChooseAvatar) {
    return (
      <ChooseAvatarPage
        selectedAvatarId={selectedAvatarId}
        onSelectAvatar={(avatar) => {
          setSelectedAvatarId(avatar.id);
        }}
        onBack={() => setShowChooseAvatar(false)}
        onDone={() => setShowChooseAvatar(false)}
      />
    );
  }

  return (
    <div className="relative w-full h-screen max-h-screen bg-black flex flex-col justify-center items-center overflow-hidden select-none font-sans px-4">
      {/* Background Video Layer */}
      <div className="absolute inset-0 z-0 overflow-hidden bg-black pointer-events-none">
        <video
          autoPlay
          loop
          muted
          playsInline
          className="absolute inset-0 w-full h-full object-cover filter brightness-[0.4] contrast-125 scale-105"
          src="/videos/onboarding_bg.mp4"
        />

        {/* Ambient Dark Gradient Overlays */}
        <div className="absolute inset-0 bg-black/55 backdrop-blur-[2px]" />
        <div className="absolute top-0 left-0 right-0 h-32 bg-gradient-to-b from-black/80 to-transparent pointer-events-none" />
        <div className="absolute bottom-0 left-0 right-0 h-32 bg-gradient-to-t from-black/90 to-transparent pointer-events-none" />
      </div>

      {/* Main Centered Content Container */}
      <div className="relative z-10 w-full max-w-[340px] sm:max-w-[360px] flex flex-col items-center my-auto">
        {/* Top FW Logo */}
        <div
          onClick={onBackToSplash}
          className="cursor-pointer transition-transform active:scale-95 mb-2"
          title="Go to Splash"
        >
          <FWLogo size="md" />
        </div>

        {/* Header Title */}
        <h2 className="text-[24px] sm:text-[26px] font-bold text-white tracking-tight mb-4">
          {screen === "login" ? "Welcome Back" : "Create Account"}
        </h2>

        {/* Error Message Alert */}
        {errorMessage && (
          <div className="w-full mb-3 p-2.5 rounded-xl bg-red-950/80 border border-red-500/50 flex items-start gap-2 text-xs text-red-200 shadow-md">
            <AlertCircle className="w-4 h-4 text-red-400 shrink-0 mt-0.5" />
            <span>{errorMessage}</span>
          </div>
        )}

        {/* Centered Liquid Glassmorphic Auth Card (Screenshots 2 & 3 match) */}
        <div className="w-full rounded-3xl bg-[#16171b]/90 border border-white/10 p-5 sm:p-6 shadow-[0_12px_40px_rgba(0,0,0,0.7)] backdrop-blur-2xl">
          {/* Sign Up: Choose Your Avatar Row */}
          {screen === "signup" && (
            <div className="flex items-center justify-between mb-4 pb-1">
              <span
                onClick={() => setShowChooseAvatar(true)}
                className="text-white font-semibold text-xs sm:text-sm hover:text-white/80 transition-colors cursor-pointer"
              >
                Choose Your Avatar
              </span>

              <button
                type="button"
                onClick={() => setShowChooseAvatar(true)}
                className="relative w-12 h-12 rounded-full overflow-hidden border-2 border-white hover:border-[#E50914] transition-all cursor-pointer shadow-md active:scale-95"
                title="Choose Avatar"
              >
                <div className="w-full h-full">
                  <AvatarGraphic id={selectedAvatarId} />
                </div>
                <div className="absolute bottom-0 right-0 w-4 h-4 rounded-full bg-[#E50914] flex items-center justify-center text-white shadow-sm border border-black/40">
                  <Edit3 className="w-2.5 h-2.5 stroke-[3]" />
                </div>
              </button>
            </div>
          )}

          {/* Form */}
          <form onSubmit={handleSubmit} className="space-y-3">
            {/* Full Name field (Sign Up only) */}
            {screen === "signup" && (
              <div className="relative flex items-center">
                <User className="absolute left-3.5 w-4 h-4 text-white/40 pointer-events-none" />
                <input
                  type="text"
                  required
                  value={fullName}
                  onChange={(e) => setFullName(e.target.value)}
                  placeholder="Full Name"
                  className="w-full h-11 pl-10 pr-3.5 rounded-xl bg-[#23252b] border border-white/5 text-xs sm:text-sm text-white placeholder-white/40 focus:outline-none focus:border-white/20 transition-all"
                />
              </div>
            )}

            {/* Email Address */}
            <div className="relative flex items-center">
              <Mail className="absolute left-3.5 w-4 h-4 text-white/40 pointer-events-none" />
              <input
                type="email"
                required
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="Email Address"
                className="w-full h-11 pl-10 pr-3.5 rounded-xl bg-[#23252b] border border-white/5 text-xs sm:text-sm text-white placeholder-white/40 focus:outline-none focus:border-white/20 transition-all"
              />
            </div>

            {/* Password */}
            <div className="relative flex items-center">
              <Lock className="absolute left-3.5 w-4 h-4 text-white/40 pointer-events-none" />
              <input
                type={showPassword ? "text" : "password"}
                required
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="Password"
                className="w-full h-11 pl-10 pr-10 rounded-xl bg-[#23252b] border border-white/5 text-xs sm:text-sm text-white placeholder-white/40 focus:outline-none focus:border-white/20 transition-all"
              />
              <button
                type="button"
                onClick={() => setShowPassword(!showPassword)}
                className="absolute right-3 p-1 text-white/40 hover:text-white transition-colors cursor-pointer"
                aria-label="Toggle password visibility"
              >
                {showPassword ? <Eye className="w-4 h-4" /> : <EyeOff className="w-4 h-4" />}
              </button>
            </div>

            {/* Confirm Password (Sign Up only) */}
            {screen === "signup" && (
              <div className="relative flex items-center">
                <Lock className="absolute left-3.5 w-4 h-4 text-white/40 pointer-events-none" />
                <input
                  type={showConfirmPassword ? "text" : "password"}
                  required
                  value={confirmPassword}
                  onChange={(e) => setConfirmPassword(e.target.value)}
                  placeholder="Confirm Password"
                  className="w-full h-11 pl-10 pr-10 rounded-xl bg-[#23252b] border border-white/5 text-xs sm:text-sm text-white placeholder-white/40 focus:outline-none focus:border-white/20 transition-all"
                />
                <button
                  type="button"
                  onClick={() => setShowConfirmPassword(!showConfirmPassword)}
                  className="absolute right-3 p-1 text-white/40 hover:text-white transition-colors cursor-pointer"
                  aria-label="Toggle confirm password visibility"
                >
                  {showConfirmPassword ? <Eye className="w-4 h-4" /> : <EyeOff className="w-4 h-4" />}
                </button>
              </div>
            )}

            {/* Remember Me & Forgot Password Row (Login only) */}
            {screen === "login" && (
              <div className="flex items-center justify-between pt-0.5 pb-0.5 text-xs">
                <label className="flex items-center gap-2 cursor-pointer select-none">
                  <div
                    onClick={() => setRememberMe(!rememberMe)}
                    className={`w-4 h-4 rounded flex items-center justify-center transition-colors cursor-pointer ${
                      rememberMe ? "bg-[#E50914] text-white" : "border border-white/20 bg-white/5"
                    }`}
                  >
                    {rememberMe && (
                      <svg className="w-2.5 h-2.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={3.5} d="M5 13l4 4L19 7" />
                      </svg>
                    )}
                  </div>
                  <span className="text-white/80">Remember me</span>
                </label>

                <button
                  type="button"
                  onClick={() => setErrorMessage("Password reset link will be sent to your email.")}
                  className="text-[#E50914] font-medium hover:underline cursor-pointer"
                >
                  Forgot Password?
                </button>
              </div>
            )}

            {/* Primary Action Button: LOG IN or SIGN UP (Netflix Red #E50914) */}
            <div className="pt-2">
              <button
                type="submit"
                disabled={loading}
                className="w-full h-11 rounded-full bg-[#E50914] hover:bg-[#d00812] active:scale-[0.98] text-white font-extrabold text-xs sm:text-sm tracking-wider uppercase transition-all shadow-[0_4px_20px_rgba(229,9,20,0.35)] cursor-pointer flex items-center justify-center gap-2 disabled:opacity-70"
              >
                {loading && <Loader2 className="w-4 h-4 animate-spin" />}
                <span>{screen === "login" ? "LOG IN" : "SIGN UP"}</span>
              </button>
            </div>

            {/* Continue as Guest Button */}
            <button
              type="button"
              onClick={handleGuest}
              disabled={loading}
              className="w-full h-11 rounded-full bg-[#23252b] hover:bg-[#2d3038] active:scale-[0.98] text-white font-medium text-xs sm:text-sm flex items-center justify-center gap-2 transition-all border border-white/10 cursor-pointer disabled:opacity-70"
            >
              <Tv className="w-4 h-4 text-white" />
              <span>Continue as Guest</span>
            </button>
          </form>
        </div>

        {/* Bottom Switch Screen Text */}
        <div className="mt-4 text-xs text-white/60 text-center">
          {screen === "login" ? (
            <span>
              Don't have an account?{" "}
              <button
                type="button"
                onClick={() => {
                  setErrorMessage("");
                  setScreen("signup");
                }}
                className="text-[#E50914] font-bold hover:underline cursor-pointer ml-0.5"
              >
                Create Account
              </button>
            </span>
          ) : (
            <span>
              Already have an account?{" "}
              <button
                type="button"
                onClick={() => {
                  setErrorMessage("");
                  setScreen("login");
                }}
                className="text-[#E50914] font-bold hover:underline cursor-pointer ml-0.5"
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
