import React, { useState } from "react";
import {
  Search,
  Bell,
  Play,
  Bookmark,
  Star,
  Headphones,
  Tv,
  Flame,
  Rocket,
  Heart,
  Moon,
  Smile,
  Sparkles,
  Home,
  Download,
  User as UserIcon,
  ChevronRight,
  TrendingUp,
  Clock,
} from "lucide-react";
import { ALL_VJS } from "./AvailableVJsPage";
import { useLiveCatalog, CatalogMovie } from "../data/liveCatalog";
import { AvatarGraphic } from "./AvatarGraphic";
import { UserProfileData } from "./EditProfileModal";

interface HomePageProps {
  userProfile?: UserProfileData;
  onSelectMovie?: (movieId: string, isSeries?: boolean, title?: string, movie?: CatalogMovie) => void;
  onLogout?: () => void;
  onNavigateTab?: (tab: "home" | "search" | "favorites" | "downloads" | "profile") => void;
  onNavigateToSearch?: () => void;
  onNavigateToNotifications?: () => void;
  onNavigateToAvailableVJs?: () => void;
  onNavigateToCategorySeeAll?: (categoryTitle: string, count?: number, iconType?: string) => void;
  onSelectVj?: (vjName: string) => void;
}

export const FreeWatchLogo: React.FC<{ className?: string }> = ({ className = "" }) => {
  return (
    <div className={`font-black tracking-tight inline-flex items-center select-none text-[22px] leading-none ${className}`}>
      <span className="text-white">FREE</span>
      <span className="text-[#00E676]">WATCH</span>
    </div>
  );
};

