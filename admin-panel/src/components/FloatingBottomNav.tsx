import React from "react";
import { Home, Search, Heart, Download, User } from "lucide-react";

export type NavTabType = "home" | "search" | "favorites" | "downloads" | "profile";

interface FloatingBottomNavProps {
  activeTab?: NavTabType;
  onNavigateTab?: (tab: NavTabType) => void;
  className?: string;
}

export const FloatingBottomNav: React.FC<FloatingBottomNavProps> = ({
  activeTab = "home",
  onNavigateTab,
  className = "",
}) => {
  const tabs: { id: NavTabType; label: string; icon: React.FC<{ className?: string }> }[] = [
    { id: "home", label: "Home", icon: Home },
    { id: "search", label: "Search", icon: Search },
    { id: "favorites", label: "Favorites", icon: Heart },
    { id: "downloads", label: "Downloads", icon: Download },
    { id: "profile", label: "Profile", icon: User },
  ];

  return (
    <nav
      className={`lg:hidden fixed bottom-4 left-4 right-4 max-w-md mx-auto z-50 rounded-full bg-[#0e0e11]/85 backdrop-blur-2xl border border-white/10 shadow-[0_8px_32px_rgba(0,0,0,0.65)] py-2 px-5 flex items-center justify-around select-none transition-all ${className}`}
      aria-label="Mobile Navigation"
    >
      {tabs.map((tab) => {
        const Icon = tab.icon;
        const isActive = activeTab === tab.id;
        return (
          <button
            key={tab.id}
            type="button"
            onClick={() => onNavigateTab?.(tab.id)}
            className="flex flex-col items-center justify-center gap-1 cursor-pointer transition-all active:scale-90 group px-2 py-0.5"
            aria-label={tab.label}
          >
            <div className="relative flex items-center justify-center">
              <Icon
                className={`w-5 h-5 transition-colors stroke-[2.2] ${
                  isActive
                    ? "text-[#00E676] drop-shadow-[0_0_8px_rgba(0,230,118,0.5)]"
                    : "text-neutral-400 group-hover:text-white"
                }`}
              />
              {isActive && (
                <span className="absolute -bottom-1.5 w-1 h-1 rounded-full bg-[#00E676] shadow-[0_0_6px_#00E676]" />
              )}
            </div>
            <span
              className={`text-[10px] font-semibold transition-colors tracking-tight ${
                isActive ? "text-[#00E676]" : "text-neutral-400 group-hover:text-white"
              }`}
            >
              {tab.label}
            </span>
          </button>
        );
      })}
    </nav>
  );
};
