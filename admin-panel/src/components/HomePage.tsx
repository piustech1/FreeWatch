import React, { useState, useEffect, useMemo } from "react";
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
  ChevronLeft,
  TrendingUp,
  Clock,
} from "lucide-react";
import { ALL_VJS } from "./AvailableVJsPage";
import { useLiveCatalog, CatalogMovie } from "../data/liveCatalog";
import { AvatarGraphic } from "./AvatarGraphic";
import { UserProfileData } from "./EditProfileModal";
import { searchTmdb, getMovieLogo } from "../services/tmdb";
import { VjBadge } from "./VjBadge";
import { FloatingBottomNav } from "./FloatingBottomNav";

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
    <img
      src="/logo_full.png"
      alt="FreeWatch"
      className={`h-9 sm:h-10 md:h-11 w-auto max-w-[160px] sm:max-w-[190px] object-contain select-none transition-all ${className}`}
    />
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

  const [heroIndex, setHeroIndex] = useState(0);
  const [isHeroPaused, setIsHeroPaused] = useState(false);
  const [touchStartX, setTouchStartX] = useState<number | null>(null);

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
    romanceMovies,
    familyMovies,
  } = useLiveCatalog();

  // 8-candidate pool for the Hero Deck matching Flutter HeroBanner
  const heroCandidates = useMemo(() => {
    const list = latestMovies.filter((m) => m.imageUrl && m.title);
    return list.length > 0 ? list.slice(0, 8) : catalog.slice(0, 8);
  }, [latestMovies, catalog]);

  const numHeroes = heroCandidates.length || 1;

  // TMDB logo caching for hero candidate items
  const [heroLogos, setHeroLogos] = useState<Record<string, string | null>>({});

  useEffect(() => {
    if (heroCandidates.length === 0) return;
    heroCandidates.forEach(async (movie) => {
      if (heroLogos[movie.id] !== undefined) return;
      try {
        const tmdb = await searchTmdb(movie.title, movie.isTv);
        if (tmdb && tmdb.id) {
          const logo = await getMovieLogo(tmdb.id, movie.isTv);
          setHeroLogos((prev) => ({ ...prev, [movie.id]: logo }));
        } else {
          setHeroLogos((prev) => ({ ...prev, [movie.id]: null }));
        }
      } catch {
        setHeroLogos((prev) => ({ ...prev, [movie.id]: null }));
      }
    });
  }, [heroCandidates]);

  // 3.5s automated slide timer matching Android app
  useEffect(() => {
    if (isHeroPaused || heroCandidates.length <= 1) return;
    const timer = setInterval(() => {
      setHeroIndex((prev) => (prev + 1) % heroCandidates.length);
    }, 3500);
    return () => clearInterval(timer);
  }, [isHeroPaused, heroCandidates.length]);

  const heroMovie = heroCandidates[heroIndex % numHeroes];

  const handleTouchStart = (e: React.TouchEvent) => {
    setIsHeroPaused(true);
    setTouchStartX(e.touches[0].clientX);
  };

  const handleTouchEnd = (e: React.TouchEvent) => {
    setIsHeroPaused(false);
    if (touchStartX === null) return;
    const diff = e.changedTouches[0].clientX - touchStartX;
    if (diff > 40) {
      // Swiped right -> previous slide
      setHeroIndex((prev) => (prev - 1 + numHeroes) % numHeroes);
    } else if (diff < -40) {
      // Swiped left -> next slide
      setHeroIndex((prev) => (prev + 1) % numHeroes);
    }
    setTouchStartX(null);
  };

  const handleTabClick = (tab: "home" | "search" | "favorites" | "downloads" | "profile") => {
    setActiveTab(tab);
    if (tab === "search" && onNavigateToSearch) {
      onNavigateToSearch();
    } else if (onNavigateTab) {
      onNavigateTab(tab);
    }
  };

  // Reusable Movie Poster Card matching Flutter app layout
  const renderMovieCard = (movie: CatalogMovie) => {
    return (
      <div
        key={movie.id}
        onClick={() => onSelectMovie?.(movie.id, movie.isTv, movie.title, movie)}
        className="w-[124px] sm:w-[138px] md:w-[148px] shrink-0 cursor-pointer group active:scale-95 transition-transform select-none"
      >
        <div className="relative aspect-[2/3] rounded-2xl overflow-hidden bg-neutral-900 border border-white/10 group-hover:border-white/30 transition-all p-2.5 flex flex-col justify-between shadow-lg">
          {movie.imageUrl ? (
            <img
              src={movie.imageUrl}
              alt={movie.title}
              onError={(e) => {
                const img = e.target as HTMLImageElement;
                if (!img.dataset.retried) {
                  img.dataset.retried = "true";
                  searchTmdb(movie.title, movie.isTv)
                    .then((tmdb) => {
                      if (tmdb?.posterUrl) {
                        img.src = tmdb.posterUrl;
                      } else {
                        img.style.display = "none";
                      }
                    })
                    .catch(() => {
                      img.style.display = "none";
                    });
                } else {
                  img.style.display = "none";
                }
              }}
              className="absolute inset-0 w-full h-full object-cover filter brightness-90 group-hover:scale-105 transition-transform duration-300"
            />
          ) : null}
          <div className="absolute inset-0 bg-gradient-to-t from-black via-black/35 to-transparent pointer-events-none" />

          {/* Top Right: Authentic Flutter VJ Badge (No green dot) */}
          <div className="relative z-10 flex justify-end">
            <VjBadge vjName={movie.vj} size="sm" />
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

  const renderMovieCardSkeleton = (idx: number) => (
    <div key={`skel-${idx}`} className="w-[124px] sm:w-[138px] md:w-[148px] shrink-0 animate-pulse select-none">
      <div className="aspect-[2/3] rounded-2xl bg-neutral-900/90 border border-white/5 relative overflow-hidden" />
      <div className="mt-2 h-3 w-4/5 rounded bg-white/10" />
      <div className="mt-1 h-2.5 w-1/2 rounded bg-white/5" />
    </div>
  );

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

      {/* 2A. MOBILE HERO FEATURED 5-POSTER STRETCHED DECK */}
      <section
        className="relative px-4 pt-4 pb-2 lg:hidden select-none"
        onTouchStart={handleTouchStart}
        onTouchEnd={handleTouchEnd}
        onMouseEnter={() => setIsHeroPaused(true)}
        onMouseLeave={() => setIsHeroPaused(false)}
      >
        {/* 5-Poster Stretched Stacked Deck Container */}
        <div className="relative w-full h-[252px] flex items-center justify-start overflow-hidden">
          {heroCandidates.map((m, idx) => {
            const offset = (idx - (heroIndex % numHeroes) + numHeroes) % numHeroes;
            const step = 78;

            let x = step * 5;
            let scale = 0.6;
            let zIndex = 0;
            let opacity = 0;
            let overlayOpacity = 0.8;
            let pointerEvents = "none";

            if (offset === 0) {
              x = 0;
              scale = 1.0;
              zIndex = 30;
              opacity = 1;
              overlayOpacity = 0;
              pointerEvents = "auto";
            } else if (offset === 1) {
              x = step * 1;
              scale = 0.92;
              zIndex = 20;
              opacity = 1;
              overlayOpacity = 0.25;
              pointerEvents = "auto";
            } else if (offset === 2) {
              x = step * 2;
              scale = 0.85;
              zIndex = 15;
              opacity = 1;
              overlayOpacity = 0.45;
              pointerEvents = "auto";
            } else if (offset === 3) {
              x = step * 3;
              scale = 0.78;
              zIndex = 10;
              opacity = 1;
              overlayOpacity = 0.65;
              pointerEvents = "auto";
            } else if (offset === 4) {
              x = step * 4;
              scale = 0.71;
              zIndex = 5;
              opacity = 0.8;
              overlayOpacity = 0.78;
              pointerEvents = "auto";
            } else if (offset === numHeroes - 1) {
              x = -130;
              scale = 0.88;
              zIndex = 2;
              opacity = 0;
              overlayOpacity = 0.85;
            }

            return (
              <div
                key={m.id}
                onClick={() => {
                  if (offset !== 0) {
                    setHeroIndex(idx);
                  } else {
                    onSelectMovie?.(m.id, m.isTv, m.title, m);
                  }
                }}
                className="absolute top-0 left-0 w-[162px] h-[242px] rounded-[20px] overflow-hidden bg-[#111827] cursor-pointer select-none"
                style={{
                  transform: `translate3d(${x}px, 0, 0) scale(${scale})`,
                  transformOrigin: "left center",
                  zIndex,
                  opacity,
                  pointerEvents: pointerEvents as any,
                  boxShadow:
                    offset === 0
                      ? "-8px 0 22px rgba(0,0,0,0.75), 0 8px 16px rgba(0,0,0,0.5)"
                      : "0 4px 12px rgba(0,0,0,0.4)",
                  transition:
                    "transform 700ms cubic-bezier(0.19, 1.0, 0.22, 1.0), opacity 700ms cubic-bezier(0.19, 1.0, 0.22, 1.0)",
                }}
              >
                {/* Clean Poster Artwork without title overlay */}
                {m.imageUrl ? (
                  <img
                    src={m.imageUrl}
                    alt=""
                    className="w-full h-full object-cover filter brightness-95"
                    onError={(e) => {
                      (e.target as HTMLImageElement).style.display = "none";
                    }}
                  />
                ) : null}

                {/* Smooth Dark Dimming Overlay based on stack depth */}
                <div
                  className="absolute inset-0 bg-black transition-opacity duration-700 pointer-events-none"
                  style={{ opacity: overlayOpacity }}
                />

                {/* Bookmark Button (Top Left) */}
                <button
                  type="button"
                  onClick={(e) => {
                    e.stopPropagation();
                    setIsBookmarked(!isBookmarked);
                  }}
                  className="absolute top-2.5 left-2.5 z-20 w-7 h-7 rounded-lg bg-white/20 backdrop-blur-md border border-white/15 flex items-center justify-center text-white hover:text-[#00E676] transition-colors cursor-pointer"
                >
                  <Bookmark
                    className={`w-3.5 h-3.5 ${
                      isBookmarked && offset === 0
                        ? "fill-[#34D399] text-[#34D399]"
                        : "text-white"
                    }`}
                  />
                </button>

                {/* Rating Badge (Top Right) */}
                <div className="absolute top-2.5 right-2.5 z-20 px-2 py-0.5 rounded-md bg-[#34D399] text-black text-[10px] font-extrabold flex items-center gap-0.5 shadow-sm">
                  <span>★</span> {m.rating || "7.5"}
                </div>

                {/* Center Play Button on Active Front Poster */}
                {offset === 0 && (
                  <div className="absolute inset-0 flex items-center justify-center pointer-events-none z-20">
                    <div className="w-11 h-11 rounded-full bg-white/20 backdrop-blur-md border border-white/30 flex items-center justify-center shadow-lg">
                      <Play className="w-4 h-4 fill-white text-white ml-0.5" />
                    </div>
                  </div>
                )}
              </div>
            );
          })}
        </div>

        {/* Below Posters Info Row (TMDB Logo / Subtitle & VJ Capsule Badge) */}
        {heroMovie && (
          <div className="mt-3 flex items-center justify-between px-1">
            <div
              onClick={() => onSelectMovie?.(heroMovie.id, heroMovie.isTv, heroMovie.title, heroMovie)}
              className="cursor-pointer group flex-1 pr-3 flex flex-col justify-center"
            >
              {heroLogos[heroMovie.id] ? (
                <img
                  src={heroLogos[heroMovie.id]!}
                  alt={heroMovie.title}
                  className="h-7 max-w-[210px] object-contain object-left drop-shadow-md"
                />
              ) : (
                <div className="text-lg font-black tracking-tight text-white font-sans leading-tight group-hover:text-[#00E676] transition-colors truncate">
                  {heroMovie.title}
                </div>
              )}
              <div className="text-[12px] text-[#7A7C85] mt-1 font-medium">
                {heroMovie.category || "Action"} • {heroMovie.year}
                {heroMovie.duration ? ` • ${heroMovie.duration}` : ""}
              </div>
            </div>

            <button
              type="button"
              onClick={() => (onSelectVj ? onSelectVj(heroMovie.vj) : onNavigateToAvailableVJs?.())}
              className="shrink-0 cursor-pointer"
            >
              <VjBadge vjName={heroMovie.vj} size="md" />
            </button>
          </div>
        )}

        {/* Dynamic Dot Pagination */}
        <div className="flex justify-center items-center gap-1.5 mt-3">
          {heroCandidates.slice(0, 6).map((_, dotIdx) => (
            <button
              key={dotIdx}
              type="button"
              onClick={() => setHeroIndex(dotIdx)}
              className={`h-1.5 rounded-full transition-all cursor-pointer ${
                heroIndex % numHeroes === dotIdx
                  ? "w-6 bg-[#00E676] shadow-sm shadow-[#00E676]/50"
                  : "w-1.5 bg-white/30 hover:bg-white/50"
              }`}
              aria-label={`Slide ${dotIdx + 1}`}
            />
          ))}
        </div>
      </section>

      {/* 2B. DESKTOP / 10-FOOT CINEMATIC TV BANNER */}
      {heroCandidates.length > 0 && (
        <div
          onMouseEnter={() => setIsHeroPaused(true)}
          onMouseLeave={() => setIsHeroPaused(false)}
          className="hidden lg:block px-6 xl:px-10 pt-4 pb-6 max-w-[1600px] mx-auto w-full select-none"
        >
          <div className="relative w-full h-[470px] xl:h-[510px] rounded-[32px] overflow-hidden border border-white/10 shadow-2xl bg-[#08080c] group">
            {/* Background Slides with Smooth Crossfade */}
            {heroCandidates.map((movie, idx) => {
              const isActive = idx === (heroIndex % numHeroes);
              return (
                <div
                  key={movie.id}
                  className={`absolute inset-0 transition-opacity duration-700 ease-in-out ${
                    isActive ? "opacity-100 z-10 pointer-events-auto" : "opacity-0 z-0 pointer-events-none"
                  }`}
                >
                  <img
                    src={movie.backdropUrl || movie.imageUrl}
                    alt={movie.title}
                    className="w-full h-full object-cover object-[center_30%] filter brightness-90 contrast-110 group-hover:scale-105 transition-transform duration-1000"
                  />
                  <div className="absolute inset-0 bg-gradient-to-r from-black via-black/85 via-45% to-transparent" />
                  <div className="absolute inset-0 bg-gradient-to-t from-black via-black/40 via-30% to-transparent" />

                  {/* Top Right: Authentic VJ Badge */}
                  <div className="absolute top-6 right-6 z-20">
                    <button
                      type="button"
                      onClick={() => onSelectVj?.(movie.vj)}
                      className="cursor-pointer"
                    >
                      <VjBadge vjName={movie.vj} size="md" />
                    </button>
                  </div>

                  {/* Left Content Column */}
                  <div className="relative z-10 h-full flex flex-col justify-end p-8 xl:p-12 max-w-2xl">
                    <div className="space-y-1 mb-3">
                      {heroLogos[movie.id] ? (
                        <img
                          src={heroLogos[movie.id]!}
                          alt={movie.title}
                          className="h-16 max-w-[340px] object-contain object-left drop-shadow-xl mb-2"
                        />
                      ) : (
                        <div className="text-3xl xl:text-5xl font-black tracking-tight text-white drop-shadow-[0_4px_12px_rgba(0,0,0,0.8)] leading-tight uppercase">
                          {movie.title}
                        </div>
                      )}
                    </div>

                    {/* Tags Row */}
                    <div className="flex items-center gap-2 mb-3">
                      <span className="px-2.5 py-1 rounded-md bg-white/10 backdrop-blur-md border border-white/15 text-xs font-black text-amber-400">
                        ★ {movie.rating}
                      </span>
                      <span className="px-2.5 py-1 rounded-md bg-white/10 backdrop-blur-md border border-white/15 text-xs font-semibold text-neutral-200">
                        {movie.duration}
                      </span>
                      <span className="px-2.5 py-1 rounded-md bg-white/10 backdrop-blur-md border border-white/15 text-xs font-semibold text-neutral-200">
                        {movie.year}
                      </span>
                      <span className="px-2.5 py-1 rounded-md bg-white/10 backdrop-blur-md border border-white/15 text-xs font-semibold text-neutral-200">
                        {movie.category}
                      </span>
                    </div>

                    {/* Synopsis */}
                    <p className="text-sm text-neutral-300 font-medium leading-relaxed mb-6 max-w-xl line-clamp-3">
                      {movie.overview}
                    </p>

                    {/* Action Buttons */}
                    <div className="flex items-center gap-4">
                      <button
                        type="button"
                        onClick={() => onSelectMovie?.(movie.id, movie.isTv, movie.title, movie)}
                        className="flex items-center gap-2.5 px-8 py-3.5 rounded-full bg-[#00E676] hover:bg-[#00c853] text-black font-black text-sm tracking-wide shadow-[0_0_25px_rgba(0,230,118,0.5)] hover:scale-105 active:scale-95 transition-all cursor-pointer"
                      >
                        <Play className="w-4 h-4 fill-black text-black" />
                        <span>WATCH NOW</span>
                      </button>

                      <button
                        type="button"
                        onClick={() => onSelectMovie?.(movie.id, movie.isTv, movie.title, movie)}
                        className="flex items-center gap-2 px-7 py-3.5 rounded-full bg-black/40 hover:bg-white/15 border border-white/40 text-white font-bold text-sm tracking-wide backdrop-blur-md hover:scale-105 active:scale-95 transition-all cursor-pointer"
                      >
                        <span>DETAILS</span>
                      </button>
                    </div>
                  </div>
                </div>
              );
            })}

            {/* Desktop Left / Right Arrow Controls */}
            <button
              type="button"
              onClick={() => setHeroIndex((prev) => (prev - 1 + numHeroes) % numHeroes)}
              aria-label="Previous Slide"
              className="absolute left-4 top-1/2 -translate-y-1/2 z-30 w-11 h-11 rounded-full bg-black/50 hover:bg-black/80 border border-white/20 text-white flex items-center justify-center opacity-0 group-hover:opacity-100 transition-all cursor-pointer backdrop-blur-md active:scale-95"
            >
              <ChevronLeft className="w-5 h-5" />
            </button>
            <button
              type="button"
              onClick={() => setHeroIndex((prev) => (prev + 1) % numHeroes)}
              aria-label="Next Slide"
              className="absolute right-4 top-1/2 -translate-y-1/2 z-30 w-11 h-11 rounded-full bg-black/50 hover:bg-black/80 border border-white/20 text-white flex items-center justify-center opacity-0 group-hover:opacity-100 transition-all cursor-pointer backdrop-blur-md active:scale-95"
            >
              <ChevronRight className="w-5 h-5" />
            </button>

            {/* Desktop Indicator Dots */}
            <div className="absolute bottom-6 right-8 z-30 flex items-center gap-2">
              {heroCandidates.map((_, i) => {
                const isActive = i === (heroIndex % numHeroes);
                return (
                  <button
                    key={i}
                    type="button"
                    onClick={() => setHeroIndex(i)}
                    aria-label={`Go to slide ${i + 1}`}
                    className={`h-2 rounded-full transition-all duration-300 cursor-pointer ${
                      isActive ? "w-8 bg-[#00E676] shadow-[0_0_8px_rgba(0,230,118,0.8)]" : "w-2 bg-white/30 hover:bg-white/60"
                    }`}
                  />
                );
              })}
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
                className="px-3 py-1 rounded-xl bg-white/[0.06] hover:bg-white/[0.12] border border-white/10 text-xs font-semibold text-white/70 hover:text-white transition-all cursor-pointer backdrop-blur-md"
              >
                See all
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
            className="px-3 py-1 rounded-xl bg-white/[0.06] hover:bg-white/[0.12] border border-white/10 text-xs font-semibold text-white/70 hover:text-white transition-all cursor-pointer backdrop-blur-md"
          >
            See all
          </button>
        </div>

        {/* Horizontal VJ Cards Scroller */}
        <div className="flex gap-3 overflow-x-auto no-scrollbar pb-1">
          {ALL_VJS.map((vj) => (
            <div
              key={vj.id}
              onClick={() => (onSelectVj ? onSelectVj(vj.name) : onNavigateToAvailableVJs?.())}
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
            className="px-3 py-1 rounded-xl bg-white/[0.06] hover:bg-white/[0.12] border border-white/10 text-xs font-semibold text-white/70 hover:text-white transition-all cursor-pointer backdrop-blur-md"
          >
            See all
          </button>
        </div>

        <div className="flex gap-3 overflow-x-auto no-scrollbar pb-1">
          {loading && latestMovies.length === 0
            ? Array.from({ length: 6 }).map((_, i) => renderMovieCardSkeleton(i))
            : latestMovies.slice(0, 15).map(renderMovieCard)}
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
            className="px-3 py-1 rounded-xl bg-white/[0.06] hover:bg-white/[0.12] border border-white/10 text-xs font-semibold text-white/70 hover:text-white transition-all cursor-pointer backdrop-blur-md"
          >
            See all
          </button>
        </div>

        <div className="flex gap-3 overflow-x-auto no-scrollbar pb-1">
          {loading && trendingMovies.length === 0
            ? Array.from({ length: 6 }).map((_, i) => renderMovieCardSkeleton(i))
            : trendingMovies.slice(0, 15).map(renderMovieCard)}
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
            onClick={() => onNavigateToCategorySeeAll?.("Series", (seriesMovies.length || 1), "tv")}
            className="px-3 py-1 rounded-xl bg-white/[0.06] hover:bg-white/[0.12] border border-white/10 text-xs font-semibold text-white/70 hover:text-white transition-all cursor-pointer backdrop-blur-md"
          >
            See all
          </button>
        </div>

        <div className="flex gap-3 overflow-x-auto no-scrollbar pb-1">
          {loading && seriesMovies.length === 0
            ? Array.from({ length: 6 }).map((_, i) => renderMovieCardSkeleton(i))
            : (seriesMovies.length > 0 ? seriesMovies : catalog.filter((m) => m.isTv)).slice(0, 15).map(renderMovieCard)}
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
            onClick={() => onNavigateToCategorySeeAll?.("Action", (actionMovies.length || latestMovies.length), "flame")}
            className="px-3 py-1 rounded-xl bg-white/[0.06] hover:bg-white/[0.12] border border-white/10 text-xs font-semibold text-white/70 hover:text-white transition-all cursor-pointer backdrop-blur-md"
          >
            See all
          </button>
        </div>

        <div className="flex gap-3 overflow-x-auto no-scrollbar pb-1">
          {loading && actionMovies.length === 0
            ? Array.from({ length: 6 }).map((_, i) => renderMovieCardSkeleton(i))
            : (actionMovies.length > 0 ? actionMovies : latestMovies.filter((m) => !m.isTv)).slice(0, 15).map(renderMovieCard)}
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
            onClick={() => onNavigateToCategorySeeAll?.("Sci-Fi", (sciFiMovies.length || 10), "rocket")}
            className="px-3 py-1 rounded-xl bg-white/[0.06] hover:bg-white/[0.12] border border-white/10 text-xs font-semibold text-white/70 hover:text-white transition-all cursor-pointer backdrop-blur-md"
          >
            See all
          </button>
        </div>

        <div className="flex gap-3 overflow-x-auto no-scrollbar pb-1">
          {loading && sciFiMovies.length === 0
            ? Array.from({ length: 6 }).map((_, i) => renderMovieCardSkeleton(i))
            : (sciFiMovies.length > 0 ? sciFiMovies : latestMovies.filter((m) => !m.isTv).slice(2)).slice(0, 15).map(renderMovieCard)}
        </div>
      </section>

      {/* 9. SECTION: ROMANCE */}
      <section className="mt-7 px-4">
        <div className="flex items-center justify-between mb-3">
          <div className="flex items-center gap-2">
            <Heart className="w-4 h-4 text-pink-500 fill-pink-500" />
            <h2 className="text-lg font-bold text-white tracking-tight">Romance &amp; Love</h2>
          </div>
          <button
            type="button"
            onClick={() => onNavigateToCategorySeeAll?.("Romance", (romanceMovies.length || 10), "heart")}
            className="px-3 py-1 rounded-xl bg-white/[0.06] hover:bg-white/[0.12] border border-white/10 text-xs font-semibold text-white/70 hover:text-white transition-all cursor-pointer backdrop-blur-md"
          >
            See all
          </button>
        </div>

        <div className="flex gap-3 overflow-x-auto no-scrollbar pb-1">
          {loading && romanceMovies.length === 0
            ? Array.from({ length: 6 }).map((_, i) => renderMovieCardSkeleton(i))
            : (romanceMovies.length > 0 ? romanceMovies : dramaMovies.length > 0 ? dramaMovies : latestMovies.slice(4)).slice(0, 15).map(renderMovieCard)}
        </div>
      </section>

      {/* 10. SECTION: ANIMATION & KIDS */}
      <section className="mt-7 px-4">
        <div className="flex items-center justify-between mb-3">
          <div className="flex items-center gap-2">
            <Smile className="w-4 h-4 text-yellow-400" />
            <h2 className="text-lg font-bold text-white tracking-tight">Animation &amp; Kids</h2>
          </div>
          <button
            type="button"
            onClick={() => onNavigateToCategorySeeAll?.("Animation", animationMovies.length || 10, "sparkles")}
            className="px-3 py-1 rounded-xl bg-white/[0.06] hover:bg-white/[0.12] border border-white/10 text-xs font-semibold text-white/70 hover:text-white transition-all cursor-pointer backdrop-blur-md"
          >
            See all
          </button>
        </div>

        <div className="flex gap-3 overflow-x-auto no-scrollbar pb-1">
          {loading && animationMovies.length === 0
            ? Array.from({ length: 6 }).map((_, i) => renderMovieCardSkeleton(i))
            : (animationMovies.length > 0 ? animationMovies : latestMovies.filter((m) => m.category.toLowerCase().includes("anim") || m.title.toLowerCase().includes("panda") || m.title.toLowerCase().includes("sonic"))).slice(0, 15).map(renderMovieCard)}
        </div>
      </section>

      {/* 11. SECTION: KIDS & FAMILY */}
      <section className="mt-7 px-4">
        <div className="flex items-center justify-between mb-3">
          <div className="flex items-center gap-2">
            <Smile className="w-4 h-4 text-sky-400" />
            <h2 className="text-lg font-bold text-white tracking-tight">Kids &amp; Family</h2>
          </div>
          <button
            type="button"
            onClick={() => onNavigateToCategorySeeAll?.("Family", familyMovies.length || 10, "sparkles")}
            className="px-3 py-1 rounded-xl bg-white/[0.06] hover:bg-white/[0.12] border border-white/10 text-xs font-semibold text-white/70 hover:text-white transition-all cursor-pointer backdrop-blur-md"
          >
            See all
          </button>
        </div>

        <div className="flex gap-3 overflow-x-auto no-scrollbar pb-1">
          {loading && familyMovies.length === 0
            ? Array.from({ length: 6 }).map((_, i) => renderMovieCardSkeleton(i))
            : (familyMovies.length > 0 ? familyMovies : animationMovies.length > 0 ? animationMovies : latestMovies).slice(0, 15).map(renderMovieCard)}
        </div>
      </section>

      {/* 12. SECTION: HORROR & THRILLER */}
      <section className="mt-7 px-4">
        <div className="flex items-center justify-between mb-3">
          <div className="flex items-center gap-2">
            <Moon className="w-4 h-4 text-red-500 fill-red-500" />
            <h2 className="text-lg font-bold text-white tracking-tight">Horror &amp; Thriller</h2>
          </div>
          <button
            type="button"
            onClick={() => onNavigateToCategorySeeAll?.("Horror", (horrorMovies.length || 10), "moon")}
            className="px-3 py-1 rounded-xl bg-white/[0.06] hover:bg-white/[0.12] border border-white/10 text-xs font-semibold text-white/70 hover:text-white transition-all cursor-pointer backdrop-blur-md"
          >
            See all
          </button>
        </div>

        <div className="flex gap-3 overflow-x-auto no-scrollbar pb-1">
          {loading && horrorMovies.length === 0
            ? Array.from({ length: 6 }).map((_, i) => renderMovieCardSkeleton(i))
            : (horrorMovies.length > 0 ? horrorMovies : latestMovies.filter((m) => !m.isTv).slice(1)).slice(0, 15).map(renderMovieCard)}
        </div>
      </section>

      {/* 13. FLOATING CURVED GLASS BOTTOM NAVIGATION BAR (Hidden on desktop) */}
      <FloatingBottomNav activeTab={activeTab} onNavigateTab={handleTabClick} />
    </div>
  );
};
