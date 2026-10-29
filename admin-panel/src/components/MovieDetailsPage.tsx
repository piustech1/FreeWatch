import React, { useState, useMemo, useRef, useEffect } from "react";
import {
  Search as SearchIcon,
  Bell,
  ArrowLeft,
  Play,
  Bookmark,
  Download,
  ChevronDown,
  Home,
  Heart,
  User as UserIcon,
  X,
  RefreshCw,
  AlertCircle
} from "lucide-react";
import Hls from "hls.js";
import { FreeWatchLogo } from "./HomePage";
import { useLiveCatalog, CatalogMovie } from "../data/liveCatalog";
import { AvatarGraphic } from "./AvatarGraphic";
import { UserProfileData } from "./EditProfileModal";
import {
  searchTmdb,
  getMovieLogo,
  getCredits,
  TmdbCastMember
} from "../services/tmdb";
import { VjBadge } from "./VjBadge";

interface MovieDetailsPageProps {
  onBack: () => void;
  onNavigateTab: (tab: "home" | "search" | "favorites" | "downloads" | "profile") => void;
  onLogout?: () => void;
  movieTitle?: string;
  movie?: CatalogMovie;
  userProfile?: UserProfileData;
  onSelectMovie?: (movieId: string, isSeries?: boolean, title?: string, movie?: CatalogMovie) => void;
  onNavigateToNotifications?: () => void;
}

