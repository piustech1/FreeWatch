import React, { useState } from "react";
import {
  Search as SearchIcon,
  Bell,
  Play,
  Heart,
  Home,
  Download,
  User as UserIcon,
} from "lucide-react";
import { FreeWatchLogo } from "./HomePage";

interface FavoritesPageProps {
  onNavigateTab: (tab: "home" | "search" | "favorites" | "downloads" | "profile") => void;
  onLogout?: () => void;
  onSelectMovie?: (movieId: string, isSeries?: boolean, title?: string) => void;
  onNavigateToNotifications?: () => void;
}

interface FavoriteMovieItem {
  id: string;
  title: string;
  rating: string;
  posterGradient: string;
  subtitle?: string;
  highlightTitle?: string;
}

const CONTINUE_WATCHING_ITEMS = [
  {
    id: "cw-1",
    title: "The Soccer Football Movie",
    progress: 35,
    gradient: "from-red-950 via-zinc-900 to-black",
  },
  {
    id: "cw-2",
    title: "Supacell",
    progress: 60,
    gradient: "from-amber-950 via-stone-900 to-black",
  },
];

const FAVORITE_MOVIES: FavoriteMovieItem[] = [
  {
    id: "fav-1",
    title: "Just Say It: Ava Peace",
    rating: "8.4",
    posterGradient: "from-purple-900 via-indigo-950 to-black",
    highlightTitle: "The story behind the hits",
  },
  {
    id: "fav-2",
    title: "What If",
    rating: "8.4",
    posterGradient: "from-sky-500 via-blue-600 to-indigo-950",
    highlightTitle: "WHAT IF",
  },
  {
    id: "fav-3",
    title: "Hope",
    rating: "8.4",
    posterGradient: "from-slate-700 via-zinc-900 to-black",
    highlightTitle: "HOPE",
  },
  {
    id: "fav-4",
    title: "Mapanukso",
    rating: "0.0",
    posterGradient: "from-stone-300 via-stone-600 to-stone-900",
    highlightTitle: "Mapanukso",
  },
  {
    id: "fav-5",
    title: "Insidious: Out of the ...",
    rating: "8.4",
    posterGradient: "from-teal-950 via-stone-900 to-black",
    highlightTitle: "INSIDIOUS",
  },
  {
    id: "fav-6",
    title: "Jurassic World: Rebir...",
    rating: "8.4",
    posterGradient: "from-red-950 via-amber-950 to-black",
    highlightTitle: "JURASSIC WORLD",
  },
  {
    id: "fav-7",
    title: "VJ Junior Special",
    rating: "8.8",
    posterGradient: "from-emerald-600 via-green-800 to-black",
    highlightTitle: "VJ JUNIOR",
  },
  {
    id: "fav-8",
    title: "Fall: The Edge",
    rating: "8.2",
    posterGradient: "from-stone-400 via-stone-700 to-stone-950",
    highlightTitle: "FALL",
  },
  {
    id: "fav-9",
    title: "Chappie / Automata",
    rating: "8.4",
    posterGradient: "from-sky-900 via-slate-800 to-zinc-900",
    highlightTitle: "REJECT",
  },
];

export const FavoritesPage: React.FC<FavoritesPageProps> = ({
  onNavigateTab,
  onLogout,
  onSelectMovie,
  onNavigateToNotifications,
}) => {
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
              32
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

      {/* 2. CONTINUE WATCHING SECTION */}
      <section className="px-4 pt-4">
        <h2 className="text-sm font-extrabold text-white tracking-wider uppercase mb-3">
          CONTINUE WATCHING
        </h2>

        {/* 2 Cards Row */}
        <div className="grid grid-cols-2 gap-3">
          {CONTINUE_WATCHING_ITEMS.map((item) => (
            <div
              key={item.id}
              onClick={() => onSelectMovie?.(item.id, false, item.title)}
              className={`relative aspect-video rounded-2xl overflow-hidden bg-gradient-to-t ${item.gradient} border border-white/10 p-2.5 flex flex-col justify-between cursor-pointer group shadow-lg active:scale-95 transition-transform`}
            >
              <div />

              {/* Center Play Button */}
              <div className="self-center w-10 h-10 rounded-full bg-white/90 text-black flex items-center justify-center shadow-lg group-hover:scale-105 transition-transform">
                <Play className="w-4 h-4 fill-black text-black ml-0.5" />
              </div>

              {/* Title Overlay */}
              <div>
                <h4 className="text-xs font-bold text-white leading-tight drop-shadow-md truncate">
                  {item.title}
                </h4>
              </div>

              {/* Bottom Progress Bar */}
              <div className="absolute bottom-0 left-0 right-0 h-1 bg-white/20">
                <div
                  className="h-full bg-[#00E676]"
                  style={{ width: `${item.progress}%` }}
                />
              </div>
            </div>
          ))}
        </div>
      </section>

      {/* 3. MY FAVORITES SECTION */}
      <section className="max-w-7xl mx-auto w-full px-4 lg:px-8 mt-6">
        <h2 className="text-sm font-extrabold text-white tracking-wider uppercase mb-3">
          MY FAVORITES
        </h2>

        {/* Responsive Movie Grid (3-cols mobile, 6-7 cols desktop) */}
        <div className="grid grid-cols-3 sm:grid-cols-4 md:grid-cols-5 lg:grid-cols-6 xl:grid-cols-7 gap-3 lg:gap-4">
          {FAVORITE_MOVIES.map((movie) => (
            <div
              key={movie.id}
              onClick={() => onSelectMovie?.(movie.id, false, movie.title)}
              className="cursor-pointer group active:scale-95 transition-transform"
            >
              <div
                className={`relative aspect-[2/3] rounded-2xl overflow-hidden bg-gradient-to-t ${movie.posterGradient} border border-white/10 group-hover:border-white/30 group-hover:scale-[1.03] transition-all p-2 flex flex-col justify-end shadow-md`}
              >
                <div className="text-center pb-1">
                  <div className="text-[11px] font-black text-white leading-tight drop-shadow-md line-clamp-2">
                    {movie.highlightTitle || movie.title}
                  </div>
                </div>
              </div>

              <div className="mt-1.5 space-y-0.5">
                <h4 className="text-[11.5px] font-bold text-white truncate">
                  {movie.title}
                </h4>
                <div className="flex items-center gap-1 text-[11px] text-neutral-400 font-medium">
                  <span className="text-amber-400">★ {movie.rating}</span>
                </div>
              </div>
            </div>
          ))}
        </div>
      </section>

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
          <Heart className="w-5 h-5 fill-[#00E676] text-[#00E676]" />
          <span className="text-[10px] font-medium text-[#00E676]">Favorites</span>
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
