import React from "react";
import { Movie } from "../types/movie";
import { MoviePosterArt } from "./MoviePosterArt";
import { Bookmark, BookmarkCheck, Play, Plus, Star, Info } from "lucide-react";

interface MovieCardProps {
  movie: Movie;
  onSelect: (movie: Movie) => void;
  onPlay: (movie: Movie) => void;
  isWatchlisted: boolean;
  onToggleWatchlist: (movie: Movie) => void;
  rank?: number;
  variant?: "poster" | "backdrop" | "compact";
  isMobileMode?: boolean;
}

export const MovieCard: React.FC<MovieCardProps> = ({
  movie,
  onSelect,
  onPlay,
  isWatchlisted,
  onToggleWatchlist,
  rank,
  variant = "poster",
  isMobileMode = false,
}) => {
  return (
    <div
      className={`group relative flex flex-col cursor-pointer transition-all duration-200 select-none ${
        variant === "backdrop" ? "w-64 sm:w-72 shrink-0" : variant === "compact" ? "w-32 sm:w-36 shrink-0" : "w-36 sm:w-44 md:w-48 shrink-0"
      }`}
      onClick={() => onSelect(movie)}
    >
      {/* If Rank is provided (Top 10), render styled ranking numeral */}
      {rank !== undefined && (
        <div className="absolute -left-3.5 -bottom-2 z-20 pointer-events-none">
          <span
            className="text-6xl sm:text-7xl font-extrabold tracking-tighter leading-none select-none text-black drop-shadow-[0_4px_8px_rgba(0,0,0,0.8)]"
            style={{
              WebkitTextStroke: "2px #475569",
              textShadow: "0 0 20px rgba(0,0,0,0.8)",
            }}
          >
            {rank}
          </span>
        </div>
      )}

      {/* Main Poster Container */}
      <div className="relative overflow-hidden rounded-xl bg-slate-900 border border-slate-800/80 group-hover:border-slate-700 transition-all duration-300 group-hover:shadow-xl group-hover:shadow-black/50">
        <MoviePosterArt
          movie={movie}
          aspectRatio={variant === "backdrop" ? "16:9" : "3:4"}
          showOverlayTitle={variant === "backdrop"}
        />

        {/* Desktop Hover Quick Action Overlay */}
        {!isMobileMode && (
          <div className="absolute inset-0 bg-black/60 opacity-0 group-hover:opacity-100 transition-opacity duration-200 flex flex-col justify-between p-3 z-20 pointer-events-auto">
            {/* Top row actions */}
            <div className="flex items-center justify-between">
              <span className="text-[10px] font-bold text-amber-400 bg-black/70 px-2 py-0.5 rounded border border-amber-400/20">
                {movie.matchScore}% Match
              </span>
              <button
                type="button"
                onClick={(e) => {
                  e.stopPropagation();
                  onToggleWatchlist(movie);
                }}
                className={`p-1.5 rounded-full transition-colors ${
                  isWatchlisted
                    ? "bg-sky-500 text-white"
                    : "bg-white/20 text-white hover:bg-white/30"
                }`}
                title={isWatchlisted ? "In Watchlist" : "Add to Watchlist"}
              >
                {isWatchlisted ? (
                  <BookmarkCheck className="w-4 h-4" />
                ) : (
                  <Bookmark className="w-4 h-4" />
                )}
              </button>
            </div>

            {/* Center Play Button */}
            <div className="flex justify-center items-center">
              <button
                type="button"
                onClick={(e) => {
                  e.stopPropagation();
                  onPlay(movie);
                }}
                className="w-11 h-11 rounded-full bg-white text-slate-950 flex items-center justify-center hover:scale-110 active:scale-95 transition-transform shadow-lg shadow-black/50"
                title="Play Trailer"
              >
                <Play className="w-5 h-5 fill-slate-950 ml-0.5" />
              </button>
            </div>

            {/* Bottom info trigger */}
            <div className="flex items-center justify-between text-xs text-slate-300">
              <span className="text-[11px] font-medium text-slate-300 truncate max-w-[100px]">
                {movie.genres[0]}
              </span>
              <button
                type="button"
                onClick={(e) => {
                  e.stopPropagation();
                  onSelect(movie);
                }}
                className="flex items-center gap-1 text-[11px] text-white/90 hover:text-white"
              >
                <Info className="w-3.5 h-3.5" />
                <span>Details</span>
              </button>
            </div>
          </div>
        )}

        {/* Mobile Quick Add / Watchlist Badge */}
        {isMobileMode && (
          <button
            type="button"
            onClick={(e) => {
              e.stopPropagation();
              onToggleWatchlist(movie);
            }}
            className={`absolute top-2 right-2 z-20 p-1.5 rounded-full backdrop-blur-md transition-colors ${
              isWatchlisted
                ? "bg-sky-500 text-white"
                : "bg-black/50 text-white/90 border border-white/20 active:scale-90"
            }`}
          >
            {isWatchlisted ? (
              <BookmarkCheck className="w-3.5 h-3.5" />
            ) : (
              <Bookmark className="w-3.5 h-3.5" />
            )}
          </button>
        )}
      </div>

      {/* Card Text & Metadata (Under Poster) */}
      {variant !== "backdrop" && (
        <div className="mt-2 space-y-0.5 px-0.5">
          <h4 className="text-xs sm:text-sm font-semibold text-slate-100 group-hover:text-sky-400 transition-colors line-clamp-1">
            {movie.title}
          </h4>
          <div className="flex items-center gap-1.5 text-[11px] text-slate-400">
            <span>{movie.releaseYear}</span>
            <span aria-hidden="true" className="text-slate-600">·</span>
            <span className="truncate">{movie.genres[0]}</span>
          </div>
        </div>
      )}
    </div>
  );
};
