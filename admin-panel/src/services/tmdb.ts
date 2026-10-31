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

export function computeTitleSimilarity(s1: string, s2: string): number {
  const norm1 = s1.toLowerCase().replace(/[^a-z0-9 ]/g, "").trim();
  const norm2 = s2.toLowerCase().replace(/[^a-z0-9 ]/g, "").trim();
  if (norm1 === norm2) return 1.0;
  if (!norm1 || !norm2) return 0;
  if (norm1.includes(norm2) || norm2.includes(norm1)) return 0.85;

  const words1 = new Set(norm1.split(/\s+/).filter((w) => w.length > 2));
  const words2 = new Set(norm2.split(/\s+/).filter((w) => w.length > 2));
  if (words1.size === 0 || words2.size === 0) return 0.5;
  const intersection = [...words1].filter((w) => words2.has(w));
  if (intersection.length === 0) return 0;
  return (intersection.length * 2) / (words1.size + words2.size);
}

/**
 * Sanitizes stream URLs: upgrades http to https for CDNs, maps parked domains, encodes spaces
 */
export function sanitizeStreamUrl(url?: string): string {
  if (!url) return "";
  let clean = url.trim();

  // Map non-CORS and dead munotech/munoserver domains to the fast BunnyCDN mirror
  if (/https?:\/\/munotech\d*\.com/i.test(clean)) {
    clean = clean.replace(/https?:\/\/munotech\d*\.com/gi, "https://munotech3.b-cdn.net");
  }
  if (/https?:\/\/munoserver\d*\.(?:club|co|com|net)/i.test(clean)) {
    clean = clean.replace(/https?:\/\/munoserver\d*\.(?:club|co|com|net)/gi, "https://munotech3.b-cdn.net");
  }

  // Upgrade http to https to avoid mixed content block across all CDNs
  if (clean.startsWith("http://")) {
    clean = clean.replace(/^http:\/\//i, "https://");
  }

  // Encode unescaped spaces
  return clean.replace(/ /g, "%20");
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
        const results = (tvData.results || []) as any[];
        // Pick best matching result by title similarity
        let best = results[0];
        let bestScore = best ? computeTitleSimilarity(clean, best.name || "") : 0;
        for (const item of results.slice(1, 6)) {
          const score = computeTitleSimilarity(clean, item.name || "");
          if (score > bestScore) {
            best = item;
            bestScore = score;
          }
        }
        if (best && bestScore >= 0.25) {
          const meta: TmdbMetadata = {
            id: best.id,
            title: best.name || clean,
            overview: best.overview,
            posterUrl: best.poster_path ? `${TMDB_IMAGE_SIZES.posterW500}${best.poster_path}` : undefined,
            backdropUrl: best.backdrop_path ? `${TMDB_IMAGE_SIZES.backdropW1280}${best.backdrop_path}` : undefined,
            isTv: true,
            voteAverage: best.vote_average,
            voteCount: best.vote_count,
            releaseYear: (best.first_air_date || "").slice(0, 4),
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
      const results = (movieData.results || []) as any[];
      let best = results[0];
      let bestScore = best ? computeTitleSimilarity(clean, best.title || "") : 0;
      for (const item of results.slice(1, 6)) {
        const score = computeTitleSimilarity(clean, item.title || "");
        if (score > bestScore) {
          best = item;
          bestScore = score;
        }
      }
      if (best && bestScore >= 0.25) {
        const meta: TmdbMetadata = {
          id: best.id,
          title: best.title || clean,
          overview: best.overview,
          posterUrl: best.poster_path ? `${TMDB_IMAGE_SIZES.posterW500}${best.poster_path}` : undefined,
          backdropUrl: best.backdrop_path ? `${TMDB_IMAGE_SIZES.backdropW1280}${best.backdrop_path}` : undefined,
          isTv: false,
          voteAverage: best.vote_average,
          voteCount: best.vote_count,
          releaseYear: (best.release_date || "").slice(0, 4),
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
      const candidates = (multiData.results || []).filter((r: any) => r.media_type === "movie" || r.media_type === "tv");
      let match = candidates[0];
      let matchScore = match ? computeTitleSimilarity(clean, match.title || match.name || "") : 0;
      for (const c of candidates.slice(1, 6)) {
        const score = computeTitleSimilarity(clean, c.title || c.name || "");
        if (score > matchScore) {
          match = c;
          matchScore = score;
        }
      }
      if (match && matchScore >= 0.25) {
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
    const url = `${TMDB_BASE_URL}/${endpoint}/${tmdbId}/images?api_key=${TMDB_API_KEY}&include_image_language=en,null`;
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
  const altEndpoint = isTv ? "movie" : "tv";
  try {
    const altUrl = `${TMDB_BASE_URL}/${altEndpoint}/${tmdbId}/images?api_key=${TMDB_API_KEY}&include_image_language=en,null`;
    const res = await fetch(altUrl);
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
      if (cast.length > 0) {
        creditsCache.set(cacheKey, cast);
        return cast;
      }
    }
  } catch (e) {
    console.warn("[TMDB] Credits fetch failed for id:", tmdbId, e);
  }

  // Fallback: Try reciprocal endpoint if primary had no cast
  const altEndpoint = isTv ? "movie" : "tv";
  try {
    const altUrl = `${TMDB_BASE_URL}/${altEndpoint}/${tmdbId}/credits?api_key=${TMDB_API_KEY}`;
    const altRes = await fetch(altUrl);
    if (altRes.ok) {
      const data = await altRes.json();
      const cast = (data.cast || []).slice(0, 12).map((c: any) => ({
        id: c.id,
        name: c.name,
        character: c.character || "Cast",
        profileUrl: c.profile_path ? `${TMDB_IMAGE_SIZES.profileW185}${c.profile_path}` : undefined,
      }));
      if (cast.length > 0) {
        creditsCache.set(cacheKey, cast);
        return cast;
      }
    }
  } catch (_) {}

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
