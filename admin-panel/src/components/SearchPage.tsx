import React, { useState, useEffect, useMemo } from "react";
import {
  Search as SearchIcon,
  SearchX,
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
import { VjBadge } from "./VjBadge";
import { FloatingBottomNav } from "./FloatingBottomNav";

export type SearchViewState = "categories" | "results" | "filters";

interface SearchPageProps {
  userProfile?: UserProfileData;
  onBackToHome?: () => void;
  onLogout?: () => void;
  onNavigateTab?: (tab: "home" | "search" | "favorites" | "downloads" | "profile") => void;
  onSelectMovie?: (movieId: string, isSeries?: boolean, title?: string, movie?: CatalogMovie) => void;
  onNavigateToNotifications?: () => void;
}

export const FOLDER_CATEGORIES = [
  { title: "Action", poster: "https://image.tmdb.org/t/p/w500/bjiS5ipwxb9JFy3XRRN4OAilSeX.jpg", query: "Action" },
  { title: "Horror", poster: "https://image.tmdb.org/t/p/w500/bXi6IQiCuHDv0Xsp7Na5966WDFG.jpg", query: "Horror" },
  { title: "Series", poster: "https://image.tmdb.org/t/p/w500/dDlG1v7kWqFfg1k5pW6bEa4Xv34.jpg", query: "Series" },
  { title: "Adventure", poster: "https://image.tmdb.org/t/p/w500/8b8R8l88Qje9dn9OE8PY05Nxl1X.jpg", query: "Adventure" },
  { title: "Love Story", poster: "https://image.tmdb.org/t/p/w500/q6y0Go1tsGEsmtFryDOJo3dEmqu.jpg", query: "Love Story" },
  { title: "Comedy", poster: "https://image.tmdb.org/t/p/w500/iuFNMS8U5cb6xfzi51Dbkovj7vM.jpg", query: "Comedy" },
  { title: "Crime", poster: "https://image.tmdb.org/t/p/w500/kKGQzkTyMbAlQUTvBhZ1nFEJ75U.jpg", query: "Crime" },
  { title: "Family", poster: "https://image.tmdb.org/t/p/w500/kDp1vUBnMpe8ak4rjgl3cLELqjU.jpg", query: "Family" },
  { title: "Sci FI", poster: "https://image.tmdb.org/t/p/w500/gEU2QniE6E77NI6lCU6MxlNBvIx.jpg", query: "Sci FI" },
  { title: "Romance", poster: "https://image.tmdb.org/t/p/w500/5qHoazZiaLe7oFBok7XlUhg96f2.jpg", query: "Romance" },
  { title: "Kungu Fu", poster: "https://image.tmdb.org/t/p/w500/qA5kPY0debq59v9H6eFv8d0yI6I.jpg", query: "Kungu Fu" },
  { title: "Drama", poster: "https://image.tmdb.org/t/p/w500/8Gxv8gSFCU0XGDykEGv7zR1n2ua.jpg", query: "Drama" },
  { title: "Sport", poster: "https://image.tmdb.org/t/p/w500/H6vke7zGiuL7z75m1N6T5gS4Vp.jpg", query: "Sport" },
  { title: "Thriller", poster: "https://image.tmdb.org/t/p/w500/6MKr3KgOLmzOP6MSuZERO41Lpkt.jpg", query: "Thriller" },
  { title: "Animation", poster: "https://image.tmdb.org/t/p/w500/vpnVM9B6NMmQpWeZvzLvDESb2QY.jpg", query: "Animation" },
  { title: "Korean", poster: "https://image.tmdb.org/t/p/w500/7IiTTgloJzvGI1TAYymCfbfl3vT.jpg", query: "Korean" },
  { title: "Filipino", poster: "https://image.tmdb.org/t/p/w500/r2J02Z2OpNTctfOSN2Ydgii51I3.jpg", query: "Filipino" },
  { title: "Indian", poster: "https://image.tmdb.org/t/p/w500/kdPMUMJzyYAc4roD52qavX0nLIC.jpg", query: "Indian" },
  { title: "Chinese", poster: "https://image.tmdb.org/t/p/w500/5kHvC0Vv83g6R52tCq4jL7sDqC6.jpg", query: "Chinese" },
  { title: "Ugandan", poster: "https://image.tmdb.org/t/p/w500/628Dep6AxEtDxjZoGP78TsOxYbK.jpg", query: "Ugandan" },
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
      const seenIds = new Set(local.map((m) => m.id));
      const seenTitles = new Set(local.map((m) => m.title.toLowerCase().trim()));
      const merged = [...local];
      apiResults.forEach((ar) => {
        const normTitle = ar.title.toLowerCase().trim();
        if (!seenIds.has(ar.id) && !seenTitles.has(normTitle)) {
          seenIds.add(ar.id);
          seenTitles.add(normTitle);
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

          {/* 2-Column Physical Folder-Tab Cards (Flutter _FolderCardItem 1:1 match) */}
          <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 gap-x-4 gap-y-6">
            {FOLDER_CATEGORIES.map((cat) => (
              <div
                key={cat.title}
                onClick={() => handleSelectCategory(cat.query)}
                className="cursor-pointer group flex flex-col active:scale-[0.98] transition-transform select-none"
              >
                {/* Physical Folder Stack */}
                <div className="relative w-full aspect-[3/4] pt-3.5">
                  {/* Tier 2 back tab ridge (topmost, narrower, gradient) */}
                  <div className="absolute top-0 left-[16%] right-[16%] h-3.5 rounded-t-lg bg-gradient-to-b from-[#2B303E] to-[#1B1E28] border-t border-x border-white/10 shadow-sm" />

                  {/* Tier 1 back tab (main folder ridge) */}
                  <div className="absolute top-1.5 left-2.5 right-2.5 h-4 rounded-t-xl bg-gradient-to-b from-[#383D4E] to-[#242835] border-t border-x border-white/15 shadow" />

                  {/* Front Poster Card */}
                  <div className="relative w-full h-full rounded-2xl overflow-hidden border border-white/15 shadow-xl bg-[#181B24] group-hover:border-[#00E676]/60 transition-all">
                    <img
                      src={cat.poster}
                      alt={cat.title}
                      className="w-full h-full object-cover filter brightness-90 group-hover:scale-105 transition-transform duration-300"
                      onError={(e) => {
                        (e.target as HTMLImageElement).src =
                          "https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=800&auto=format&fit=crop&q=80";
                      }}
                    />
                    <div className="absolute inset-0 bg-gradient-to-t from-black/80 via-black/20 to-transparent pointer-events-none" />

                    {/* Bottom Title on Poster */}
                    <div className="absolute bottom-2.5 left-2.5 right-2.5 z-10 text-left">
                      <span className="text-sm font-extrabold text-white tracking-tight drop-shadow-md group-hover:text-[#00E676] transition-colors">
                        {cat.title}
                      </span>
                    </div>
                  </div>
                </div>
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
            <div className="flex flex-col items-center justify-center py-24 text-center select-none">
              <SearchX className="w-14 h-14 text-white/40 mb-3.5 stroke-[1.5]" />
              <h3 className="text-white text-base sm:text-lg font-bold tracking-tight">No movies found</h3>
              <p className="text-white/50 text-xs sm:text-sm mt-1.5 max-w-xs leading-relaxed">
                Try searching for another genre or title
              </p>
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
                      <VjBadge vjName={movie.vj} size="sm" />
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

      {/* 4. FLOATING CURVED GLASS BOTTOM NAVIGATION BAR */}
      <FloatingBottomNav activeTab="search" onNavigateTab={onNavigateTab} />
    </div>
  );
};
