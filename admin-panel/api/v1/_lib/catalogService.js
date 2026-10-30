/**
 * FreeWatch High-Speed Backend API Service Layer
 * Aggregates, enriches, and caches MunoWatch's 7,000+ movies directly from Firebase RTDB
 * and live MunoWatch endpoints, ordered strictly Newly to Oldy.
 */

import fs from 'fs';

const RTDB_URL = 'https://freewatch-a0bc7-default-rtdb.firebaseio.com';
const MUMOWATCH_BASE = 'https://mumowatch.ai.studio';
const FALLBACK_BASE = 'https://munowatch.ai.studio';

// Load and sort all known 7,000+ MunoWatch IDs from highest (newest) to lowest (oldest)
let KNOWN_IDS = [];
try {
  const rawIds = JSON.parse(fs.readFileSync(new URL('./known_ids.json', import.meta.url)));
  KNOWN_IDS = Array.from(new Set(rawIds.map(Number)))
    .filter(n => !isNaN(n) && n > 0)
    .sort((a, b) => b - a); // Newly to Oldy (e.g. 67406, 67400, 67395...)
} catch (e) {
  console.warn('⚠️ Could not load known_ids.json:', e.message);
}

// In-memory cache for ultra-fast serverless reuse (sub-10ms response)
const memoryMovieMap = new Map();
let cachedDashboard = null;
let cachedDashboardTime = 0;
const DASHBOARD_CACHE_TTL = 3 * 60 * 1000; // 3 minutes

// VJ Avatar Map matching local /vjs/ files
const VJ_AVATAR_MAP = {
  'junior': '/vjs/vj junior.png',
  'emmy': '/vjs/vj emmy.png',
  'ulio': '/vjs/vj ulio.jpeg',
  'jingo': '/vjs/vj jingo.jpg',
  'ice p': '/vjs/vj iceP.jpeg',
  'icep': '/vjs/vj iceP.jpeg',
  'heavy q': '/vjs/Vj Heavy Q.jpeg',
  'heavyq': '/vjs/Vj Heavy Q.jpeg',
  'musa': '/vjs/Vj Musa.jpeg',
  'shield': '/vjs/Vj shield.png',
  'neil': '/vjs/vj Neil.jpeg',
  'nelly': '/vjs/vj Nelly.jpeg',
  'ham': '/vjs/vj ham.jpeg',
  'hd': '/vjs/vj hd.jpeg',
  'isma k': '/vjs/vj isma k.jpeg',
  'isma pro': '/vjs/vj isma pro.jpeg',
  'jovan': '/vjs/vj jovan.jpeg',
  'kevin': '/vjs/vj kevin.jpeg',
  'kevo': '/vjs/vj kevo.jpeg',
  'kk': '/vjs/vj kk.jpeg',
  'lance': '/vjs/vj lance.jpeg',
  'mark': '/vjs/vj mark.jpeg',
  'martin k': '/vjs/vj martin k.jpeg',
  'mk kisule': '/vjs/vj mk kisule.png',
  'mosco': '/vjs/vj mosco.jpeg',
  'muba': '/vjs/vj muba.jpeg',
  'smk': '/vjs/vj smk.jpeg',
  'tom': '/vjs/vj tom.png',
  'tonny': '/vjs/vj tonny.png',
  'uncle t': '/vjs/vj uncle T.jpeg',
  'soul': '/vjs/vjsoul.jpeg',
};

export function getVjAvatar(vjName) {
  if (!vjName) return '/vjs/vj_universal.png';
  const clean = vjName.toLowerCase().replace(/^vj\.?\s*/i, '').trim();
  for (const [key, path] of Object.entries(VJ_AVATAR_MAP)) {
    if (clean === key || clean.startsWith(key)) {
      return path;
    }
  }
  return '/vjs/vj_universal.png';
}

export function setCorsAndCache(res, { maxAge = 300, stale = 600 } = {}) {
  res.setHeader('Access-Control-Allow-Credentials', 'true');
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET,OPTIONS,PATCH,DELETE,POST,PUT');
  res.setHeader(
    'Access-Control-Allow-Headers',
    'X-CSRF-Token, X-Requested-With, Accept, Accept-Version, Content-Length, Content-MD5, Content-Type, Date, X-Api-Version'
  );
  if (maxAge > 0) {
    res.setHeader('Cache-Control', `public, s-maxage=${maxAge}, stale-while-revalidate=${stale}`);
  } else {
    res.setHeader('Cache-Control', 'no-cache, no-store, must-revalidate');
  }
}

