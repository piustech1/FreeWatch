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
  RefreshCw,
  AlertCircle,
  Loader2
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
  getSeasonEpisodes,
  cleanTitleForTmdb,
  sanitizeStreamUrl,
  TmdbCastMember
} from "../services/tmdb";
import { VjBadge } from "./VjBadge";
import { FloatingBottomNav } from "./FloatingBottomNav";

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
  const [tmdbLogo, setTmdbLogo] = useState<string | null>(null);
  const [tmdbBackdrop, setTmdbBackdrop] = useState<string | null>(null);
  const [isLoadingEpisodes, setIsLoadingEpisodes] = useState<boolean>(true);
  const [castList, setCastList] = useState<TmdbCastMember[]>([]);
  const [resolvedEpisodes, setResolvedEpisodes] = useState<CatalogMovie["episodes"]>([]);
  const [healedDetails, setHealedDetails] = useState<{ title?: string; vj?: string; streamUrl?: string; imageUrl?: string } | null>(null);

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
        streamUrl: "",
        episodes: [],
      }
    );
  }, [incomingMovie, seriesTitle, seriesMovies]);

  // Reset state when switching to another series
  useEffect(() => {
    setActiveEpisodeIndex(0);
    setIsPlaying(false);
    setStreamError(false);
    setResolvedEpisodes([]);
    setHealedDetails(null);
    setTmdbBackdrop(null);
    setTmdbLogo(null);
    if (typeof window !== "undefined") {
      window.scrollTo({ top: 0, behavior: "smooth" });
    }
  }, [activeSeries.id]);

  // Auto-heal placeholder series titles on mount
  useEffect(() => {
    if (/^(?:Movie|Series|Luganda Release)\s*#\d+/i.test(activeSeries.title) && activeSeries.id) {
      fetch(`https://mumowatch.ai.studio/movie/${activeSeries.id}`)
        .then((r) => (r.ok ? r.json() : null))
        .then((d) => {
          if (d && d.title && !/^(?:Movie|Series)\s*#/i.test(d.title)) {
            const rawVj = (d.vj || "").trim();
            const vjClean = rawVj ? (rawVj.toUpperCase().startsWith("VJ") ? rawVj : `VJ ${rawVj}`) : "VJ Junior";
            setHealedDetails({
              title: d.title.trim(),
              vj: vjClean,
              streamUrl: d.playingurl || undefined,
              imageUrl: d.image || undefined,
            });
          }
        })
        .catch(() => {});
    }
  }, [activeSeries.id, activeSeries.title]);

  const displayTitle = healedDetails?.title || activeSeries.title;
  const displayVj = healedDetails?.vj || activeSeries.vj;

  // Deep episode resolution from MunoWatch /series/:code & search + TMDB Season Stills
  useEffect(() => {
    let cancelled = false;

    async function loadMetadataAndEpisodes() {
      setIsLoadingEpisodes(true);
      try {
        const tmdb = await searchTmdb(displayTitle, true);
        let tmdbEps: any[] = [];
        if (tmdb && tmdb.id) {
          if (tmdb.backdropUrl) {
            setTmdbBackdrop(tmdb.backdropUrl);
          }
          getMovieLogo(tmdb.id, tmdb.isTv).then((l) => {
            if (!cancelled) setTmdbLogo(l);
          });
          getCredits(tmdb.id, tmdb.isTv).then((c) => {
            if (!cancelled) setCastList(c);
          });
          if (tmdb.isTv) {
            tmdbEps = await getSeasonEpisodes(tmdb.id, 1);
          }
        }

        const cleanTitle = cleanTitleForTmdb(activeSeries.title);
        const lowerTitle = cleanTitle.toLowerCase();
        let munoEpisodes: any[] = [];

        // Dedicated resolution for Kari / Karikaada
        if (lowerTitle.includes("kari")) {
          munoEpisodes = [
            {
              id: 65212,
              title: "Karikaada Part 1",
              playingurl: "http://munotech.b-cdn.net/devine/devine42/Karikaada Part 1.mp4",
              image: activeSeries.backdropUrl || activeSeries.imageUrl,
            },
            {
              id: 65213,
              title: "Karikaada Part 2",
              playingurl: "http://munotech.b-cdn.net/devine/devine42/Karikaada Part 2.mp4",
              image: activeSeries.backdropUrl || activeSeries.imageUrl,
            },
          ];
        } else if (lowerTitle.includes("hobbit")) {
          // Dedicated franchise resolution for The Hobbit
          try {
            const hobbitQueries = ["Hobbit", "Hobbit 2", "Hobbit 3"];
            for (const hq of hobbitQueries) {
              const res = await fetch(`https://mumowatch.ai.studio/search?q=${encodeURIComponent(hq)}`);
              if (res.ok) {
                const data = await res.json();
                if (Array.isArray(data.series)) {
                  data.series.forEach((s: any) => {
                    if (Array.isArray(s.episodes)) {
                      munoEpisodes.push(...s.episodes);
                    }
                  });
                }
              }
            }
          } catch {}
        } else {
          // General resolution from /series/:code & search
          const codesToTry = [
            activeSeries.seriesCode,
            activeSeries.id,
          ].filter(Boolean);

          for (const code of codesToTry) {
            try {
              const controller = new AbortController();
              const timeoutId = setTimeout(() => controller.abort(), 3500);
              const res = await fetch(`https://mumowatch.ai.studio/series/${code}`, { signal: controller.signal });
              clearTimeout(timeoutId);
              if (res.ok) {
                const data = await res.json();
                if (data && Array.isArray(data.episodes) && data.episodes.length > 0) {
                  munoEpisodes = data.episodes;
                  break;
                }
              }
            } catch {}
          }

          if (munoEpisodes.length === 0 && cleanTitle.length > 0) {
            try {
              const sRes = await fetch(`https://mumowatch.ai.studio/search?q=${encodeURIComponent(cleanTitle)}`);
              if (sRes.ok) {
                const sData = await sRes.json();
                if (Array.isArray(sData.series) && sData.series.length > 0) {
                  // Inspect all discovered series codes to fetch true full episode seasons
                  for (const ser of sData.series) {
                    if (ser.series_code && String(ser.series_code) !== "0") {
                      try {
                        const epRes = await fetch(`https://mumowatch.ai.studio/series/${ser.series_code}`);
                        if (epRes.ok) {
                          const epData = await epRes.json();
                          if (epData && Array.isArray(epData.episodes) && epData.episodes.length > 0) {
                            munoEpisodes.push(...epData.episodes);
                          }
                        }
                      } catch {}
                    }
                    if (Array.isArray(ser.episodes) && ser.episodes.length > 0) {
                      munoEpisodes.push(...ser.episodes);
                    }
                  }
                }
              }
            } catch {}
          }
        }

        // Deduplicate munoEpisodes by id, title, or stream URL
        if (munoEpisodes.length > 0) {
          const seen = new Set();
          munoEpisodes = munoEpisodes.filter((ep: any) => {
            const key = ep.id || ep.title || ep.playingurl;
            if (seen.has(key)) return false;
            seen.add(key);
            return true;
          });
        }

        if (!cancelled && munoEpisodes.length > 0) {
          const mapped = munoEpisodes.map((ep: any, idx: number) => {
            const epNum = idx + 1;
            const tmdbEp = tmdbEps.find((t) => t.episodeNumber === epNum);
            return {
              num: epNum,
              title: ep.title || tmdbEp?.name || `${activeSeries.title} Episode ${epNum}`,
              duration: tmdbEp?.runtime ? `${tmdbEp.runtime}m` : "45m",
              streamUrl: ep.playingurl || ep.playingUrl || activeSeries.streamUrl,
              stillUrl:
                tmdbEp?.stillUrl ||
                ep.image ||
                ep.thumbnail ||
                activeSeries.backdropUrl ||
                activeSeries.imageUrl,
            };
          });

          // If MunoWatch search returned fewer episodes than TMDB has for the full season:
          if (tmdbEps.length > mapped.length) {
            for (let i = mapped.length; i < tmdbEps.length; i++) {
              const te = tmdbEps[i];
              mapped.push({
                num: te.episodeNumber || (i + 1),
                title: te.name || `${activeSeries.title} Episode ${i + 1}`,
                duration: te.runtime ? `${te.runtime}m` : "48m",
                streamUrl: activeSeries.streamUrl || mapped[0]?.streamUrl,
                stillUrl: te.stillUrl || activeSeries.backdropUrl || activeSeries.imageUrl,
              });
            }
          }

          setResolvedEpisodes(mapped);
          return;
        }

        if (!cancelled && tmdbEps.length > 0) {
          const mapped = tmdbEps.map((te) => ({
            num: te.episodeNumber,
            title: te.name,
            duration: te.runtime ? `${te.runtime}m` : "45m",
            streamUrl: activeSeries.streamUrl,
            stillUrl: te.stillUrl || activeSeries.backdropUrl,
          }));
          setResolvedEpisodes(mapped);
          return;
        }

        // If series already had genuine episodes passed in, use them directly without mockups
        if (!cancelled && activeSeries.episodes && activeSeries.episodes.length > 0) {
          setResolvedEpisodes(activeSeries.episodes.map(ep => ({
            num: ep.num,
            title: ep.title,
            duration: ep.duration,
            streamUrl: ep.streamUrl,
            stillUrl: activeSeries.backdropUrl || activeSeries.imageUrl,
          })));
        }
      } catch (err) {
        console.warn("Failed to load series metadata:", err);
      } finally {
        if (!cancelled) {
          setIsLoadingEpisodes(false);
        }
      }
    }

    loadMetadataAndEpisodes();
    return () => {
      cancelled = true;
    };
  }, [activeSeries.id, activeSeries.title]);

  const episodes = useMemo(() => {
    if (resolvedEpisodes && resolvedEpisodes.length > 0) {
      return resolvedEpisodes.map((ep) => ({
        ...ep,
        streamUrl: sanitizeStreamUrl(ep.streamUrl),
      }));
    }
    if (activeSeries.episodes && activeSeries.episodes.length > 0) {
      return activeSeries.episodes.map((ep) => ({
        ...ep,
        streamUrl: sanitizeStreamUrl(ep.streamUrl),
      }));
    }
    if (isLoadingEpisodes) {
      return [];
    }
    const defaultUrl = sanitizeStreamUrl(activeSeries.streamUrl || "https://munotech3.b-cdn.net/gugwa/gugwa42/07.Mirzapur.SN2.VJ.Ashim.1080.mp4");
    return [
      { num: 1, title: `${activeSeries.title} Episode 01`, duration: "50m", streamUrl: defaultUrl, stillUrl: activeSeries.backdropUrl },
      { num: 2, title: `${activeSeries.title} Episode 02`, duration: "48m", streamUrl: defaultUrl, stillUrl: activeSeries.backdropUrl },
      { num: 3, title: `${activeSeries.title} Episode 03`, duration: "52m", streamUrl: defaultUrl, stillUrl: activeSeries.backdropUrl },
      { num: 4, title: `${activeSeries.title} Episode 04`, duration: "54m", streamUrl: defaultUrl, stillUrl: activeSeries.backdropUrl },
    ];
  }, [resolvedEpisodes, activeSeries, isLoadingEpisodes]);

  const currentEpisode = episodes[activeEpisodeIndex] || episodes[0];
  const streamUrl = useMemo(
    () => sanitizeStreamUrl(currentEpisode?.streamUrl || activeSeries.streamUrl),
    [currentEpisode, activeSeries.streamUrl]
  );

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

  // Record series to watch history in localStorage
  useEffect(() => {
    try {
      const saved = localStorage.getItem("freewatch_watch_history");
      const list: CatalogMovie[] = saved ? JSON.parse(saved) : [];
      const filtered = list.filter((m) => m.id !== activeSeries.id);
      const updated = [activeSeries, ...filtered].slice(0, 50);
      localStorage.setItem("freewatch_watch_history", JSON.stringify(updated));
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
    let mirrorIndex = 0;
    const cleanUrl = streamUrl.endsWith(".mp4") ? streamUrl : `${streamUrl}.mp4`;
    const MIRRORS = [
      cleanUrl,
      cleanUrl.replace(/https?:\/\/[^/]+/i, "https://munotech3.b-cdn.net"),
      cleanUrl.replace(/https?:\/\/[^/]+/i, "https://munotek-vault.b-cdn.net"),
      cleanUrl.replace(/https?:\/\/[^/]+/i, "https://munotech2.b-cdn.net"),
    ];

    const handleStreamFailure = () => {
      mirrorIndex++;
      if (mirrorIndex < MIRRORS.length) {
        const nextMirror = MIRRORS[mirrorIndex];
        if (nextMirror && nextMirror !== video.src) {
          video.src = nextMirror;
          video.load();
          video.play().catch(() => {});
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

  const handleNextEpisode = () => {
    if (episodes.length === 0) return;
    const nextIdx = (activeEpisodeIndex + 1) % episodes.length;
    if (videoRef.current) {
      videoRef.current.pause();
    }
    setActiveEpisodeIndex(nextIdx);
    setIsPlaying(true);
  };

  return (
    <div className="w-full min-h-screen bg-black text-white font-sans flex flex-col pb-24 select-none">
      {/* 1. TOP HEADER BAR */}
      <header className="sticky top-0 z-40 w-full bg-black/90 backdrop-blur-md px-4 py-3 flex items-center justify-between border-b border-white/5">
        <div className="flex items-center gap-3">
          <button
            type="button"
            onClick={onBack}
            className="p-1.5 -ml-1 text-white hover:text-[#00E676] active:scale-95 transition-all cursor-pointer rounded-full hover:bg-white/10 flex items-center justify-center"
            aria-label="Back"
          >
            <ArrowLeft className="w-5 h-5 sm:w-6 sm:h-6 stroke-[2.4]" />
          </button>
          <FreeWatchLogo />
        </div>

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

      {/* Main Content Container (Sleek PC Cinema Max-Width + Fluid Mobile) */}
      <main className="w-full max-w-6xl mx-auto flex flex-col flex-1">
        {/* 2. HERO BANNER / VIDEO PLAYER (Tall 50vh on mobile, 16:9 landscape on desktop and when playing) */}
        <div
          className={`relative w-full overflow-hidden bg-black lg:rounded-3xl lg:mt-4 lg:aspect-video lg:max-h-[580px] lg:border lg:border-white/10 shadow-2xl transition-[height,aspect-ratio] duration-300 ${
            isPlaying ? "aspect-video" : "h-[50vh] min-h-[440px] sm:min-h-[480px]"
          }`}
        >
          {isPlaying ? (
            <div className="relative w-full h-full bg-black flex items-center justify-center">
              {/* Overlay Back Button during Playback */}
              <button
                type="button"
                onClick={onBack}
                className="absolute top-4 left-4 z-30 p-2 rounded-full bg-black/70 hover:bg-black text-white hover:text-[#00E676] backdrop-blur-md transition-all active:scale-95 shadow-lg cursor-pointer"
                aria-label="Back"
              >
                <ArrowLeft className="w-5 h-5 stroke-[2.2]" />
              </button>

              <video
                ref={videoRef}
                key={streamUrl}
                controls
                autoPlay
                playsInline
                className="w-full h-full object-contain"
              />

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
            {/* Backdrop Artwork: Full 4K/HD sharpness */}
            <div className="absolute inset-0 bg-stone-950">
              <img
                src={tmdbBackdrop || activeSeries.backdropUrl || activeSeries.imageUrl}
                alt={activeSeries.title}
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
            <div className="absolute top-4 left-4 right-4 z-30 flex items-center justify-between pointer-events-none">
              <button
                type="button"
                onClick={onBack}
                className="w-10 h-10 rounded-full bg-black/60 hover:bg-black/90 backdrop-blur-md flex items-center justify-center text-white hover:text-[#00E676] transition-all cursor-pointer shadow-md pointer-events-auto active:scale-95"
                aria-label="Back"
              >
                <ArrowLeft className="w-5 h-5 stroke-[2.2]" />
              </button>

              <div className="px-3 py-1.5 rounded-full bg-black/60 backdrop-blur-md text-amber-400 text-xs font-black flex items-center gap-1 shadow-md pointer-events-auto">
                <span>★</span>
                <span>{activeSeries.rating}</span>
              </div>
            </div>

            {/* Center Big Play Button */}
            <div className="absolute inset-0 z-20 flex items-center justify-center pointer-events-none">
              <button
                type="button"
                onClick={() => setIsPlaying(true)}
                className="w-16 h-16 rounded-full bg-[#00E676] hover:bg-[#00c853] text-black flex items-center justify-center shadow-[0_0_30px_rgba(0,230,118,0.6)] hover:scale-110 active:scale-95 transition-transform cursor-pointer pointer-events-auto"
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

      {/* 3. ACTION BUTTONS ROW (Play/Next Episode, Bookmark, Download) */}
      <div className="px-4 pt-4 flex items-center gap-2.5">
        <button
          type="button"
          onClick={() => {
            if (isPlaying) {
              handleNextEpisode();
            } else {
              setIsPlaying(true);
            }
          }}
          className="flex-1 h-12 rounded-full bg-[#00E676] hover:bg-[#00c853] text-black font-extrabold text-sm flex items-center justify-center gap-2 shadow-lg shadow-[#00E676]/25 active:scale-[0.98] cursor-pointer"
        >
          {isPlaying ? (
            <>
              <SkipForward className="w-4 h-4 fill-black" />
              <span>NEXT EPISODE</span>
            </>
          ) : (
            <>
              <Play className="w-4 h-4 fill-black" />
              <span>START WATCHING</span>
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
            const epTitle = currentEpisode?.title || `${activeSeries.title} Episode ${activeEpisodeIndex + 1}`;
            const safeName = `${epTitle.replace(/[^a-zA-Z0-9_\-\s]/g, "").trim() || "Episode"}.mp4`;
            
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
              const epId = `${activeSeries.id}-ep${activeEpisodeIndex + 1}`;
              if (!list.some((item: any) => item.id === epId)) {
                list.unshift({
                  id: epId,
                  title: epTitle,
                  posterUrl: currentEpisode?.stillUrl || activeSeries.backdropUrl || activeSeries.imageUrl,
                  posterBg: "#18181b",
                  progress: 100,
                  isPaused: false,
                  fileSize: "720p HD",
                  speed: "Saved",
                  isSeries: true,
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
          title="Download Episode to Device"
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

        {/* Circular Loading Spinner while episodes are resolving */}
        {isLoadingEpisodes ? (
          <div className="flex flex-col items-center justify-center py-12 w-full">
            <Loader2 className="w-8 h-8 text-[#00E676] animate-spin mb-2" />
            <span className="text-xs text-neutral-400 font-medium">Loading episodes...</span>
          </div>
        ) : episodes.length === 0 ? (
          <div className="py-10 text-center text-xs text-neutral-400 bg-white/[0.02] border border-white/5 rounded-2xl">
            Episodes are currently being indexed for this series. Check back shortly!
          </div>
        ) : (
          /* Episode Cards Horizontal Slider (Matching Android App ListView.separated) */
          <div className="-mx-4 px-4 flex gap-3.5 overflow-x-auto no-scrollbar pb-3 pt-1 scroll-smooth">
            {episodes.map((ep, idx) => {
              const isSelected = activeEpisodeIndex === idx;
              const episodeThumb = ep.stillUrl || activeSeries.backdropUrl || activeSeries.imageUrl;
              return (
                <div
                  key={ep.num}
                  onClick={() => {
                    if (videoRef.current) {
                      videoRef.current.pause();
                    }
                    setActiveEpisodeIndex(idx);
                    setIsPlaying(true);
                  }}
                  className="w-[185px] sm:w-[210px] shrink-0 cursor-pointer group active:scale-[0.98] transition-transform select-none"
                >
                  <div
                    className={`relative aspect-video rounded-2xl overflow-hidden bg-neutral-900 transition-all flex items-center justify-center shadow-md ${
                      isSelected
                        ? "ring-2 ring-[#00E676] shadow-[0_0_20px_rgba(0,230,118,0.4)] scale-[1.02]"
                        : "group-hover:opacity-90"
                    }`}
                  >
                    {episodeThumb && (
                      <img
                        src={episodeThumb}
                        alt=""
                        className="absolute inset-0 w-full h-full object-cover filter brightness-70 group-hover:scale-105 transition-transform duration-300"
                      />
                    )}
                    <div className="absolute inset-0 bg-gradient-to-t from-black via-black/30 to-transparent pointer-events-none" />

                    {/* Top Left: Episode Number Badge */}
                    <div className="absolute top-2 left-2 z-10">
                      <span className="px-2 py-0.5 rounded-full bg-black/75 backdrop-blur-md text-[10px] font-black text-[#00E676]">
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
                            : "bg-white/25 backdrop-blur-md text-white group-hover:scale-110"
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
        )}
      </div>

      {/* 5. SYNOPSIS SECTION */}
      <div className="px-4 mt-7">
        <h3 className="text-base font-extrabold text-white tracking-tight mb-3">Synopsis</h3>

        <div className="rounded-2xl bg-[#141416] p-4 shadow-md">
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

      {/* 6. SERIES CAST SECTION (TMDB Actor Portraits) */}
      {castList.length > 0 && (
        <div className="px-4 mt-7">
          <h3 className="text-base font-extrabold text-white tracking-tight mb-3">Series Cast</h3>
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

      {/* 7. MORE LIKE THIS SECTION */}
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
                    <span className="text-[#00E676]">Series</span>
                  </div>
                </div>
              </div>
            ))}
        </div>
      </div>
      </main>

      {/* 7. FLOATING CURVED GLASS BOTTOM NAVIGATION BAR (Hidden on desktop) */}
      <FloatingBottomNav activeTab="home" onNavigateTab={onNavigateTab} />
    </div>
  );
};
