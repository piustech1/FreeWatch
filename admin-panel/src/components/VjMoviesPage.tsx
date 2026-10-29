import React, { useState, useEffect, useMemo } from "react";
import {
  ArrowLeft,
  Search as SearchIcon,
  Bell,
  Home,
  Heart,
  Download,
  User as UserIcon,
  Star,
  Play,
  Film,
} from "lucide-react";
import { FreeWatchLogo } from "./HomePage";
import { VJDetailItem } from "./AvailableVJsPage";
import { useLiveCatalog, CatalogMovie } from "../data/liveCatalog";
import { AvatarGraphic } from "./AvatarGraphic";
import { UserProfileData } from "./EditProfileModal";
import { VjBadge } from "./VjBadge";

interface VjMoviesPageProps {
  vj: VJDetailItem;
  onBack: () => void;
  onSelectMovie: (movieId: string, isSeries?: boolean, title?: string, movie?: CatalogMovie) => void;
  onNavigateTab: (tab: "home" | "search" | "favorites" | "downloads" | "profile") => void;
  onNavigateToNotifications?: () => void;
  onLogout?: () => void;
  userProfile?: UserProfileData;
}

export const VjMoviesPage: React.FC<VjMoviesPageProps> = ({
  vj,
  onBack,
  onSelectMovie,
  onNavigateTab,
  onNavigateToNotifications,
  userProfile,
}) => {
  const { getMoviesByVj } = useLiveCatalog();
  const [apiVjMovies, setApiVjMovies] = useState<CatalogMovie[]>([]);

  // Asynchronously query MunoWatch for this VJ to populate real titles if needed
  useEffect(() => {
    let cancelled = false;
    const cleanVj = vj.name.toLowerCase().replace("vj", "").trim();

    fetch(`/api/v1/search?q=${encodeURIComponent(vj.name)}`)
      .then((r) => (r.ok ? r.json() : null))
      .then((json) => {
        if (!cancelled && json && json.success && Array.isArray(json.data)) {
          const matched: CatalogMovie[] = json.data
            .filter((m: any) => {
              const mvj = (m.vj || "").toLowerCase();
              return mvj.includes(cleanVj) || cleanVj.includes(mvj);
            })
            .map((m: any, idx: number) => ({
              id: String(m.id || `vj-api-${idx}`),
              title: m.title,
              vj: m.vj || vj.name,
              category: m.category || "Action",
              genres: m.genres || [m.category || "Action", "Luganda Dubbed"],
              imageUrl: m.poster || m.image || "https://apposters.b-cdn.net/laba/yo/naki/gNxs2151.jpg",
              backdropUrl: m.backdrop || m.poster || "",
              rating: String(m.rating || "8.5"),
              year: String(m.year || "2025"),
              duration: m.duration || (m.isTv ? "50m" : "1h 45m"),
              isTv: Boolean(m.isTv || m.is_series),
              seriesCode: m.series_code,
              overview: m.overview || "",
              streamUrl: m.streamUrl || m.playingurl || "",
              episodes: m.episodes,
            }));
          setApiVjMovies(matched);
        }
      })
      .catch(() => {});

    return () => {
      cancelled = true;
    };
  }, [vj.name]);

  const moviesToDisplay = useMemo(() => {
    const list = getMoviesByVj(vj.name);
    if (apiVjMovies.length > 0) {
      const seen = new Set(list.map((m) => m.id));
      const combined = [...list];
      apiVjMovies.forEach((m) => {
        if (!seen.has(m.id)) {
          seen.add(m.id);
          combined.push(m);
        }
      });
      return combined;
    }
    return list;
  }, [vj.name, getMoviesByVj, apiVjMovies]);

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

      {/* 2. SUBHEADER: BACK BUTTON, VJ NAME & MOVIE COUNT PILL */}
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

          <div className="flex items-center gap-2.5">
            <div className="w-8 h-8 rounded-full overflow-hidden bg-purple-900 border border-white/20 shrink-0">
              <img
                src={vj.photoUrl}
                alt={vj.name}
                onError={(e) => {
                  (e.target as HTMLImageElement).src = "/vjs/vj_universal.png";
                }}
                className="w-full h-full object-cover"
              />
            </div>
            <div>
              <h1 className="text-xl font-black text-white tracking-tight">{vj.name}</h1>
              <p className="text-xs text-[#00E676] font-semibold">{vj.subtitle}</p>
            </div>
          </div>
        </div>

        <div className="px-3 py-1 rounded-full bg-white/[0.06] border border-white/10 text-xs font-semibold text-white/70 backdrop-blur-md">
          {moviesToDisplay.length} Movies
        </div>
      </div>

      {/* 3. MOVIES POSTER GRID OR EMPTY STATE */}
      {moviesToDisplay.length === 0 ? (
        <div className="flex-1 flex flex-col items-center justify-center py-24 px-4 text-center">
          <div className="w-16 h-16 rounded-2xl bg-purple-950/40 border border-purple-500/20 flex items-center justify-center mb-3">
            <Film className="w-8 h-8 text-purple-400" />
          </div>
          <h3 className="text-base font-bold text-white">No movies found for {vj.name}</h3>
          <p className="text-xs text-neutral-400 max-w-sm mt-1">
            We are continuously indexing more Luganda releases translated by {vj.name}. Check back soon!
          </p>
        </div>
      ) : (
        <div className="px-4 lg:px-8 pt-3 grid grid-cols-3 sm:grid-cols-4 md:grid-cols-5 lg:grid-cols-6 gap-3.5 max-w-7xl mx-auto w-full flex-1">
          {moviesToDisplay.map((movie) => (
            <div
              key={movie.id}
              onClick={() => onSelectMovie(movie.id, movie.isTv, movie.title, movie)}
              className="cursor-pointer group flex flex-col active:scale-95 transition-transform select-none"
            >
              {/* Poster Card */}
              <div className="relative aspect-[2/3] rounded-2xl overflow-hidden bg-neutral-900 border border-white/10 group-hover:border-white/30 group-hover:scale-[1.03] transition-all shadow-md p-2 flex flex-col justify-between">
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
                  <VjBadge vjName={movie.vj || vj.name} size="sm" />
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
      )}

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
