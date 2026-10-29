import React, { useState, useEffect } from "react";
import {
  Search as SearchIcon,
  Bell,
  Pause,
  Play,
  Trash2,
  Film,
} from "lucide-react";
import { FreeWatchLogo } from "./HomePage";
import { AvatarGraphic } from "./AvatarGraphic";
import { UserProfileData } from "./EditProfileModal";
import { FloatingBottomNav } from "./FloatingBottomNav";

export interface DownloadItem {
  id: string;
  title: string;
  posterUrl?: string;
  posterBg: string;
  progress: number; // 0 - 100
  isPaused: boolean;
  fileSize: string;
  speed: string;
  isSeries?: boolean;
}

interface DownloadsPageProps {
  onNavigateTab: (tab: "home" | "search" | "favorites" | "downloads" | "profile") => void;
  onLogout?: () => void;
  userProfile?: UserProfileData;
  onSelectMovie?: (movieId: string, isSeries?: boolean, title?: string) => void;
  onNavigateToNotifications?: () => void;
}

export const DownloadsPage: React.FC<DownloadsPageProps> = ({
  onNavigateTab,
  onLogout,
  userProfile,
  onSelectMovie,
  onNavigateToNotifications,
}) => {
  const [downloads, setDownloads] = useState<DownloadItem[]>(() => {
    try {
      const saved = localStorage.getItem("freewatch_downloads");
      if (saved) return JSON.parse(saved);
    } catch {}
    return [];
  });

  // Simulated progress update when active downloads exist
  useEffect(() => {
    if (downloads.length === 0) return;
    const timer = setInterval(() => {
      setDownloads((prev) =>
        prev.map((item) => {
          if (!item.isPaused && item.progress < 100) {
            const nextProgress = Math.min(100, item.progress + 1);
            return {
              ...item,
              progress: nextProgress,
            };
          }
          return item;
        })
      );
    }, 2500);

    return () => clearInterval(timer);
  }, [downloads.length]);

  const handleTogglePause = (id: string, e: React.MouseEvent) => {
    e.stopPropagation();
    setDownloads((prev) =>
      prev.map((item) =>
        item.id === id ? { ...item, isPaused: !item.isPaused } : item
      )
    );
  };

  const handleDelete = (id: string, e: React.MouseEvent) => {
    e.stopPropagation();
    setDownloads((prev) => {
      const next = prev.filter((item) => item.id !== id);
      try {
        localStorage.setItem("freewatch_downloads", JSON.stringify(next));
      } catch {}
      return next;
    });
  };

  const handleClearAll = () => {
    setDownloads([]);
    try {
      localStorage.removeItem("freewatch_downloads");
    } catch {}
  };

  return (
    <div className="w-full min-h-screen bg-black text-white font-sans flex flex-col pb-24 select-none">
      {/* 1. TOP HEADER BAR */}
      <header className="sticky top-0 z-40 w-full bg-black/90 backdrop-blur-md px-4 py-3 flex items-center justify-between border-b border-white/5">
        <FreeWatchLogo />

        <div className="flex items-center gap-4">
          <button
            type="button"
            onClick={() => onNavigateTab("search")}
            className="p-1 text-white hover:text-[#00E676] transition-colors cursor-pointer"
            aria-label="Search"
          >
            <SearchIcon className="w-5 h-5 stroke-[2.2]" />
          </button>

          <button
            type="button"
            onClick={onNavigateToNotifications}
            className="relative p-1 text-white hover:text-[#00E676] transition-colors cursor-pointer"
            aria-label="Notifications"
          >
            <Bell className="w-5 h-5 stroke-[2.2]" />
            <span className="absolute -top-1 -right-1.5 w-4 h-4 rounded-full bg-[#E50914] text-[10px] font-bold text-white flex items-center justify-center">
              39
            </span>
          </button>

          <button
            type="button"
            onClick={() => onNavigateTab("profile")}
            title="Account Profile"
            className="w-8 h-8 rounded-full overflow-hidden border border-white/20 active:scale-95 transition-transform cursor-pointer"
          >
            <AvatarGraphic id={userProfile?.avatarId || "mirabel"} />
          </button>
        </div>
      </header>

      {/* 2. SUBHEADER: DOWNLOADED MOVIES TITLE & CLEAR ALL */}
      <div className="max-w-6xl mx-auto w-full px-4 lg:px-8 pt-4 pb-3 flex items-center justify-between">
        <div className="flex items-center gap-2.5">
          <div className="text-[#E50914] flex items-center justify-center">
            <svg
              className="w-5 h-5"
              viewBox="0 0 24 24"
              fill="none"
              stroke="#E50914"
              strokeWidth="2.5"
              strokeLinecap="round"
              strokeLinejoin="round"
            >
              <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" />
              <polyline points="7 10 12 15 17 10" />
              <line x1="12" y1="15" x2="12" y2="3" />
            </svg>
          </div>
          <h1 className="text-base font-extrabold text-white tracking-wider uppercase">
            DOWNLOADED MOVIES ({downloads.length})
          </h1>
        </div>

        {downloads.length > 0 && (
          <button
            type="button"
            onClick={handleClearAll}
            className="text-xs font-semibold text-neutral-400 hover:text-white transition-colors cursor-pointer"
          >
            Clear all
          </button>
        )}
      </div>

      {/* 3. DOWNLOADS LIST CONTAINER */}
      <div className="max-w-6xl mx-auto w-full px-4 lg:px-8 space-y-3.5 flex-1">
        {downloads.map((item) => (
          <div
            key={item.id}
            onClick={() => onSelectMovie?.(item.id, item.isSeries, item.title)}
            className="rounded-2xl bg-[#17171a] border border-white/5 p-3 flex items-center justify-between gap-3 shadow-md active:scale-[0.99] transition-transform cursor-pointer group"
          >
            {/* Left: Thumbnail poster preview */}
            <div
              className={`w-14 sm:w-16 aspect-[3/4] rounded-xl overflow-hidden bg-gradient-to-t ${item.posterBg} border border-white/10 shrink-0 relative flex items-center justify-center`}
            >
              {item.posterUrl ? (
                <img
                  src={item.posterUrl}
                  alt={item.title}
                  className="w-full h-full object-cover"
                />
              ) : (
                <Film className="w-5 h-5 text-white/40" />
              )}
            </div>

            {/* Middle: Title, progress bar, file size & speed */}
            <div className="flex-1 min-w-0 pr-2">
              <div className="flex items-center justify-between mb-1.5">
                <h3 className="text-xs sm:text-sm font-bold text-white truncate group-hover:text-[#00E676] transition-colors">
                  {item.title}
                </h3>
                <span className="text-[11px] font-semibold text-neutral-400 ml-2">
                  {item.progress}%
                </span>
              </div>

              {/* Progress Track */}
              <div className="w-full h-1.5 rounded-full bg-neutral-800 overflow-hidden relative">
                <div
                  className={`h-full transition-all duration-300 ${
                    item.isPaused ? "bg-amber-400" : "bg-[#00E676]"
                  }`}
                  style={{ width: `${item.progress}%` }}
                />
              </div>

              {/* Bottom detail row */}
              <div className="flex items-center justify-between text-[10px] text-neutral-400 font-medium mt-1.5">
                <span>{item.fileSize}</span>
                <span>{item.isPaused ? "Paused" : item.speed}</span>
              </div>
            </div>

            {/* Right: Controls (Pause/Play & Delete) */}
            <div className="flex items-center gap-1.5 shrink-0">
              <button
                type="button"
                onClick={(e) => handleTogglePause(item.id, e)}
                title={item.isPaused ? "Resume" : "Pause"}
                className="p-1.5 rounded-full bg-white/5 hover:bg-white/15 text-white transition-colors cursor-pointer"
              >
                {item.isPaused ? (
                  <Play className="w-4 h-4 fill-white" />
                ) : (
                  <Pause className="w-4 h-4 fill-white" />
                )}
              </button>

              <button
                type="button"
                onClick={(e) => handleDelete(item.id, e)}
                title="Delete"
                className="p-1.5 text-neutral-400 hover:text-red-400 transition-colors cursor-pointer"
              >
                <Trash2 className="w-4 h-4 stroke-[2]" />
              </button>
            </div>
          </div>
        ))}

        {/* Empty State with authentic SVG */}
        {downloads.length === 0 && (
          <div className="flex flex-col items-center justify-center pt-24 pb-12 text-center px-4">
            <div className="w-36 h-36 mb-6 flex items-center justify-center">
              <img
                src="/assets/images/empty_downloads.svg"
                alt="Empty Downloads"
                className="w-full h-full object-contain filter drop-shadow-[0_4px_20px_rgba(0,0,0,0.8)]"
                onError={(e) => {
                  (e.target as HTMLImageElement).style.display = "none";
                }}
              />
            </div>
            <h2 className="text-xl font-black text-white mb-2">No Downloads Yet</h2>
            <p className="text-xs text-neutral-400 max-w-xs mb-6 leading-relaxed">
              Downloaded movies and series will appear here for fast offline playback with no buffering.
            </p>
            <button
              type="button"
              onClick={() => onNavigateTab("home")}
              className="px-7 py-3.5 rounded-full bg-[#00E676] hover:bg-[#00c853] text-black font-extrabold text-xs uppercase tracking-wider active:scale-95 transition-all shadow-lg shadow-[#00E676]/25 cursor-pointer"
            >
              Browse Movies
            </button>
          </div>
        )}
      </div>

      {/* 4. FLOATING CURVED BOTTOM NAVIGATION PILL */}
      <FloatingBottomNav activeTab="downloads" onNavigateTab={onNavigateTab} />
    </div>
  );
};
