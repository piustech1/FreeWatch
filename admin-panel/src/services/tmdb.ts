/**
 * TMDB API Client and Metadata Enrichment Service for FreeWatch Web
 * Mirrors Flutter's tmdb_datasource.dart and movie_repository.dart logic.
 */

const TMDB_API_KEY = "13b3f57eb9c4b90cb8a202f4c8f119c6";
const TMDB_BASE_URL = "https://api.themoviedb.org/3";
export const TMDB_IMAGE_BASE = "https://image.tmdb.org/t/p";

export const TMDB_IMAGE_SIZES = {
  posterW200: `${TMDB_IMAGE_BASE}/w200`,
  posterW342: `${TMDB_IMAGE_BASE}/w342`,
  posterW500: `${TMDB_IMAGE_BASE}/w500`,
  logoW500: `${TMDB_IMAGE_BASE}/w500`,
  backdropW780: `${TMDB_IMAGE_BASE}/w780`,
  backdropW1280: `${TMDB_IMAGE_BASE}/w1280`,
  backdropOriginal: `${TMDB_IMAGE_BASE}/original`,
  profileW185: `${TMDB_IMAGE_BASE}/w185`,
  stillW500: `${TMDB_IMAGE_BASE}/w500`,
};

export interface TmdbCastMember {
  id: number;
  name: string;
  character: string;
  profileUrl?: string;
}

export interface TmdbEpisodeData {
  episodeNumber: number;
  name: string;
  overview: string;
  stillUrl?: string;
  airDate?: string;
  voteAverage?: number;
  runtime?: number;
}

export interface TmdbMetadata {
  id: number;
  title: string;
  overview?: string;
  posterUrl?: string;
  backdropUrl?: string;
  logoUrl?: string;
  isTv: boolean;
  voteAverage?: number;
  voteCount?: number;
  releaseYear?: string;
  cast?: TmdbCastMember[];
  genres?: string[];
}

// In-memory caches to prevent redundant network queries
const metadataCache = new Map<string, TmdbMetadata | null>();
const logoCache = new Map<string, string | null>();
const creditsCache = new Map<string, TmdbCastMember[]>();
const seasonEpisodesCache = new Map<string, TmdbEpisodeData[]>();

/**
 * Clean title for TMDB search matching Flutter's _cleanTitleForTmdb
 */
export function cleanTitleForTmdb(rawTitle: string): string {
  if (!rawTitle) return "";
  let clean = rawTitle.trim();

  // Strip file extensions
  clean = clean.replace(/\.(mp4|mkv|avi|mov)$/i, "");

  // Strip VJ names
  clean = clean.replace(/\b(?:vj|v\.j\.?)\s+[a-z0-9_-]+/gi, "");

  // Strip season/episode notations
  clean = clean.replace(/\b(?:season\s*\d+|s\d{1,2}|ep(?:isode)?\s*\d+|eps\s*\d+|part\s*\d+|pt\s*\d+)\b/gi, "");

  // Strip resolution & quality tags
  clean = clean.replace(/\b(?:1080p?|720p?|480p?|4k|uhd|hdrip|web-?dl|bluray|x264|hevc)\b/gi, "");

  // Strip trailing years like .2024 or (2024)
  clean = clean.replace(/[(\[]?\b(19\d\d|20\d\d)\b[)\]]?/g, "");

  // Replace dots, underscores, dashes with space
  clean = clean.replace(/[._\-]+/g, " ");

  // Collapse whitespace
  clean = clean.replace(/\s+/g, " ").trim();
  return clean;
}

/**
 * Searches TMDB for TV series or movies with priority matching
 */
