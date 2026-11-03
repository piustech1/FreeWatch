import React from "react";
import { X, Music } from "lucide-react";

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

  const handleJoin = () => {
    try {
      localStorage.setItem("has_clicked_join_community_v1", "true");
    } catch {}
    if (onJoinTikTok) {
      onJoinTikTok();
    } else {
      window.open?.("https://www.tiktok.com/@freewatchmoviesug?_r=1&_t=ZS-9AV8GRTNGfi", "_blank");
      onClose();
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/80 backdrop-blur-md p-4 animate-in fade-in duration-300 select-none">
      {/* Click outside backdrop */}
      <div className="absolute inset-0" onClick={onClose} />

      {/* Main Promo Dialog: Responsive Portrait on Mobile, Elegant Landscape on PC */}
      <div className="relative z-10 w-full max-w-[340px] sm:max-w-[580px] rounded-[24px] overflow-hidden bg-[#0F1117] border border-white/10 shadow-[0_16px_50px_rgba(0,0,0,0.9)] flex flex-col sm:flex-row">
        {/* Floating Top-Right Close Button */}
        <button
          type="button"
          onClick={onClose}
          className="absolute top-3 right-3 z-30 w-8 h-8 rounded-full bg-black/60 hover:bg-black/90 active:scale-95 text-white/80 hover:text-white flex items-center justify-center transition-all cursor-pointer backdrop-blur-md border border-white/10"
          aria-label="Close"
        >
          <X className="w-4 h-4 stroke-[2.2]" />
        </button>

        {/* Banner Artwork: 3:4 on Mobile, Full-Height Left Column on PC */}
        <div
          onClick={handleJoin}
          className="relative w-full sm:w-[240px] aspect-[3/4] sm:aspect-auto cursor-pointer overflow-hidden bg-[#161822] shrink-0"
        >
          <img
            src="/tiktok_promo_banner.png"
            alt="FreeWatch TikTok Community"
            onError={(e) => {
              (e.target as HTMLImageElement).src =
                "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=500&auto=format&fit=crop&q=80";
            }}
            className="w-full h-full object-cover filter contrast-105 brightness-100 hover:scale-105 transition-transform duration-500"
          />

          {/* Vignette Gradients */}
          <div className="absolute inset-0 bg-gradient-to-t from-[#0F1117] via-transparent to-transparent sm:hidden pointer-events-none" />
          <div className="hidden sm:block absolute inset-0 bg-gradient-to-r from-transparent via-transparent to-[#0F1117] pointer-events-none" />
        </div>

        {/* Content & Actions: Below artwork on Mobile, Right Column on PC */}
        <div className="p-5 sm:p-6 flex-1 flex flex-col justify-between">
          <div>
            <h3 className="text-xl sm:text-2xl font-black text-white leading-tight tracking-tight mb-2">
              Join FreeWatch on TikTok
            </h3>

            <p className="text-xs sm:text-[13px] text-neutral-300 leading-relaxed font-normal mb-5">
              Get instant updates on the newest Luganda dubbed blockbusters &amp; daily movie releases.
            </p>
          </div>

          {/* CTA Buttons matching clean Flutter layout */}
          <div className="flex flex-col gap-2.5">
            {/* Primary TikTok Community CTA Button */}
            <button
              type="button"
              onClick={handleJoin}
              className="w-full h-[46px] rounded-[14px] bg-gradient-to-r from-[#FE2C55] via-[#FF0050] to-[#E50914] hover:brightness-110 active:scale-[0.98] font-black text-white text-[14px] tracking-wide flex items-center justify-center gap-2 shadow-lg shadow-[#FE2C55]/30 transition-all cursor-pointer"
            >
              <Music className="w-4 h-4 fill-white text-white" />
              <span>Join TikTok Community</span>
            </button>

            {/* Continue Watching Button */}
            <button
              type="button"
              onClick={onClose}
              className="w-full h-[38px] rounded-[12px] bg-white/[0.05] hover:bg-white/[0.1] active:scale-[0.98] font-semibold text-neutral-400 hover:text-white text-[12.5px] transition-all cursor-pointer flex items-center justify-center"
            >
              Continue to FreeWatch
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};
