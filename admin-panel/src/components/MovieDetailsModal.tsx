import React, { useState } from "react";
import { Movie } from "../types/movie";
import { MoviePosterArt } from "./MoviePosterArt";
import {
  X,
  Play,
  Bookmark,
  BookmarkCheck,
  Download,
  Share2,
  Star,
  Clock,
  Calendar,
  Volume2,
  Tv,
  Check,
  ChevronRight,
} from "lucide-react";

interface MovieDetailsModalProps {
  movie: Movie | null;
  onClose: () => void;
  onPlay: (movie: Movie) => void;
  isWatchlisted: boolean;
  onToggleWatchlist: (movie: Movie) => void;
  allMovies: Movie[];
  onSelectMovie: (movie: Movie) => void;
  isMobileMode?: boolean;
}

export const MovieDetailsModal: React.FC<MovieDetailsModalProps> = ({
  movie,
  onClose,
  onPlay,
  isWatchlisted,
  onToggleWatchlist,
  allMovies,
  onSelectMovie,
  isMobileMode = false,
}) => {
  const [activeTab, setActiveTab] = useState<"overview" | "episodes" | "cast" | "similar">("overview");
  const [downloadState, setDownloadState] = useState<"idle" | "downloading" | "downloaded">("idle");
  const [copiedShare, setCopiedShare] = useState(false);

  if (!movie) return null;

  const similarMovies = allMovies
    .filter((m) => m.id !== movie.id && m.genres.some((g) => movie.genres.includes(g)))
    .slice(0, 4);

  const handleDownload = () => {
    if (downloadState === "idle") {
      setDownloadState("downloading");
      setTimeout(() => {
        setDownloadState("downloaded");
      }, 1500);
    }
  };

  const handleShare = () => {
    navigator.clipboard?.writeText(window.location.href);
    setCopiedShare(true);
    setTimeout(() => setCopiedShare(false), 2000);
  };

  return (
    <div className="fixed inset-0 z-50 flex items-end md:items-center justify-center bg-black/80 backdrop-blur-md transition-all duration-300 p-0 md:p-4 animate-in fade-in">
      {/* Backdrop click to close */}
      <div className="absolute inset-0" onClick={onClose} />

      {/* Modal / Sheet Container */}
      <div
        className={`relative z-10 w-full bg-slate-900 border border-slate-800 shadow-2xl overflow-hidden transition-all duration-300 ${
          isMobileMode
            ? "max-h-[90vh] rounded-t-3xl flex flex-col"
            : "max-w-4xl max-h-[88vh] rounded-2xl flex flex-col"
        }`}
      >
        {/* Mobile Drag Handle */}
        {isMobileMode && (
          <div className="w-12 h-1.5 bg-slate-700 rounded-full mx-auto my-2.5 shrink-0" />
        )}

        {/* Close Button */}
        <button
          onClick={onClose}
          className="absolute top-3 right-3 z-30 p-2 rounded-full bg-black/60 hover:bg-black/90 text-slate-300 hover:text-white transition-colors border border-white/10"
          aria-label="Close details"
        >
          <X className="w-4 h-4" />
        </button>

        {/* Scrollable Content Body */}
        <div className="overflow-y-auto no-scrollbar flex-1 pb-8">
          {/* Hero Backdrop Banner */}
          <div className="relative aspect-video sm:aspect-[21/9] w-full overflow-hidden bg-slate-950">
            <div
              className={`absolute inset-0 bg-gradient-to-r ${movie.backdropGradient} opacity-90`}
            />

            {/* Ambient pattern */}
            <div className="absolute inset-0 bg-[radial-gradient(circle_at_top,_var(--tw-gradient-stops))] from-white/10 via-transparent to-black" />

            {/* Gradient Scrim */}
            <div className="absolute inset-0 bg-gradient-to-t from-slate-900 via-slate-900/60 to-transparent flex flex-col justify-end p-4 sm:p-6">
              <div className="max-w-xl space-y-2">
                <div className="flex items-center gap-2 text-xs font-medium text-slate-300">
                  <span className="text-sky-400 font-semibold">{movie.matchScore}% Match</span>
                  <span>·</span>
                  <span>{movie.releaseYear}</span>
                  <span>·</span>
                  <span className="px-1.5 py-0.5 rounded text-[10px] bg-slate-800/80 border border-slate-700 text-slate-200">
                    {movie.ageRating}
                  </span>
                  <span>·</span>
                  <span>{movie.duration}</span>
                  <span>·</span>
                  <span className="text-slate-400">{movie.quality}</span>
                </div>

                <h2 className="text-xl sm:text-3xl font-extrabold text-white tracking-tight">
                  {movie.title}
                </h2>

                {movie.tagline && (
                  <p className="text-xs sm:text-sm text-slate-400 italic line-clamp-1">
                    "{movie.tagline}"
                  </p>
                )}
              </div>
            </div>

            {/* Play Button Overlay on Banner */}
            <button
              onClick={() => {
                onClose();
                onPlay(movie);
              }}
              className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-14 h-14 sm:w-16 sm:h-16 rounded-full bg-sky-500/90 text-white flex items-center justify-center hover:bg-sky-400 hover:scale-105 active:scale-95 transition-all shadow-xl shadow-sky-500/20"
              aria-label="Play trailer"
            >
              <Play className="w-6 h-6 fill-white ml-0.5" />
            </button>
          </div>

          {/* Primary Action Buttons Bar */}
          <div className="px-4 sm:px-6 pt-4 flex flex-wrap items-center gap-3">
            <button
              onClick={() => {
                onClose();
                onPlay(movie);
              }}
              className="flex-1 min-w-[140px] py-2.5 px-4 rounded-xl bg-white text-slate-950 font-semibold text-sm flex items-center justify-center gap-2 hover:bg-slate-200 active:scale-[0.98] transition-all shadow-md"
            >
              <Play className="w-4 h-4 fill-slate-950" />
              <span>Watch Now</span>
            </button>

            <button
              onClick={() => onToggleWatchlist(movie)}
              className={`py-2.5 px-4 rounded-xl font-medium text-sm flex items-center justify-center gap-2 border transition-all active:scale-[0.98] ${
                isWatchlisted
                  ? "bg-sky-950 border-sky-600 text-sky-300"
                  : "bg-slate-800/80 hover:bg-slate-800 border-slate-700 text-slate-200"
              }`}
            >
              {isWatchlisted ? (
                <>
                  <BookmarkCheck className="w-4 h-4 text-sky-400" />
                  <span>In List</span>
                </>
              ) : (
                <>
                  <Bookmark className="w-4 h-4" />
                  <span>My List</span>
                </>
              )}
            </button>

            <button
              onClick={handleDownload}
              className={`py-2.5 px-4 rounded-xl font-medium text-sm flex items-center justify-center gap-2 border transition-all active:scale-[0.98] ${
                downloadState === "downloaded"
                  ? "bg-emerald-950 border-emerald-600 text-emerald-300"
                  : downloadState === "downloading"
                  ? "bg-slate-800 border-amber-500 text-amber-300 animate-pulse"
                  : "bg-slate-800/80 hover:bg-slate-800 border-slate-700 text-slate-200"
              }`}
            >
              {downloadState === "downloaded" ? (
                <>
                  <Check className="w-4 h-4 text-emerald-400" />
                  <span>Downloaded</span>
                </>
              ) : downloadState === "downloading" ? (
                <span>Saving...</span>
              ) : (
                <>
                  <Download className="w-4 h-4" />
                  <span className="hidden sm:inline">Download</span>
                </>
              )}
            </button>

            <button
              onClick={handleShare}
              className="p-2.5 rounded-xl bg-slate-800/80 hover:bg-slate-800 border border-slate-700 text-slate-300 hover:text-white transition-colors"
              title="Share Link"
            >
              {copiedShare ? (
                <Check className="w-4 h-4 text-emerald-400" />
              ) : (
                <Share2 className="w-4 h-4" />
              )}
            </button>
          </div>

          {/* Navigation Tabs (Overview / Episodes / Cast / Similar) */}
          <div className="px-4 sm:px-6 mt-6 border-b border-slate-800">
            <div className="flex items-center gap-6 text-sm font-medium">
              <button
                onClick={() => setActiveTab("overview")}
                className={`pb-3 relative transition-colors ${
                  activeTab === "overview"
                    ? "text-white font-semibold"
                    : "text-slate-400 hover:text-slate-200"
                }`}
              >
                Overview
                {activeTab === "overview" && (
                  <div className="absolute bottom-0 left-0 right-0 h-0.5 bg-sky-500" />
                )}
              </button>

              {movie.type === "series" && movie.episodes && (
                <button
                  onClick={() => setActiveTab("episodes")}
                  className={`pb-3 relative transition-colors ${
                    activeTab === "episodes"
                      ? "text-white font-semibold"
                      : "text-slate-400 hover:text-slate-200"
                  }`}
                >
                  Episodes ({movie.episodes.length})
                  {activeTab === "episodes" && (
                    <div className="absolute bottom-0 left-0 right-0 h-0.5 bg-sky-500" />
                  )}
                </button>
              )}

              <button
                onClick={() => setActiveTab("cast")}
                className={`pb-3 relative transition-colors ${
                  activeTab === "cast"
                    ? "text-white font-semibold"
                    : "text-slate-400 hover:text-slate-200"
                }`}
              >
                Cast & Crew
                {activeTab === "cast" && (
                  <div className="absolute bottom-0 left-0 right-0 h-0.5 bg-sky-500" />
                )}
              </button>

              <button
                onClick={() => setActiveTab("similar")}
                className={`pb-3 relative transition-colors ${
                  activeTab === "similar"
                    ? "text-white font-semibold"
                    : "text-slate-400 hover:text-slate-200"
                }`}
              >
                More Like This
                {activeTab === "similar" && (
                  <div className="absolute bottom-0 left-0 right-0 h-0.5 bg-sky-500" />
                )}
              </button>
            </div>
          </div>

          {/* Tab Content Panes */}
          <div className="px-4 sm:px-6 pt-5">
            {activeTab === "overview" && (
              <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                <div className="md:col-span-2 space-y-4">
                  <p className="text-sm leading-relaxed text-slate-300">
                    {movie.overview}
                  </p>

                  <div className="pt-2 flex flex-wrap items-center gap-2">
                    <span className="text-xs text-slate-500">Genres:</span>
                    {movie.genres.map((genre, i) => (
                      <span
                        key={genre}
                        className="text-xs text-slate-300 font-medium"
                      >
                        {genre}
                        {i < movie.genres.length - 1 && " · "}
                      </span>
                    ))}
                  </div>

                  <div className="pt-2 text-xs text-slate-400 space-y-1">
                    <div>
                      <span className="text-slate-500">Director: </span>
                      <span className="text-slate-300 font-medium">{movie.director}</span>
                    </div>
                    <div>
                      <span className="text-slate-500">Audio: </span>
                      <span className="text-slate-300">Dolby Atmos, 5.1 Surround, Stereo</span>
                    </div>
                    <div>
                      <span className="text-slate-500">Subtitles: </span>
                      <span className="text-slate-300">English [CC], Spanish, French, German, Japanese</span>
                    </div>
                  </div>
                </div>

                {/* Right side quick specs */}
                <div className="rounded-xl bg-slate-800/40 border border-slate-800 p-4 space-y-3">
                  <div className="flex items-center justify-between text-xs">
                    <span className="text-slate-400">IMDb Rating</span>
                    <span className="font-bold text-amber-400 flex items-center gap-1">
                      <Star className="w-3.5 h-3.5 fill-amber-400" />
                      {movie.rating} / 10 ({movie.voteCount})
                    </span>
                  </div>
                  <div className="flex items-center justify-between text-xs border-t border-slate-800 pt-2">
                    <span className="text-slate-400">Content Rating</span>
                    <span className="font-semibold text-slate-200">{movie.ageRating}</span>
                  </div>
                  <div className="flex items-center justify-between text-xs border-t border-slate-800 pt-2">
                    <span className="text-slate-400">Resolution</span>
                    <span className="font-semibold text-sky-400">{movie.quality}</span>
                  </div>
                  <div className="flex items-center justify-between text-xs border-t border-slate-800 pt-2">
                    <span className="text-slate-400">Format</span>
                    <span className="font-semibold text-slate-200">
                      {movie.type === "series" ? `${movie.totalSeasons} Seasons` : "Feature Film"}
                    </span>
                  </div>
                </div>
              </div>
            )}

            {/* Episodes Tab */}
            {activeTab === "episodes" && movie.episodes && (
              <div className="space-y-3">
                <div className="text-xs text-slate-400 font-medium">Season 1</div>
                <div className="divide-y divide-slate-800/80">
                  {movie.episodes.map((ep) => (
                    <div
                      key={ep.id}
                      onClick={() => {
                        onClose();
                        onPlay(movie);
                      }}
                      className="py-3 flex items-start gap-3 hover:bg-slate-800/50 rounded-lg p-2 transition-colors cursor-pointer group"
                    >
                      <div className={`w-28 aspect-video rounded-lg bg-gradient-to-br ${ep.thumbnailGradient} relative shrink-0 flex items-center justify-center border border-slate-800`}>
                        <Play className="w-5 h-5 text-white/80 group-hover:text-white group-hover:scale-110 transition-transform fill-white/80" />
                        <span className="absolute bottom-1 right-1 text-[9px] bg-black/80 px-1 rounded text-slate-300">
                          {ep.duration}
                        </span>
                      </div>
                      <div className="flex-1 min-w-0">
                        <div className="flex items-center justify-between">
                          <h4 className="text-xs sm:text-sm font-semibold text-white group-hover:text-sky-400 transition-colors truncate">
                            {ep.episodeNumber}. {ep.title}
                          </h4>
                          <span className="text-[11px] text-slate-400 tabular-nums ml-2">
                            {ep.duration}
                          </span>
                        </div>
                        <p className="text-xs text-slate-400 mt-1 line-clamp-2">
                          {ep.overview}
                        </p>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {/* Cast & Crew Tab */}
            {activeTab === "cast" && (
              <div className="grid grid-cols-2 sm:grid-cols-4 gap-4">
                {movie.cast.map((member) => (
                  <div
                    key={member.name}
                    className="p-3 rounded-xl bg-slate-800/40 border border-slate-800 flex items-center gap-3"
                  >
                    <div
                      className={`w-10 h-10 rounded-full bg-gradient-to-tr ${member.avatarBg} flex items-center justify-center text-white font-bold text-xs shrink-0`}
                    >
                      {member.name
                        .split(" ")
                        .map((n) => n[0])
                        .join("")}
                    </div>
                    <div className="min-w-0">
                      <h5 className="text-xs font-semibold text-white truncate">
                        {member.name}
                      </h5>
                      <p className="text-[11px] text-slate-400 truncate">
                        {member.character}
                      </p>
                    </div>
                  </div>
                ))}
              </div>
            )}

            {/* More Like This Tab */}
            {activeTab === "similar" && (
              <div className="grid grid-cols-2 sm:grid-cols-4 gap-4">
                {similarMovies.map((sim) => (
                  <div
                    key={sim.id}
                    onClick={() => onSelectMovie(sim)}
                    className="cursor-pointer group"
                  >
                    <MoviePosterArt movie={sim} aspectRatio="3:4" />
                    <div className="mt-1.5">
                      <h5 className="text-xs font-medium text-slate-200 group-hover:text-sky-400 transition-colors truncate">
                        {sim.title}
                      </h5>
                      <span className="text-[10px] text-slate-400">
                        {sim.releaseYear} · {sim.rating}★
                      </span>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};
