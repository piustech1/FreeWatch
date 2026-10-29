import React, { useMemo } from "react";
import {
  ArrowLeft,
  Search as SearchIcon,
  Bell,
  Home,
  Heart,
  Download,
  User as UserIcon,
  Star,
  Sparkles,
  Flame,
  Tv,
  Moon,
  Smile,
  Rocket,
  Compass,
  TrendingUp,
  Play,
} from "lucide-react";
import { FreeWatchLogo } from "./HomePage";
import { useLiveCatalog, CatalogMovie } from "../data/liveCatalog";
import { AvatarGraphic } from "./AvatarGraphic";
import { UserProfileData } from "./EditProfileModal";

interface CategorySeeAllPageProps {
  categoryTitle: string;
  count?: number;
  iconType?: string;
  onBack: () => void;
  onSelectMovie: (movieId: string, isSeries?: boolean, title?: string, movie?: CatalogMovie) => void;
  onNavigateTab: (tab: "home" | "search" | "favorites" | "downloads" | "profile") => void;
  onNavigateToNotifications?: () => void;
  onLogout?: () => void;
  userProfile?: UserProfileData;
}

export const CategorySeeAllPage: React.FC<CategorySeeAllPageProps> = ({
  categoryTitle = "Latest on FreeWatch",
  count = 43,
  iconType = "sparkles",
  onBack,
  onSelectMovie,
  onNavigateTab,
  onNavigateToNotifications,
  userProfile,
}) => {
  const {
    catalog,
    latestMovies,
    trendingMovies,
    seriesMovies,
    actionMovies,
    dramaMovies,
    sciFiMovies,
  } = useLiveCatalog();

  const moviesToDisplay: CatalogMovie[] = useMemo(() => {
    const t = categoryTitle.toLowerCase();
    if (t.includes("latest")) return latestMovies;
    if (t.includes("trend")) return trendingMovies;
    if (t.includes("series") || t.includes("tv")) return seriesMovies;
    if (t.includes("action")) return actionMovies;
    if (t.includes("sci-fi") || t.includes("fantasy")) return sciFiMovies;
    if (t.includes("romance") || t.includes("drama")) return dramaMovies;
    if (t.includes("horror") || t.includes("thriller")) {
      return catalog.filter((m) => /horror|thriller/i.test(m.category));
    }
    return catalog;
  }, [categoryTitle, latestMovies, trendingMovies, seriesMovies, actionMovies, sciFiMovies, dramaMovies, catalog]);

  const renderIcon = () => {
    switch (iconType) {
      case "flame":
        return <Flame className="w-4 h-4 text-orange-500" />;
      case "tv":
        return <Tv className="w-4 h-4 text-red-500" />;
      case "rocket":
        return <Rocket className="w-4 h-4 text-purple-400" />;
      case "heart":
        return <Heart className="w-4 h-4 text-pink-500 fill-pink-500" />;
      case "moon":
        return <Moon className="w-4 h-4 text-red-500 fill-red-500" />;
      case "smile":
        return <Smile className="w-4 h-4 text-amber-400" />;
      case "trending":
        return <TrendingUp className="w-4 h-4 text-[#00E676]" />;
      default:
        return <Sparkles className="w-4 h-4 text-[#00E5FF]" />;
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
            onClick={onNavigateToNotifications}
            className="relative p-1 text-white hover:text-[#00E676] transition-colors cursor-pointer"
            aria-label="Notifications"
          >
            <Bell className="w-5 h-5 stroke-[2.2]" />
            <span className="absolute -top-1 -right-1.5 w-4 h-4 rounded-full bg-[#E50914] text-[10px] font-bold text-white flex items-center justify-center">
              37
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

      {/* 2. SUBHEADER: BACK BUTTON, SECTION TITLE & COUNT PILL */}
      <div className="px-4 pt-3 pb-2 flex items-center justify-between">
        <div className="flex items-center gap-3">
          <button
            type="button"
            onClick={onBack}
            className="w-9 h-9 rounded-full bg-[#1c1c1f] hover:bg-[#27272a] flex items-center justify-center text-white transition-colors cursor-pointer shrink-0"
            aria-label="Back"
          >
            <ArrowLeft className="w-5 h-5 stroke-[2.2]" />
          </button>

          <div className="flex items-center gap-2">
            {renderIcon()}
            <div>
              <h1 className="text-xl font-black text-white tracking-tight">{categoryTitle}</h1>
              <p className="text-xs text-neutral-400 font-normal">Streaming in high quality HD</p>
            </div>
          </div>
        </div>

        <div className="px-3 py-1 rounded-full bg-[#3b0764]/60 border border-[#a855f7]/40 text-xs font-bold text-[#d8b4fe] shadow-sm">
          {moviesToDisplay.length} Movies
        </div>
      </div>

      {/* 3. MOVIES 3-COLUMN POSTER GRID */}
      <div className="px-4 lg:px-8 pt-3 grid grid-cols-3 sm:grid-cols-4 md:grid-cols-5 lg:grid-cols-6 gap-3.5 max-w-7xl mx-auto w-full flex-1">
        {moviesToDisplay.map((movie) => (
          <div
            key={movie.id}
            onClick={() => onSelectMovie(movie.id, movie.isTv, movie.title, movie)}
            className="cursor-pointer group flex flex-col active:scale-95 transition-transform select-none"
          >
            {/* Poster Card */}
            <div className="relative aspect-[2/3] rounded-2xl overflow-hidden bg-neutral-900 border border-white/10 group-hover:border-[#00E676]/60 group-hover:scale-[1.03] transition-all shadow-md p-2 flex flex-col justify-between">
              {movie.imageUrl && (
                <img
                  src={movie.imageUrl}
                  alt={movie.title}
                  onError={(e) => {
                    (e.target as HTMLImageElement).style.display = "none";
                  }}
                  className="absolute inset-0 w-full h-full object-cover filter brightness-85 group-hover:scale-105 transition-transform"
                />
              )}
              <div className="absolute inset-0 bg-gradient-to-t from-black via-black/25 to-transparent pointer-events-none" />

              <div className="relative z-10 flex justify-end">
                <span className="px-1.5 py-0.5 rounded-full bg-[#581c87]/90 border border-purple-400/40 text-[9px] font-bold text-white flex items-center gap-1 shadow-sm">
                  <span>{movie.vj}</span>
                </span>
              </div>

              {/* Hover Play Button */}
              <div className="absolute inset-0 flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity z-10 pointer-events-none">
                <div className="w-9 h-9 rounded-full bg-[#00E676] text-black flex items-center justify-center shadow-lg">
                  <Play className="w-4 h-4 fill-black ml-0.5" />
                </div>
              </div>

              <div className="relative z-10 text-left pt-6">
                <div className="text-xs font-black text-white leading-tight drop-shadow-md line-clamp-2">
                  {movie.title}
                </div>
              </div>
            </div>

            {/* Bottom Rating and Year */}
            <div className="flex items-center gap-1.5 mt-1.5 px-0.5 text-xs font-bold text-neutral-300">
              <div className="flex items-center gap-1 text-amber-400">
                <Star className="w-3 h-3 fill-amber-400" />
                <span className="text-[11px] font-black text-white">{movie.rating}</span>
              </div>
              <span className="text-[11px] font-medium text-neutral-400">• {movie.year}</span>
            </div>
          </div>
        ))}
      </div>

      {/* 4. FIXED BOTTOM NAVIGATION BAR */}
      <nav className="lg:hidden fixed bottom-0 left-0 right-0 z-50 h-16 bg-black/95 backdrop-blur-lg border-t border-white/10 px-4 flex items-center justify-around">
        <button
          type="button"
          onClick={() => onNavigateTab("home")}
          className="flex flex-col items-center gap-1 cursor-pointer transition-colors"
        >
          <Home className="w-5 h-5 text-[#00E676]" />
          <span className="text-[10px] font-medium text-[#00E676]">Home</span>
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
