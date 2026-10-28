import React, { useState } from "react";

interface SplashScreenProps {
  onGetStarted: () => void;
  onLogIn: () => void;
}

export const FWLogo: React.FC<{ size?: "sm" | "md" | "lg"; className?: string }> = ({
  size = "md",
  className = "",
}) => {
  const sizeClass = size === "sm" ? "text-[20px]" : size === "lg" ? "text-[32px]" : "text-[26px]";
  return (
    <div className={`font-black tracking-tighter inline-flex items-center select-none ${sizeClass} leading-none ${className}`}>
      <span className="text-white">F</span>
      <span className="text-[#00E676]">W</span>
    </div>
  );
};

export const SplashScreen: React.FC<SplashScreenProps> = ({ onGetStarted, onLogIn }) => {
  const [activeSlide, setActiveSlide] = useState(0);

  return (
    <div className="relative w-full min-h-screen bg-black flex flex-col justify-between overflow-hidden select-none font-sans">
      {/* Background Video Layer */}
      <div className="absolute inset-0 z-0 overflow-hidden bg-black">
        <video
          autoPlay
          loop
          muted
          playsInline
          className="absolute inset-0 w-full h-full object-cover filter brightness-[0.4] contrast-125 scale-105"
          src="https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4"
        />

        {/* Ambient Dark Gradient Overlays */}
        <div className="absolute inset-0 bg-black/40 backdrop-blur-[1px]" />
        <div className="absolute top-0 left-0 right-0 h-40 bg-gradient-to-b from-black/80 via-black/40 to-transparent pointer-events-none" />
        <div className="absolute bottom-0 left-0 right-0 h-[460px] bg-gradient-to-t from-black via-black/95 via-45% to-transparent pointer-events-none" />
      </div>

      {/* Top Bar: FW on left, Log In on right */}
      <header className="relative z-10 w-full max-w-6xl mx-auto flex items-center justify-between px-6 pt-10 sm:pt-12">
        <div className="flex items-center gap-3">
          <FWLogo />
          <div className="hidden lg:flex items-center gap-2 px-3 py-1 rounded-full bg-white/5 border border-white/10 text-xs font-bold text-neutral-300">
            <span className="w-2 h-2 rounded-full bg-[#00E676] animate-pulse" />
            <span>PC Web &amp; TV Cinema Edition</span>
          </div>
        </div>

        <button
          onClick={onLogIn}
          className="px-5 py-2 rounded-full bg-[#2b2b2b]/80 hover:bg-[#383838] active:scale-95 transition-all text-sm font-medium text-white backdrop-blur-md border border-white/5 cursor-pointer"
        >
          Log In
        </button>
      </header>

      {/* Main Content Area: Responsive split layout on PC */}
      <div className="relative z-10 w-full max-w-6xl mx-auto px-6 py-10 flex flex-col lg:flex-row lg:items-center lg:justify-between gap-10">
        {/* Left Column (Desktop Showcase) */}
        <div className="hidden lg:flex flex-col space-y-4 max-w-lg">
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-[#581c87]/60 border border-purple-400/30 text-purple-200 text-xs font-extrabold tracking-wider uppercase">
            <span>✨ Uganda&apos;s #1 Dubbed Streaming Hub</span>
          </div>

          <h2 className="text-4xl xl:text-5xl font-black text-white leading-tight tracking-tight">
            Watch the world&apos;s greatest movies in <span className="text-[#00E676]">Luganda</span>.
          </h2>

          <p className="text-neutral-300 text-sm leading-relaxed">
            Experience premium blockbusters, Hollywood hits, Korean dramas, Indian action, and anime with legendary translations from VJ Junior, VJ Emmy, VJ Jingo, VJ Isma Pro, and more.
          </p>

          <div className="flex items-center gap-4 pt-2">
            <div className="px-4 py-2.5 rounded-2xl bg-white/5 border border-white/10 text-center">
              <div className="text-xl font-black text-white">3,200+</div>
              <div className="text-[11px] text-neutral-400 font-medium">Luganda Movies</div>
            </div>
            <div className="px-4 py-2.5 rounded-2xl bg-white/5 border border-white/10 text-center">
              <div className="text-xl font-black text-[#00E676]">37+</div>
              <div className="text-[11px] text-neutral-400 font-medium">Famous VJs</div>
            </div>
            <div className="px-4 py-2.5 rounded-2xl bg-white/5 border border-white/10 text-center">
              <div className="text-xl font-black text-[#00E5FF]">1080p</div>
              <div className="text-[11px] text-neutral-400 font-medium">Ultra Crisp Video</div>
            </div>
          </div>
        </div>

        {/* Right / Bottom Card Area: Exact typography, pagination pill, and Get Started CTA */}
        <div className="w-full max-w-md space-y-4 bg-black/40 lg:bg-[#121216]/80 lg:border lg:border-white/10 lg:p-8 lg:rounded-3xl lg:backdrop-blur-xl">
          {/* Headlines */}
          <div className="space-y-2">
            <h1 className="text-[28px] sm:text-[32px] font-extrabold text-white leading-[1.18] tracking-tight">
              The greatest stories,
              <br />
              all in one place.
            </h1>

            <p className="text-[13.5px] sm:text-[14px] text-neutral-300 leading-snug font-normal max-w-sm">
              Unlimited streaming for movies, series &amp; exclusive hits translated by top Ugandan VJs.
            </p>
          </div>

          {/* Pagination Indicator */}
          <div className="flex items-center gap-1.5 pt-1 pb-1">
            <button
              onClick={() => setActiveSlide(0)}
              className={`transition-all duration-200 rounded-full ${
                activeSlide === 0
                  ? "w-6 h-1.5 bg-[#00E676]"
                  : "w-1.5 h-1.5 bg-neutral-600 hover:bg-neutral-500"
              }`}
              aria-label="Slide 1"
            />
            <button
              onClick={() => setActiveSlide(1)}
              className={`transition-all duration-200 rounded-full ${
                activeSlide === 1
                  ? "w-6 h-1.5 bg-[#00E676]"
                  : "w-1.5 h-1.5 bg-neutral-600 hover:bg-neutral-500"
              }`}
              aria-label="Slide 2"
            />
          </div>

          {/* Get Started Button */}
          <button
            onClick={onGetStarted}
            className="w-full h-[52px] sm:h-14 rounded-full bg-[#00E676] hover:bg-[#00c853] text-black font-extrabold text-[15px] sm:text-base flex items-center justify-center transition-all duration-150 active:scale-[0.98] cursor-pointer shadow-lg shadow-[#00E676]/20"
          >
            Get Started
          </button>
        </div>
      </div>
    </div>
  );
};
