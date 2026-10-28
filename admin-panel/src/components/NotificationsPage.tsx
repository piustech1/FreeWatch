import React, { useState } from "react";
import {
  ArrowLeft,
  Search as SearchIcon,
  Bell,
  Home,
  Heart,
  Download,
  User as UserIcon,
} from "lucide-react";
import { FreeWatchLogo } from "./HomePage";

interface NotificationItem {
  id: string;
  title: string;
  timestamp: string;
  isUnread: boolean;
  isSeries?: boolean;
  movieTitle: string;
  posterBg: string;
  posterImage?: string;
  posterBadgeText?: string;
}

interface NotificationsPageProps {
  onBack: () => void;
  onNavigateTab: (tab: "home" | "search" | "favorites" | "downloads" | "profile") => void;
  onSelectMovie?: (movieId: string, isSeries?: boolean, title?: string) => void;
  onLogout?: () => void;
}

const INITIAL_NOTIFICATIONS: NotificationItem[] = [
  {
    id: "notif-1",
    title: "New Release: Head Over Hooves translated by Vj Mosco is now streaming on FreeWatch!",
    timestamp: "Just now",
    isUnread: true,
    isSeries: false,
    movieTitle: "Head Over Hooves",
    posterBg: "from-sky-500 via-cyan-600 to-amber-700",
    posterBadgeText: "Head Over Hooves",
  },
  {
    id: "notif-2",
    title: "New Release: Shaun the Sheep: The Beast of Mossy Bottom translated by Vj Mosco is now streaming on FreeWatch!",
    timestamp: "Just now",
    isUnread: true,
    isSeries: false,
    movieTitle: "Shaun the Sheep: The Beast of Mossy Bottom",
    posterBg: "from-purple-900 via-indigo-950 to-emerald-950",
    posterBadgeText: "Shaun the Sheep",
  },
  {
    id: "notif-3",
    title: "New Release: PAW Patrol: The Dino Movie translated by Vj Mosco is now streaming on FreeWatch!",
    timestamp: "Just now",
    isUnread: true,
    isSeries: false,
    movieTitle: "PAW Patrol: The Dino Movie",
    posterBg: "from-amber-600 via-orange-800 to-amber-950",
    posterBadgeText: "PAW PATROL",
  },
  {
    id: "notif-4",
    title: "New Release: Garuda di Dadaku translated by Vj Mosco is now streaming on FreeWatch!",
    timestamp: "Just now",
    isUnread: true,
    isSeries: false,
    movieTitle: "Garuda di Dadaku",
    posterBg: "from-blue-700 via-cyan-900 to-stone-900",
    posterBadgeText: "GARUDA DI DADAKU",
  },
  {
    id: "notif-5",
    title: "New Release: Chickenhare and the Secret of the Groundhog translated by Vj Mosco is now streaming on FreeWatch!",
    timestamp: "Just now",
    isUnread: true,
    isSeries: false,
    movieTitle: "Chickenhare and the Secret of the Groundhog",
    posterBg: "from-rose-800 via-amber-900 to-orange-950",
    posterBadgeText: "Chickenhare",
  },
  {
    id: "notif-6",
    title: "New Release: Chickenhare and the Secret of the Groundhog translated by Vj Mosco is now streaming on FreeWatch!",
    timestamp: "Just now",
    isUnread: true,
    isSeries: false,
    movieTitle: "Chickenhare and the Secret of the Groundhog",
    posterBg: "from-rose-800 via-amber-900 to-orange-950",
    posterBadgeText: "Chickenhare",
  },
  {
    id: "notif-7",
    title: "New Release: EPS 1 - 2 translated by Luganda Dubbed is now streaming on FreeWatch!",
    timestamp: "Just now",
    isUnread: true,
    isSeries: true,
    movieTitle: "Wednesday Season 2: Episode 1",
    posterBg: "from-stone-900 via-zinc-800 to-black",
    posterBadgeText: "EPS 1 - 2",
  },
];

export const NotificationsPage: React.FC<NotificationsPageProps> = ({
  onBack,
  onNavigateTab,
  onSelectMovie,
}) => {
  const [notifications, setNotifications] = useState<NotificationItem[]>(INITIAL_NOTIFICATIONS);

  const unreadCount = notifications.filter((n) => n.isUnread).length;

  const handleMarkAllRead = () => {
    setNotifications((prev) => prev.map((item) => ({ ...item, isUnread: false })));
  };

  const handleItemClick = (notif: NotificationItem) => {
    // mark single as read
    setNotifications((prev) =>
      prev.map((item) => (item.id === notif.id ? { ...item, isUnread: false } : item))
    );
    if (onSelectMovie) {
      onSelectMovie(notif.id, notif.isSeries, notif.movieTitle);
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
            <img
              src="https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100&auto=format&fit=crop&q=80"
              alt="Profile"
              className="w-full h-full object-cover"
            />
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

        <button
          type="button"
          onClick={handleMarkAllRead}
          className="text-xs font-medium text-neutral-400 hover:text-white transition-colors cursor-pointer"
        >
          Mark all read
        </button>
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

      {/* 4. SECTION HEADER: TODAY */}
      <div className="px-4 pt-5 pb-2">
        <span className="text-sm font-medium text-neutral-400">Today</span>
      </div>

      {/* 5. NOTIFICATION LIST */}
      <div className="px-4 divide-y divide-white/[0.06] flex-1">
        {notifications.map((notif) => (
          <div
            key={notif.id}
            onClick={() => handleItemClick(notif)}
            className="py-3.5 flex items-start gap-3.5 cursor-pointer group active:bg-white/[0.02] transition-colors rounded-xl px-1"
          >
            {/* Poster Thumbnail */}
            <div
              className={`w-14 h-18 sm:w-16 sm:h-20 rounded-xl overflow-hidden bg-gradient-to-t ${notif.posterBg} shrink-0 border border-white/10 flex flex-col justify-between p-1.5 shadow-md group-hover:scale-105 transition-transform`}
            >
              <div className="text-[8px] font-black uppercase tracking-tight text-white/90 leading-tight">
                {notif.posterBadgeText}
              </div>
              <div className="w-full text-center">
                <span className="text-[7.5px] px-1 py-0.5 rounded bg-black/60 font-bold text-[#00E676]">
                  HD
                </span>
              </div>
            </div>

            {/* Notification Text and Meta */}
            <div className="flex-1 min-w-0 pr-2">
              <p className="text-xs sm:text-sm font-medium text-white leading-snug line-clamp-2">
                {notif.title}
              </p>
              <span className="text-[11px] text-neutral-400 font-normal mt-1 block">
                {notif.timestamp}
              </span>
            </div>

            {/* Unread Red Dot */}
            <div className="pt-2 shrink-0">
              {notif.isUnread && (
                <span className="w-2.5 h-2.5 rounded-full bg-[#E50914] block shadow-sm shadow-[#E50914]/50" />
              )}
            </div>
          </div>
        ))}
      </div>

      {/* 6. FIXED BOTTOM NAVIGATION BAR (Hidden on desktop) */}
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
    </div>
  );
};
