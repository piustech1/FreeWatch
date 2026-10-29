import React, { useState, useEffect, useMemo } from "react";
import {
  Search as SearchIcon,
  Bell,
  ArrowLeft,
  SlidersHorizontal,
  List,
  Grid,
  X,
  Zap,
  ChevronDown,
  ChevronUp,
  Play,
  Star,
  Home,
  Heart,
  Download,
  User as UserIcon,
} from "lucide-react";
import { FreeWatchLogo } from "./HomePage";
import { useLiveCatalog, CatalogMovie } from "../data/liveCatalog";
import { ALL_VJS } from "./AvailableVJsPage";
import { AvatarGraphic } from "./AvatarGraphic";
import { UserProfileData } from "./EditProfileModal";

export type SearchViewState = "categories" | "results" | "filters";

interface SearchPageProps {
  userProfile?: UserProfileData;
  onBackToHome?: () => void;
  onLogout?: () => void;
  onNavigateTab?: (tab: "home" | "search" | "favorites" | "downloads" | "profile") => void;
  onSelectMovie?: (movieId: string, isSeries?: boolean, title?: string, movie?: CatalogMovie) => void;
  onNavigateToNotifications?: () => void;
}

const CATEGORIES_LIST = [
  "Action",
  "Adventure",
  "Animation",
  "Comedy",
  "Crime",
  "Documentary",
  "Drama",
  "Family",
  "Fantasy",
  "History",
  "Horror",
  "Music",
  "Mystery",
  "Romance",
  "Science Fiction",
  "TV Series",
  "Thriller",
  "War",
  "Western",
];

