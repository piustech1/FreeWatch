import React, { useState, useMemo, useRef, useEffect } from "react";
import {
  Search as SearchIcon,
  Bell,
  ArrowLeft,
  Play,
  Pause,
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
  sanitizeStreamUrl,
  TmdbCastMember
} from "../services/tmdb";
import { VjBadge } from "./VjBadge";
import { FloatingBottomNav } from "./FloatingBottomNav";

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
  const [tmdbBackdrop, setTmdbBackdrop] = useState<string | null>(null);
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

  const [healedDetails, setHealedDetails] = useState<{
    title?: string;
    vj?: string;
    streamUrl?: string;
    imageUrl?: string;
    overview?: string;
  } | null>(null);

  // Auto-heal placeholder movie titles or missing streams on mount
  useEffect(() => {
    const isGenericTitle = !activeMovie.title || /^(?:Movie|Series|Luganda Release|Untitled)\s*#?\d*/i.test(activeMovie.title);
    const isFallbackStream = !activeMovie.streamUrl || activeMovie.streamUrl.includes("sample") || activeMovie.streamUrl.includes("07.Mirzapur");

    if ((isGenericTitle || isFallbackStream) && activeMovie.id && /^\d+$/.test(activeMovie.id)) {
      fetch(`https://mumowatch.ai.studio/movie/${activeMovie.id}`)
        .then((r) => (r.ok ? r.json() : null))
        .then((d) => {
          if (d && d.title && !/^(?:Movie|Series)\s*#/i.test(d.title)) {
            const rawVj = (d.vj || "").trim();
            const vjClean = rawVj
              ? rawVj.toUpperCase().startsWith("VJ")
                ? rawVj
                : `VJ ${rawVj}`
              : "VJ Junior";
            setHealedDetails({
              title: d.title.trim(),
              vj: vjClean,
              streamUrl: d.playingurl || undefined,
              imageUrl: d.image || undefined,
              overview: d.description || undefined,
            });
          }
        })
        .catch(() => {});
    }
  }, [activeMovie.id, activeMovie.title, activeMovie.streamUrl]);

  const displayTitle = healedDetails?.title || activeMovie.title;
  const displayVj = healedDetails?.vj || activeMovie.vj;
  const displayOverview = healedDetails?.overview || activeMovie.overview;
  const displayPoster = healedDetails?.imageUrl || activeMovie.imageUrl;

  // Load TMDB Logo, Backdrop & Cast
  useEffect(() => {
    let cancelled = false;
    async function loadTmdbData() {
      try {
        const tmdb = await searchTmdb(displayTitle, activeMovie.isTv);
        if (!cancelled && tmdb && tmdb.id) {
          if (tmdb.backdropUrl) {
            setTmdbBackdrop(tmdb.backdropUrl);
          }
          getMovieLogo(tmdb.id, tmdb.isTv).then((l) => {
            if (!cancelled) setTmdbLogo(l);
          });
          getCredits(tmdb.id, tmdb.isTv).then((c) => {
            if (!cancelled) setCastList(c);
          });
        }
      } catch {}
    }
    loadTmdbData();
    return () => {
      cancelled = true;
    };
  }, [displayTitle, activeMovie.isTv]);

  const streamUrl = useMemo(
    () => sanitizeStreamUrl(healedDetails?.streamUrl || activeMovie.streamUrl),
    [healedDetails?.streamUrl, activeMovie.streamUrl]
  );

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

  // Video Streaming Setup with HLS, MP4 and CDN mirror recovery
  useEffect(() => {
    if (!isPlaying || !streamUrl || !videoRef.current) return;
    setStreamError(false);

    const video = videoRef.current;
    let hlsInstance: Hls | null = null;
    let mirrorTried = false;

    const handleStreamFailure = () => {
      if (!mirrorTried && streamUrl.includes("munotech")) {
        mirrorTried = true;
        const mirror = streamUrl.replace(/http:\/\/munotech\d*\.com/g, "https://munotech3.b-cdn.net");
        if (mirror !== streamUrl) {
          video.src = mirror;
          video.play().catch(() => setStreamError(true));
          return;
        }
      }
      setStreamError(true);
    };

    video.onerror = handleStreamFailure;

    if (streamUrl.includes(".m3u8")) {
      if (video.canPlayType("application/vnd.apple.mpegurl")) {
        video.src = streamUrl;
      } else if (Hls.isSupported()) {
        hlsInstance = new Hls({ enableWorker: true });
        hlsInstance.loadSource(streamUrl);
        hlsInstance.attachMedia(video);
        hlsInstance.on(Hls.Events.ERROR, handleStreamFailure);
      }
    } else {
      video.src = streamUrl;
      video.play().catch(() => {});
    }

    return () => {
      video.onerror = null;
      if (hlsInstance) {
        hlsInstance.destroy();
      }
    };
  }, [isPlaying, streamUrl]);

  // Recommendations: More Like This (category or genre matched)
  const moreLikeThisList = useMemo(() => {
    return catalog
      .filter(
        (m) =>
          m.id !== activeMovie.id &&
          (m.category === activeMovie.category ||
            m.genres.some((g) => activeMovie.genres.includes(g)))
      )
      .slice(0, 10);
  }, [catalog, activeMovie]);

  // Related movies from same VJ
  const relatedList = useMemo(() => {
    const v = displayVj.toLowerCase().replace("vj", "").trim();
    return catalog
      .filter((m) => m.id !== activeMovie.id && m.vj.toLowerCase().includes(v))
      .slice(0, 8);
  }, [catalog, activeMovie, displayVj]);

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

      {/* 2. HERO BANNER / VIDEO PLAYER (Tall 50vh when stopped, 16:9 snug aspect-video when playing) */}
      <div
        className={`relative w-full overflow-hidden bg-black transition-[height,aspect-ratio] duration-300 ${
          isPlaying ? "aspect-video" : "h-[50vh] min-h-[440px] sm:min-h-[480px]"
        }`}
      >
        {isPlaying ? (
          <div className="relative w-full h-full bg-black flex items-center justify-center">
            <video
              ref={videoRef}
              controls
              autoPlay
              playsInline
              onError={() => setStreamError(true)}
              className="w-full h-full object-contain"
            />

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
                    className="px-4 py-2 rounded-full bg-[#00E676] text-black font-bold text-xs flex items-center gap-1.5 active:scale-95 transition-all shadow-md"
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
            {/* Backdrop Artwork: Full 4K/HD sharpness, zero muddy dimming */}
            <div className="absolute inset-0 bg-stone-950">
              <img
                src={tmdbBackdrop || activeMovie.backdropUrl || activeMovie.imageUrl}
                alt={activeMovie.title}
                onError={(e) => {
                  (e.target as HTMLImageElement).src =
                    "https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=1600&auto=format&fit=crop&q=80";
                }}
                className="w-full h-full object-cover object-center filter brightness-95 transition-all duration-300"
              />
              <div className="absolute inset-0 bg-gradient-to-t from-black via-black/25 to-transparent pointer-events-none" />
            </div>

            {/* Ambient subtle fade into bottom controls */}
            <div className="absolute bottom-0 left-0 right-0 h-32 bg-gradient-to-t from-black via-black/80 to-transparent pointer-events-none" />

            {/* Floating Top Controls: Back Button & Rating Badge */}
            <div className="absolute top-4 left-4 right-4 z-20 flex items-center justify-between">
              <button
                type="button"
                onClick={onBack}
                className="w-10 h-10 rounded-full bg-black/60 backdrop-blur-md flex items-center justify-center text-white hover:bg-black transition-colors cursor-pointer shadow-md"
                aria-label="Back"
              >
                <ArrowLeft className="w-5 h-5 stroke-[2.2]" />
              </button>

              <div className="px-3 py-1.5 rounded-full bg-black/60 backdrop-blur-md text-amber-400 text-xs font-black flex items-center gap-1 shadow-md">
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
                    alt={displayTitle}
                    className="h-8 sm:h-10 max-w-[240px] sm:max-w-[320px] object-contain object-left drop-shadow-xl"
                  />
                ) : (
                  <h1 className="text-xl sm:text-2xl lg:text-3xl font-black text-white font-sans leading-tight drop-shadow-md">
                    {displayTitle}
                  </h1>
                )}

                <VjBadge vjName={displayVj} size="md" />
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

      {/* 3. ACTION BUTTONS ROW (Play/Pause, Bookmark, Download) */}
      <div className="px-4 pt-4 flex items-center gap-2.5">
        <button
          type="button"
          onClick={() => {
            if (isPlaying) {
              if (videoRef.current) {
                videoRef.current.pause();
              }
              setIsPlaying(false);
            } else {
              setIsPlaying(true);
            }
          }}
          className="flex-1 h-12 rounded-full bg-[#00E676] hover:bg-[#00c853] text-black font-extrabold text-sm flex items-center justify-center gap-2 shadow-lg shadow-[#00E676]/25 active:scale-[0.98] cursor-pointer"
        >
          {isPlaying ? (
            <>
              <Pause className="w-4 h-4 fill-black text-black" />
              <span>PAUSE</span>
            </>
          ) : (
            <>
              <Play className="w-4 h-4 fill-black" />
              <span>PLAY MOVIE</span>
            </>
          )}
        </button>

        <button
          type="button"
          onClick={toggleFavorite}
          className={`w-12 h-12 rounded-2xl flex items-center justify-center transition-all cursor-pointer shadow-md ${
            isBookmarked
              ? "bg-[#00E676] text-black"
              : "bg-white/[0.08] text-white hover:bg-white/[0.15] backdrop-blur-md"
          }`}
          title="Bookmark"
        >
          <Bookmark className={`w-5 h-5 ${isBookmarked ? "fill-black" : ""}`} />
        </button>

        <button
          type="button"
          onClick={() => {
            if (!streamUrl) return;
            setIsDownloaded(true);
            const safeName = `${displayTitle.replace(/[^a-zA-Z0-9_\-\s]/g, "").trim() || "Movie"}.mp4`;
            
            // 1. Direct browser download trigger
            const link = document.createElement("a");
            link.href = streamUrl;
            link.download = safeName;
            link.target = "_blank";
            link.rel = "noopener noreferrer";
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);

            // 2. Persist to freewatch_downloads for the Downloads page
            try {
              const saved = localStorage.getItem("freewatch_downloads");
              const list = saved ? JSON.parse(saved) : [];
              if (!list.some((item: any) => item.id === activeMovie.id)) {
                list.unshift({
                  id: activeMovie.id,
                  title: displayTitle,
                  posterUrl: displayPoster,
                  posterBg: "#18181b",
                  progress: 100,
                  isPaused: false,
                  fileSize: "720p HD",
                  speed: "Saved",
                  isSeries: activeMovie.isTv,
                });
                localStorage.setItem("freewatch_downloads", JSON.stringify(list));
              }
            } catch {}
          }}
          className={`w-12 h-12 rounded-2xl flex items-center justify-center transition-all cursor-pointer shadow-md ${
            isDownloaded
              ? "bg-[#00E676] text-black shadow-[#00E676]/30"
              : "bg-white/[0.08] text-white hover:bg-white/[0.15] backdrop-blur-md"
          }`}
          title="Download MP4 to Device"
        >
          <Download className="w-5 h-5" />
        </button>
      </div>

      {/* 4. SYNOPSIS SECTION */}
      <div className="px-4 mt-7">
        <h3 className="text-base font-extrabold text-white tracking-tight mb-3">Synopsis</h3>

        <div className="rounded-2xl bg-[#141416] p-4 shadow-md">
          <p className={`text-xs text-neutral-300 leading-relaxed font-normal ${isReadMore ? "" : "line-clamp-3"}`}>
            {displayOverview}
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

      {/* 6. MORE LIKE THIS RECOMMENDATIONS */}
      {moreLikeThisList.length > 0 && (
        <div className="px-4 mt-7">
          <h3 className="text-base font-extrabold text-white tracking-tight mb-3">
            More Like This
          </h3>

          <div className="flex gap-3 overflow-x-auto no-scrollbar pb-1">
            {moreLikeThisList.map((movie) => (
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
                    <span>{movie.category}</span>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* 7. MORE FROM THIS VJ */}
      {relatedList.length > 0 && (
        <div className="px-4 mt-7">
          <h3 className="text-base font-extrabold text-white tracking-tight mb-3">
            More from {displayVj}
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
      )}

      {/* 6. FLOATING CURVED GLASS BOTTOM NAVIGATION BAR (Hidden on desktop) */}
      <FloatingBottomNav activeTab="home" onNavigateTab={onNavigateTab} />
    </div>
  );
};
