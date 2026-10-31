import React, { useState, useEffect } from "react";
import {
  Search as SearchIcon,
  Bell,
  LogOut,
  Edit2,
  CheckCircle,
  Film,
  Download,
  ChevronRight,
  ChevronDown,
  MessageSquare,
  Sparkles,
  Info,
  Heart,
  Star,
} from "lucide-react";
import { FreeWatchLogo } from "./HomePage";
import { EditProfileModal, UserProfileData } from "./EditProfileModal";
import { AvatarGraphic } from "./AvatarGraphic";
import { VjBadge } from "./VjBadge";
import { CatalogMovie } from "../data/liveCatalog";
import { FloatingBottomNav } from "./FloatingBottomNav";

interface ProfilePageProps {
  onNavigateTab: (tab: "home" | "search" | "favorites" | "downloads" | "profile") => void;
  onLogout?: () => void;
  onNavigateToDeveloperChat?: () => void;
  onNavigateToNotifications?: () => void;
  onSelectMovie?: (movieId: string, isSeries?: boolean, title?: string) => void;
  userProfile?: UserProfileData;
  onUpdateProfile?: (data: UserProfileData) => void;
}

export const ProfilePage: React.FC<ProfilePageProps> = ({
  onNavigateTab,
  onLogout,
  onNavigateToDeveloperChat,
  onNavigateToNotifications,
  onSelectMovie,
  userProfile = {
    displayName: "Admin2",
    bio: "Luganda dubbed movie lover • Streaming on FreeWatch",
    avatarId: "mirabel",
  },
  onUpdateProfile,
}) => {
  const [cachedDataSize, setCachedDataSize] = useState("142 MB");
  const [isCacheCleared, setIsCacheCleared] = useState(false);
  const [isWatchHistoryOpen, setIsWatchHistoryOpen] = useState(true);
  const [isSavedMoviesOpen, setIsSavedMoviesOpen] = useState(true);
  const [isEditProfileOpen, setIsEditProfileOpen] = useState(false);

  const [watchHistory, setWatchHistory] = useState<CatalogMovie[]>([]);
  const [savedMovies, setSavedMovies] = useState<CatalogMovie[]>([]);

  useEffect(() => {
    try {
      const hist = localStorage.getItem("freewatch_watch_history");
      if (hist) {
        setWatchHistory(JSON.parse(hist));
      }
    } catch {}
    try {
      const favs = localStorage.getItem("freewatch_favorites");
      if (favs) {
        setSavedMovies(JSON.parse(favs));
      }
    } catch {}
  }, []);

  const handleClearCache = () => {
    setCachedDataSize("0 MB");
    setIsCacheCleared(true);
    setTimeout(() => {
      setIsCacheCleared(false);
    }, 2000);
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
          </button>

          <button
            type="button"
            onClick={() => onNavigateTab("profile")}
            title="Account Profile"
            className="w-8 h-8 rounded-full overflow-hidden border border-white/20 active:scale-95 transition-transform cursor-pointer"
          >
            <AvatarGraphic id={userProfile.avatarId || "mirabel"} />
          </button>
        </div>
      </header>

      {/* 2. TOP RIGHT RED LOGOUT BUTTON */}
      <div className="px-4 pt-3 flex justify-end">
        <button
          type="button"
          onClick={onLogout}
          title="Sign Out"
          className="w-11 h-11 rounded-2xl bg-[#E50914] hover:bg-[#d00812] active:scale-95 text-white flex items-center justify-center shadow-lg shadow-[#E50914]/25 cursor-pointer transition-transform"
        >
          <LogOut className="w-5 h-5 stroke-[2.2]" />
        </button>
      </div>

      {/* 3. USER PROFILE IDENTITY & AVATAR */}
      <div className="flex flex-col items-center mt-1 px-4">
        <div
          onClick={() => setIsEditProfileOpen(true)}
          className="relative cursor-pointer group active:scale-95 transition-transform"
        >
          <div className="w-24 h-24 rounded-full p-0.5 bg-gradient-to-tr from-amber-400 via-yellow-300 to-amber-500 shadow-xl shadow-amber-500/10">
            <div className="w-full h-full rounded-full overflow-hidden border-2 border-black">
              <AvatarGraphic id={userProfile.avatarId || "mirabel"} />
            </div>
          </div>

          {/* Pencil edit badge */}
          <button
            type="button"
            onClick={(e) => {
              e.stopPropagation();
              setIsEditProfileOpen(true);
            }}
            className="absolute bottom-0 right-0 w-7 h-7 rounded-full bg-[#1c1c1e] border-2 border-black text-white flex items-center justify-center cursor-pointer shadow-md hover:bg-[#2c2c30] transition-colors"
            title="Edit Profile"
          >
            <Edit2 className="w-3.5 h-3.5" />
          </button>
        </div>

        {/* Username with Blue Verified Checkmark */}
        <div className="mt-3 flex items-center gap-1.5">
          <h2 className="text-xl font-extrabold text-white tracking-tight">
            {userProfile.displayName || "Admin2"}
          </h2>
          <CheckCircle className="w-4 h-4 fill-[#00B0FF] text-black" />
        </div>

        {/* User Bio */}
        <p className="text-xs text-neutral-400 mt-1 font-normal text-center max-w-xs">
          {userProfile.bio || "Luganda dubbed movie lover • Streaming on FreeWatch"}
        </p>
      </div>

      {/* 4. SPLIT STATS CARD (Watched vs Downloaded) */}
      <div className="px-4 mt-5">
        <div className="w-full rounded-2xl overflow-hidden border border-white/5 grid grid-cols-2 shadow-lg">
          {/* Left Half: Dynamic Movies Watched */}
          <div className="bg-[#121829] p-4 flex items-center gap-3 border-r border-white/5">
            <div className="w-10 h-10 rounded-xl bg-sky-950/60 flex items-center justify-center text-sky-400 shrink-0">
              <Film className="w-5 h-5 fill-sky-400/20" />
            </div>
            <div className="min-w-0">
              <div className="text-sm font-extrabold text-white truncate">
                {watchHistory.length} {watchHistory.length === 1 ? "Movie" : "Movies"}
              </div>
              <div className="text-xs font-semibold text-sky-400">Watched</div>
            </div>
          </div>

          {/* Right Half: 0 Movies Downloaded */}
          <div className="bg-[#1f1712] p-4 flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-amber-950/60 flex items-center justify-center text-amber-500 shrink-0">
              <Download className="w-5 h-5" />
            </div>
            <div className="min-w-0">
              <div className="text-sm font-extrabold text-white truncate">0 Movies</div>
              <div className="text-xs font-semibold text-amber-500">Downloaded</div>
            </div>
          </div>
        </div>
      </div>

      {/* 5. WATCH HISTORY & SAVED MOVIES COLLAPSIBLE MENUS */}
      <div className="px-4 mt-4 space-y-4">
        {/* Section 1: Watch History */}
        <div className="space-y-3">
          <div
            onClick={() => setIsWatchHistoryOpen(!isWatchHistoryOpen)}
            className="w-full h-12 rounded-2xl bg-[#141416] border border-white/5 px-4 flex items-center justify-between cursor-pointer hover:border-white/10 active:scale-[0.99] transition-all"
          >
            <div className="flex items-center gap-2">
              <span className="text-xs font-black text-white tracking-wider">WATCH HISTORY</span>
              <span className="px-2 py-0.5 rounded bg-white/10 text-[10px] font-bold text-neutral-300">
                {watchHistory.length}
              </span>
            </div>
            <div className="flex items-center gap-1.5 text-neutral-500">
              <ChevronRight className="w-4 h-4" />
              <ChevronDown
                className={`w-4 h-4 transition-transform duration-200 ${
                  isWatchHistoryOpen ? "rotate-0 text-white" : "-rotate-90 text-neutral-500"
                }`}
              />
            </div>
          </div>

          {/* Horizontal Watch History Shelf */}
          {isWatchHistoryOpen && (
            watchHistory.length === 0 ? (
              <div className="w-full py-8 px-4 rounded-2xl bg-white/[0.03] border border-white/5 flex flex-col items-center justify-center text-center">
                <Film className="w-7 h-7 text-white/20 mb-2" />
                <p className="text-xs font-medium text-white/50">No watch history recorded yet</p>
                <p className="text-[11px] text-white/30 mt-0.5">Start streaming any movie to track your movies</p>
              </div>
            ) : (
              <div className="flex gap-3 overflow-x-auto no-scrollbar pb-1 pt-0.5">
                {watchHistory.map((movie) => (
                  <div
                    key={movie.id}
                    onClick={() => onSelectMovie?.(movie.id, movie.isTv, movie.title)}
                    className="w-28 sm:w-32 shrink-0 cursor-pointer group active:scale-95 transition-transform"
                  >
                    <div className="relative aspect-[2/3] rounded-2xl overflow-hidden bg-neutral-900 border border-white/10 group-hover:border-white/30 transition-all p-2 flex flex-col justify-between shadow-md">
                      {movie.imageUrl && (
                        <img
                          src={movie.imageUrl}
                          alt={movie.title}
                          className="absolute inset-0 w-full h-full object-cover filter brightness-85 group-hover:scale-105 transition-transform"
                          onError={(e) => {
                            (e.target as HTMLImageElement).style.display = "none";
                          }}
                        />
                      )}
                      <div className="absolute inset-0 bg-gradient-to-t from-black via-black/30 to-transparent pointer-events-none" />
                      <div className="relative z-10 flex justify-end">
                        <VjBadge vjName={movie.vj} size="sm" />
                      </div>
                      <div className="relative z-10 text-left pt-6">
                        <div className="text-[11px] font-black text-white leading-tight drop-shadow-md line-clamp-2">
                          {movie.title}
                        </div>
                      </div>
                    </div>
                    <div className="mt-1.5 px-0.5">
                      <div className="text-xs font-bold text-white truncate">{movie.title}</div>
                      <div className="flex items-center gap-1 text-[11px] text-neutral-400 font-medium mt-0.5">
                        <Star className="w-3 h-3 fill-amber-400 text-amber-400" />
                        <span className="font-bold text-white">{movie.rating || "8.5"}</span>
                        <span>• {movie.year || "2025"}</span>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            )
          )}
        </div>

        {/* Section 2: Saved Movies */}
        <div className="space-y-3">
          <div
            onClick={() => setIsSavedMoviesOpen(!isSavedMoviesOpen)}
            className="w-full h-12 rounded-2xl bg-[#141416] border border-white/5 px-4 flex items-center justify-between cursor-pointer hover:border-white/10 active:scale-[0.99] transition-all"
          >
            <div className="flex items-center gap-2">
              <span className="text-xs font-black text-white tracking-wider">SAVED MOVIES</span>
              <span className="px-2 py-0.5 rounded bg-white/10 text-[10px] font-bold text-neutral-300">
                {savedMovies.length}
              </span>
            </div>
            <div className="flex items-center gap-1.5 text-neutral-500">
              <ChevronRight className="w-4 h-4" />
              <ChevronDown
                className={`w-4 h-4 transition-transform duration-200 ${
                  isSavedMoviesOpen ? "rotate-0 text-white" : "-rotate-90 text-neutral-500"
                }`}
              />
            </div>
          </div>

          {/* Horizontal Saved Movies Shelf */}
          {isSavedMoviesOpen && (
            savedMovies.length === 0 ? (
              <div className="w-full py-8 px-4 rounded-2xl bg-white/[0.03] border border-white/5 flex flex-col items-center justify-center text-center">
                <Heart className="w-7 h-7 text-white/20 mb-2" />
                <p className="text-xs font-medium text-white/50">No saved movies recorded yet</p>
                <p className="text-[11px] text-white/30 mt-0.5">Tap the bookmark icon on any movie to add it here</p>
              </div>
            ) : (
              <div className="flex gap-3 overflow-x-auto no-scrollbar pb-1 pt-0.5">
                {savedMovies.map((movie) => (
                  <div
                    key={movie.id}
                    onClick={() => onSelectMovie?.(movie.id, movie.isTv, movie.title)}
                    className="w-28 sm:w-32 shrink-0 cursor-pointer group active:scale-95 transition-transform"
                  >
                    <div className="relative aspect-[2/3] rounded-2xl overflow-hidden bg-neutral-900 border border-white/10 group-hover:border-white/30 transition-all p-2 flex flex-col justify-between shadow-md">
                      {movie.imageUrl && (
                        <img
                          src={movie.imageUrl}
                          alt={movie.title}
                          className="absolute inset-0 w-full h-full object-cover filter brightness-85 group-hover:scale-105 transition-transform"
                          onError={(e) => {
                            (e.target as HTMLImageElement).style.display = "none";
                          }}
                        />
                      )}
                      <div className="absolute inset-0 bg-gradient-to-t from-black via-black/30 to-transparent pointer-events-none" />
                      <div className="relative z-10 flex justify-end">
                        <VjBadge vjName={movie.vj} size="sm" />
                      </div>
                      <div className="relative z-10 text-left pt-6">
                        <div className="text-[11px] font-black text-white leading-tight drop-shadow-md line-clamp-2">
                          {movie.title}
                        </div>
                      </div>
                    </div>
                    <div className="mt-1.5 px-0.5">
                      <div className="text-xs font-bold text-white truncate">{movie.title}</div>
                      <div className="flex items-center gap-1 text-[11px] text-neutral-400 font-medium mt-0.5">
                        <Star className="w-3 h-3 fill-amber-400 text-amber-400" />
                        <span className="font-bold text-white">{movie.rating || "8.5"}</span>
                        <span>• {movie.year || "2025"}</span>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            )
          )}
        </div>
      </div>

      {/* 6. SETTINGS & SYSTEM */}
      <div className="px-4 mt-6">
        <h3 className="text-xs font-extrabold text-neutral-400 tracking-wider uppercase mb-2.5">
          SETTINGS & SYSTEM
        </h3>

        <div className="rounded-2xl bg-[#141416] border border-white/5 divide-y divide-white/5 overflow-hidden">
          {/* Talk to Developer */}
          <div
            onClick={onNavigateToDeveloperChat}
            className="p-3.5 flex items-center justify-between cursor-pointer hover:bg-white/[0.04] active:scale-[0.99] transition-all"
          >
            <div className="flex items-center gap-3 min-w-0">
              <div className="w-9 h-9 rounded-xl bg-purple-950/70 border border-purple-800/30 text-purple-400 flex items-center justify-center shrink-0">
                <MessageSquare className="w-4 h-4" />
              </div>
              <div className="min-w-0">
                <div className="text-xs font-bold text-white truncate">Talk to Developer</div>
                <div className="text-[11px] text-neutral-400 truncate">
                  Direct chat with the developer & support
                </div>
              </div>
            </div>
            <ChevronRight className="w-4 h-4 text-neutral-500 shrink-0 ml-2" />
          </div>

          {/* Clear Cache */}
          <div className="p-3.5 flex items-center justify-between">
            <div className="flex items-center gap-3 min-w-0">
              <div className="w-9 h-9 rounded-xl bg-emerald-950/70 border border-emerald-800/30 text-emerald-400 flex items-center justify-center shrink-0">
                <Sparkles className="w-4 h-4" />
              </div>
              <div className="min-w-0">
                <div className="text-xs font-bold text-white truncate">Clear Cache</div>
                <div className="text-[11px] text-neutral-400 truncate">
                  {isCacheCleared ? "Cache successfully cleared" : `${cachedDataSize} cached data`}
                </div>
              </div>
            </div>

            <button
              type="button"
              onClick={handleClearCache}
              className="px-4 py-1 rounded-full bg-emerald-950/80 border border-emerald-700/40 text-emerald-400 text-xs font-bold hover:bg-emerald-900 transition-colors cursor-pointer shrink-0 ml-2"
            >
              Clear
            </button>
          </div>

          {/* App Version */}
          <div className="p-3.5 flex items-center justify-between">
            <div className="flex items-center gap-3 min-w-0">
              <div className="w-9 h-9 rounded-xl bg-sky-950/70 border border-sky-800/30 text-sky-400 flex items-center justify-center shrink-0">
                <Info className="w-4 h-4" />
              </div>
              <div className="min-w-0">
                <div className="text-xs font-bold text-white truncate">App Version</div>
                <div className="text-[11px] text-neutral-400 truncate">
                  FreeWatch v1.0.55 (Build 56)
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* 7. FOLLOW US ON TIKTOK STRIP */}
      <div className="px-4 mt-6">
        <div className="w-full h-14 rounded-full bg-[#16171b] px-5 flex items-center justify-between shadow-lg">
          <div className="flex items-center gap-3">
            <div className="w-6 h-6 rounded-full bg-white flex items-center justify-center text-black">
              <span className="text-xs font-black">♪</span>
            </div>
            <span className="text-xs font-bold text-white">Follow us on TikTok</span>
          </div>

          <button
            type="button"
            onClick={() => {
              try {
                localStorage.setItem("has_clicked_join_community_v1", "true");
              } catch {}
              window.open("https://www.tiktok.com/@freewatchmoviesug?_r=1&_t=ZS-9AV8GRTNGfi", "_blank");
            }}
            className="px-5 py-2 rounded-full bg-[#E50914] hover:bg-[#d00812] active:scale-95 text-white font-extrabold text-xs shadow-md shadow-[#E50914]/20 cursor-pointer transition-transform"
          >
            Follow
          </button>
        </div>
      </div>

      {/* 8. FLOATING CURVED BOTTOM NAVIGATION PILL */}
      <FloatingBottomNav activeTab="profile" onNavigateTab={onNavigateTab} />

      {/* Edit Profile Bottom Sheet Modal matching Screenshot 1 */}
      <EditProfileModal
        isOpen={isEditProfileOpen}
        onClose={() => setIsEditProfileOpen(false)}
        currentProfile={userProfile}
        onSave={(updated) => {
          onUpdateProfile?.(updated);
        }}
      />
    </div>
  );
};