export const SearchPage: React.FC<SearchPageProps> = ({
  userProfile,
  onBackToHome,
  onLogout,
  onNavigateTab,
  onSelectMovie,
  onNavigateToNotifications,
}) => {
  const [viewState, setViewState] = useState<SearchViewState>("categories");
  const [searchQuery, setSearchQuery] = useState("");
  const [selectedGenre, setSelectedGenre] = useState("All");
  const [selectedVj, setSelectedVj] = useState("All");
  const [selectedType, setSelectedType] = useState("All");
  const [apiResults, setApiResults] = useState<CatalogMovie[]>([]);

  const { searchCatalog, catalog, totalCount } = useLiveCatalog();

  // Trigger live search on MunoWatch backend if query is entered
  useEffect(() => {
    if (!searchQuery.trim()) {
      setApiResults([]);
      return;
    }
    const timer = setTimeout(() => {
      fetch(`/api/v1/search?q=${encodeURIComponent(searchQuery)}`)
        .then((r) => (r.ok ? r.json() : null))
        .then((json) => {
          if (json && json.success && Array.isArray(json.data)) {
            const mapped: CatalogMovie[] = json.data.map((m: any, idx: number) => ({
              id: String(m.id || `api-${idx}`),
              title: m.title,
              vj: m.vj || 'Luganda Dubbed',
              category: m.category || 'Action',
              genres: m.genres || [m.category || 'Action', 'Luganda Dubbed'],
              imageUrl: m.poster || m.image || 'https://apposters.b-cdn.net/laba/yo/naki/gNxs2151.jpg',
              backdropUrl: m.backdrop || m.backdrop_path || m.poster || 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=1600&auto=format&fit=crop&q=80',
              rating: String(m.rating || '8.5'),
              year: String(m.year || '2025'),
              duration: m.duration || (m.isTv ? '50m' : '1h 45m'),
              isTv: Boolean(m.isTv || m.is_series),
              seriesCode: m.series_code,
              overview: m.overview || '',
              streamUrl: m.streamUrl || m.playingurl || '',
              episodes: m.episodes,
            }));
            setApiResults(mapped);
          }
        })
        .catch(() => {});
    }, 350);

    return () => clearTimeout(timer);
  }, [searchQuery]);

  const searchResults: CatalogMovie[] = useMemo(() => {
    let local = searchCatalog(searchQuery, selectedGenre, selectedVj);
    if (searchQuery.trim() && apiResults.length > 0) {
      const seen = new Set(local.map((m) => m.id));
      const merged = [...local];
      apiResults.forEach((ar) => {
        if (!seen.has(ar.id)) {
          seen.add(ar.id);
          merged.push(ar);
        }
      });
      local = merged;
    }
    if (selectedType === "Series") {
      local = local.filter((m) => m.isTv);
    } else if (selectedType === "Movies") {
      local = local.filter((m) => !m.isTv);
    }
    return local;
  }, [searchQuery, selectedGenre, selectedVj, selectedType, searchCatalog, apiResults]);

  const handleSelectCategory = (cat: string) => {
    setSelectedGenre(cat);
    setSearchQuery("");
    setViewState("results");
  };

  return (
    <div className="w-full min-h-screen bg-black text-white font-sans flex flex-col pb-24 select-none">
      {/* 1. TOP HEADER BAR */}
      <header className="sticky top-0 z-40 w-full bg-black/90 backdrop-blur-md px-4 py-3 flex items-center justify-between border-b border-white/5">
        <FreeWatchLogo />

        <div className="flex items-center gap-4">
          <button
            type="button"
            onClick={() => setViewState("categories")}
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
              28
            </span>
          </button>

          <button
            type="button"
            onClick={() => (onNavigateTab ? onNavigateTab("profile") : onLogout?.())}
            title="Account Profile"
            className="w-8 h-8 rounded-full overflow-hidden border border-white/20 active:scale-95 transition-transform cursor-pointer"
          >
            <AvatarGraphic id={userProfile?.avatarId || "mirabel"} />
          </button>
        </div>
      </header>

      {/* ============================================================ */}
      {/* VIEW A: INITIAL CATEGORIES VIEW */}
      {/* ============================================================ */}
      {viewState === "categories" && (
        <div className="px-4 lg:px-8 pt-3 flex-1 max-w-7xl mx-auto w-full">
          {/* Search Pill Input */}
          <div className="w-full h-12 rounded-full bg-[#18181b] border border-white/10 px-5 flex items-center justify-between hover:border-white/20 transition-all shadow-inner">
            <input
              type="text"
              placeholder="Search 7,000+ movies & VJs..."
              value={searchQuery}
              onChange={(e) => {
                setSearchQuery(e.target.value);
                setViewState("results");
              }}
              onFocus={() => setViewState("results")}
              className="w-full bg-transparent text-sm text-white placeholder-neutral-400 focus:outline-none"
            />
            <SearchIcon className="w-4 h-4 text-neutral-400 shrink-0" />
          </div>

          {/* Heading */}
          <div className="text-center mt-7 mb-6 relative">
            <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-48 h-16 bg-[#00E676]/10 rounded-full blur-2xl pointer-events-none" />
            <h1 className="relative text-2xl font-bold text-white tracking-tight">Movie Categories</h1>
            <p className="relative text-xs text-neutral-400 mt-2 leading-relaxed">
              Browse thousands of Luganda dubbed movies &amp; series by genre
            </p>
          </div>

          {/* 2-Column Categories Grid */}
          <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-3">
            {CATEGORIES_LIST.map((cat) => (
              <div
                key={cat}
                onClick={() => handleSelectCategory(cat)}
                className="h-16 rounded-2xl bg-[#141416] hover:bg-[#1f1f23] border border-white/5 hover:border-[#00E676]/40 flex items-center justify-center p-3 cursor-pointer group active:scale-[0.98] transition-all shadow-md"
              >
                <span className="text-sm font-bold text-neutral-200 group-hover:text-[#00E676] transition-colors text-center">
                  {cat}
                </span>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* ============================================================ */}
      {/* VIEW B: RESULTS SEARCH VIEW */}
      {/* ============================================================ */}
      {viewState === "results" && (
        <div className="px-4 lg:px-8 pt-3 flex-1 max-w-7xl mx-auto w-full">
          {/* Active Search Input with Back Arrow */}
          <div className="flex items-center gap-3">
            <button
              type="button"
              onClick={() => setViewState("categories")}
              className="w-10 h-10 rounded-full bg-[#18181b] hover:bg-[#222226] border border-white/10 flex items-center justify-center text-white cursor-pointer shrink-0"
              aria-label="Back to Categories"
            >
              <ArrowLeft className="w-5 h-5 stroke-[2.2]" />
            </button>

            <div className="flex-1 h-12 rounded-full bg-[#18181b] border border-white/10 px-4 flex items-center justify-between">
              <input
                type="text"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                placeholder="Search movies, series or VJs..."
                className="w-full bg-transparent text-sm text-white placeholder-neutral-500 focus:outline-none"
                autoFocus
              />
              {searchQuery ? (
                <button
                  type="button"
                  onClick={() => setSearchQuery("")}
                  className="p-1 text-neutral-400 hover:text-white cursor-pointer"
                >
                  <X className="w-4 h-4" />
                </button>
              ) : (
                <SearchIcon className="w-4 h-4 text-neutral-400" />
              )}
            </div>

            <button
              type="button"
              onClick={() => setViewState("filters")}
              className="w-10 h-10 rounded-full bg-[#18181b] hover:bg-[#222226] border border-white/10 flex items-center justify-center text-white cursor-pointer shrink-0"
              title="Filters"
            >
              <SlidersHorizontal className="w-4 h-4" />
            </button>
          </div>

          {/* Quick Genre Pills */}
          <div className="flex gap-2 overflow-x-auto no-scrollbar py-3">
            {["All", "Action", "Series", "Adventure", "Comedy", "Horror", "Drama", "Sci-Fi"].map((g) => {
              const isActive = selectedGenre === g;
              return (
                <button
                  key={g}
                  type="button"
                  onClick={() => setSelectedGenre(g)}
                  className={`px-3.5 py-1.5 rounded-full text-xs font-semibold whitespace-nowrap transition-all cursor-pointer ${
                    isActive
                      ? "bg-[#00E676] text-black shadow-md shadow-[#00E676]/20 font-black"
                      : "bg-[#18181b] text-neutral-300 border border-white/5 hover:border-white/20"
                  }`}
                >
                  {g}
                </button>
              );
            })}
          </div>

          {/* Subheader: Result Count */}
          <div className="flex items-center justify-between pb-3">
            <span className="text-xs text-neutral-400 font-medium">
              Found <strong className="text-white">{searchResults.length}</strong> titles
              {selectedGenre !== "All" && ` in ${selectedGenre}`}
            </span>
          </div>

          {/* 3-Column / Responsive Results Grid */}
          {searchResults.length === 0 ? (
            <div className="text-center py-20 text-neutral-400">
              <SearchIcon className="w-12 h-12 mx-auto mb-3 opacity-30 text-[#00E676]" />
              <p className="text-base font-bold text-white">No movies found</p>
              <p className="text-xs text-neutral-500 mt-1">Try another search term or clear filters</p>
            </div>
          ) : (
            <div className="grid grid-cols-3 sm:grid-cols-4 md:grid-cols-5 lg:grid-cols-6 gap-3">
              {searchResults.map((movie) => (
                <div
                  key={movie.id}
                  onClick={() => onSelectMovie?.(movie.id, movie.isTv, movie.title, movie)}
                  className="cursor-pointer group flex flex-col active:scale-95 transition-transform select-none"
                >
                  <div className="relative aspect-[2/3] rounded-2xl overflow-hidden bg-neutral-900 border border-white/10 group-hover:border-[#00E676]/60 transition-all p-2 flex flex-col justify-between shadow-md">
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

                  <div className="mt-1 flex items-center gap-1 text-[10.5px] text-neutral-400 font-medium">
                    <span className="text-amber-400 font-bold">★ {movie.rating}</span>
                    <span>•</span>
                    <span>{movie.year}</span>
                    {movie.isTv && <span className="text-[#00E676]">• Series</span>}
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      )}

      {/* ============================================================ */}
      {/* VIEW C: FILTERS MODAL VIEW */}
      {/* ============================================================ */}
      {viewState === "filters" && (
        <div className="px-4 lg:px-8 pt-3 flex-1 flex flex-col justify-between max-w-2xl mx-auto w-full">
          <div className="space-y-6">
            <div className="flex items-center justify-between">
              <button
                type="button"
                onClick={() => setViewState("results")}
                className="p-1 text-white hover:text-neutral-300 transition-colors cursor-pointer"
                aria-label="Close filters"
              >
                <X className="w-6 h-6 stroke-[2.5]" />
              </button>
              <h1 className="text-2xl font-black text-white tracking-tight">Filter Movies</h1>
              <button
                type="button"
                onClick={() => {
                  setSelectedGenre("All");
                  setSelectedVj("All");
                  setSelectedType("All");
                }}
                className="text-xs font-bold text-[#00E676] cursor-pointer"
              >
                Reset
              </button>
            </div>

            {/* QUICK SELECT GENRE */}
            <div className="space-y-2">
              <div className="flex items-center gap-1.5 text-xs font-bold text-purple-400 tracking-wider uppercase">
                <Zap className="w-3.5 h-3.5 fill-purple-400 text-purple-400" />
                <span>GENRE</span>
              </div>

              <div className="flex gap-2 flex-wrap">
                {["All", "Action", "Series", "Adventure", "Comedy", "Horror", "Drama", "Sci-Fi"].map((genre) => {
                  const isActive = selectedGenre === genre;
                  return (
                    <button
                      key={genre}
                      type="button"
                      onClick={() => setSelectedGenre(genre)}
                      className={`px-4 py-2 rounded-full text-xs font-semibold whitespace-nowrap transition-all cursor-pointer ${
                        isActive
                          ? "bg-[#00E676] text-black font-black shadow-md shadow-[#00E676]/20"
                          : "bg-[#1c1c1e] text-neutral-300 hover:bg-[#252528]"
                      }`}
                    >
                      {genre}
                    </button>
                  );
                })}
              </div>
            </div>

            {/* TRANSLATOR / VJ */}
            <div className="space-y-2">
              <div className="text-xs font-bold text-neutral-400 tracking-wider uppercase">
                TRANSLATOR / VJ
              </div>
              <div className="flex gap-2 flex-wrap max-h-36 overflow-y-auto">
                {["All", ...ALL_VJS.map((v) => v.name)].map((v) => {
                  const isActive = selectedVj === v;
                  return (
                    <button
                      key={v}
                      type="button"
                      onClick={() => setSelectedVj(v)}
                      className={`px-3.5 py-1.5 rounded-full text-xs font-semibold whitespace-nowrap transition-all cursor-pointer ${
                        isActive
                          ? "bg-[#581c87] text-white border border-purple-400"
                          : "bg-[#1c1c1e] text-neutral-300 hover:bg-[#252528]"
                      }`}
                    >
                      {v}
                    </button>
                  );
                })}
              </div>
            </div>

            {/* TYPE: MOVIES OR SERIES */}
            <div className="space-y-2">
              <div className="text-xs font-bold text-neutral-400 tracking-wider uppercase">
                CONTENT TYPE
              </div>
              <div className="flex gap-3">
                {["All", "Movies", "Series"].map((t) => {
                  const isActive = selectedType === t;
                  return (
                    <button
                      key={t}
                      type="button"
                      onClick={() => setSelectedType(t)}
                      className={`flex-1 py-3 rounded-2xl text-xs font-bold transition-all cursor-pointer ${
                        isActive
                          ? "bg-white text-black font-black"
                          : "bg-[#1c1c1e] text-neutral-300 hover:bg-[#252528]"
                      }`}
                    >
                      {t}
                    </button>
                  );
                })}
              </div>
            </div>
          </div>

          {/* Apply Button */}
          <div className="pt-6">
            <button
              type="button"
              onClick={() => setViewState("results")}
              className="w-full h-12 rounded-full bg-[#00E676] text-black font-extrabold text-sm flex items-center justify-center shadow-lg shadow-[#00E676]/25 hover:bg-[#00c853] transition-all cursor-pointer"
            >
              Apply Filters ({searchResults.length} Results)
            </button>
          </div>
        </div>
      )}

      {/* 4. FIXED BOTTOM NAVIGATION BAR */}
      <nav className="lg:hidden fixed bottom-0 left-0 right-0 z-50 h-16 bg-black/95 backdrop-blur-lg border-t border-white/10 px-4 flex items-center justify-around">
        <button
          type="button"
          onClick={() => (onNavigateTab ? onNavigateTab("home") : onBackToHome?.())}
          className="flex flex-col items-center gap-1 cursor-pointer transition-colors"
        >
          <Home className="w-5 h-5 text-neutral-500" />
          <span className="text-[10px] font-medium text-neutral-500">Home</span>
        </button>

        <button
          type="button"
          onClick={() => setViewState("results")}
          className="flex flex-col items-center gap-1 cursor-pointer transition-colors"
        >
          <SearchIcon className="w-5 h-5 text-[#00E676]" />
          <span className="text-[10px] font-medium text-[#00E676]">Search</span>
        </button>

        <button
          type="button"
          onClick={() => onNavigateTab?.("favorites")}
          className="flex flex-col items-center gap-1 cursor-pointer transition-colors"
        >
          <Heart className="w-5 h-5 text-neutral-500" />
          <span className="text-[10px] font-medium text-neutral-500">Favorites</span>
        </button>

        <button
          type="button"
          onClick={() => onNavigateTab?.("downloads")}
          className="flex flex-col items-center gap-1 cursor-pointer transition-colors"
        >
          <Download className="w-5 h-5 text-neutral-500" />
          <span className="text-[10px] font-medium text-neutral-500">Downloads</span>
        </button>

        <button
          type="button"
          onClick={() => onNavigateTab?.("profile")}
          className="flex flex-col items-center gap-1 cursor-pointer transition-colors"
        >
          <UserIcon className="w-5 h-5 text-neutral-500" />
          <span className="text-[10px] font-medium text-neutral-500">Profile</span>
        </button>
      </nav>
    </div>
  );
};
