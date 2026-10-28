import React, { useState, useEffect } from "react";
import {
  Search as SearchIcon,
  Bell,
  Download,
  Pause,
  Play,
  Trash2,
  Home,
  Heart,
  User as UserIcon,
  Film,
} from "lucide-react";
import { FreeWatchLogo } from "./HomePage";

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
  onSelectMovie?: (movieId: string, isSeries?: boolean, title?: string) => void;
  onNavigateToNotifications?: () => void;
}

export const DownloadsPage: React.FC<DownloadsPageProps> = ({
  onNavigateTab,
  onLogout,
  onSelectMovie,
  onNavigateToNotifications,
}) => {
  // Downloads state matching Screenshot_20261028-215736_3c8b88b9.png
  const [downloads, setDownloads] = useState<DownloadItem[]>([
    {
      id: "mirzapur-4",
      title: "Mirzapur 4",
      posterBg: "from-amber-950 via-orange-950 to-black",
      progress: 2,
      isPaused: false,
      fileSize: "1.4 GB",
      speed: "3.2 MB/s",
      isSeries: true,
    },
  ]);

  // Subtle simulated progress update when not paused
  useEffect(() => {
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
  }, []);

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
    setDownloads((prev) => prev.filter((item) => item.id !== id));
  };

  const handleClearAll = () => {
    setDownloads([]);
  };

  const handleRestoreSample = () => {
    setDownloads([
      {
        id: "mirzapur-4",
        title: "Mirzapur 4",
        posterBg: "from-amber-950 via-orange-950 to-black",
        progress: 2,
        isPaused: false,
        fileSize: "1.4 GB",
        speed: "3.2 MB/s",
        isSeries: true,
      },
    ]);
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
            <img
              src="https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100&auto=format&fit=crop&q=80"
              alt="Profile"
              className="w-full h-full object-cover"
            />
          </button>
        </div>
      </header>

      {/* 2. SUBHEADER: DOWNLOADED MOVIES TITLE & CLEAR ALL */}
      <div className="max-w-6xl mx-auto w-full px-4 lg:px-8 pt-4 pb-3 flex items-center justify-between">
        <div className="flex items-center gap-2.5">
          {/* Red Download Tray Icon matching screenshot */}
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

          <h1 className="text-base sm:text-lg font-black text-white tracking-tight">
            Downloaded Movies ({downloads.length})
          </h1>
        </div>

        {downloads.length > 0 && (
          <button
            type="button"
            onClick={handleClearAll}
            className="text-xs font-semibold text-neutral-400 hover:text-white transition-colors cursor-pointer"
          >
            Clear All
          </button>
        )}
      </div>

      {/* DESKTOP STORAGE & STATS WIDGET */}
      <div className="hidden lg:grid grid-cols-3 gap-4 max-w-6xl mx-auto w-full px-4 lg:px-8 mb-4">
        <div className="rounded-2xl bg-[#111114] border border-white/5 p-4 flex flex-col justify-between">
          <div className="text-xs text-neutral-400 font-medium">FreeWatch Storage</div>
          <div className="text-xl font-black text-white mt-1">1.4 GB Used</div>
          <div className="w-full h-1.5 bg-neutral-800 rounded-full mt-2 overflow-hidden">
            <div className="w-[12%] h-full bg-[#00E676] rounded-full" />
          </div>
          <div className="text-[10px] text-neutral-400 mt-1.5">54.2 GB free on local device</div>
        </div>

        <div className="rounded-2xl bg-[#111114] border border-white/5 p-4 flex flex-col justify-between">
          <div className="text-xs text-neutral-400 font-medium">Download Quality</div>
          <div className="text-base font-black text-white mt-1">1080p FHD Cinema</div>
          <div className="text-[11px] text-[#00E676] font-semibold mt-1">Luganda Dubbed Audio Included</div>
          <div className="text-[10px] text-neutral-400 mt-1">Smart auto-download next episode: ON</div>
        </div>

        <div className="rounded-2xl bg-[#111114] border border-white/5 p-4 flex flex-col justify-between">
          <div className="text-xs text-neutral-400 font-medium">Offline Playback</div>
          <div className="text-base font-black text-white mt-1">Airplane Mode Ready</div>
          <div className="text-[11px] text-sky-400 font-semibold mt-1">No Internet Connection Required</div>
          <div className="text-[10px] text-neutral-400 mt-1">Encrypted local media cache</div>
        </div>
      </div>

      {/* 3. DOWNLOADS CONTENT LIST */}
      <div className="max-w-6xl mx-auto w-full px-4 lg:px-8 pt-1 flex-1 space-y-3">
        {downloads.map((item) => (
          <div
            key={item.id}
            onClick={() => onSelectMovie?.(item.id, item.isSeries, item.title)}
            className="w-full rounded-2xl bg-[#131316] border border-white/5 p-3 flex items-center gap-3.5 shadow-lg group hover:border-white/10 active:scale-[0.99] transition-all cursor-pointer"
          >
            {/* Mirzapur Thumbnail matching screenshot */}
            <div className="w-16 h-20 rounded-xl overflow-hidden bg-gradient-to-t from-amber-950 via-orange-950 to-black border border-white/10 relative shrink-0 p-1 flex flex-col justify-between shadow-md">
              <div className="absolute inset-0 bg-[radial-gradient(circle_at_bottom,_var(--tw-gradient-stops))] from-amber-600/40 via-red-950 to-black pointer-events-none" />
              <div />
              <div className="relative z-10 text-center pb-0.5">
                <div className="text-[9px] font-black text-amber-400 tracking-wider leading-none drop-shadow-md">
                  MIRZAPUR
                </div>
              </div>
            </div>

            {/* Middle Info Column: Title, Progress Bar, Status */}
            <div className="flex-1 min-w-0 pr-1">
              <h3 className="text-sm sm:text-base font-bold text-white tracking-tight truncate">
                {item.title}
              </h3>

              {/* Progress Bar Track */}
              <div className="w-full h-1 bg-[#27272a] rounded-full overflow-hidden mt-2 mb-1.5">
                <div
                  className="h-full bg-[#00E676] rounded-full transition-all duration-300"
                  style={{ width: `${Math.max(2, item.progress)}%` }}
                />
              </div>

              {/* Status Text (Downloading 2% / Paused) */}
              <div className="text-xs font-semibold text-[#00E676]">
                {item.progress >= 100
                  ? "Downloaded"
                  : item.isPaused
                  ? `Paused (${item.progress}%)`
                  : `Downloading ${item.progress}%`}
              </div>
            </div>

            {/* Right Action Buttons: Pause/Play & Trash */}
            <div className="flex items-center gap-2.5 shrink-0 pl-1">
              {/* Pause / Resume Button */}
              <button
                type="button"
                onClick={(e) => handleTogglePause(item.id, e)}
                title={item.isPaused ? "Resume" : "Pause"}
                className="w-8 h-8 rounded-full bg-white/10 hover:bg-white/20 active:scale-95 flex items-center justify-center text-white transition-all cursor-pointer"
              >
                {item.isPaused ? (
                  <Play className="w-3.5 h-3.5 fill-white text-white ml-0.5" />
                ) : (
                  <div className="flex items-center gap-0.5">
                    <span className="w-1 h-3.5 bg-white rounded-sm inline-block" />
                    <span className="w-1 h-3.5 bg-white rounded-sm inline-block" />
                  </div>
                )}
              </button>

              {/* Delete Trash Button */}
              <button
                type="button"
                onClick={(e) => handleDelete(item.id, e)}
                title="Remove Download"
                className="p-1.5 text-neutral-400 hover:text-red-400 transition-colors cursor-pointer"
              >
                <Trash2 className="w-4 h-4 stroke-[2]" />
              </button>
            </div>
          </div>
        ))}

        {/* Empty State when list is cleared */}
        {downloads.length === 0 && (
          <div className="flex flex-col items-center justify-center pt-20 pb-12 text-center px-4">
            <div className="w-16 h-16 rounded-full bg-neutral-900 border border-white/5 flex items-center justify-center text-neutral-500 mb-3">
              <Download className="w-7 h-7" />
            </div>
            <h2 className="text-base font-bold text-white mb-1">No Downloads Yet</h2>
            <p className="text-xs text-neutral-400 max-w-xs mb-5">
              Downloaded movies and series will appear here for offline playback anytime.
            </p>
            <div className="flex items-center gap-3">
              <button
                type="button"
                onClick={handleRestoreSample}
                className="px-4 py-2 rounded-full bg-neutral-800 hover:bg-neutral-700 text-xs font-semibold text-neutral-200 transition-colors cursor-pointer"
              >
                Restore Mirzapur
              </button>
              <button
                type="button"
                onClick={() => onNavigateTab("home")}
                className="px-5 py-2 rounded-full bg-[#00E676] hover:bg-[#00c865] text-xs font-extrabold text-black transition-colors cursor-pointer"
              >
                Browse Movies
              </button>
            </div>
          </div>
        )}
      </div>

      {/* 4. FIXED BOTTOM NAVIGATION BAR (Hidden on desktop) */}
      <nav className="lg:hidden fixed bottom-0 left-0 right-0 z-50 h-16 bg-black/95 backdrop-blur-lg border-t border-white/10 px-4 flex items-center justify-around">
        <button
          type="button"
          onClick={() => onNavigateTab("home")}
          className="flex flex-col items-center gap-1 cursor-pointer transition-colors"
        >
          <Home className="w-5 h-5 text-neutral-500" />
          <span className="text-[10px] font-medium text-neutral-500">Home</span>
        </button>

        <button
          type="button"
          onClick={() => onNavigateTab("search")}
          className="flex flex-col items-center gap-1 cursor-pointer transition-colors"
        >
          <SearchIcon className="w-5 h-5 text-neutral-500" />
          <span className="text-[10px] font-medium text-neutral-500">Search</span>
        </button>

        <button
          type="button"
          onClick={() => onNavigateTab("favorites")}
          className="flex flex-col items-center gap-1 cursor-pointer transition-colors"
        >
          <Heart className="w-5 h-5 text-neutral-500" />
          <span className="text-[10px] font-medium text-neutral-500">Favorites</span>
        </button>

        <button
          type="button"
          onClick={() => onNavigateTab("downloads")}
          className="flex flex-col items-center gap-1 cursor-pointer transition-colors"
        >
          <Download className="w-5 h-5 text-[#00E676]" />
          <span className="text-[10px] font-medium text-[#00E676]">Downloads</span>
        </button>

        <button
          type="button"
          onClick={() => onNavigateTab("profile")}
          className="flex flex-col items-center gap-1 cursor-pointer transition-colors"
        >
          <UserIcon className="w-5 h-5 text-neutral-500" />
          <span className="text-[10px] font-medium text-neutral-500">Profile</span>
        </button>
      </nav>
    </div>
  );
};
