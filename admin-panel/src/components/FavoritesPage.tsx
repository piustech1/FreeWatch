import React, { useState, useEffect } from "react";
import {
  Search as SearchIcon,
  Bell,
  Play,
  Heart,
  Home,
  Download,
  User as UserIcon,
  Trash2,
} from "lucide-react";
import { FreeWatchLogo } from "./HomePage";
import { CatalogMovie } from "../data/liveCatalog";
import { AvatarGraphic } from "./AvatarGraphic";
import { UserProfileData } from "./EditProfileModal";

interface FavoritesPageProps {
  onNavigateTab: (tab: "home" | "search" | "favorites" | "downloads" | "profile") => void;
  onLogout?: () => void;
  userProfile?: UserProfileData;
  onSelectMovie?: (movieId: string, isSeries?: boolean, title?: string, movie?: CatalogMovie) => void;
  onNavigateToNotifications?: () => void;
}

export const FavoritesPage: React.FC<FavoritesPageProps> = ({
  onNavigateTab,
  onLogout,
  userProfile,
  onSelectMovie,
  onNavigateToNotifications,
}) => {
  const [favorites, setFavorites] = useState<CatalogMovie[]>([]);

  useEffect(() => {
    try {
      const saved = localStorage.getItem("freewatch_favorites");
      if (saved) {
        setFavorites(JSON.parse(saved));
      }
    } catch {}
  }, []);

  const handleRemoveFavorite = (movieId: string, e: React.MouseEvent) => {
    e.stopPropagation();
    const next = favorites.filter((m) => m.id !== movieId);
    setFavorites(next);
    try {
      localStorage.setItem("freewatch_favorites", JSON.stringify(next));
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
              32
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

      {/* 2. MAIN CONTENT AREA */}
      {favorites.length === 0 ? (
        <div className="flex-1 flex flex-col items-center justify-center py-24 px-4 text-center">
          <div className="w-36 h-36 mb-6 flex items-center justify-center">
            <img
              src="/assets/images/empty_favorites.svg"
              alt="Empty Favorites"
              className="w-full h-full object-contain filter drop-shadow-[0_4px_20px_rgba(0,0,0,0.8)]"
              onError={(e) => {
                (e.target as HTMLImageElement).style.display = "none";
              }}
            />
          </div>
          <h3 className="text-xl font-black text-white mb-2">No Favorites Yet</h3>
          <p className="text-xs text-neutral-400 max-w-xs mb-6 leading-relaxed">
            Discover great Luganda dubbed movies and series, then tap the bookmark icon to save them for easy access.
          </p>
          <button
            type="button"
            onClick={() => onNavigateTab("home")}
            className="px-7 py-3.5 rounded-full bg-[#00E676] hover:bg-[#00c853] text-black font-extrabold text-xs uppercase tracking-wider active:scale-95 transition-all shadow-lg shadow-[#00E676]/25 cursor-pointer"
          >
            Browse Movies
          </button>
        </div>
      ) : (
        <section className="max-w-7xl mx-auto w-full px-4 lg:px-8 mt-6">
          <div className="flex items-center justify-between mb-4">
            <div className="flex items-center gap-2">
              <Heart className="w-4 h-4 text-[#00E676] fill-[#00E676]" />
              <h2 className="text-sm font-extrabold text-white tracking-wider uppercase">
                MY FAVORITES ({favorites.length})
              </h2>
            </div>
            <button
              type="button"
              onClick={() => {
                setFavorites([]);
                try {
                  localStorage.removeItem("freewatch_favorites");
                } catch {}
              }}
              className="text-xs text-neutral-400 hover:text-red-400 transition-colors cursor-pointer"
            >
              Clear all
            </button>
          </div>

          {/* Grid of favorited movies */}
          <div className="grid grid-cols-3 sm:grid-cols-4 md:grid-cols-5 lg:grid-cols-6 xl:grid-cols-7 gap-3 lg:gap-4">
            {favorites.map((movie) => (
              <div
                key={movie.id}
                onClick={() => onSelectMovie?.(movie.id, movie.isTv, movie.title, movie)}
                className="cursor-pointer group active:scale-95 transition-transform select-none relative"
              >
                <div className="relative aspect-[2/3] rounded-2xl overflow-hidden bg-neutral-900 border border-white/10 group-hover:border-[#00E676]/60 transition-all p-2 flex flex-col justify-between shadow-lg">
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
                  <div className="absolute inset-0 bg-gradient-to-t from-black via-black/35 to-transparent pointer-events-none" />

                  {/* Top: Remove button & Rating */}
                  <div className="relative z-10 flex items-center justify-between">
                    <span className="px-1.5 py-0.5 rounded bg-black/60 backdrop-blur-md text-amber-400 text-[10px] font-bold">
                      ★ {movie.rating}
                    </span>
                    <button
                      type="button"
                      onClick={(e) => handleRemoveFavorite(movie.id, e)}
                      title="Remove from favorites"
                      className="w-6 h-6 rounded-full bg-black/60 hover:bg-red-600/80 text-white flex items-center justify-center transition-colors cursor-pointer"
                    >
                      <Trash2 className="w-3 h-3" />
                    </button>
                  </div>

                  {/* Center Play Button on Hover */}
                  <div className="absolute inset-0 flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity z-10 pointer-events-none">
                    <div className="w-9 h-9 rounded-full bg-[#00E676] text-black flex items-center justify-center shadow-lg">
                      <Play className="w-4 h-4 fill-black ml-0.5" />
                    </div>
                  </div>

                  {/* Bottom: Title */}
                  <div className="relative z-10 text-left pt-6">
                    <div className="text-xs font-black text-white leading-tight drop-shadow-md line-clamp-2">
                      {movie.title}
                    </div>
                  </div>
                </div>

                <div className="mt-1.5 flex items-center gap-1.5 text-[11px] text-neutral-400 font-medium">
                  <span className="text-neutral-400">{movie.year}</span>
                  {movie.isTv && (
                    <>
                      <span>•</span>
                      <span className="text-[#00E676] font-semibold">Series</span>
                    </>
                  )}
                </div>
              </div>
            ))}
          </div>
        </section>
      )}

      {/* 3. FIXED BOTTOM NAVIGATION BAR (Hidden on desktop) */}
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
