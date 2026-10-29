import React, { useState, useEffect } from "react";
import {
  ArrowLeft,
  Search as SearchIcon,
  Bell,
  BellOff,
  Home,
  Heart,
  Download,
  User as UserIcon,
} from "lucide-react";
import { FreeWatchLogo } from "./HomePage";
import { AvatarGraphic } from "./AvatarGraphic";
import { UserProfileData } from "./EditProfileModal";
import { useLiveCatalog, CatalogMovie } from "../data/liveCatalog";

interface NotificationItem {
  id: string;
  movieId?: string;
  title: string;
  timestamp: string;
  isUnread: boolean;
  isSeries?: boolean;
  movieTitle: string;
  posterImage?: string;
  movie?: CatalogMovie;
}

interface NotificationsPageProps {
  onBack: () => void;
  onNavigateTab: (tab: "home" | "search" | "favorites" | "downloads" | "profile") => void;
  onSelectMovie?: (movieId: string, isSeries?: boolean, title?: string, movie?: CatalogMovie) => void;
  onLogout?: () => void;
  userProfile?: UserProfileData;
}

export const NotificationsPage: React.FC<NotificationsPageProps> = ({
  onBack,
  onNavigateTab,
  onSelectMovie,
  userProfile,
}) => {
  const { latestMovies } = useLiveCatalog();

  const [notifications, setNotifications] = useState<NotificationItem[]>(() => {
    try {
      const saved = localStorage.getItem("freewatch_user_notifications_v1");
      if (saved) return JSON.parse(saved);
    } catch {}
    return [];
  });

  // Dynamically populate notifications based on latest releases if none stored
  useEffect(() => {
    if (latestMovies.length === 0) return;
    setNotifications((prev) => {
      if (prev.length > 0) return prev;
      const initial = latestMovies.slice(0, 8).map((m, idx) => ({
        id: `notif-${m.id}`,
        movieId: m.id,
        title: `New Release: ${m.title} translated by ${m.vj} is now streaming on FreeWatch!`,
        timestamp: idx === 0 ? "Just now" : idx < 3 ? "1h ago" : "Earlier today",
        isUnread: idx < 3,
        isSeries: m.isTv,
        movieTitle: m.title,
        posterImage: m.imageUrl,
        movie: m,
      }));
      try {
        localStorage.setItem("freewatch_user_notifications_v1", JSON.stringify(initial));
      } catch {}
      return initial;
    });
  }, [latestMovies]);

  const unreadCount = notifications.filter((n) => n.isUnread).length;

  const handleMarkAllRead = () => {
    setNotifications((prev) => {
      const updated = prev.map((item) => ({ ...item, isUnread: false }));
      try {
        localStorage.setItem("freewatch_user_notifications_v1", JSON.stringify(updated));
      } catch {}
      return updated;
    });
  };

  const handleItemClick = (notif: NotificationItem) => {
    setNotifications((prev) => {
      const updated = prev.map((item) =>
        item.id === notif.id ? { ...item, isUnread: false } : item
      );
      try {
        localStorage.setItem("freewatch_user_notifications_v1", JSON.stringify(updated));
      } catch {}
      return updated;
    });
    if (onSelectMovie) {
      onSelectMovie(notif.movieId || notif.id, notif.isSeries, notif.movieTitle, notif.movie);
    }
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
            className="relative p-1 text-[#00E676] transition-colors cursor-pointer"
            aria-label="Notifications"
          >
            <Bell className="w-5 h-5 stroke-[2.2]" />
            {unreadCount > 0 && (
              <span className="absolute -top-1 -right-1.5 w-4 h-4 rounded-full bg-[#E50914] text-[10px] font-bold text-white flex items-center justify-center">
                {unreadCount > 99 ? "99+" : unreadCount}
              </span>
            )}
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

      {/* 2. SUBHEADER: BACK BUTTON & MARK ALL READ */}
      <div className="px-4 pt-4 flex items-center justify-between">
        <button
          type="button"
          onClick={onBack}
          className="p-1 text-white hover:text-[#00E676] transition-colors cursor-pointer"
          aria-label="Back"
        >
          <ArrowLeft className="w-6 h-6 stroke-[2.3]" />
        </button>

        {notifications.length > 0 && unreadCount > 0 && (
          <button
            type="button"
            onClick={handleMarkAllRead}
            className="text-xs font-semibold text-white/60 hover:text-white transition-colors cursor-pointer"
          >
            Mark all read
          </button>
        )}
      </div>

      {/* 3. TITLE ROW: NOTIFICATIONS BADGE */}
      <div className="px-4 pt-4 flex items-center gap-2.5">
        <h1 className="text-3xl font-extrabold text-white tracking-tight">Notifications</h1>
        {unreadCount > 0 && (
          <span className="w-6 h-6 rounded-full bg-[#E50914] text-xs font-bold text-white flex items-center justify-center shadow-md">
            {unreadCount}
          </span>
        )}
      </div>

      {/* 4. NOTIFICATION LIST OR EMPTY STATE */}
      {notifications.length === 0 ? (
        <div className="flex-1 flex flex-col items-center justify-center p-8 text-center my-auto">
          <div className="w-16 h-16 rounded-3xl bg-white/[0.06] border border-white/10 flex items-center justify-center mb-4 text-white/40 shadow-inner">
            <BellOff className="w-8 h-8" />
          </div>
          <h3 className="text-lg font-bold text-white mb-1.5">No notifications yet</h3>
          <p className="text-xs text-neutral-400 max-w-xs leading-relaxed">
            We will notify you right here whenever newly translated Luganda movies and series drop!
          </p>
        </div>
      ) : (
        <div className="px-4 mt-4 divide-y divide-white/[0.06] flex-1">
          <div className="py-2">
            <span className="text-xs font-semibold text-neutral-400 uppercase tracking-wider">Recent</span>
          </div>

          {notifications.map((notif) => (
            <div
              key={notif.id}
              onClick={() => handleItemClick(notif)}
              className="py-3.5 flex items-start gap-3.5 cursor-pointer group active:bg-white/[0.02] transition-colors rounded-xl px-1"
            >
              {/* Poster Thumbnail */}
              <div className="w-14 h-20 rounded-xl overflow-hidden bg-neutral-900 shrink-0 border border-white/10 relative shadow-md group-hover:scale-105 transition-transform">
                {notif.posterImage ? (
                  <img
                    src={notif.posterImage}
                    alt=""
                    onError={(e) => {
                      (e.target as HTMLImageElement).style.display = "none";
                    }}
                    className="w-full h-full object-cover"
                  />
                ) : (
                  <div className="w-full h-full flex items-center justify-center bg-purple-950 text-white font-bold text-[10px] p-1 text-center">
                    {notif.movieTitle}
                  </div>
                )}
                <div className="absolute inset-0 bg-gradient-to-t from-black/40 via-transparent to-transparent pointer-events-none" />
              </div>

              {/* Notification Text Content */}
              <div className="flex-1 min-w-0 pr-1">
                <p className="text-xs sm:text-sm font-semibold text-white/90 leading-snug line-clamp-2 group-hover:text-white transition-colors">
                  {notif.title}
                </p>
                <div className="mt-1.5 flex items-center gap-2">
                  <span className="text-[11px] font-medium text-neutral-400">{notif.timestamp}</span>
                  {notif.isSeries && (
                    <span className="text-[10px] font-bold text-[#00E676] bg-[#00E676]/10 px-1.5 py-0.2 rounded">
                      Series
                    </span>
                  )}
                </div>
              </div>

              {/* Blue Unread Dot */}
              {notif.isUnread && (
                <div className="w-2.5 h-2.5 rounded-full bg-[#00B0FF] shrink-0 mt-2 shadow-[0_0_8px_rgba(0,176,255,0.7)]" />
              )}
            </div>
          ))}
        </div>
      )}

      {/* 5. FIXED BOTTOM NAVIGATION BAR */}
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
          <UserIcon className="w-5 h-5 text-neutral-500" />
          <span className="text-[10px] font-medium text-neutral-500">Profile</span>
        </button>
      </nav>
    </div>
  );
};
