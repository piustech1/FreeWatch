import React from "react";
import { X, Clapperboard, Music } from "lucide-react";

interface AppLaunchBannerModalProps {
  isOpen: boolean;
  onClose: () => void;
  onJoinTikTok?: () => void;
}

export const AppLaunchBannerModal: React.FC<AppLaunchBannerModalProps> = ({
  isOpen,
  onClose,
  onJoinTikTok,
}) => {
  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/85 backdrop-blur-md p-4 animate-in fade-in duration-300 select-none">
      {/* Click outside backdrop */}
      <div className="absolute inset-0" onClick={onClose} />

      {/* Main Banner Card matching Screenshot 2 */}
      <div className="relative z-10 w-full max-w-[340px] sm:max-w-[360px] rounded-[32px] overflow-hidden bg-gradient-to-b from-[#0a0d18] via-[#0c1024] to-[#070913] border border-cyan-400/40 p-5 shadow-[0_0_60px_rgba(6,182,212,0.25)] flex flex-col items-center">
        {/* Top Close Button */}
        <button
          type="button"
          onClick={onClose}
          className="absolute top-4 right-4 z-20 w-7 h-7 rounded-full bg-white/10 hover:bg-white/20 active:scale-95 text-white/80 hover:text-white flex items-center justify-center transition-colors cursor-pointer"
          aria-label="Close"
        >
          <X className="w-4 h-4 stroke-[2.5]" />
        </button>

        {/* 1. Neon Glowing Logo Header */}
        <div className="pt-1 pb-2">
          <h2
            className="text-3xl font-black tracking-tight text-transparent bg-clip-text bg-gradient-to-r from-cyan-300 via-cyan-400 to-sky-300 drop-shadow-[0_0_16px_rgba(0,229,255,0.9)]"
            style={{
              textShadow: "0 0 20px rgba(0,229,255,0.7), 0 0 40px rgba(0,229,255,0.4)",
            }}
          >
            FreeWatch
          </h2>
        </div>

        {/* 2. Visual Artwork: Girl with Headphones & TikTok Neon Atmosphere */}
        <div className="relative w-full h-56 sm:h-60 rounded-2xl overflow-hidden my-2 flex items-center justify-center">
          {/* Animated Waveform Background */}
          <div className="absolute inset-0 flex items-center justify-center pointer-events-none opacity-40">
            <svg className="w-full h-full" viewBox="0 0 200 100" preserveAspectRatio="none">
              <path
                d="M0,50 Q25,20 50,50 T100,50 T150,50 T200,50"
                fill="none"
                stroke="#00E5FF"
                strokeWidth="2"
              />
              <path
                d="M0,50 Q25,80 50,50 T100,50 T150,50 T200,50"
                fill="none"
                stroke="#FF0050"
                strokeWidth="1.5"
              />
            </svg>
          </div>

          {/* Glowing TikTok Neon Symbols in Background */}
          <div className="absolute top-4 left-3 text-cyan-400/80 text-2xl font-black drop-shadow-[0_0_8px_#00E5FF] rotate-[-15deg] pointer-events-none">
            ♪
          </div>
          <div className="absolute top-8 right-4 text-[#FF0050]/80 text-xl font-black drop-shadow-[0_0_8px_#FF0050] rotate-[15deg] pointer-events-none">
            ♫
          </div>
          <div className="absolute bottom-6 right-5 text-cyan-400/60 text-lg pointer-events-none">
            ♪
          </div>

          {/* Official FreeWatch Promo Artwork */}
          <img
            src="/tiktok_promo_banner.png"
            alt="FreeWatch Streaming"
            onError={(e) => {
              (e.target as HTMLImageElement).src = "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=500&auto=format&fit=crop&q=80";
            }}
            className="w-full h-full object-cover object-center filter contrast-105 brightness-100"
          />

          {/* Ambient Inner Gradient */}
          <div className="absolute inset-0 bg-gradient-to-t from-[#0a0d18] via-transparent to-transparent pointer-events-none" />
          <div className="absolute inset-0 bg-gradient-to-b from-[#0a0d18]/60 via-transparent to-transparent pointer-events-none" />
        </div>

        {/* 3. Tech Chamfered Badge: No Payment to Watch Movies Daily */}
        <div className="w-full relative px-1 my-1">
          <div className="relative rounded-2xl bg-gradient-to-r from-slate-200 via-neutral-100 to-slate-200 border-2 border-cyan-400/70 p-3 shadow-[0_0_15px_rgba(0,229,255,0.4)] text-black">
            <div className="flex items-center justify-between">
              <div className="flex-1 text-center pr-1">
                <div className="text-[13px] sm:text-sm font-black tracking-tight leading-tight text-neutral-900">
                  No Payment to
                </div>
                <div className="text-[13px] sm:text-sm font-black tracking-tight leading-tight text-neutral-900">
                  Watch Movies Daily
                </div>
              </div>

              {/* Clapperboard Icon with Play button */}
              <div className="w-8 h-8 rounded-lg bg-cyan-950 border border-cyan-500/50 flex items-center justify-center text-cyan-400 shrink-0 shadow-sm">
                <Clapperboard className="w-4 h-4 text-cyan-300" />
              </div>
            </div>
          </div>

          <div className="text-[11px] font-semibold text-neutral-400 mt-1.5 text-center">
            @FreeWatch
          </div>
        </div>

        {/* 4. Action Buttons */}
        <div className="w-full space-y-2.5 mt-3">
          {/* TikTok Hot Pink Button */}
          <button
            type="button"
            onClick={
              onJoinTikTok ||
              (() => {
                window.open?.("https://tiktok.com", "_blank");
                onClose();
              })
            }
            className="w-full h-12 rounded-2xl bg-gradient-to-r from-[#FF0050] to-[#E50914] hover:brightness-110 active:scale-[0.99] font-black text-white text-sm tracking-wide flex items-center justify-center gap-2 shadow-lg shadow-[#FF0050]/30 transition-all cursor-pointer"
          >
            <Music className="w-4 h-4 fill-white text-white" />
            <span>Join FreeWatch on TikTok</span>
          </button>

          {/* Continue Watching Button */}
          <button
            type="button"
            onClick={onClose}
            className="w-full h-12 rounded-2xl bg-[#161822] hover:bg-[#1f2230] active:scale-[0.99] font-bold text-neutral-300 text-sm tracking-wide transition-all cursor-pointer"
          >
            Continue Watching
          </button>
        </div>
      </div>
    </div>
  );
};
