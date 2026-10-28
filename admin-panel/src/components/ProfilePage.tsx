import React, { useState } from "react";
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
  Home,
  Heart,
  User as UserIcon,
  Star,
} from "lucide-react";
import { FreeWatchLogo } from "./HomePage";
import { EditProfileModal, UserProfileData } from "./EditProfileModal";
import { AvatarGraphic } from "./AvatarGraphic";

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
            <span className="absolute -top-1 -right-1.5 w-4 h-4 rounded-full bg-[#E50914] text-[10px] font-bold text-white flex items-center justify-center">
              42
            </span>
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
          {/* Left Half: 75 Movies Watched */}
          <div className="bg-[#121829] p-4 flex items-center gap-3 border-r border-white/5">
            <div className="w-10 h-10 rounded-xl bg-sky-950/60 flex items-center justify-center text-sky-400 shrink-0">
              <Film className="w-5 h-5 fill-sky-400/20" />
            </div>
            <div className="min-w-0">
              <div className="text-sm font-extrabold text-white truncate">75 Movies</div>
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
                75
              </span>
            </div>
            {/* Right double indicator > v matching screenshot */}
            <div className="flex items-center gap-1.5 text-neutral-500">
              <ChevronRight className="w-4 h-4" />
              <ChevronDown
                className={`w-4 h-4 transition-transform duration-200 ${
                  isWatchHistoryOpen ? "rotate-0 text-white" : "-rotate-90 text-neutral-500"
                }`}
              />
            </div>
          </div>

          {/* Horizontal Watch History Shelf matching Screenshot 3 */}
          {isWatchHistoryOpen && (
            <div className="flex gap-3 overflow-x-auto no-scrollbar pb-1 pt-0.5">
              {/* Card 1: The Soccer Football Movie */}
              <div
                onClick={() => onSelectMovie?.("soccer-movie", false, "The Soccer Football Movie")}
                className="w-28 sm:w-32 shrink-0 cursor-pointer group active:scale-95 transition-transform"
              >
                <div className="relative aspect-[2/3] rounded-2xl overflow-hidden bg-gradient-to-t from-red-950 via-red-900/60 to-black border border-white/10 group-hover:border-white/30 transition-all p-2 flex flex-col justify-between shadow-md">
                  <div className="absolute inset-0 bg-[radial-gradient(ellipse_at_center,_var(--tw-gradient-stops))] from-red-600/30 via-zinc-900 to-black pointer-events-none" />
                  <div className="flex justify-start">
                    <span className="text-[7.5px] font-bold text-red-400">NETFLIX</span>
                  </div>
                  <div className="relative z-10 text-center">
                    <div className="text-[10px] font-black text-white tracking-tight leading-tight uppercase drop-shadow-md">
                      THE SOCCER
                    </div>
                    <div className="text-xs font-black text-white tracking-tight leading-none uppercase drop-shadow-md">
                      FOOTBALL MOVIE
                    </div>
                  </div>
                </div>
                <div className="mt-1.5 px-0.5">
                  <div className="text-xs font-bold text-white truncate">The Soccer Footb...</div>
                  <div className="flex items-center gap-1 text-[11px] text-neutral-400 font-medium mt-0.5">
                    <Star className="w-3 h-3 fill-amber-400 text-amber-400" />
                    <span className="font-bold text-white">8.4</span>
                    <span>• 2026</span>
                  </div>
                </div>
              </div>

              {/* Card 2: Supacell */}
              <div
                onClick={() => onSelectMovie?.("supacell", true, "Supacell")}
                className="w-28 sm:w-32 shrink-0 cursor-pointer group active:scale-95 transition-transform"
              >
                <div className="relative aspect-[2/3] rounded-2xl overflow-hidden bg-gradient-to-t from-teal-950 via-emerald-900/50 to-black border border-white/10 group-hover:border-white/30 transition-all p-2 flex flex-col justify-between shadow-md">
                  <div className="absolute inset-0 bg-[radial-gradient(circle_at_top,_var(--tw-gradient-stops))] from-amber-400/30 via-teal-900/40 to-black pointer-events-none" />
                  <div />
                  <div className="relative z-10 text-center pb-2">
                    <div className="text-sm font-black text-amber-300 tracking-wider leading-none drop-shadow-md">
                      SUPACELL
                    </div>
                  </div>
                </div>
                <div className="mt-1.5 px-0.5">
                  <div className="text-xs font-bold text-white truncate">Supacell</div>
                  <div className="flex items-center gap-1 text-[11px] text-neutral-400 font-medium mt-0.5">
                    <Star className="w-3 h-3 fill-amber-400 text-amber-400" />
                    <span className="font-bold text-white">8.4</span>
                    <span>• 2026</span>
                  </div>
                </div>
              </div>

              {/* Card 3: The Blob */}
              <div
                onClick={() => onSelectMovie?.("the-blob", false, "The Blob")}
                className="w-28 sm:w-32 shrink-0 cursor-pointer group active:scale-95 transition-transform"
              >
                <div className="relative aspect-[2/3] rounded-2xl overflow-hidden bg-gradient-to-t from-pink-950 via-purple-950 to-black border border-white/10 group-hover:border-white/30 transition-all p-2 flex flex-col justify-between shadow-md">
                  <div className="absolute inset-0 bg-[radial-gradient(ellipse_at_center,_var(--tw-gradient-stops))] from-pink-600/30 via-purple-950 to-black pointer-events-none" />
                  <div />
                  <div className="relative z-10 text-center pb-2">
                    <div className="text-base font-serif font-black text-amber-200 tracking-widest leading-none drop-shadow-md">
                      THE BLOB
                    </div>
                  </div>
                </div>
                <div className="mt-1.5 px-0.5">
                  <div className="text-xs font-bold text-white truncate">The Blob</div>
                  <div className="flex items-center gap-1 text-[11px] text-neutral-400 font-medium mt-0.5">
                    <Star className="w-3 h-3 fill-amber-400 text-amber-400" />
                    <span className="font-bold text-white">8.6</span>
                    <span>• 2024</span>
                  </div>
                </div>
              </div>

              {/* Card 4: Mirzapur */}
              <div
                onClick={() => onSelectMovie?.("mirzapur", true, "Mirzapur")}
                className="w-28 sm:w-32 shrink-0 cursor-pointer group active:scale-95 transition-transform"
              >
                <div className="relative aspect-[2/3] rounded-2xl overflow-hidden bg-gradient-to-t from-amber-950 via-orange-950 to-black border border-white/10 group-hover:border-white/30 transition-all p-2 flex flex-col justify-between shadow-md">
                  <div className="absolute inset-0 bg-[radial-gradient(circle_at_bottom,_var(--tw-gradient-stops))] from-amber-600/40 via-red-950 to-black pointer-events-none" />
                  <div />
                  <div className="relative z-10 text-center pb-1">
                    <div className="text-sm font-black text-amber-400 tracking-widest leading-none drop-shadow-md">
                      MIRZAPUR
                    </div>
                  </div>
                </div>
                <div className="mt-1.5 px-0.5">
                  <div className="text-xs font-bold text-white truncate">Mirzapur</div>
                  <div className="flex items-center gap-1 text-[11px] text-neutral-400 font-medium mt-0.5">
                    <Star className="w-3 h-3 fill-amber-400 text-amber-400" />
                    <span className="font-bold text-white">8.4</span>
                    <span>• 2026</span>
                  </div>
                </div>
              </div>
            </div>
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
                23
              </span>
            </div>
            {/* Right double indicator > v matching screenshot */}
            <div className="flex items-center gap-1.5 text-neutral-500">
              <ChevronRight className="w-4 h-4" />
              <ChevronDown
                className={`w-4 h-4 transition-transform duration-200 ${
                  isSavedMoviesOpen ? "rotate-0 text-white" : "-rotate-90 text-neutral-500"
                }`}
              />
            </div>
          </div>

          {/* Horizontal Saved Movies Shelf matching Screenshot 3 */}
          {isSavedMoviesOpen && (
            <div className="flex gap-3 overflow-x-auto no-scrollbar pb-1 pt-0.5">
              {/* Card 1: Just Say It: Ava Peace */}
              <div
                onClick={() => onSelectMovie?.("ava-peace", false, "Just Say It: Ava Peace: The story behind the hits")}
                className="w-28 sm:w-32 shrink-0 cursor-pointer group active:scale-95 transition-transform"
              >
                <div className="relative aspect-[2/3] rounded-2xl overflow-hidden bg-gradient-to-t from-indigo-950 via-purple-950 to-black border border-white/10 group-hover:border-white/30 transition-all p-2 flex flex-col justify-between shadow-md">
                  <div className="absolute inset-0 bg-gradient-to-b from-indigo-900/40 to-black pointer-events-none" />
                  <div />
                  <div className="relative z-10">
                    <span className="text-[6.5px] font-black text-lime-400 uppercase block">Ava Peace:</span>
                    <div className="text-[9px] font-black text-white leading-tight">
                      The story behind the hits
                    </div>
                  </div>
                </div>
                <div className="mt-1.5 px-0.5">
                  <div className="text-xs font-bold text-white truncate">Just Say It: Ava P...</div>
                  <div className="flex items-center gap-1 text-[11px] text-neutral-400 font-medium mt-0.5">
                    <Star className="w-3 h-3 fill-amber-400 text-amber-400" />
                    <span className="font-bold text-white">8.4</span>
                    <span>• 2026</span>
                  </div>
                </div>
              </div>

              {/* Card 2: What If */}
              <div
                onClick={() => onSelectMovie?.("what-if", false, "What If")}
                className="w-28 sm:w-32 shrink-0 cursor-pointer group active:scale-95 transition-transform"
              >
                <div className="relative aspect-[2/3] rounded-2xl overflow-hidden bg-gradient-to-t from-sky-950 via-sky-800 to-black border border-white/10 group-hover:border-white/30 transition-all p-2 flex flex-col justify-between shadow-md">
                  <div className="absolute inset-0 bg-[radial-gradient(ellipse_at_center,_var(--tw-gradient-stops))] from-sky-400/30 via-sky-900/50 to-black pointer-events-none" />
                  <div className="text-center pt-1">
                    <div className="text-xs font-black text-amber-300 tracking-wider">
                      WHAT IF
                    </div>
                  </div>
                  <div className="text-center pb-2">
                    <span className="text-xl font-bold text-sky-300">?</span>
                  </div>
                </div>
                <div className="mt-1.5 px-0.5">
                  <div className="text-xs font-bold text-white truncate">What If</div>
                  <div className="flex items-center gap-1 text-[11px] text-neutral-400 font-medium mt-0.5">
                    <Star className="w-3 h-3 fill-amber-400 text-amber-400" />
                    <span className="font-bold text-white">8.4</span>
                    <span>• 2026</span>
                  </div>
                </div>
              </div>

              {/* Card 3: Hope */}
              <div
                onClick={() => onSelectMovie?.("hope", false, "Hope")}
                className="w-28 sm:w-32 shrink-0 cursor-pointer group active:scale-95 transition-transform"
              >
                <div className="relative aspect-[2/3] rounded-2xl overflow-hidden bg-gradient-to-t from-zinc-950 via-slate-900 to-black border border-white/10 group-hover:border-white/30 transition-all p-2 flex flex-col justify-between shadow-md">
                  <div className="absolute inset-0 bg-gradient-to-b from-slate-700/30 to-black pointer-events-none" />
                  <div />
                  <div className="relative z-10 text-center pb-2">
                    <div className="text-sm font-serif font-black text-white tracking-widest leading-none drop-shadow-md">
                      HOPE
                    </div>
                  </div>
                </div>
                <div className="mt-1.5 px-0.5">
                  <div className="text-xs font-bold text-white truncate">Hope</div>
                  <div className="flex items-center gap-1 text-[11px] text-neutral-400 font-medium mt-0.5">
                    <Star className="w-3 h-3 fill-amber-400 text-amber-400" />
                    <span className="font-bold text-white">8.4</span>
                    <span>• 2026</span>
                  </div>
                </div>
              </div>

              {/* Card 4: Mapanukso */}
              <div
                onClick={() => onSelectMovie?.("mapanukso", false, "Mapanukso")}
                className="w-28 sm:w-32 shrink-0 cursor-pointer group active:scale-95 transition-transform"
              >
                <div className="relative aspect-[2/3] rounded-2xl overflow-hidden bg-gradient-to-t from-emerald-950 via-stone-900 to-black border border-white/10 group-hover:border-white/30 transition-all p-2 flex flex-col justify-between shadow-md">
                  <div className="absolute inset-0 bg-gradient-to-t from-black via-zinc-900/60 to-transparent pointer-events-none" />
                  <div />
                  <div className="relative z-10 text-center pb-2">
                    <div className="text-xs font-serif font-bold text-white tracking-tight leading-none drop-shadow-md">
                      Mapanukso
                    </div>
                  </div>
                </div>
                <div className="mt-1.5 px-0.5">
                  <div className="text-xs font-bold text-white truncate">Mapanukso</div>
                  <div className="flex items-center gap-1 text-[11px] text-neutral-400 font-medium mt-0.5">
                    <Star className="w-3 h-3 fill-amber-400 text-amber-400" />
                    <span className="font-bold text-white">7.0</span>
                    <span>• 2003</span>
                  </div>
                </div>
              </div>
            </div>
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
        <div className="w-full h-14 rounded-full bg-black border border-white/10 px-5 flex items-center justify-between shadow-md">
          <div className="flex items-center gap-3">
            <div className="w-6 h-6 rounded-full bg-white flex items-center justify-center text-black">
              <span className="text-xs font-black">♪</span>
            </div>
            <span className="text-xs font-bold text-white">Follow us on TikTok</span>
          </div>

          <button
            type="button"
            className="px-5 py-2 rounded-full bg-[#E50914] hover:bg-[#d00812] active:scale-95 text-white font-extrabold text-xs shadow-md shadow-[#E50914]/20 cursor-pointer transition-transform"
          >
            Follow
          </button>
        </div>
      </div>

      {/* 8. FIXED BOTTOM NAVIGATION BAR (Profile Active - Hidden on desktop) */}
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
          <Download className="w-5 h-5 text-neutral-500" />
          <span className="text-[10px] font-medium text-neutral-500">Downloads</span>
        </button>

        <button
          type="button"
          onClick={() => onNavigateTab("profile")}
          className="flex flex-col items-center gap-1 cursor-pointer transition-colors"
        >
          <UserIcon className="w-5 h-5 text-[#00E676]" />
          <span className="text-[10px] font-medium text-[#00E676]">Profile</span>
        </button>
      </nav>

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