export const MovieDetailsPage: React.FC<MovieDetailsPageProps> = ({
  onBack,
  onNavigateTab,
  onLogout,
  movieTitle = "The MOST DANGEROUS GAME",
  movie: incomingMovie,
  userProfile,
  onSelectMovie,
  onNavigateToNotifications,
}) => {
  const [isPlaying, setIsPlaying] = useState(false);
  const [isBookmarked, setIsBookmarked] = useState(false);
  const [isDownloaded, setIsDownloaded] = useState(false);
  const [isReadMore, setIsReadMore] = useState(false);
  const [streamError, setStreamError] = useState(false);
  const [tmdbLogo, setTmdbLogo] = useState<string | null>(null);
  const [castList, setCastList] = useState<TmdbCastMember[]>([]);

  const videoRef = useRef<HTMLVideoElement>(null);
  const { catalog, latestMovies } = useLiveCatalog();

  // Resolve active movie from prop or catalog lookup
  const activeMovie: CatalogMovie = useMemo(() => {
    if (incomingMovie) return incomingMovie;
    const found = catalog.find(
      (m) =>
        m.title.toLowerCase().trim() === movieTitle.toLowerCase().trim() ||
        m.id === movieTitle
    );
    if (found) return found;
    return (
      latestMovies[0] || {
        id: "default-movie",
        title: movieTitle,
        vj: "VJ Junior",
        category: "Action",
        genres: ["Action", "Luganda Dubbed"],
        imageUrl: "https://apposters.b-cdn.net/laba/yo/naki/gNxs2151.jpg",
        backdropUrl: "https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=1600&auto=format&fit=crop&q=80",
        rating: "8.8",
        year: "2025",
        duration: "1h 55m",
        isTv: false,
        overview: `Experience ${movieTitle} in crisp full HD with exclusive, spiced-up Luganda translation. Streaming free on FreeWatch.`,
        streamUrl: "https://munotech3.b-cdn.net/gugwa/gugwa42/07.Mirzapur.SN2.VJ.Ashim.1080.mp4",
      }
    );
  }, [incomingMovie, movieTitle, catalog, latestMovies]);

  // Load TMDB Logo & Cast
  useEffect(() => {
    let cancelled = false;
    async function loadTmdbData() {
      try {
        const tmdb = await searchTmdb(activeMovie.title, false);
        if (!cancelled && tmdb && tmdb.id) {
          getMovieLogo(tmdb.id, false).then((l) => {
            if (!cancelled) setTmdbLogo(l);
          });
          getCredits(tmdb.id, false).then((c) => {
            if (!cancelled) setCastList(c);
          });
        }
      } catch {}
    }
    loadTmdbData();
    return () => {
      cancelled = true;
    };
  }, [activeMovie.title]);

  const streamUrl = activeMovie.streamUrl;

  // Sync bookmarks from localStorage
  useEffect(() => {
    try {
      const saved = localStorage.getItem("freewatch_favorites");
      if (saved) {
        const list: CatalogMovie[] = JSON.parse(saved);
        if (list.some((m) => m.id === activeMovie.id)) {
          setIsBookmarked(true);
        }
      }
    } catch {}
  }, [activeMovie.id]);

  // Record movie to watch history in localStorage
  useEffect(() => {
    try {
      const saved = localStorage.getItem("freewatch_watch_history");
      const list: CatalogMovie[] = saved ? JSON.parse(saved) : [];
      const filtered = list.filter((m) => m.id !== activeMovie.id);
      const updated = [activeMovie, ...filtered].slice(0, 50);
      localStorage.setItem("freewatch_watch_history", JSON.stringify(updated));
    } catch {}
  }, [activeMovie.id]);

  const toggleFavorite = () => {
    const nextState = !isBookmarked;
    setIsBookmarked(nextState);
    try {
      const saved = localStorage.getItem("freewatch_favorites");
      let list: CatalogMovie[] = saved ? JSON.parse(saved) : [];
      if (nextState) {
        if (!list.some((m) => m.id === activeMovie.id)) {
          list.push(activeMovie);
        }
      } else {
        list = list.filter((m) => m.id !== activeMovie.id);
      }
      localStorage.setItem("freewatch_favorites", JSON.stringify(list));
    } catch {}
  };

  // Video Streaming Setup with HLS and MP4 fallback
  useEffect(() => {
    if (!isPlaying || !streamUrl || !videoRef.current) return;
    setStreamError(false);

    const video = videoRef.current;
    let hlsInstance: Hls | null = null;

    if (streamUrl.includes(".m3u8")) {
      if (video.canPlayType("application/vnd.apple.mpegurl")) {
        video.src = streamUrl;
      } else if (Hls.isSupported()) {
        hlsInstance = new Hls({ enableWorker: true });
        hlsInstance.loadSource(streamUrl);
        hlsInstance.attachMedia(video);
        hlsInstance.on(Hls.Events.ERROR, () => {
          setStreamError(true);
        });
      }
    } else {
      video.src = streamUrl;
    }

    return () => {
      if (hlsInstance) {
        hlsInstance.destroy();
      }
    };
  }, [isPlaying, streamUrl]);

  // Related movies from same VJ
  const relatedList = useMemo(() => {
    return catalog
      .filter((m) => m.vj === activeMovie.vj && m.id !== activeMovie.id)
      .slice(0, 8);
  }, [catalog, activeMovie]);

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
              35
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

      {/* 2. HERO BANNER / VIDEO PLAYER */}
      <div className="relative w-full aspect-[4/5] sm:aspect-[16/10] lg:aspect-[21/9] overflow-hidden bg-stone-950">
        {isPlaying ? (
          <div className="relative w-full h-full bg-black flex items-center justify-center">
            <video
              ref={videoRef}
              referrerPolicy="no-referrer"
              crossOrigin="anonymous"
              controls
              autoPlay
              playsInline
              onError={() => setStreamError(true)}
              className="w-full h-full object-contain"
            />
            <button
              type="button"
              onClick={() => setIsPlaying(false)}
              className="absolute top-4 right-4 z-30 px-3 py-1.5 rounded-full bg-black/80 hover:bg-black border border-white/20 text-white text-xs font-bold flex items-center gap-1.5 cursor-pointer shadow-lg backdrop-blur-md"
            >
              <X className="w-3.5 h-3.5" />
              <span>Close Player</span>
            </button>

            {/* Error Overlay */}
            {streamError && (
              <div className="absolute inset-0 bg-black/90 backdrop-blur-sm flex flex-col items-center justify-center p-6 text-center z-20">
                <AlertCircle className="w-12 h-12 text-[#E50914] mb-3" />
                <h3 className="text-lg font-bold text-white mb-1">Stream Error</h3>
                <p className="text-xs text-neutral-400 max-w-sm mb-4">
                  Video stream could not be loaded directly. Click below to retry.
                </p>
                <div className="flex gap-3">
                  <button
                    type="button"
                    onClick={() => {
                      setStreamError(false);
                      if (videoRef.current) {
                        videoRef.current.load();
                        videoRef.current.play().catch(() => {});
                      }
                    }}
                    className="px-4 py-2 rounded-full bg-[#00E676] text-black font-bold text-xs flex items-center gap-1.5 active:scale-95 transition-all"
                  >
                    <RefreshCw className="w-3.5 h-3.5" />
                    <span>Retry Stream</span>
                  </button>
                </div>
              </div>
            )}
          </div>
        ) : (
          <>
            {/* Backdrop Artwork */}
            <div className="absolute inset-0 bg-stone-950">
              <img
                src={activeMovie.backdropUrl || activeMovie.imageUrl}
                alt={activeMovie.title}
                onError={(e) => {
                  (e.target as HTMLImageElement).src =
                    "https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=1600&auto=format&fit=crop&q=80";
                }}
                className="w-full h-full object-cover object-top opacity-70 filter brightness-75 contrast-110 scale-105"
              />
              <div className="absolute inset-0 bg-gradient-to-t from-black via-black/40 to-black/60" />
            </div>

            {/* Ambient Scrims */}
            <div className="absolute top-0 left-0 right-0 h-28 bg-gradient-to-b from-black/80 to-transparent pointer-events-none" />
            <div className="absolute bottom-0 left-0 right-0 h-48 bg-gradient-to-t from-black via-black/85 to-transparent pointer-events-none" />

            {/* Floating Top Controls: Back Button & Rating Badge */}
            <div className="absolute top-4 left-4 right-4 z-20 flex items-center justify-between">
              <button
                type="button"
                onClick={onBack}
                className="w-10 h-10 rounded-full bg-black/60 backdrop-blur-md border border-white/10 flex items-center justify-center text-white hover:bg-black transition-colors cursor-pointer"
                aria-label="Back"
              >
                <ArrowLeft className="w-5 h-5 stroke-[2.2]" />
              </button>

              <div className="px-3 py-1.5 rounded-full bg-black/60 backdrop-blur-md border border-white/10 text-amber-400 text-xs font-black flex items-center gap-1 shadow-md">
                <span>★</span>
                <span>{activeMovie.rating}</span>
              </div>
            </div>

            {/* Center Big Play Button */}
            <div className="absolute inset-0 z-20 flex items-center justify-center">
              <button
                type="button"
                onClick={() => setIsPlaying(true)}
                className="w-16 h-16 rounded-full bg-[#00E676] hover:bg-[#00c853] text-black flex items-center justify-center shadow-[0_0_30px_rgba(0,230,118,0.6)] hover:scale-110 active:scale-95 transition-transform cursor-pointer"
                title="Play Movie"
              >
                <Play className="w-7 h-7 fill-black ml-1" />
              </button>
            </div>

            {/* Hero Bottom Info */}
            <div className="absolute bottom-3 left-4 right-4 z-20 space-y-2">
              <div className="text-xs font-medium text-neutral-400">
                {activeMovie.year} • {activeMovie.category}
              </div>

              <div className="flex items-center justify-between gap-3">
                {tmdbLogo ? (
                  <img
                    src={tmdbLogo}
                    alt={activeMovie.title}
                    className="h-8 sm:h-10 max-w-[240px] sm:max-w-[320px] object-contain object-left drop-shadow-xl"
                  />
                ) : (
                  <h1 className="text-xl sm:text-2xl lg:text-3xl font-black text-white font-sans leading-tight drop-shadow-md">
                    {activeMovie.title}
                  </h1>
                )}

                <VjBadge vjName={activeMovie.vj} size="md" />
              </div>

              {/* Tags */}
              <div className="flex items-center gap-2 pt-1 flex-wrap">
                <span className="px-3 py-1 rounded-full bg-[#1c1c1e] text-[11px] font-semibold text-neutral-300">
                  {activeMovie.duration}
                </span>
                <span className="px-3 py-1 rounded-full bg-[#1c1c1e] text-[11px] font-semibold text-neutral-300">
                  {activeMovie.category}
                </span>
                <span className="px-3 py-1 rounded-full bg-[#1c1c1e] text-[11px] font-semibold text-neutral-300">
                  HD 1080p
                </span>
                <span className="px-3 py-1 rounded-full bg-[#1c1c1e] text-[11px] font-semibold text-[#00E676]">
                  Luganda Dubbed
                </span>
              </div>
            </div>
          </>
        )}
      </div>

      {/* 3. ACTION BUTTONS ROW (Play, Bookmark, Download) */}
      <div className="px-4 pt-4 flex items-center gap-2.5">
        <button
          type="button"
          onClick={() => setIsPlaying(true)}
          className="flex-1 h-12 rounded-full bg-[#00E676] hover:bg-[#00c853] text-black font-extrabold text-sm flex items-center justify-center gap-2 shadow-lg shadow-[#00E676]/25 active:scale-[0.98] cursor-pointer"
        >
          <Play className="w-4 h-4 fill-black" />
          <span>{isPlaying ? "NOW PLAYING" : "PLAY MOVIE"}</span>
        </button>

        <button
          type="button"
          onClick={toggleFavorite}
          className={`w-12 h-12 rounded-2xl flex items-center justify-center border transition-all cursor-pointer ${
            isBookmarked
              ? "bg-[#00E676] border-[#00E676] text-black"
              : "bg-white/[0.06] border-white/10 text-white hover:bg-white/[0.12] backdrop-blur-md"
          }`}
          title="Bookmark"
        >
          <Bookmark className={`w-5 h-5 ${isBookmarked ? "fill-black" : ""}`} />
        </button>

        <button
          type="button"
          onClick={() => {
            setIsDownloaded(true);
            window.open?.(streamUrl, "_blank");
          }}
          className={`w-12 h-12 rounded-2xl flex items-center justify-center border transition-all cursor-pointer ${
            isDownloaded
              ? "bg-sky-500 border-sky-500 text-white"
              : "bg-white/[0.06] border-white/10 text-white hover:bg-white/[0.12] backdrop-blur-md"
          }`}
          title="Download MP4"
        >
          <Download className="w-5 h-5" />
        </button>
      </div>

      {/* 4. SYNOPSIS SECTION */}
      <div className="px-4 mt-7">
        <h3 className="text-base font-extrabold text-white tracking-tight mb-3">Synopsis</h3>

        <div className="rounded-2xl bg-[#141416] border border-white/5 p-4 shadow-md">
          <p className={`text-xs text-neutral-300 leading-relaxed font-normal ${isReadMore ? "" : "line-clamp-3"}`}>
            {activeMovie.overview}
          </p>

          <button
            type="button"
            onClick={() => setIsReadMore(!isReadMore)}
            className="mt-3 px-3 py-1.5 rounded-full bg-[#222226] hover:bg-[#2c2c32] text-xs font-semibold text-white flex items-center gap-1.5 transition-colors cursor-pointer"
          >
            <span>{isReadMore ? "Show less" : "Read more"}</span>
            <ChevronDown className={`w-3.5 h-3.5 transition-transform ${isReadMore ? "rotate-180" : ""}`} />
          </button>
        </div>
      </div>

      {/* 5. MOVIE CAST SECTION (TMDB Actor Portraits) */}
      {castList.length > 0 && (
        <div className="px-4 mt-7">
          <h3 className="text-base font-extrabold text-white tracking-tight mb-3">Cast</h3>
          <div className="flex gap-4 overflow-x-auto no-scrollbar pb-2 pt-1">
            {castList.slice(0, 15).map((actor) => (
              <div key={actor.id} className="flex flex-col items-center text-center w-16 shrink-0">
                <div className="w-14 h-14 rounded-full overflow-hidden border border-white/10 bg-neutral-900 shadow-md mb-1.5">
                  {actor.profileUrl ? (
                    <img
                      src={actor.profileUrl}
                      alt={actor.name}
                      className="w-full h-full object-cover"
                      onError={(e) => {
                        (e.target as HTMLImageElement).style.display = "none";
                      }}
                    />
                  ) : (
                    <div className="w-full h-full flex items-center justify-center text-neutral-500 text-xs">
                      {actor.name.charAt(0)}
                    </div>
                  )}
                </div>
                <span className="text-[11px] font-bold text-white line-clamp-1 leading-tight">{actor.name}</span>
                <span className="text-[9px] text-neutral-400 line-clamp-1 leading-tight mt-0.5">{actor.character}</span>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* 6. MORE FROM THIS VJ */}
      <div className="px-4 mt-7">
        <h3 className="text-base font-extrabold text-white tracking-tight mb-3">
          More from {activeMovie.vj}
        </h3>

        <div className="flex gap-3 overflow-x-auto no-scrollbar pb-1">
          {relatedList.map((movie) => (
            <div
              key={movie.id}
              onClick={() => {
                setIsPlaying(false);
                onSelectMovie?.(movie.id, movie.isTv, movie.title, movie);
              }}
              className="w-[124px] sm:w-[138px] shrink-0 cursor-pointer group active:scale-95 transition-transform"
            >
              <div className="relative aspect-[2/3] rounded-2xl overflow-hidden bg-neutral-900 border border-white/10 group-hover:border-white/30 transition-all p-2 flex flex-col justify-between shadow-md">
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
                <div className="absolute inset-0 bg-gradient-to-t from-black via-black/30 to-transparent pointer-events-none" />

                <div className="relative z-10 flex justify-end">
                  <VjBadge vjName={movie.vj} size="sm" />
                </div>
                <div className="relative z-10 text-left pt-6">
                  <div className="text-xs font-black text-white leading-tight drop-shadow-md line-clamp-2">
                    {movie.title}
                  </div>
                </div>
              </div>

              <div className="mt-1.5 space-y-0.5">
                <div className="flex items-center gap-1 text-[11px] text-neutral-400 font-medium">
                  <span className="text-amber-400 font-bold">★ {movie.rating}</span>
                  <span>•</span>
                  <span>{movie.year}</span>
                </div>
              </div>
            </div>
          ))}
        </div>
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
          <UserIcon className="w-5 h-5 text-neutral-500" />
          <span className="text-[10px] font-medium text-neutral-500">Profile</span>
        </button>
      </nav>
    </div>
  );
};
