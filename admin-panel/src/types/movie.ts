export interface CastMember {
  name: string;
  character: string;
  avatarBg: string;
}

export interface Episode {
  id: string;
  episodeNumber: number;
  title: string;
  duration: string;
  overview: string;
  thumbnailGradient: string;
}

export interface Movie {
  id: string;
  title: string;
  tagline?: string;
  overview: string;
  rating: number; // e.g. 8.8
  voteCount: string;
  releaseYear: number;
  duration: string; // e.g. "2h 24m"
  genres: string[];
  director: string;
  cast: CastMember[];
  ageRating: string; // "PG-13", "R", "TV-MA"
  quality: "4K UHD" | "1080p HD" | "IMAX Enhanced";
  matchScore: number; // e.g. 97
  posterGradient: string; // CSS gradient for aesthetic visual presentation
  accentColor: string; // Hex color for themes
  backdropGradient: string;
  trailerTitle?: string;
  isTrending?: boolean;
  isNowPlaying?: boolean;
  isTop10?: number; // rank 1 to 10
  isPopular?: boolean;
  totalSeasons?: number;
  episodes?: Episode[];
  imageUrl?: string;
  backdropUrl?: string;
  vj?: string;
  streamUrl?: string;
}

export type ViewTab = "home" | "explore" | "watchlist" | "profile";
export type DeviceViewMode = "auto" | "mobile" | "desktop";
