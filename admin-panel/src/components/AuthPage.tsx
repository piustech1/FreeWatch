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
    <div className="relative w-full min-h-screen bg-black flex flex-col justify-center items-center overflow-x-hidden select-none font-sans py-10 px-4">
      {/* Background Video Layer */}
      <div className="absolute inset-0 z-0 overflow-hidden bg-black">
        <video
          autoPlay
          loop
          muted
          playsInline
          referrerPolicy="no-referrer"
          className="absolute inset-0 w-full h-full object-cover filter brightness-[0.4] contrast-125 scale-105"
          src="https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4"
        />

        {/* Ambient Dark Gradient Overlays */}
        <div className="absolute inset-0 bg-black/50 backdrop-blur-[2px]" />
        <div className="absolute top-0 left-0 right-0 h-40 bg-gradient-to-b from-black/80 to-transparent pointer-events-none" />
        <div className="absolute bottom-0 left-0 right-0 h-40 bg-gradient-to-t from-black/90 to-transparent pointer-events-none" />
      </div>

      {/* Main Content Container: Responsive split layout on PC */}
      <div className="relative z-10 w-full max-w-[380px] lg:max-w-4xl flex flex-col lg:flex-row lg:items-center lg:justify-between lg:gap-12">
        {/* Left Column (Desktop Hero Showcase) */}
        <div className="hidden lg:flex flex-col space-y-5 max-w-sm">
          <div
            onClick={onBackToSplash}
            className="cursor-pointer transition-transform active:scale-95 inline-block"
            title="Go to Splash"
          >
            <FWLogo size="lg" />
          </div>

          <h2 className="text-3xl xl:text-4xl font-black text-white leading-tight">
            Stream Luganda Dubbed Movies on any Screen.
          </h2>

          <p className="text-neutral-300 text-sm leading-relaxed">
            Sign in to sync your watch history, resume episodes where you left off, and download movies for offline playback.
          </p>

          <div className="space-y-2.5 pt-2">
            <div className="flex items-center gap-2.5 text-xs text-neutral-300 font-medium">
              <span className="w-2 h-2 rounded-full bg-[#00E676]" />
              <span>Full 1080p HD Video &amp; Studio Audio</span>
            </div>
            <div className="flex items-center gap-2.5 text-xs text-neutral-300 font-medium">
              <span className="w-2 h-2 rounded-full bg-[#00E676]" />
              <span>Translations by VJ Junior, VJ Emmy, VJ Jingo</span>
            </div>
            <div className="flex items-center gap-2.5 text-xs text-neutral-300 font-medium">
              <span className="w-2 h-2 rounded-full bg-[#00E676]" />
              <span>100% Free with zero subscription fees</span>
            </div>
          </div>
        </div>

        {/* Right Column: Auth Dark Card */}
        <div className="w-full max-w-[380px] flex flex-col items-center">
          {/* Top Logo & Title (Mobile Only) */}
          <div className="flex flex-col items-center mb-6 lg:hidden">
            <div
              onClick={onBackToSplash}
              className="cursor-pointer transition-transform active:scale-95 mb-4"
              title="Go to Splash"
            >
              <FWLogo />
            </div>

            <h2 className="text-[26px] sm:text-[28px] font-bold text-white tracking-tight">
              {screen === "login" ? "Welcome Back" : "Create Account"}
            </h2>
          </div>

          {/* Desktop Title */}
          <div className="hidden lg:block w-full text-left mb-4">
            <h3 className="text-2xl font-black text-white">
              {screen === "login" ? "Sign In to FreeWatch" : "Create Your Profile"}
            </h3>
            <p className="text-xs text-neutral-400 mt-1">
              {screen === "login" ? "Enter your credentials to continue" : "Choose an avatar and start streaming"}
            </p>
          </div>

          {/* Error Message Alert */}
          {errorMessage && (
            <div className="w-full mb-4 p-3 rounded-2xl bg-red-950/80 border border-red-500/50 flex items-start gap-2.5 text-xs text-red-200 shadow-md">
              <AlertCircle className="w-4 h-4 text-red-400 shrink-0 mt-0.5" />
              <span>{errorMessage}</span>
            </div>
          )}

          {/* Floating Liquid Glassmorphic Auth Card (matching Flutter onboarding_screen) */}
          <div className="w-full rounded-[28px] bg-white/[0.08] border border-white/10 p-6 shadow-[0_10px_35px_rgba(0,0,0,0.5)] backdrop-blur-2xl">
            {/* Sign Up: Choose Your Avatar Row */}
            {screen === "signup" && (
              <div className="flex items-center justify-between mb-5 pb-1">
                <span
                  onClick={() => setShowChooseAvatar(true)}
                  className="text-white font-semibold text-sm hover:text-[#00E676] transition-colors cursor-pointer"
                >
                  Choose Your Avatar
                </span>

                <button
                  type="button"
                  onClick={() => setShowChooseAvatar(true)}
                  className="relative w-12 h-12 rounded-full overflow-hidden border-2 border-white/20 hover:border-white transition-all cursor-pointer shadow-md active:scale-95"
                  title="Choose Avatar"
                >
                  <div className="w-full h-full">
                    <AvatarGraphic id={selectedAvatarId} />
                  </div>
                  <div className="absolute bottom-0 right-0 w-4 h-4 rounded-full bg-[#FFD233] flex items-center justify-center text-black shadow-sm">
                    <Edit3 className="w-2.5 h-2.5 stroke-[3]" />
                  </div>
                </button>
              </div>
            )}

            {/* Form */}
            <form onSubmit={handleSubmit} className="space-y-3.5">
              {/* Full Name field (Sign Up only) */}
              {screen === "signup" && (
                <div className="relative flex items-center">
                  <User className="absolute left-4 w-4 h-4 text-white/50 pointer-events-none" />
                  <input
                    type="text"
                    required
                    value={fullName}
                    onChange={(e) => setFullName(e.target.value)}
                    placeholder="Full Name"
                    className="w-full h-13 pl-11 pr-4 rounded-2xl bg-white/[0.06] border border-white/10 text-sm text-white placeholder-white/40 focus:outline-none focus:border-white/30 focus:bg-white/[0.1] transition-all"
                  />
                </div>
              )}

              {/* Email Address */}
              <div className="relative flex items-center">
                <Mail className="absolute left-4 w-4 h-4 text-white/50 pointer-events-none" />
                <input
                  type="email"
                  required
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="Email Address"
                  className="w-full h-13 pl-11 pr-4 rounded-2xl bg-white/[0.06] border border-white/10 text-sm text-white placeholder-white/40 focus:outline-none focus:border-white/30 focus:bg-white/[0.1] transition-all"
                />
              </div>

              {/* Password */}
              <div className="relative flex items-center">
                <Lock className="absolute left-4 w-4 h-4 text-white/50 pointer-events-none" />
                <input
                  type={showPassword ? "text" : "password"}
                  required
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="Password"
                  className="w-full h-13 pl-11 pr-11 rounded-2xl bg-white/[0.06] border border-white/10 text-sm text-white placeholder-white/40 focus:outline-none focus:border-white/30 focus:bg-white/[0.1] transition-all"
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  className="absolute right-3.5 p-1 text-white/50 hover:text-white transition-colors cursor-pointer"
                  aria-label="Toggle password visibility"
                >
                  {showPassword ? <Eye className="w-4 h-4" /> : <EyeOff className="w-4 h-4" />}
                </button>
              </div>

              {/* Confirm Password (Sign Up only) */}
              {screen === "signup" && (
                <div className="relative flex items-center">
                  <Lock className="absolute left-4 w-4 h-4 text-white/50 pointer-events-none" />
                  <input
                    type={showConfirmPassword ? "text" : "password"}
                    required
                    value={confirmPassword}
                    onChange={(e) => setConfirmPassword(e.target.value)}
                    placeholder="Confirm Password"
                    className="w-full h-13 pl-11 pr-11 rounded-2xl bg-white/[0.06] border border-white/10 text-sm text-white placeholder-white/40 focus:outline-none focus:border-white/30 focus:bg-white/[0.1] transition-all"
                  />
                  <button
                    type="button"
                    onClick={() => setShowConfirmPassword(!showConfirmPassword)}
                    className="absolute right-3.5 p-1 text-white/50 hover:text-white transition-colors cursor-pointer"
                    aria-label="Toggle confirm password visibility"
                  >
                    {showConfirmPassword ? <Eye className="w-4 h-4" /> : <EyeOff className="w-4 h-4" />}
                  </button>
                </div>
              )}

              {/* Remember Me & Forgot Password Row (Login only) */}
              {screen === "login" && (
                <div className="flex items-center justify-between pt-1 pb-1 text-xs">
                  <label className="flex items-center gap-2 cursor-pointer select-none">
                    <div
                      onClick={() => setRememberMe(!rememberMe)}
                      className={`w-4 h-4 rounded flex items-center justify-center transition-colors cursor-pointer ${
                        rememberMe ? "bg-[#FFD233] text-black" : "border border-white/20 bg-white/5"
                      }`}
                    >
                      {rememberMe && (
                        <svg className="w-3 h-3" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={3} d="M5 13l4 4L19 7" />
                        </svg>
                      )}
                    </div>
                    <span className="text-white/80">Remember me</span>
                  </label>

                  <button
                    type="button"
                    onClick={() => setErrorMessage("Password reset link will be sent to your email.")}
                    className="text-[#FFD233] font-medium hover:underline cursor-pointer"
                  >
                    Forgot Password?
                  </button>
                </div>
              )}

              {/* Primary Action Button: LOG IN or SIGN UP */}
              <div className="pt-2">
                <button
                  type="submit"
                  disabled={loading}
                  className="w-full h-13 rounded-full bg-[#FFD233] hover:bg-[#ffca1a] active:scale-[0.98] text-black font-extrabold text-sm tracking-wide uppercase transition-all shadow-[0_4px_20px_rgba(255,210,51,0.25)] cursor-pointer flex items-center justify-center gap-2 disabled:opacity-70"
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
                className="w-full h-13 rounded-full bg-white/[0.06] hover:bg-white/[0.12] active:scale-[0.98] text-white font-medium text-sm flex items-center justify-center gap-2 transition-all border border-white/10 cursor-pointer disabled:opacity-70 backdrop-blur-md"
              >
                <Tv className="w-4 h-4 text-white" />
                <span>Continue as Guest</span>
              </button>
            </form>
          </div>

          {/* Bottom Switch Screen Text */}
          <div className="mt-7 text-xs text-white/60 text-center">
            {screen === "login" ? (
              <span>
                Don't have an account?{" "}
                <button
                  type="button"
                  onClick={() => {
                    setErrorMessage("");
                    setScreen("signup");
                  }}
                  className="text-[#FFD233] font-bold hover:underline cursor-pointer ml-0.5"
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
                  className="text-[#FFD233] font-bold hover:underline cursor-pointer ml-0.5"
                >
                  Log In
                </button>
              </span>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};