export const HomePage: React.FC<HomePageProps> = ({
  userProfile,
  onSelectMovie,
  onLogout,
  onNavigateTab,
  onNavigateToSearch,
  onNavigateToNotifications,
  onNavigateToAvailableVJs,
  onNavigateToCategorySeeAll,
  onSelectVj,
}) => {
  const [activeTab, setActiveTab] = useState<"home" | "search" | "favorites" | "downloads" | "profile">("home");
  const [isBookmarked, setIsBookmarked] = useState(false);
  const [desktopFocusedCard, setDesktopFocusedCard] = useState<string>("");
  const [desktopFocusedVj, setDesktopFocusedVj] = useState<string>("vj-junior");

  const {
    catalog,
    totalCount,
    loading,
    latestMovies,
    trendingMovies,
    seriesMovies,
    actionMovies,
    dramaMovies,
    comedyMovies,
    sciFiMovies,
    horrorMovies,
    animationMovies,
  } = useLiveCatalog();

  const heroMovie = latestMovies[0] || catalog[0];
  const heroMovie2 = latestMovies[1] || catalog[1];
  const heroMovie3 = latestMovies[2] || catalog[2];
  const heroMovie4 = latestMovies[3] || catalog[3];

  const handleTabClick = (tab: "home" | "search" | "favorites" | "downloads" | "profile") => {
    setActiveTab(tab);
    if (tab === "search" && onNavigateToSearch) {
      onNavigateToSearch();
    } else if (onNavigateTab) {
      onNavigateTab(tab);
    }
  };

  // Reusable Movie Poster Card
  const renderMovieCard = (movie: CatalogMovie) => {
    return (
      <div
        key={movie.id}
        onClick={() => onSelectMovie?.(movie.id, movie.isTv, movie.title, movie)}
        className="w-[120px] sm:w-[136px] md:w-[148px] shrink-0 cursor-pointer group active:scale-95 transition-transform select-none"
      >
        <div className="relative aspect-[2/3] rounded-2xl overflow-hidden bg-neutral-900 border border-white/10 group-hover:border-[#00E676]/60 transition-all p-2.5 flex flex-col justify-between shadow-lg">
          {movie.imageUrl ? (
            <img
              src={movie.imageUrl}
              alt={movie.title}
              onError={(e) => {
                (e.target as HTMLImageElement).style.display = "none";
              }}
              className="absolute inset-0 w-full h-full object-cover filter brightness-90 group-hover:scale-105 transition-transform duration-300"
            />
          ) : null}
          <div className="absolute inset-0 bg-gradient-to-t from-black via-black/35 to-transparent pointer-events-none" />

          {/* Top Right: VJ Badge */}
          <div className="relative z-10 flex justify-end">
            <span className="px-2 py-0.5 rounded-full bg-[#581c87]/90 border border-purple-400/40 text-[9px] font-bold text-white flex items-center gap-1 shadow-sm backdrop-blur-sm">
              <span className="w-1.5 h-1.5 rounded-full bg-[#00E676] inline-block" />
              <span className="truncate max-w-[70px]">{movie.vj}</span>
            </span>
          </div>

          {/* Center Play Button on Hover */}
          <div className="absolute inset-0 flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity z-10 pointer-events-none">
            <div className="w-9 h-9 rounded-full bg-[#00E676] text-black flex items-center justify-center shadow-lg">
              <Play className="w-4 h-4 fill-black ml-0.5" />
            </div>
          </div>

          {/* Bottom Title */}
          <div className="relative z-10 text-left pt-6">
            <div className="text-xs font-black text-white tracking-tight line-clamp-2 leading-tight drop-shadow-md">
              {movie.title}
            </div>
          </div>
        </div>

        <div className="mt-1.5 flex items-center gap-1.5 text-[11px] text-neutral-400 font-medium">
          <span className="text-amber-400 font-bold">★ {movie.rating}</span>
          <span>•</span>
          <span>{movie.year}</span>
          {movie.isTv && (
            <>
              <span>•</span>
              <span className="text-[#00E676] font-semibold">Series</span>
            </>
          )}
        </div>
      </div>
    );
  };

  return (
    <div className="w-full min-h-screen bg-black text-white font-sans flex flex-col pb-24 select-none">
      {/* 1. TOP BAR */}
      <header className="sticky top-0 z-40 w-full bg-black/90 backdrop-blur-md px-4 lg:px-8 py-3 flex items-center justify-between border-b border-white/5">
        <div className="flex items-center gap-3">
          <FreeWatchLogo />
          {/* Subtle Android TV UI Badge on Desktop */}
          <div className="hidden lg:flex items-center gap-1.5 px-2.5 py-1 rounded-full bg-white/5 border border-white/10 text-[11px] font-bold text-neutral-300">
            <span className="w-2 h-2 rounded-full bg-[#00E676] animate-pulse" />
            <span>TV UI (10-FOOT)</span>
          </div>
        </div>

        <div className="flex items-center gap-4">
          <button
            type="button"
            onClick={onNavigateToSearch || (() => onNavigateTab?.("search"))}
            className="p-1 text-white hover:text-[#00E676] transition-colors cursor-pointer"
            aria-label="Search"
          >
            <Search className="w-5 h-5 stroke-[2.2]" />
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

      {/* 2A. MOBILE HERO FEATURED 3D CAROUSEL */}
      <section className="relative px-4 pt-4 pb-2 lg:hidden">
        <div className="relative w-full h-[340px] sm:h-[380px] flex items-center justify-start overflow-hidden">
          {/* Card 4 */}
          {heroMovie4 && (
            <div className="absolute left-[240px] sm:left-[300px] w-[180px] sm:w-[210px] h-[280px] sm:h-[320px] rounded-2xl overflow-hidden bg-neutral-900 border border-white/10 opacity-40 scale-85 pointer-events-none">
              <img src={heroMovie4.imageUrl} alt="" className="w-full h-full object-cover filter brightness-75" />
              <div className="absolute inset-0 bg-gradient-to-t from-black via-transparent to-transparent" />
              <div className="absolute top-2.5 right-2.5 px-1.5 py-0.5 rounded bg-[#00E5FF] text-black text-[10px] font-bold flex items-center gap-0.5">
                <span>★</span> {heroMovie4.rating}
              </div>
              <div className="absolute bottom-3 left-3 text-lg font-black text-amber-400 tracking-wider line-clamp-1">
                {heroMovie4.title}
              </div>
            </div>
          )}

          {/* Card 3 */}
          {heroMovie3 && (
            <div className="absolute left-[160px] sm:left-[200px] w-[185px] sm:w-[215px] h-[290px] sm:h-[330px] rounded-2xl overflow-hidden bg-neutral-900 border border-white/10 opacity-60 scale-90 pointer-events-none">
              <img src={heroMovie3.imageUrl} alt="" className="w-full h-full object-cover filter brightness-75" />
              <div className="absolute inset-0 bg-gradient-to-t from-black via-transparent to-transparent" />
              <div className="absolute top-2.5 right-2.5 px-1.5 py-0.5 rounded bg-[#00E5FF] text-black text-[10px] font-bold flex items-center gap-0.5">
                <span>★</span> {heroMovie3.rating}
              </div>
              <div className="absolute bottom-3 left-3 text-xl font-black text-amber-400 tracking-wider line-clamp-1">
                {heroMovie3.title}
              </div>
            </div>
          )}

          {/* Card 2 */}
          {heroMovie2 && (
            <div className="absolute left-[85px] sm:left-[110px] w-[190px] sm:w-[220px] h-[300px] sm:h-[340px] rounded-2xl overflow-hidden bg-neutral-900 border border-white/10 opacity-80 scale-95 pointer-events-none">
              <img src={heroMovie2.imageUrl} alt="" className="w-full h-full object-cover filter brightness-75" />
              <div className="absolute inset-0 bg-gradient-to-t from-black via-transparent to-transparent" />
              <div className="absolute top-2.5 right-2.5 px-1.5 py-0.5 rounded bg-[#00E5FF] text-black text-[10px] font-bold flex items-center gap-0.5">
                <span>★</span> {heroMovie2.rating}
              </div>
              <div className="absolute bottom-3 left-3 text-2xl font-black text-amber-400 tracking-wider line-clamp-1">
                {heroMovie2.title}
              </div>
            </div>
          )}

          {/* Card 1: Front Active Card */}
          {heroMovie && (
            <div
              onClick={() => onSelectMovie?.(heroMovie.id, heroMovie.isTv, heroMovie.title, heroMovie)}
              className="relative z-20 w-[200px] sm:w-[230px] h-[310px] sm:h-[350px] rounded-2xl overflow-hidden bg-neutral-900 border border-white/15 shadow-2xl flex flex-col justify-between p-3 cursor-pointer group active:scale-[0.98] transition-transform"
            >
              <img
                src={heroMovie.imageUrl}
                alt={heroMovie.title}
                className="absolute inset-0 w-full h-full object-cover filter brightness-85 group-hover:scale-105 transition-transform duration-300"
              />
              <div className="absolute inset-0 bg-gradient-to-t from-black via-black/40 to-transparent pointer-events-none" />

              {/* Top Row Badges */}
              <div className="relative z-10 flex items-center justify-between">
                <button
                  type="button"
                  onClick={(e) => {
                    e.stopPropagation();
                    setIsBookmarked(!isBookmarked);
                  }}
                  className="w-7 h-7 rounded-lg bg-black/60 backdrop-blur-md flex items-center justify-center text-white hover:text-[#00E676] transition-colors cursor-pointer"
                >
                  <Bookmark className={`w-3.5 h-3.5 ${isBookmarked ? "fill-[#00E676] text-[#00E676]" : ""}`} />
                </button>

                <div className="px-1.5 py-0.5 rounded bg-[#00E5FF] text-black text-[10px] font-extrabold flex items-center gap-0.5 shadow-sm">
                  <span>★</span> {heroMovie.rating}
                </div>
              </div>

              {/* Center Play Button */}
              <div className="absolute inset-0 flex items-center justify-center pointer-events-none z-10">
                <div className="w-12 h-12 rounded-full bg-white/20 backdrop-blur-md border border-white/30 flex items-center justify-center shadow-lg group-hover:scale-110 transition-transform">
                  <Play className="w-5 h-5 fill-white text-white ml-0.5" />
                </div>
              </div>

              {/* Bottom Title */}
              <div className="relative z-10 pt-8">
                <h3 className="text-xl sm:text-2xl font-black tracking-tight text-white drop-shadow-md line-clamp-2">
                  {heroMovie.title}
                </h3>
              </div>
            </div>
          )}
        </div>

        {/* Hero Metadata & VJ Badge */}
        {heroMovie && (
          <div className="mt-3 flex items-center justify-between px-1">
            <div
              onClick={() => onSelectMovie?.(heroMovie.id, heroMovie.isTv, heroMovie.title, heroMovie)}
              className="cursor-pointer group flex-1 pr-3"
            >
              <div className="text-base font-black tracking-tight text-white font-sans leading-tight group-hover:text-[#00E676] transition-colors truncate">
                {heroMovie.title}
              </div>
              <div className="text-xs text-neutral-400 mt-1 font-medium">
                {heroMovie.category} • {heroMovie.year} • {heroMovie.duration}
              </div>
            </div>

            <button
              type="button"
              onClick={() => onSelectVj ? onSelectVj(heroMovie.vj) : onNavigateToAvailableVJs?.()}
              className="flex items-center gap-2 px-3 py-1.5 rounded-full bg-[#4c1d95]/80 border border-[#7c3aed]/50 text-white text-xs font-semibold hover:bg-[#4c1d95] transition-all cursor-pointer shadow-sm active:scale-95 shrink-0"
            >
              <span>{heroMovie.vj}</span>
              <div className="w-5 h-5 rounded-full bg-white/10 flex items-center justify-center">
                <Headphones className="w-3 h-3 text-[#00E676]" />
              </div>
            </button>
          </div>
        )}
      </section>

      {/* 2B. DESKTOP / 10-FOOT CINEMATIC TV BANNER */}
      {heroMovie && (
        <div className="hidden lg:block px-6 xl:px-10 pt-4 pb-6 max-w-[1600px] mx-auto w-full">
          <div className="relative w-full h-[470px] xl:h-[510px] rounded-[32px] overflow-hidden border border-white/10 shadow-2xl bg-[#08080c] group">
            {/* Background Cinematic Artwork */}
            <div className="absolute inset-0">
              <img
                src={heroMovie.backdropUrl || heroMovie.imageUrl}
                alt={heroMovie.title}
                className="w-full h-full object-cover object-[center_30%] filter brightness-90 contrast-110 group-hover:scale-105 transition-transform duration-700"
              />
              <div className="absolute inset-0 bg-gradient-to-r from-black via-black/85 via-45% to-transparent" />
              <div className="absolute inset-0 bg-gradient-to-t from-black via-black/40 via-30% to-transparent" />
            </div>

            {/* Top Right: VJ Badge Pill */}
            <div className="absolute top-6 right-6 z-20">
              <button
                type="button"
                onClick={() => onSelectVj?.(heroMovie.vj)}
                className="flex items-center gap-2 px-4 py-2 rounded-full bg-[#4c1d95]/90 hover:bg-[#581c87] border border-[#a855f7]/50 text-white text-xs font-extrabold shadow-xl backdrop-blur-md transition-all cursor-pointer active:scale-95"
              >
                <div className="w-5 h-5 rounded-full overflow-hidden bg-purple-300 border border-white/40 flex items-center justify-center text-[10px] text-purple-950 font-black">
                  VJ
                </div>
                <span className="tracking-wider">{heroMovie.vj}</span>
              </button>
            </div>

            {/* Left Content Column */}
            <div className="relative z-10 h-full flex flex-col justify-end p-8 xl:p-12 max-w-2xl">
              <div className="space-y-1 mb-3">
                <div className="text-3xl xl:text-5xl font-black tracking-tight text-white drop-shadow-[0_4px_12px_rgba(0,0,0,0.8)] leading-tight uppercase">
                  {heroMovie.title}
                </div>
              </div>

              {/* Tags Row */}
              <div className="flex items-center gap-2 mb-3">
                <span className="px-2.5 py-1 rounded-md bg-white/10 backdrop-blur-md border border-white/15 text-xs font-black text-amber-400">
                  ★ {heroMovie.rating}
                </span>
                <span className="px-2.5 py-1 rounded-md bg-white/10 backdrop-blur-md border border-white/15 text-xs font-semibold text-neutral-200">
                  {heroMovie.duration}
                </span>
                <span className="px-2.5 py-1 rounded-md bg-white/10 backdrop-blur-md border border-white/15 text-xs font-semibold text-neutral-200">
                  {heroMovie.year}
                </span>
                <span className="px-2.5 py-1 rounded-md bg-white/10 backdrop-blur-md border border-white/15 text-xs font-semibold text-neutral-200">
                  {heroMovie.category}
                </span>
              </div>

              {/* Synopsis */}
              <p className="text-sm text-neutral-300 font-medium leading-relaxed mb-6 max-w-xl line-clamp-3">
                {heroMovie.overview}
              </p>

              {/* Action Buttons */}
              <div className="flex items-center gap-4">
                <button
                  type="button"
                  onClick={() => onSelectMovie?.(heroMovie.id, heroMovie.isTv, heroMovie.title, heroMovie)}
                  className="flex items-center gap-2.5 px-8 py-3.5 rounded-full bg-[#00E676] hover:bg-[#00c853] text-black font-black text-sm tracking-wide shadow-[0_0_25px_rgba(0,230,118,0.5)] hover:scale-105 active:scale-95 transition-all cursor-pointer"
                >
                  <Play className="w-4 h-4 fill-black text-black" />
                  <span>WATCH NOW</span>
                </button>

                <button
                  type="button"
                  onClick={() => onSelectMovie?.(heroMovie.id, heroMovie.isTv, heroMovie.title, heroMovie)}
                  className="flex items-center gap-2 px-7 py-3.5 rounded-full bg-black/40 hover:bg-white/15 border border-white/40 text-white font-bold text-sm tracking-wide backdrop-blur-md hover:scale-105 active:scale-95 transition-all cursor-pointer"
                >
                  <span>DETAILS</span>
                </button>
              </div>
            </div>
          </div>

          {/* Desktop AVAILABLE VJs ROW */}
          <div className="mt-8">
            <div className="flex items-center justify-between mb-3">
              <h3 className="text-base font-extrabold tracking-tight text-white uppercase">
                AVAILABLE VJs
              </h3>
              <button
                type="button"
                onClick={onNavigateToAvailableVJs}
                className="text-xs font-bold text-neutral-400 hover:text-white transition-colors cursor-pointer"
              >
                See all ({ALL_VJS.length})
              </button>
            </div>

            <div className="grid grid-cols-3 xl:grid-cols-6 gap-3.5">
              {ALL_VJS.slice(0, 6).map((vj) => {
                const isFocused = desktopFocusedVj === vj.id;
                return (
                  <div
                    key={vj.id}
                    onClick={() => {
                      setDesktopFocusedVj(vj.id);
                      onSelectVj ? onSelectVj(vj.name) : onNavigateToAvailableVJs?.();
                    }}
                    onMouseEnter={() => setDesktopFocusedVj(vj.id)}
                    className={`relative h-24 rounded-2xl overflow-hidden bg-gradient-to-r ${vj.bgColor} border flex items-center justify-between cursor-pointer transition-all duration-200 ${
                      isFocused
                        ? "border-[#a855f7] shadow-[0_0_20px_rgba(168,85,247,0.4)] scale-102 ring-2 ring-purple-400/50"
                        : "border-white/10 hover:border-white/30"
                    }`}
                  >
                    <div className="relative h-full w-[45%] overflow-hidden">
                      <img
                        src={vj.photoUrl}
                        alt={vj.name}
                        onError={(e) => {
                          (e.target as HTMLImageElement).src = "/vjs/vj_universal.png";
                        }}
                        className="w-full h-full object-cover grayscale contrast-125 brightness-95"
                      />
                      <div
                        className="absolute top-0 right-0 bottom-0 w-6 pointer-events-none"
                        style={{
                          clipPath: "polygon(100% 0, 100% 100%, 0 70%, 50% 30%)",
                          backgroundColor: vj.accentColor,
                          opacity: 0.9,
                        }}
                      />
                    </div>

                    <div className="flex-1 px-3 flex flex-col justify-center items-end text-right">
                      <h4 className="text-xs xl:text-sm font-black tracking-wider text-white">
                        {vj.name}
                      </h4>
                      <span className="text-[9px] xl:text-[10px] font-extrabold tracking-wider text-sky-300 mt-0.5 uppercase">
                        {vj.subtitle}
                      </span>
                    </div>
                  </div>
                );
              })}
            </div>
          </div>
        </div>
      )}

      {/* 3. SECTION: MOBILE AVAILABLE VJS */}
      <section className="mt-6 px-4 lg:hidden">
        <div className="flex items-center justify-between mb-3">
          <div className="flex items-center gap-2">
            <span className="text-purple-400 font-black text-lg">ហ</span>
            <h2 className="text-lg font-bold text-white tracking-tight">Available VJs</h2>
          </div>
          <button
            type="button"
            onClick={onNavigateToAvailableVJs}
            className="px-3 py-1 rounded-full bg-[#1e1b2e] border border-white/5 text-[11px] font-semibold text-neutral-300 hover:text-white transition-colors cursor-pointer"
          >
            See all ({ALL_VJS.length})
          </button>
        </div>

        {/* Horizontal VJ Cards Scroller */}
        <div className="flex gap-3 overflow-x-auto no-scrollbar pb-1">
          {ALL_VJS.map((vj) => (
            <div
              key={vj.id}
              onClick={() => onSelectVj ? onSelectVj(vj.name) : onNavigateToAvailableVJs?.()}
              className={`min-w-[190px] h-[95px] rounded-2xl bg-gradient-to-r ${vj.bgColor} border border-white/10 flex items-center justify-between relative overflow-hidden shrink-0 cursor-pointer hover:border-white/20 transition-all`}
            >
              <div className="relative h-full w-[45%] overflow-hidden">
                <img
                  src={vj.photoUrl}
                  alt={vj.name}
                  onError={(e) => {
                    (e.target as HTMLImageElement).src = "/vjs/vj_universal.png";
                  }}
                  className="w-full h-full object-cover grayscale contrast-125 brightness-90"
                />
                <div
                  className="absolute top-0 right-0 bottom-0 w-6 pointer-events-none"
                  style={{
                    clipPath: "polygon(100% 0, 100% 100%, 0 70%, 50% 30%)",
                    backgroundColor: vj.accentColor,
                    opacity: 0.9,
                  }}
                />
              </div>
              <div className="flex-1 px-3 flex flex-col justify-center items-end text-right">
                <div className="text-xs font-black text-white tracking-wider">{vj.name}</div>
                <div className="text-[9px] font-bold text-sky-300 mt-0.5">{vj.subtitle}</div>
              </div>
            </div>
          ))}
        </div>
      </section>

      {/* 4. SECTION: LATEST ON FREEWATCH */}
      <section className="mt-7 px-4">
        <div className="flex items-center justify-between mb-3">
          <div className="flex items-center gap-2">
            <Sparkles className="w-4 h-4 text-[#00E5FF]" />
            <h2 className="text-lg font-bold text-white tracking-tight">Latest on FreeWatch</h2>
          </div>
          <button
            type="button"
            onClick={() => onNavigateToCategorySeeAll?.("Latest on FreeWatch", totalCount || latestMovies.length, "sparkles")}
            className="px-3 py-1 rounded-full bg-[#1e1b2e] border border-white/5 text-[11px] font-semibold text-neutral-300 hover:text-white transition-colors cursor-pointer"
          >
            See all
          </button>
        </div>

        <div className="flex gap-3 overflow-x-auto no-scrollbar pb-1">
          {latestMovies.slice(0, 15).map(renderMovieCard)}
        </div>
      </section>

      {/* 5. SECTION: TRENDING NOW */}
      <section className="mt-7 px-4">
        <div className="flex items-center justify-between mb-3">
          <div className="flex items-center gap-2">
            <TrendingUp className="w-4 h-4 text-[#00E676]" />
            <h2 className="text-lg font-bold text-white tracking-tight">Trending Now</h2>
          </div>
          <button
            type="button"
            onClick={() => onNavigateToCategorySeeAll?.("Trending Now", trendingMovies.length, "trending")}
            className="px-3 py-1 rounded-full bg-[#1e1b2e] border border-white/5 text-[11px] font-semibold text-neutral-300 hover:text-white transition-colors cursor-pointer"
          >
            See all
          </button>
        </div>

        <div className="flex gap-3 overflow-x-auto no-scrollbar pb-1">
          {trendingMovies.slice(0, 15).map(renderMovieCard)}
        </div>
      </section>

      {/* 6. SECTION: LUGANDA SERIES */}
      <section className="mt-7 px-4">
        <div className="flex items-center justify-between mb-3">
          <div className="flex items-center gap-2">
            <Tv className="w-4 h-4 text-red-500" />
            <h2 className="text-lg font-bold text-white tracking-tight">Luganda Series</h2>
          </div>
          <button
            type="button"
            onClick={() => onNavigateToCategorySeeAll?.("Series", seriesMovies.length, "tv")}
            className="px-3 py-1 rounded-full bg-[#1e1b2e] border border-white/5 text-[11px] font-semibold text-neutral-300 hover:text-white transition-colors cursor-pointer"
          >
            See all ({seriesMovies.length})
          </button>
        </div>

        <div className="flex gap-3 overflow-x-auto no-scrollbar pb-1">
          {seriesMovies.slice(0, 15).map(renderMovieCard)}
        </div>
      </section>

      {/* 7. SECTION: ACTION */}
      <section className="mt-7 px-4">
        <div className="flex items-center justify-between mb-3">
          <div className="flex items-center gap-2">
            <Flame className="w-4 h-4 text-orange-500" />
            <h2 className="text-lg font-bold text-white tracking-tight">Action Movies</h2>
          </div>
          <button
            type="button"
            onClick={() => onNavigateToCategorySeeAll?.("Action", actionMovies.length, "flame")}
            className="px-3 py-1 rounded-full bg-[#1e1b2e] border border-white/5 text-[11px] font-semibold text-neutral-300 hover:text-white transition-colors cursor-pointer"
          >
            See all
          </button>
        </div>

        <div className="flex gap-3 overflow-x-auto no-scrollbar pb-1">
          {actionMovies.slice(0, 15).map(renderMovieCard)}
        </div>
      </section>

      {/* 8. SECTION: SCI-FI & FANTASY */}
      <section className="mt-7 px-4">
        <div className="flex items-center justify-between mb-3">
          <div className="flex items-center gap-2">
            <Rocket className="w-4 h-4 text-purple-400" />
            <h2 className="text-lg font-bold text-white tracking-tight">Sci-Fi &amp; Fantasy</h2>
          </div>
          <button
            type="button"
            onClick={() => onNavigateToCategorySeeAll?.("Sci-Fi", sciFiMovies.length, "rocket")}
            className="px-3 py-1 rounded-full bg-[#1e1b2e] border border-white/5 text-[11px] font-semibold text-neutral-300 hover:text-white transition-colors cursor-pointer"
          >
            See all
          </button>
        </div>

        <div className="flex gap-3 overflow-x-auto no-scrollbar pb-1">
          {sciFiMovies.slice(0, 15).map(renderMovieCard)}
        </div>
      </section>

      {/* 9. SECTION: DRAMA & ROMANCE */}
      <section className="mt-7 px-4">
        <div className="flex items-center justify-between mb-3">
          <div className="flex items-center gap-2">
            <Heart className="w-4 h-4 text-pink-500 fill-pink-500" />
            <h2 className="text-lg font-bold text-white tracking-tight">Drama &amp; Romance</h2>
          </div>
          <button
            type="button"
            onClick={() => onNavigateToCategorySeeAll?.("Romance", dramaMovies.length, "heart")}
            className="px-3 py-1 rounded-full bg-[#1e1b2e] border border-white/5 text-[11px] font-semibold text-neutral-300 hover:text-white transition-colors cursor-pointer"
          >
            See all
          </button>
        </div>

        <div className="flex gap-3 overflow-x-auto no-scrollbar pb-1">
          {dramaMovies.slice(0, 15).map(renderMovieCard)}
        </div>
      </section>

      {/* 10. SECTION: HORROR & THRILLER */}
      <section className="mt-7 px-4">
        <div className="flex items-center justify-between mb-3">
          <div className="flex items-center gap-2">
            <Moon className="w-4 h-4 text-red-500 fill-red-500" />
            <h2 className="text-lg font-bold text-white tracking-tight">Horror &amp; Thriller</h2>
          </div>
          <button
            type="button"
            onClick={() => onNavigateToCategorySeeAll?.("Horror", 31, "moon")}
            className="px-3 py-1 rounded-full bg-[#1e1b2e] border border-white/5 text-[11px] font-semibold text-neutral-300 hover:text-white transition-colors cursor-pointer"
          >
            See all
          </button>
        </div>

        <div className="flex gap-3 overflow-x-auto no-scrollbar pb-1">
          {horrorMovies.slice(0, 15).map(renderMovieCard)}
        </div>
      </section>

      {/* 11. SECTION: ANIMATION & CARTOONS */}
      {animationMovies.length > 0 && (
        <section className="mt-7 px-4">
          <div className="flex items-center justify-between mb-3">
            <div className="flex items-center gap-2">
              <Smile className="w-4 h-4 text-yellow-400" />
              <h2 className="text-lg font-bold text-white tracking-tight">Animation &amp; Kids</h2>
            </div>
            <button
              type="button"
              onClick={() => onNavigateToCategorySeeAll?.("Animation", animationMovies.length, "sparkles")}
              className="px-3 py-1 rounded-full bg-[#1e1b2e] border border-white/5 text-[11px] font-semibold text-neutral-300 hover:text-white transition-colors cursor-pointer"
            >
              See all
            </button>
          </div>

          <div className="flex gap-3 overflow-x-auto no-scrollbar pb-1">
            {animationMovies.slice(0, 15).map(renderMovieCard)}
          </div>
        </section>
      )}

      {/* 11. FIXED BOTTOM NAVIGATION BAR (Hidden on desktop) */}
      <nav className="lg:hidden fixed bottom-0 left-0 right-0 z-50 h-16 bg-black/95 backdrop-blur-lg border-t border-white/10 px-4 flex items-center justify-around">
        <button
          type="button"
          onClick={() => handleTabClick("home")}
          className="flex flex-col items-center gap-1 cursor-pointer transition-colors"
        >
          <Home className={`w-5 h-5 ${activeTab === "home" ? "text-[#00E676]" : "text-neutral-500"}`} />
          <span className={`text-[10px] font-medium ${activeTab === "home" ? "text-[#00E676]" : "text-neutral-500"}`}>
            Home
          </span>
        </button>

        <button
          type="button"
          onClick={() => handleTabClick("search")}
          className="flex flex-col items-center gap-1 cursor-pointer transition-colors"
        >
          <Search className={`w-5 h-5 ${activeTab === "search" ? "text-[#00E676]" : "text-neutral-500"}`} />
          <span className={`text-[10px] font-medium ${activeTab === "search" ? "text-[#00E676]" : "text-neutral-500"}`}>
            Search
          </span>
        </button>

        <button
          type="button"
          onClick={() => handleTabClick("favorites")}
          className="flex flex-col items-center gap-1 cursor-pointer transition-colors"
        >
          <Heart className={`w-5 h-5 ${activeTab === "favorites" ? "text-[#00E676]" : "text-neutral-500"}`} />
          <span className={`text-[10px] font-medium ${activeTab === "favorites" ? "text-[#00E676]" : "text-neutral-500"}`}>
            Favorites
          </span>
        </button>

        <button
          type="button"
          onClick={() => handleTabClick("downloads")}
          className="flex flex-col items-center gap-1 cursor-pointer transition-colors"
        >
          <Download className={`w-5 h-5 ${activeTab === "downloads" ? "text-[#00E676]" : "text-neutral-500"}`} />
          <span className={`text-[10px] font-medium ${activeTab === "downloads" ? "text-[#00E676]" : "text-neutral-500"}`}>
            Downloads
          </span>
        </button>

        <button
          type="button"
          onClick={() => handleTabClick("profile")}
          className="flex flex-col items-center gap-1 cursor-pointer transition-colors"
        >
          <UserIcon className={`w-5 h-5 ${activeTab === "profile" ? "text-[#00E676]" : "text-neutral-500"}`} />
          <span className={`text-[10px] font-medium ${activeTab === "profile" ? "text-[#00E676]" : "text-neutral-500"}`}>
            Profile
          </span>
        </button>
      </nav>
    </div>
  );
};