export async function searchTmdb(title: string, isTv: boolean = false): Promise<TmdbMetadata | null> {
  const clean = cleanTitleForTmdb(title);
  if (!clean || clean.length < 2) return null;

  const cacheKey = `${clean.toLowerCase()}_${isTv ? "tv" : "movie"}`;
  if (metadataCache.has(cacheKey)) {
    return metadataCache.get(cacheKey) || null;
  }

  try {
    // 1. Try searchTv first if isTv is true or title indicates a show
    if (isTv) {
      const tvUrl = `${TMDB_BASE_URL}/search/tv?api_key=${TMDB_API_KEY}&query=${encodeURIComponent(clean)}`;
      const tvRes = await fetch(tvUrl);
      if (tvRes.ok) {
        const tvData = await tvRes.json();
        const first = tvData.results?.[0];
        if (first) {
          const meta: TmdbMetadata = {
            id: first.id,
            title: first.name || clean,
            overview: first.overview,
            posterUrl: first.poster_path ? `${TMDB_IMAGE_SIZES.posterW500}${first.poster_path}` : undefined,
            backdropUrl: first.backdrop_path ? `${TMDB_IMAGE_SIZES.backdropW1280}${first.backdrop_path}` : undefined,
            isTv: true,
            voteAverage: first.vote_average,
            voteCount: first.vote_count,
            releaseYear: (first.first_air_date || "").slice(0, 4),
          };
          metadataCache.set(cacheKey, meta);
          return meta;
        }
      }
    }

    // 2. Query searchMovies
    const movieUrl = `${TMDB_BASE_URL}/search/movie?api_key=${TMDB_API_KEY}&query=${encodeURIComponent(clean)}`;
    const movieRes = await fetch(movieUrl);
    if (movieRes.ok) {
      const movieData = await movieRes.json();
      const first = movieData.results?.[0];
      if (first) {
        const meta: TmdbMetadata = {
          id: first.id,
          title: first.title || clean,
          overview: first.overview,
          posterUrl: first.poster_path ? `${TMDB_IMAGE_SIZES.posterW500}${first.poster_path}` : undefined,
          backdropUrl: first.backdrop_path ? `${TMDB_IMAGE_SIZES.backdropW1280}${first.backdrop_path}` : undefined,
          isTv: false,
          voteAverage: first.vote_average,
          voteCount: first.vote_count,
          releaseYear: (first.release_date || "").slice(0, 4),
        };
        metadataCache.set(cacheKey, meta);
        return meta;
      }
    }

    // 3. Fallback: multi-search
    const multiUrl = `${TMDB_BASE_URL}/search/multi?api_key=${TMDB_API_KEY}&query=${encodeURIComponent(clean)}`;
    const multiRes = await fetch(multiUrl);
    if (multiRes.ok) {
      const multiData = await multiRes.json();
      const match = (multiData.results || []).find((r: any) => r.media_type === "movie" || r.media_type === "tv");
      if (match) {
        const isMatchedTv = match.media_type === "tv";
        const meta: TmdbMetadata = {
          id: match.id,
          title: match.title || match.name || clean,
          overview: match.overview,
          posterUrl: match.poster_path ? `${TMDB_IMAGE_SIZES.posterW500}${match.poster_path}` : undefined,
          backdropUrl: match.backdrop_path ? `${TMDB_IMAGE_SIZES.backdropW1280}${match.backdrop_path}` : undefined,
          isTv: isMatchedTv,
          voteAverage: match.vote_average,
          voteCount: match.vote_count,
          releaseYear: (match.release_date || match.first_air_date || "").slice(0, 4),
        };
        metadataCache.set(cacheKey, meta);
        return meta;
      }
    }
  } catch (e) {
    console.warn("[TMDB] search failed for:", clean, e);
  }

  metadataCache.set(cacheKey, null);
  return null;
}

/**
 * Fetch transparent PNG movie or TV logo from TMDB
 */
