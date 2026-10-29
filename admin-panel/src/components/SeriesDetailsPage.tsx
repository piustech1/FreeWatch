import React, { useState, useMemo, useRef, useEffect } from "react";
import {
  Search as SearchIcon,
  Bell,
  ArrowLeft,
  Play,
  SkipForward,
  Bookmark,
  Download,
  ChevronDown,
  Home,
  Heart,
  User as UserIcon,
  X,
  Headphones,
  RefreshCw,
  AlertCircle
} from "lucide-react";
import Hls from "hls.js";
import { FreeWatchLogo } from "./HomePage";
import { useLiveCatalog, CatalogMovie } from "../data/liveCatalog";
import { AvatarGraphic } from "./AvatarGraphic";
import { UserProfileData } from "./EditProfileModal";

interface SeriesDetailsPageProps {
  onBack: () => void;
  onNavigateTab: (tab: "home" | "search" | "favorites" | "downloads" | "profile") => void;
  onLogout?: () => void;
  seriesTitle?: string;
  movie?: CatalogMovie;
  userProfile?: UserProfileData;
  onSelectMovie?: (movieId: string, isSeries?: boolean, title?: string, movie?: CatalogMovie) => void;
  onNavigateToNotifications?: () => void;
}

export const SeriesDetailsPage: React.FC<SeriesDetailsPageProps> = ({
  onBack,
  onNavigateTab,
  onLogout,
  seriesTitle = "Wednesday Season 2",
  movie: incomingMovie,
  userProfile,
  onSelectMovie,
  onNavigateToNotifications,
}) => {
  const [activeEpisodeIndex, setActiveEpisodeIndex] = useState<number>(0);
  const [isPlaying, setIsPlaying] = useState<boolean>(false);
  const [isBookmarked, setIsBookmarked] = useState<boolean>(false);
  const [isDownloaded, setIsDownloaded] = useState<boolean>(false);
  const [isReadMore, setIsReadMore] = useState<boolean>(false);
  const [streamError, setStreamError] = useState<boolean>(false);

  const videoRef = useRef<HTMLVideoElement>(null);
  const { seriesMovies, catalog } = useLiveCatalog();

  // Resolve active series object
  const activeSeries: CatalogMovie = useMemo(() => {
    if (incomingMovie) return incomingMovie;
    const found = seriesMovies.find(
      (m) =>
        m.title.toLowerCase().trim() === seriesTitle.toLowerCase().trim() ||
        m.id === seriesTitle
    );
    if (found) return found;
    return (
      seriesMovies[0] || {
        id: "default-series",
        title: seriesTitle,
        vj: "VJ Ashim",
        category: "Series",
        genres: ["Series", "Drama", "Crime"],
        imageUrl: "https://apposters.b-cdn.net/laba/yo/naki/gNxs2151.jpg",
        backdropUrl: "https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=1600&auto=format&fit=crop&q=80",
        rating: "9.3",
        year: "2025",
        duration: "50m",
        isTv: true,
        overview: `Intense plot twists and tactical power struggles unfold in this acclaimed series, spiced up with exclusive Luganda voice-over translation.`,
        streamUrl: "https://munotech3.b-cdn.net/gugwa/gugwa42/07.Mirzapur.SN2.VJ.Ashim.1080.mp4",
        episodes: [
          { num: 1, title: "Episode 1", duration: "50m", streamUrl: "https://munotech3.b-cdn.net/gugwa/gugwa42/01.Mirzapur.SN1.VJ.Ashim.1080.mp4" },
          { num: 2, title: "Episode 2", duration: "48m", streamUrl: "https://munotech3.b-cdn.net/gugwa/gugwa42/02.Mirzapur.SN2.VJ.Ashim.1080.mp4" },
          { num: 3, title: "Episode 3", duration: "52m", streamUrl: "https://munotech3.b-cdn.net/gugwa/gugwa42/03.Mirzapur.SN2.VJ.Ashim.1080.mp4" },
          { num: 4, title: "Episode 4", duration: "55m", streamUrl: "https://munotech3.b-cdn.net/gugwa/gugwa42/04.Mirzapur.SN2.VJ.Ashim.1080.mp4" },
        ],
      }
    );
  }, [incomingMovie, seriesTitle, seriesMovies]);

  const episodes = useMemo(() => {
    if (activeSeries.episodes && activeSeries.episodes.length > 0) {
      return activeSeries.episodes;
    }
    const defaultUrl = activeSeries.streamUrl || "https://munotech3.b-cdn.net/gugwa/gugwa42/07.Mirzapur.SN2.VJ.Ashim.1080.mp4";
    return [
      { num: 1, title: `${activeSeries.title} Episode 01`, duration: "50m", streamUrl: defaultUrl },
      { num: 2, title: `${activeSeries.title} Episode 02`, duration: "48m", streamUrl: defaultUrl },
      { num: 3, title: `${activeSeries.title} Episode 03`, duration: "52m", streamUrl: defaultUrl },
      { num: 4, title: `${activeSeries.title} Episode 04`, duration: "54m", streamUrl: defaultUrl },
    ];
  }, [activeSeries]);

  const currentEpisode = episodes[activeEpisodeIndex] || episodes[0];
  const streamUrl = currentEpisode?.streamUrl || activeSeries.streamUrl;

  // Sync bookmarks from localStorage
  useEffect(() => {
    try {
      const saved = localStorage.getItem("freewatch_favorites");
      if (saved) {
        const list: CatalogMovie[] = JSON.parse(saved);
        if (list.some((m) => m.id === activeSeries.id)) {
          setIsBookmarked(true);
        }
      }
    } catch {}
  }, [activeSeries.id]);

  const toggleFavorite = () => {
    const nextState = !isBookmarked;
    setIsBookmarked(nextState);
    try {
      const saved = localStorage.getItem("freewatch_favorites");
      let list: CatalogMovie[] = saved ? JSON.parse(saved) : [];
      if (nextState) {
        if (!list.some((m) => m.id === activeSeries.id)) {
          list.push(activeSeries);
        }
      } else {
        list = list.filter((m) => m.id !== activeSeries.id);
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

  const handleNextEpisode = () => {
    const nextIdx = (activeEpisodeIndex + 1) % episodes.length;
    setActiveEpisodeIndex(nextIdx);
    setIsPlaying(true);
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
      <div className="relative w-full aspect-[4/5] sm:aspect-[16/10] lg:aspect-[21/9] overflow-hidden bg-zinc-950">
        {isPlaying ? (
          <div className="relative w-full h-full bg-black flex items-center justify-center">
            <video
              ref={videoRef}
              key={streamUrl}
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
                  Episode stream could not be loaded directly. Click below to retry.
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
                src={activeSeries.backdropUrl || activeSeries.imageUrl}
                alt={activeSeries.title}
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
                <span>{activeSeries.rating}</span>
              </div>
            </div>

            {/* Center Big Play Button */}
            <div className="absolute inset-0 z-20 flex items-center justify-center">
              <button
                type="button"
                onClick={() => setIsPlaying(true)}
                className="w-16 h-16 rounded-full bg-[#00E676] hover:bg-[#00c853] text-black flex items-center justify-center shadow-[0_0_30px_rgba(0,230,118,0.6)] hover:scale-110 active:scale-95 transition-transform cursor-pointer"
                title="Play Series"
              >
                <Play className="w-7 h-7 fill-black ml-1" />
              </button>
            </div>

            {/* Hero Bottom Info */}
            <div className="absolute bottom-3 left-4 right-4 z-20 space-y-2">
              <div className="text-xs font-medium text-neutral-400">
                {activeSeries.year} • {episodes.length} Episodes
              </div>

              <div className="flex items-center justify-between gap-3">
                <h1 className="text-xl sm:text-2xl lg:text-3xl font-black text-white font-sans leading-tight drop-shadow-md">
                  {activeSeries.title}
                </h1>

                <div className="flex items-center gap-1.5 px-3 py-1.5 rounded-full bg-[#4c1d95] text-white text-[11px] font-bold shrink-0 shadow-md">
                  <Headphones className="w-3.5 h-3.5 text-[#00E676]" />
                  <span>{activeSeries.vj}</span>
                </div>
              </div>

              {/* Tags */}
              <div className="flex items-center gap-2 pt-1 flex-wrap">
                <span className="px-3 py-1 rounded-full bg-[#1c1c1e] text-[11px] font-semibold text-neutral-300">
                  {episodes.length} Episodes
                </span>
                <span className="px-3 py-1 rounded-full bg-[#1c1c1e] text-[11px] font-semibold text-neutral-300">
                  HD 1080p
                </span>
                <span className="px-3 py-1 rounded-full bg-[#1c1c1e] text-[11px] font-semibold text-[#00E676]">
                  Luganda Dubbed Series
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
          <span>{isPlaying ? `PLAYING ${currentEpisode?.title || "EPISODE"}` : "START WATCHING"}</span>
        </button>

        <button
          type="button"
          onClick={toggleFavorite}
          className={`w-12 h-12 rounded-2xl flex items-center justify-center border transition-all cursor-pointer ${
            isBookmarked
              ? "bg-[#00E676] border-[#00E676] text-black"
              : "bg-[#1c1c1e] border-white/5 text-white hover:bg-[#28282b]"
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
              : "bg-[#1c1c1e] border-white/5 text-white hover:bg-[#28282b]"
          }`}
          title="Download Episode"
        >
          <Download className="w-5 h-5" />
        </button>
      </div>

      {/* 4. EPISODES LIST ROW */}
      <div className="px-4 mt-6">
        <div className="flex items-center justify-between mb-3">
          <h2 className="text-base font-extrabold text-white tracking-wider uppercase">
            EPISODES ({episodes.length})
          </h2>

          <button
            type="button"
            onClick={handleNextEpisode}
            className="px-3.5 py-1.5 rounded-full bg-[#00E676] text-black font-extrabold text-xs flex items-center gap-1.5 shadow-md shadow-[#00E676]/20 cursor-pointer active:scale-95 transition-all"
          >
            <SkipForward className="w-3 h-3 fill-black" />
            <span>Next Episode</span>
          </button>
        </div>

        {/* Episode Cards Horizontal Slider (Matching Android App ListView.separated) */}
        <div className="flex gap-3.5 overflow-x-auto no-scrollbar pb-3 pt-1">
          {episodes.map((ep, idx) => {
            const isSelected = activeEpisodeIndex === idx;
            return (
              <div
                key={ep.num}
                onClick={() => {
                  setActiveEpisodeIndex(idx);
                  setIsPlaying(true);
                }}
                className="w-[185px] sm:w-[210px] shrink-0 cursor-pointer group active:scale-[0.98] transition-transform select-none"
              >
                <div
                  className={`relative aspect-video rounded-2xl overflow-hidden bg-neutral-900 border transition-all flex items-center justify-center shadow-md ${
                    isSelected
                      ? "border-[#00E676] ring-2 ring-[#00E676]/40 scale-[1.02]"
                      : "border-white/10 group-hover:border-white/20"
                  }`}
                >
                  {(activeSeries.backdropUrl || activeSeries.imageUrl) && (
                    <img
                      src={activeSeries.backdropUrl || activeSeries.imageUrl}
                      alt=""
                      className="absolute inset-0 w-full h-full object-cover filter brightness-70 group-hover:scale-105 transition-transform duration-300"
                    />
                  )}
                  <div className="absolute inset-0 bg-gradient-to-t from-black via-black/30 to-transparent pointer-events-none" />

                  {/* Top Left: Episode Number Badge */}
                  <div className="absolute top-2 left-2 z-10">
                    <span className="px-2 py-0.5 rounded-full bg-black/75 backdrop-blur-md border border-white/10 text-[10px] font-black text-[#00E676]">
                      EP {ep.num}
                    </span>
                  </div>

                  {/* Top Right: Duration */}
                  <div className="absolute top-2 right-2 z-10">
                    <span className="px-1.5 py-0.5 rounded bg-black/60 text-[9px] font-bold text-neutral-300">
                      {ep.duration || "45m"}
                    </span>
                  </div>

                  {/* Center Play Indicator */}
                  <div className="relative z-10">
                    <div
                      className={`w-10 h-10 rounded-full flex items-center justify-center shadow-lg transition-transform ${
                        isSelected
                          ? "bg-[#00E676] text-black scale-110 shadow-[#00E676]/30"
                          : "bg-white/25 backdrop-blur-md border border-white/40 text-white group-hover:scale-110"
                      }`}
                    >
                      <Play
                        className={`w-4 h-4 ml-0.5 ${
                          isSelected ? "fill-black text-black" : "fill-white text-white"
                        }`}
                      />
                    </div>
                  </div>
                </div>

                <div className="mt-2 px-0.5">
                  <h4 className="text-xs font-bold text-white leading-tight truncate">
                    {ep.title}
                  </h4>
                  <div className="text-[11px] text-neutral-400 mt-0.5 flex items-center gap-1.5">
                    <span className="text-[#00E676] font-semibold">{isSelected ? "Now Playing" : "Episode " + ep.num}</span>
                    <span>•</span>
                    <span>{ep.duration || "45m"}</span>
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      </div>

      {/* 5. SYNOPSIS SECTION */}
      <div className="px-4 mt-7">
        <h3 className="text-base font-extrabold text-white tracking-tight mb-3">Synopsis</h3>

        <div className="rounded-2xl bg-[#141416] border border-white/5 p-4 shadow-md">
          <p className={`text-xs text-neutral-300 leading-relaxed font-normal ${isReadMore ? "" : "line-clamp-3"}`}>
            {activeSeries.overview}
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

      {/* 6. MORE LIKE THIS SECTION */}
      <div className="px-4 mt-7">
        <h3 className="text-base font-extrabold text-white tracking-tight mb-3">More Like This</h3>

        <div className="flex gap-3 overflow-x-auto no-scrollbar pb-1">
          {seriesMovies
            .filter((m) => m.id !== activeSeries.id)
            .slice(0, 10)
            .map((movie) => (
              <div
                key={movie.id}
                onClick={() => {
                  setIsPlaying(false);
                  onSelectMovie?.(movie.id, movie.isTv, movie.title, movie);
                }}
                className="w-[120px] sm:w-[136px] shrink-0 cursor-pointer group active:scale-95 transition-transform"
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
                  <div className="absolute inset-0 bg-gradient-to-t from-black via-black/30 to-transparent pointer-events-none" />

                  <div className="relative z-10 flex justify-end">
                    <span className="px-1.5 py-0.5 rounded bg-black/60 backdrop-blur-md text-amber-400 text-[10px] font-bold flex items-center gap-0.5">
                      ★ {movie.rating}
                    </span>
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
                    <span className="text-[#00E676]">Series</span>
                  </div>
                </div>
              </div>
            ))}
        </div>
      </div>

      {/* 7. FIXED BOTTOM NAVIGATION BAR (Hidden on desktop) */}
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