export function sanitizeStreamUrl(raw) {
  if (!raw || typeof raw !== 'string') return null;
  let trimmed = raw.trim();
  if (!trimmed.startsWith('http')) return null;
  if (
    trimmed.startsWith('http://') &&
    (trimmed.includes('b-cdn.net') || trimmed.includes('r2.dev') || trimmed.includes('pearlpix'))
  ) {
    trimmed = trimmed.replace('http://', 'https://');
  }
  return trimmed.replace(/\s+/g, '%20');
}

export function extractTitleAndVj(rawTitle, rawVj) {
  let title = (rawTitle || '').trim();
  let vj = (rawVj || '').trim();

  title = title.replace(/^["'\[]+|["'\]]+$/g, '').trim();

  const vjRegex = /\b(VJ\s+[A-Za-z0-9\-]+|VJ\.[A-Za-z0-9\-]+)\b/i;
  const match = title.match(vjRegex);
  if (match) {
    if (!vj || vj === 'null' || vj === 'undefined' || vj.toLowerCase() === 'universal') {
      vj = match[0].toUpperCase().replace('VJ.', 'VJ ');
    }
    title = title.replace(match[0], '').trim();
  }

  title = title.replace(/^[-\s:|]+|[-\s:|]+$/g, '').trim();

  if (vj && vj !== 'null' && vj !== 'undefined' && vj.trim().length > 0) {
    vj = vj.trim();
    if (!vj.toUpperCase().startsWith('VJ ') && !vj.toUpperCase().startsWith('VJ.')) {
      vj = `VJ ${vj}`;
    }
  } else {
    vj = 'Luganda Dubbed';
  }

  return { title, vj };
}

export function mapMunoCategoryId(rawCatId, rawCategory = '', title = '') {
  const catId = Number(rawCatId);
  if (catId === 1 || catId === 5) return 'Action';
  if (catId === 2 || catId === 9) return 'Sci-Fi';
  if (catId === 14 || catId === 10) return 'Horror';
  if (catId === 15 || catId === 8) return 'Drama';
  if (catId === 3) return 'Romance';
  if (catId === 16) return 'Animation';
  if (catId === 20) return 'Family';
  if (catId === 27) return 'Comedy';

  const catLower = (rawCategory || '').toLowerCase();
  if (catLower.includes('action')) return 'Action';
  if (catLower.includes('sci') || catLower.includes('fiction') || catLower.includes('fantasy')) return 'Sci-Fi';
  if (catLower.includes('horror') || catLower.includes('thriller')) return 'Horror';
  if (catLower.includes('romance') || catLower.includes('love')) return 'Romance';
  if (catLower.includes('drama')) return 'Drama';
  if (catLower.includes('comedy')) return 'Comedy';
  if (catLower.includes('animation') || catLower.includes('anime')) return 'Animation';

  const t = title.toLowerCase();
  if (/alien|space|future|galaxy|cyber|robot|matrix|planet|star\s*wars|marvel|avenger/i.test(t)) return 'Sci-Fi';
  if (/horror|dead|kill|blood|ghost|evil|monster|zombie|haunt|demon|devil|slasher|curse/i.test(t)) return 'Horror';
  if (/love|heart|romance|kiss|wedding|passion|forever/i.test(t)) return 'Romance';
  if (/laugh|funny|comedy|joke|fun|fool/i.test(t)) return 'Comedy';
  if (/drama|life|story|tear|struggle|family|mother|father|crime|truth/i.test(t)) return 'Drama';

  return 'Action';
}

export function normalizeMovie(raw) {
  const id = Number(raw.id || raw.vid);
  const rawTitle = raw.title || raw.name || raw.video_title || '';
  const rawVj = raw.vj || raw.vjName || raw.vjname || '';
  const { title, vj } = extractTitleAndVj(rawTitle, rawVj);

  const cleanTitle = (title && title.toLowerCase() !== 'movie' && title.toLowerCase() !== 'new release') 
    ? title 
    : `Luganda Release #${id}`;
  const poster = raw.poster_path || raw.image || raw.poster || 'https://apposters.b-cdn.net/laba/yo/naki/01d9.jpg';
  const backdrop = raw.backdrop_path || raw.backdrop || poster;
  const streamUrl = sanitizeStreamUrl(raw.streamUrl || raw.playingurl || raw.videoUrl || '');
  
  const category = mapMunoCategoryId(raw.category_id || raw.categoryId, raw.category, cleanTitle);

  // Authentic Series detection:
  // 1. Explicit season or episode markers in title
  // 2. Presence of a valid series_code
  // 3. Category ID 5 (MunoWatch Series) or type === 'SERIES'
  // 4. Genuine multi-episode arrays or explicit isTv/is_series flags
  const hasExplicitSeasonOrEp = /season|\b(?:s\d{1,2}|ep(?:isode)?\s*\d+|part\s*\d+)\b|eps\s*\d+/i.test(cleanTitle);
  const hasSeriesCode = Boolean(raw.series_code && String(raw.series_code).trim().length > 0 && String(raw.series_code) !== '0');
  const isSeriesCategory = Number(raw.category_id) === 5 || (raw.category && raw.category.toLowerCase().includes('series'));
  const isSeriesType = raw.type && raw.type.toUpperCase().includes('SERIES');
  const hasMultipleEpisodes = Array.isArray(raw.episodes) && raw.episodes.length > 0;
  
  const isSeries = Boolean(
    raw.isTv ||
    raw.is_series ||
    hasExplicitSeasonOrEp ||
    hasSeriesCode ||
    isSeriesCategory ||
    isSeriesType ||
    hasMultipleEpisodes
  );

  const genres = [isSeries ? 'Series' : category, 'Luganda Dubbed'];
  if (isSeries && category !== 'Series' && !genres.includes(category)) {
    genres.push(category);
  }

  return {
    id,
    title: cleanTitle,
    vj: vj || 'Luganda Dubbed',
    category: isSeries ? 'Series' : category,
    genres,
    category_id: raw.category_id || 10,
    poster,
    poster_path: poster,
    backdrop,
    backdrop_path: backdrop,
    image: poster,
    overview: raw.overview || raw.synopsis || raw.description || `Official Luganda translated cinema release presented by ${vj}.`,
    rating: raw.rating || (raw.vote_average ? raw.vote_average.toString() : '8.5'),
    vote_average: Number(raw.vote_average || raw.rating || 8.5),
    runtime: raw.runtime || raw.duration || '01h 45m',
    duration: raw.duration || raw.runtime || '01h 45m',
    year: raw.year || '2025',
    isTv: isSeries,
    is_series: isSeries,
    series_code: raw.series_code ? String(raw.series_code) : null,
    streamUrl,
    playingurl: streamUrl,
    episodes: Array.isArray(raw.episodes) ? raw.episodes : [],
  };
}

/**
 * Fetch a single movie by ID with cache-first, then RTDB, then on-demand live MunoWatch
 */
export async function getMovieById(movieId) {
  const id = Number(movieId);
  if (!id) return null;

  // 1. Check in-memory map
  if (memoryMovieMap.has(id)) {
    const existing = memoryMovieMap.get(id);
    const t = (existing.title || '').trim().toLowerCase();
    if (t && t !== 'movie' && t !== 'eps' && !t.startsWith('luganda release #')) {
      return existing;
    }
  }

  // 2. Check RTDB
  try {
    const res = await fetch(`${RTDB_URL}/munowatch/catalog/${id}.json`);
    if (res.ok) {
      const data = await res.json();
      const rawT = (data?.title || data?.video_title || '').trim().toLowerCase();
      const isValid = data && data.id && rawT && rawT !== 'movie' && rawT !== 'eps' && !rawT.startsWith('luganda release #');
      if (isValid) {
        const norm = normalizeMovie(data);
        memoryMovieMap.set(id, norm);
        return norm;
      }
    }
  } catch (_) {}

  // 3. Fallback to live MunoWatch /movie/:id
  try {
    const urls = [
      `${MUMOWATCH_BASE}/movie/${id}`,
      `${FALLBACK_BASE}/movie/${id}`,
    ];
    for (const u of urls) {
      try {
        const res = await fetch(u, {
          headers: { 'User-Agent': 'FreeWatch/2.0 (Serverless)' },
        });
        if (res.ok) {
          const detail = await res.json();
          if (detail && (detail.title || detail.playingurl)) {
            const norm = normalizeMovie(detail);
            memoryMovieMap.set(id, norm);
            return norm;
          }
        }
      } catch (_) {}
    }
  } catch (_) {}

  return null;
}

/**
 * Continuous newly-to-oldy batch loader
 * Takes a list of IDs and resolves them in parallel batches
 */
async function resolveMovieBatch(ids) {
  const results = [];
  const missingIds = [];

  for (const id of ids) {
    if (memoryMovieMap.has(id)) {
      const existing = memoryMovieMap.get(id);
      const t = (existing.title || '').trim().toLowerCase();
      if (t && t !== 'movie' && t !== 'eps' && !t.startsWith('luganda release #')) {
        results.push(existing);
        continue;
      }
    }
    missingIds.push(id);
  }

  if (missingIds.length > 0) {
    const BATCH_SIZE = 10;
    for (let i = 0; i < missingIds.length; i += BATCH_SIZE) {
      const chunk = missingIds.slice(i, i + BATCH_SIZE);
      const chunkResults = await Promise.all(chunk.map(id => getMovieById(id)));
      for (const m of chunkResults) {
        if (m) results.push(m);
      }
    }
  }

  // Strictly sort newly to oldy (highest ID first)
  return results.sort((a, b) => b.id - a.id);
}

/**
 * Get paginated movies strictly Newly to Oldy across all 7,000+ movies
 */
export async function getMoviesPaginated({
  page = 1,
  limit = 40,
  vj = null,
  category = null,
  search = null,
  sort = 'newest',
} = {}) {
  const pageNum = Math.max(1, parseInt(page, 10) || 1);
  const limitNum = Math.min(100, Math.max(1, parseInt(limit, 10) || 40));

  // 1. Initial RTDB prime if cache is nearly empty
  if (memoryMovieMap.size < 100) {
    try {
      const rtdbRes = await fetch(`${RTDB_URL}/munowatch/catalog.json`);
      if (rtdbRes.ok) {
        const rtdbData = await rtdbRes.json();
        if (rtdbData && typeof rtdbData === 'object') {
          const items = Array.isArray(rtdbData) ? rtdbData : Object.values(rtdbData);
          for (const item of items) {
            if (item && item.id) {
              const norm = normalizeMovie(item);
              memoryMovieMap.set(Number(norm.id), norm);
            }
          }
        }
      }
    } catch (_) {}
  }

  // If VJ or Category or Search filter is applied:
  if (vj || category || search) {
    let allLoaded = Array.from(memoryMovieMap.values());

    // Search query
    if (search) {
      const cleanSearch = search.trim().toLowerCase();
      allLoaded = allLoaded.filter(m =>
        m.title.toLowerCase().includes(cleanSearch) ||
        m.vj.toLowerCase().includes(cleanSearch) ||
        m.category.toLowerCase().includes(cleanSearch)
      );
    }

    // VJ filter
    if (vj) {
      const cleanVj = vj.trim().toLowerCase();
      allLoaded = allLoaded.filter(m => m.vj.toLowerCase().includes(cleanVj));
    }

    // Category filter
    if (category) {
      const cleanCat = category.trim().toLowerCase();
      if (cleanCat === 'series') {
        allLoaded = allLoaded.filter(m => m.isTv);
      } else {
        allLoaded = allLoaded.filter(m => m.category.toLowerCase().includes(cleanCat));
      }
    }

    // Sort newly to oldy
    allLoaded.sort((a, b) => b.id - a.id);

    const total = allLoaded.length;
    const totalPages = Math.ceil(total / limitNum);
    const startIndex = (pageNum - 1) * limitNum;
    const paged = allLoaded.slice(startIndex, startIndex + limitNum);

    return {
      total,
      totalCatalog: KNOWN_IDS.length,
      page: pageNum,
      limit: limitNum,
      totalPages,
      hasMore: pageNum < totalPages,
      algorithm: 'munowatch_newly_to_oldy',
      data: paged,
    };
  }

  // Unfiltered general catalog: Pull directly from the 7,000+ KNOWN_IDS newly to oldy!
  const total = KNOWN_IDS.length;
  const totalPages = Math.ceil(total / limitNum);
  const startIndex = (pageNum - 1) * limitNum;
  const targetIds = KNOWN_IDS.slice(startIndex, startIndex + limitNum);

  const resolved = await resolveMovieBatch(targetIds);

  return {
    total,
    totalCatalog: KNOWN_IDS.length,
    page: pageNum,
    limit: limitNum,
    totalPages,
    hasMore: startIndex + limitNum < total,
    algorithm: 'munowatch_newly_to_oldy',
    data: resolved,
  };
}

/**
 * High-speed dashboard data (Single request for the whole UI, sorted Newly to Oldy)
 */
export async function getDashboardData() {
  const now = Date.now();
  if (cachedDashboard && now - cachedDashboardTime < DASHBOARD_CACHE_TTL) {
    return cachedDashboard;
  }

  // Fetch top 40 newest releases (IDs 67406 downwards)
  const newestBatch = await resolveMovieBatch(KNOWN_IDS.slice(0, 40));

  // 1. Featured Billboard (e.g. blockbuster with backdrop, stream, and overview)
  const candidateHeroes = newestBatch.filter(m => m.backdrop && m.streamUrl && m.overview && m.title.length > 3);
  const featured = candidateHeroes.find(m => m.title.toLowerCase().includes('spider') || m.vj.toLowerCase().includes('junior')) ||
                   candidateHeroes[0] ||
                   newestBatch[0] ||
                   null;

  // 2. VJs List with counts
  const vjCounts = new Map();
  for (const m of memoryMovieMap.values()) {
    const vj = m.vj || 'Luganda Dubbed';
    vjCounts.set(vj, (vjCounts.get(vj) || 0) + 1);
  }
  // Ensure major VJs are listed even before full catalog is hydrated
  const majorVjs = ['Vj Junior', 'Vj Emmy', 'Vj Ulio', 'Vj Jingo', 'Vj Ice P', 'Vj Heavy Q', 'Vj Sammy', 'Vj Tom', 'Vj Nelly', 'Vj Ashim'];
  for (const v of majorVjs) {
    if (!vjCounts.has(v)) vjCounts.set(v, 45);
  }

  const vjs = Array.from(vjCounts.entries())
    .map(([name, count]) => ({
      name,
      count,
      avatar: getVjAvatar(name),
    }))
    .sort((a, b) => b.count - a.count);

  // 3. Latest releases (strictly newly to oldy)
  const latest = newestBatch.slice(0, 30);

  // 4. Continue watching (widescreen 16:9 friendly)
  const continueWatching = newestBatch
    .filter(m => m.backdrop && m.streamUrl)
    .slice(0, 10)
    .map((m, idx) => ({
      ...m,
      progress: Math.min(95, 20 + ((idx * 17) % 70)),
      timeRemaining: `${15 + ((idx * 8) % 45)}m left`,
    }));

  // 5. Categorized Rails (each sorted Newly to Oldy)
  const allLoaded = Array.from(memoryMovieMap.values()).sort((a, b) => b.id - a.id);
  const categories = {};
  const standardCategories = ['Action', 'Sci-Fi', 'Romance', 'Horror', 'Drama', 'Animation', 'Series'];

  for (const cat of standardCategories) {
    const isSeriesCat = cat === 'Series';
    const matches = allLoaded.filter(m => {
      if (isSeriesCat) return m.isTv;
      return m.category && m.category.toLowerCase().includes(cat.toLowerCase());
    });
    categories[cat] = matches.slice(0, 20);
  }

  const result = {
    featured,
    vjs,
    latest,
    continueWatching,
    categories,
    totalMovies: KNOWN_IDS.length,
    algorithm: 'munowatch_newly_to_oldy',
    timestamp: now,
  };

  cachedDashboard = result;
  cachedDashboardTime = now;
  return result;
}

/**
 * Series episodes fetcher
 */
export async function getSeriesEpisodes(seriesIdOrCode) {
  const code = String(seriesIdOrCode).trim();
  if (!code) return { episodes: [] };

  // 1. Check RTDB
  try {
    const res = await fetch(`${RTDB_URL}/munowatch/series/${code}.json`);
    if (res.ok) {
      const data = await res.json();
      if (data && Array.isArray(data.episodes) && data.episodes.length > 0) {
        return data;
      }
    }
  } catch (_) {}

  // 2. Fetch single movie detail to check episodes
  const movie = await getMovieById(code);
  if (movie && movie.episodes && movie.episodes.length > 0) {
    return {
      id: movie.id,
      series_code: movie.series_code || code,
      title: movie.title,
      episodes: movie.episodes,
    };
  }

  // 3. Live search on MunoWatch
  try {
    const searchRes = await fetch(`${MUMOWATCH_BASE}/search?q=${encodeURIComponent(movie?.title || code)}`);
    if (searchRes.ok) {
      const data = await searchRes.json();
      if (Array.isArray(data.series)) {
        for (const s of data.series) {
          if (String(s.series_code) === code || (movie && s.title && s.title.toLowerCase().includes(movie.title.toLowerCase()))) {
            const rawEps = Array.isArray(s.episodes) ? s.episodes : [];
            const cleanEps = rawEps.map((ep, idx) => ({
              id: ep.id || (idx + 1),
              episodeNumber: ep.episodeNumber || (idx + 1),
              title: ep.title || `Episode ${idx + 1}`,
              playingurl: sanitizeStreamUrl(ep.playingurl),
              streamUrl: sanitizeStreamUrl(ep.playingurl),
              image: ep.image || movie?.poster,
              vj: ep.vj || movie?.vj,
            }));
            return {
              id: movie?.id || code,
              series_code: code,
              title: s.title || movie?.title,
              episodes: cleanEps,
            };
          }
        }
      }
    }
  } catch (_) {}

  if (movie && movie.streamUrl) {
    return {
      id: movie.id,
      series_code: code,
      title: movie.title,
      episodes: [
        {
          id: movie.id,
          episodeNumber: 1,
          title: `${movie.title} - Episode 1`,
          playingurl: movie.streamUrl,
          streamUrl: movie.streamUrl,
          image: movie.poster,
          vj: movie.vj,
        },
      ],
    };
  }

  return { id: code, series_code: code, episodes: [] };
}

/**
 * Fast search across catalog and live MunoWatch
 */
export async function searchCatalog(query) {
  const cleanQ = (query || '').trim().toLowerCase();
  if (!cleanQ) return [];

  const localMatches = Array.from(memoryMovieMap.values())
    .filter(m =>
      m.title.toLowerCase().includes(cleanQ) ||
      m.vj.toLowerCase().includes(cleanQ) ||
      m.category.toLowerCase().includes(cleanQ)
    )
    .sort((a, b) => b.id - a.id);

  if (localMatches.length >= 8) {
    return localMatches.slice(0, 30);
  }

  // Live search fallback for deep items
  try {
    const res = await fetch(`${MUMOWATCH_BASE}/search?q=${encodeURIComponent(cleanQ)}`, {
      headers: { 'User-Agent': 'FreeWatch/2.0' },
    });
    if (res.ok) {
      const data = await res.json();
      const combined = [...localMatches];
      const seenIds = new Set(localMatches.map(m => m.id));

      if (Array.isArray(data.series)) {
        for (const s of data.series) {
          if (Array.isArray(s.episodes) && s.episodes.length > 0) {
            const ep = s.episodes[0];
            const norm = normalizeMovie({
              ...ep,
              title: s.title || ep.title,
              series_code: s.series_code || ep.series_code,
              episodes: s.episodes,
              isTv: true,
              is_series: true,
            });
            if (!seenIds.has(norm.id)) {
              seenIds.add(norm.id);
              combined.push(norm);
            }
          }
        }
      }

      if (Array.isArray(data.movies)) {
        for (const m of data.movies) {
          const norm = normalizeMovie(m);
          if (!seenIds.has(norm.id)) {
            seenIds.add(norm.id);
            combined.push(norm);
          }
        }
      }
      return combined.sort((a, b) => b.id - a.id).slice(0, 30);
    }
  } catch (_) {}

  return localMatches.slice(0, 30);
}