export async function getMovieLogo(tmdbId: number, isTv: boolean = false): Promise<string | null> {
  const cacheKey = `${tmdbId}_${isTv ? "tv" : "movie"}`;
  if (logoCache.has(cacheKey)) {
    return logoCache.get(cacheKey) || null;
  }

  const endpoint = isTv ? "tv" : "movie";
  try {
    const url = `${TMDB_BASE_URL}/${endpoint}/${tmdbId}/images?api_key=${TMDB_API_KEY}`;
    const res = await fetch(url);
    if (res.ok) {
      const data = await res.json();
      const logos = data.logos as any[] | undefined;
      if (logos && logos.length > 0) {
        // Prioritize English logos
        const enLogo = logos.find((l) => l.iso_639_1 === "en") || logos[0];
        if (enLogo?.file_path) {
          const logoUrl = `${TMDB_IMAGE_SIZES.logoW500}${enLogo.file_path}`;
          logoCache.set(cacheKey, logoUrl);
          return logoUrl;
        }
      }
    }
  } catch (e) {
    console.warn("[TMDB] Logo fetch failed for id:", tmdbId, e);
  }

  // Fallback: If not found in primary endpoint, try the other
  if (!isTv) {
    try {
      const tvUrl = `${TMDB_BASE_URL}/tv/${tmdbId}/images?api_key=${TMDB_API_KEY}`;
      const res = await fetch(tvUrl);
      if (res.ok) {
        const data = await res.json();
        const logos = data.logos as any[] | undefined;
        if (logos && logos.length > 0) {
          const enLogo = logos.find((l) => l.iso_639_1 === "en") || logos[0];
          if (enLogo?.file_path) {
            const logoUrl = `${TMDB_IMAGE_SIZES.logoW500}${enLogo.file_path}`;
            logoCache.set(cacheKey, logoUrl);
            return logoUrl;
          }
        }
      }
    } catch (_) {}
  }

  logoCache.set(cacheKey, null);
  return null;
}

/**
 * Fetch authentic cast members with photos and character names
 */
export async function getCredits(tmdbId: number, isTv: boolean = false): Promise<TmdbCastMember[]> {
  const cacheKey = `${tmdbId}_${isTv ? "tv" : "movie"}`;
  if (creditsCache.has(cacheKey)) {
    return creditsCache.get(cacheKey) || [];
  }

  const endpoint = isTv ? "tv" : "movie";
  try {
    const url = `${TMDB_BASE_URL}/${endpoint}/${tmdbId}/credits?api_key=${TMDB_API_KEY}`;
    const res = await fetch(url);
    if (res.ok) {
      const data = await res.json();
      const cast = (data.cast || []).slice(0, 12).map((c: any) => ({
        id: c.id,
        name: c.name,
        character: c.character || "Cast",
        profileUrl: c.profile_path ? `${TMDB_IMAGE_SIZES.profileW185}${c.profile_path}` : undefined,
      }));
      creditsCache.set(cacheKey, cast);
      return cast;
    }
  } catch (e) {
    console.warn("[TMDB] Credits fetch failed for id:", tmdbId, e);
  }

  creditsCache.set(cacheKey, []);
  return [];
}

/**
 * Fetch real TV season episodes from TMDB with unique backdrop stills and titles
 */
export async function getSeasonEpisodes(tmdbId: number, seasonNumber: number = 1): Promise<TmdbEpisodeData[]> {
  const cacheKey = `${tmdbId}_s${seasonNumber}`;
  if (seasonEpisodesCache.has(cacheKey)) {
    return seasonEpisodesCache.get(cacheKey) || [];
  }

  try {
    const url = `${TMDB_BASE_URL}/tv/${tmdbId}/season/${seasonNumber}?api_key=${TMDB_API_KEY}`;
    const res = await fetch(url);
    if (res.ok) {
      const data = await res.json();
      const episodes = (data.episodes || []).map((e: any) => ({
        episodeNumber: e.episode_number,
        name: e.name || `Episode ${e.episode_number}`,
        overview: e.overview || "",
        stillUrl: e.still_path ? `${TMDB_IMAGE_SIZES.stillW500}${e.still_path}` : undefined,
        airDate: e.air_date,
        voteAverage: e.vote_average,
        runtime: e.runtime || 45,
      }));
      seasonEpisodesCache.set(cacheKey, episodes);
      return episodes;
    }
  } catch (e) {
    console.warn("[TMDB] Season episodes fetch failed for id:", tmdbId, "season:", seasonNumber, e);
  }

  seasonEpisodesCache.set(cacheKey, []);
  return [];
}
