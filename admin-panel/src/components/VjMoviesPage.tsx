import React, { useState, useEffect, useMemo } from "react";
import {
  ArrowLeft,
  Search as SearchIcon,
  Bell,
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
import { FloatingBottomNav } from "./FloatingBottomNav";

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
  const initialLocal = useMemo(() => getMoviesByVj(vj.name), [getMoviesByVj, vj.name]);
  const [isLoading, setIsLoading] = useState<boolean>(initialLocal.length === 0);

  // Asynchronously query MunoWatch for this VJ to populate real titles
  useEffect(() => {
    let cancelled = false;
    const cleanVj = vj.name.toLowerCase().replace("vj", "").trim();

    async function fetchVjReleases() {
      if (initialLocal.length === 0) {
        setIsLoading(true);
      }
      try {
        let resultsData: any[] = [];

        // 1. First try serverless endpoint
        try {
          const r = await fetch(`/api/v1/search?q=${encodeURIComponent(vj.name)}`);
          if (r.ok) {
            const json = await r.json();
            if (json && json.success && Array.isArray(json.data) && json.data.length > 0) {
              resultsData = json.data;
            }
          }
        } catch (_) {}

        // 2. Direct fallback to MunoWatch public API if serverless returned empty
        if (resultsData.length === 0) {
          try {
            const munoRes = await fetch(`https://mumowatch.ai.studio/search?q=${encodeURIComponent(vj.name)}`);
            if (munoRes.ok) {
              const mData = await munoRes.json();
              if (Array.isArray(mData.series)) {
                mData.series.forEach((s: any) => {
                  if (Array.isArray(s.episodes) && s.episodes.length > 0) {
                    const ep = s.episodes[0];
                    resultsData.push({
                      ...ep,
                      title: s.title || ep.title,
                      vj: s.vj || ep.vj || vj.name,
                      isTv: true,
                    });
                  }
                });
              }
              if (Array.isArray(mData.movies)) {
                resultsData.push(...mData.movies);
              }
            }
          } catch (_) {}
        }

        if (!cancelled && resultsData.length > 0) {
          const matched: CatalogMovie[] = resultsData
            .filter((m: any) => {
              const mvj = (m.vj || m.vjname || "").toLowerCase();
              return mvj.includes(cleanVj) || cleanVj.includes(mvj) || !mvj || mvj.includes("universal");
            })
            .map((m: any, idx: number) => ({
              id: String(m.id || `vj-api-${idx}`),
              title: m.title || m.video_title || `Movie #${m.id}`,
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
      } catch (_) {
      } finally {
        if (!cancelled) {
          setIsLoading(false);
        }
      }
    }

    fetchVjReleases();

    return () => {
      cancelled = true;
    };
  }, [vj.name, initialLocal.length]);

  const moviesToDisplay = useMemo(() => {
    const list = getMoviesByVj(vj.name);
    if (apiVjMovies.length > 0) {
      const seen = new Set(list.map((m) => m.id));
      const seenTitles = new Set(list.map((m) => m.title.toLowerCase().trim()));
      const combined = [...list];
      apiVjMovies.forEach((m) => {
        const normTitle = m.title.toLowerCase().trim();
        if (!seen.has(m.id) && !seenTitles.has(normTitle)) {
          seen.add(m.id);
          seenTitles.add(normTitle);
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

      {/* 3. MOVIES POSTER GRID, SKELETON LOADER, OR EMPTY STATE */}
      {isLoading && moviesToDisplay.length === 0 ? (
        <div className="px-4 lg:px-8 pt-3 grid grid-cols-3 sm:grid-cols-4 md:grid-cols-5 lg:grid-cols-6 gap-3.5 max-w-7xl mx-auto w-full flex-1">
          {Array.from({ length: 12 }).map((_, i) => (
            <div key={`vj-skel-${i}`} className="flex flex-col space-y-2">
              <div className="aspect-[2/3] rounded-2xl bg-white/[0.05] border border-white/5 animate-pulse relative overflow-hidden flex flex-col justify-between p-2">
                <div className="flex justify-end">
                  <div className="w-12 h-4 rounded-full bg-white/10" />
                </div>
                <div className="space-y-1.5">
                  <div className="w-3/4 h-3 rounded bg-white/10" />
                  <div className="w-1/2 h-2.5 rounded bg-white/10" />
                </div>
              </div>
              <div className="flex items-center gap-2 px-1">
                <div className="w-8 h-2.5 rounded bg-white/10 animate-pulse" />
                <div className="w-8 h-2.5 rounded bg-white/10 animate-pulse" />
              </div>
            </div>
          ))}
        </div>
      ) : moviesToDisplay.length === 0 ? (
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

      {/* 4. FLOATING CURVED BOTTOM NAVIGATION PILL */}
      <FloatingBottomNav onNavigateTab={onNavigateTab} />
    </div>
  );
};
