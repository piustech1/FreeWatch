import React from "react";
import { Movie } from "../types/movie";
import { Film, Sparkles, Star } from "lucide-react";

interface MoviePosterArtProps {
  movie: Movie;
  aspectRatio?: "3:4" | "16:9" | "square";
  className?: string;
  showOverlayTitle?: boolean;
}

export const MoviePosterArt: React.FC<MoviePosterArtProps> = ({
  movie,
  aspectRatio = "3:4",
  className = "",
  showOverlayTitle = true,
}) => {
  const aspectClass =
    aspectRatio === "16:9"
      ? "aspect-video"
      : aspectRatio === "square"
      ? "aspect-square"
      : "aspect-[3/4]";

  const [imageError, setImageError] = React.useState(false);
  const displayImage = !imageError && (aspectRatio === "16:9" ? (movie.backdropUrl || movie.imageUrl) : (movie.imageUrl || movie.backdropUrl));

  return (
    <div
      className={`relative overflow-hidden rounded-xl bg-gradient-to-br ${movie.posterGradient || "from-slate-900 to-black"} ${aspectClass} select-none shadow-md ${className}`}
    >
      {/* Real Poster Image (if available) */}
      {displayImage ? (
        <img
          src={displayImage}
          alt={movie.title}
          onError={() => setImageError(true)}
          className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300 filter brightness-90"
        />
      ) : (
        <>
          {/* Cinematic subtle light reflections & geometric ambient texture */}
          <div className="absolute inset-0 opacity-20 pointer-events-none">
            <svg className="w-full h-full" xmlns="http://www.w3.org/2000/svg">
              <defs>
                <radialGradient id={`glow-${movie.id}`} cx="50%" cy="30%" r="60%">
                  <stop offset="0%" stopColor={movie.accentColor || "#00E676"} stopOpacity="0.8" />
                  <stop offset="100%" stopColor="transparent" stopOpacity="0" />
                </radialGradient>
                <linearGradient id={`diag-${movie.id}`} x1="0" y1="0" x2="1" y2="1">
                  <stop offset="0%" stopColor="white" stopOpacity="0.1" />
                  <stop offset="100%" stopColor="transparent" stopOpacity="0" />
                </linearGradient>
              </defs>
              <rect width="100%" height="100%" fill={`url(#glow-${movie.id})`} />
              <line x1="0" y1="0" x2="100%" y2="100%" stroke={`url(#diag-${movie.id})`} strokeWidth="1" />
            </svg>
          </div>

          {/* Stylized cinema icon / silhouette motif */}
          <div className="absolute inset-0 flex items-center justify-center opacity-30">
            <div
              className="w-20 h-20 rounded-full border border-white/20 flex items-center justify-center"
              style={{ borderColor: `${movie.accentColor || "#00E676"}40` }}
            >
              <Film className="w-8 h-8 text-white/50" />
            </div>
          </div>
        </>
      )}

      {/* Top right quality tag */}
      <div className="absolute top-2.5 right-2.5 z-10">
        <span className="text-[10px] font-bold tracking-wider px-1.5 py-0.5 rounded bg-black/60 backdrop-blur-sm text-slate-200 border border-white/10 uppercase">
          {movie.quality}
        </span>
      </div>

      {/* Top left rating tag */}
      <div className="absolute top-2.5 left-2.5 z-10 flex items-center gap-1 px-1.5 py-0.5 rounded bg-black/60 backdrop-blur-sm border border-white/10">
        <Star className="w-3 h-3 fill-amber-400 text-amber-400" />
        <span className="text-xs font-bold text-white tabular-nums">{movie.rating.toFixed(1)}</span>
      </div>

      {/* Bottom overlay with gradient scrim and clean typography */}
      <div className="absolute inset-0 bg-gradient-to-t from-black via-black/40 to-transparent flex flex-col justify-end p-3 pointer-events-none">
        {showOverlayTitle && (
          <div className="space-y-1">
            <div className="flex items-center gap-1.5 text-[11px] font-medium text-slate-300">
              <span>{movie.releaseYear}</span>
              <span aria-hidden="true" className="text-slate-600">·</span>
              <span className="truncate">{movie.genres[0]}</span>
              {movie.duration && (
                <>
                  <span aria-hidden="true" className="text-slate-600">·</span>
                  <span className="shrink-0">{movie.duration}</span>
                </>
              )}
            </div>
            <h4 className="text-sm font-bold text-white leading-tight line-clamp-1 drop-shadow-sm">
              {movie.title}
            </h4>
          </div>
        )}
      </div>

      {/* Subtle bottom accent line */}
      <div
        className="absolute bottom-0 left-0 right-0 h-1"
        style={{ backgroundColor: movie.accentColor }}
      />
    </div>
  );
};
