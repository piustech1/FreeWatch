import React from "react";
import {
  Search,
  Home,
  Users,
  Grid,
  Heart,
  Download,
  Settings,
  Bell,
} from "lucide-react";
import { AvatarGraphic } from "./AvatarGraphic";
import { UserProfileData } from "./EditProfileModal";

export type DesktopNavTarget =
  | "home"
  | "search"
  | "available-vjs"
  | "categories"
  | "favorites"
  | "downloads"
  | "profile"
  | "notifications";

interface DesktopNavRailProps {
  currentNav: string;
  onNavigate: (target: DesktopNavTarget) => void;
  userProfile?: UserProfileData;
  notificationCount?: number;
}

export const DesktopNavRail: React.FC<DesktopNavRailProps> = ({
  currentNav,
  onNavigate,
  userProfile = {
    displayName: "Admin2",
    bio: "Luganda dubbed movie lover • Streaming on FreeWatch",
    avatarId: "mirabel",
  },
  notificationCount = 42,
}) => {
  return (
    <aside
      className="hidden lg:flex fixed top-0 bottom-0 left-0 w-20 xl:w-22 bg-[#090a0f]/95 backdrop-blur-2xl border-r border-white/10 z-50 flex-col items-center py-6 justify-between select-none"
      aria-label="Desktop Navigation Rail"
    >
      {/* 1. TOP: USER AVATAR WITH STATUS GLOW */}
      <div className="flex flex-col items-center gap-4">
        <button
          type="button"
          onClick={() => onNavigate("profile")}
          title={`${userProfile.displayName} Profile`}
          className="group relative cursor-pointer active:scale-95 transition-transform"
        >
          <div className="w-12 h-12 rounded-full p-0.5 bg-gradient-to-tr from-amber-400 via-yellow-300 to-amber-500 shadow-md group-hover:shadow-[0_0_15px_rgba(245,158,11,0.5)] transition-all">
            <div className="w-full h-full rounded-full overflow-hidden border border-black bg-black">
              <AvatarGraphic id={userProfile.avatarId || "mirabel"} />
            </div>
          </div>
          {/* Online green indicator */}
          <span className="absolute bottom-0 right-0 w-3 h-3 rounded-full bg-[#00E676] border-2 border-black" />
        </button>

        {/* Notification Bell with Badge */}
        <button
          type="button"
          onClick={() => onNavigate("notifications")}
          title="Notifications"
          className="relative p-2.5 rounded-2xl text-neutral-400 hover:text-white hover:bg-white/5 transition-all cursor-pointer group"
        >
          <Bell className="w-5 h-5 group-hover:scale-110 transition-transform" />
          {notificationCount > 0 && (
            <span className="absolute top-1 right-1 px-1.5 py-0.2 rounded-full bg-[#E50914] text-[9px] font-black text-white flex items-center justify-center shadow-sm">
              {notificationCount}
            </span>
          )}
        </button>
      </div>

      {/* 2. MIDDLE: CORE TV & PC ACTION ICONS matching 1793218681981_752aed45.jpg */}
      <nav className="flex flex-col items-center gap-4 w-full px-2">
        {/* Search */}
        <button
          type="button"
          onClick={() => onNavigate("search")}
          title="Search Movies & Series"
          className={`w-12 h-12 rounded-2xl flex items-center justify-center transition-all cursor-pointer group ${
            currentNav === "search"
              ? "bg-[#00E676] text-black shadow-[0_0_20px_rgba(0,230,118,0.6)] font-bold"
              : "text-neutral-400 hover:text-white hover:bg-white/5"
          }`}
        >
          <Search className="w-5 h-5 group-hover:scale-110 transition-transform" />
        </button>

        {/* Home (Highlighted with neon green circular/rounded glow) */}
        <button
          type="button"
          onClick={() => onNavigate("home")}
          title="Home"
          className={`w-12 h-12 rounded-2xl flex items-center justify-center transition-all cursor-pointer group ${
            currentNav === "home"
              ? "bg-[#00E676] text-black shadow-[0_0_25px_rgba(0,230,118,0.7)] font-bold scale-105"
              : "text-neutral-400 hover:text-white hover:bg-white/5"
          }`}
        >
          <Home className="w-5 h-5 group-hover:scale-110 transition-transform" />
        </button>

        {/* VJs (Available VJs) */}
        <button
          type="button"
          onClick={() => onNavigate("available-vjs")}
          title="Available VJs (Translators)"
          className={`w-12 h-12 rounded-2xl flex flex-col items-center justify-center transition-all cursor-pointer group ${
            currentNav === "available-vjs" || currentNav === "vj-movies"
              ? "bg-[#00E676] text-black shadow-[0_0_20px_rgba(0,230,118,0.6)] font-bold"
              : "text-neutral-400 hover:text-white hover:bg-white/5"
          }`}
        >
          <Users className="w-4 h-4 group-hover:scale-110 transition-transform" />
          <span className="text-[9px] font-black tracking-tight leading-none mt-0.5">VJs</span>
        </button>

        {/* Categories / Browse */}
        <button
          type="button"
          onClick={() => onNavigate("categories")}
          title="Explore Categories"
          className={`w-12 h-12 rounded-2xl flex items-center justify-center transition-all cursor-pointer group ${
            currentNav === "category-see-all" || currentNav === "categories"
              ? "bg-[#00E676] text-black shadow-[0_0_20px_rgba(0,230,118,0.6)] font-bold"
              : "text-neutral-400 hover:text-white hover:bg-white/5"
          }`}
        >
          <Grid className="w-5 h-5 group-hover:scale-110 transition-transform" />
        </button>

        {/* Favorites */}
        <button
          type="button"
          onClick={() => onNavigate("favorites")}
          title="Favorites"
          className={`w-12 h-12 rounded-2xl flex items-center justify-center transition-all cursor-pointer group ${
            currentNav === "favorites"
              ? "bg-[#00E676] text-black shadow-[0_0_20px_rgba(0,230,118,0.6)] font-bold"
              : "text-neutral-400 hover:text-white hover:bg-white/5"
          }`}
        >
          <Heart className="w-5 h-5 group-hover:scale-110 transition-transform" />
        </button>

        {/* Downloads */}
        <button
          type="button"
          onClick={() => onNavigate("downloads")}
          title="Downloaded Movies"
          className={`w-12 h-12 rounded-2xl flex items-center justify-center transition-all cursor-pointer group ${
            currentNav === "downloads"
              ? "bg-[#00E676] text-black shadow-[0_0_20px_rgba(0,230,118,0.6)] font-bold"
              : "text-neutral-400 hover:text-white hover:bg-white/5"
          }`}
        >
          <Download className="w-5 h-5 group-hover:scale-110 transition-transform" />
        </button>
      </nav>

      {/* 3. BOTTOM: SETTINGS / PROFILE GEAR */}
      <div className="flex flex-col items-center gap-2">
        <button
          type="button"
          onClick={() => onNavigate("profile")}
          title="Settings & Account"
          className={`w-11 h-11 rounded-2xl flex items-center justify-center transition-all cursor-pointer group ${
            currentNav === "profile"
              ? "bg-white/20 text-[#00E676]"
              : "text-neutral-400 hover:text-white hover:bg-white/5"
          }`}
        >
          <Settings className="w-5 h-5 group-hover:rotate-45 transition-transform" />
        </button>
      </div>
    </aside>
  );
};
