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
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/75 backdrop-blur-md p-4 animate-in fade-in duration-300 select-none">
      {/* Click outside backdrop */}
      <div className="absolute inset-0" onClick={onClose} />

      {/* Main Promo Dialog matching Flutter TiktokPromoModal */}
      <div className="relative z-10 w-full max-w-[340px] rounded-[24px] overflow-hidden bg-[#0F1117]/95 shadow-[0_12px_40px_rgba(0,0,0,0.85)] flex flex-col">
        {/* Floating Top-Right Close Button */}
        <button
          type="button"
          onClick={onClose}
          className="absolute top-2.5 right-2.5 z-20 w-8 h-8 rounded-full bg-black/60 hover:bg-black/80 active:scale-95 text-white flex items-center justify-center transition-all cursor-pointer"
          aria-label="Close"
        >
          <X className="w-4 h-4 stroke-[2.2]" />
        </button>

        {/* 3:4 Aspect Ratio Banner Artwork */}
        <div
          onClick={handleJoin}
          className="relative w-full aspect-[3/4] cursor-pointer overflow-hidden bg-[#161822]"
        >
          <img
            src="/tiktok_promo_banner.png"
            alt="FreeWatch TikTok Community"
            onError={(e) => {
              (e.target as HTMLImageElement).src =
                "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=500&auto=format&fit=crop&q=80";
            }}
            className="w-full h-full object-cover filter contrast-105 brightness-100"
          />

          {/* Bottom Vignette Gradient */}
          <div className="absolute left-0 right-0 bottom-0 h-16 bg-gradient-to-t from-[#0F1117] to-transparent pointer-events-none" />
        </div>

        {/* Action CTA Buttons */}
        <div className="p-4 pt-2 flex flex-col gap-2">
          {/* Primary TikTok Community CTA Button */}
          <button
            type="button"
            onClick={handleJoin}
            className="w-full h-[46px] rounded-[14px] bg-gradient-to-r from-[#FE2C55] to-[#FF0050] hover:brightness-110 active:scale-[0.98] font-bold text-white text-[14.5px] tracking-tight flex items-center justify-center gap-2 shadow-lg shadow-[#FE2C55]/30 transition-all cursor-pointer"
          >
            <Music className="w-4 h-4 fill-white text-white" />
            <span>Join FreeWatch on TikTok</span>
          </button>

          {/* Continue Watching Button */}
          <button
            type="button"
            onClick={onClose}
            className="w-full h-[38px] rounded-[12px] bg-white/[0.06] hover:bg-white/[0.12] active:scale-[0.98] font-semibold text-[#94A3B8] hover:text-white text-[13px] transition-all cursor-pointer flex items-center justify-center"
          >
            Continue Watching
          </button>
        </div>
      </div>
    </div>
  );
};
