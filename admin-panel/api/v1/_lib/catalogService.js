/**
 * FreeWatch High-Speed Backend API Service Layer
 * Aggregates, enriches, and caches MunoWatch data directly from Firebase RTDB
 * and live MunoWatch endpoints.
 */

const RTDB_URL = 'https://freewatch-a0bc7-default-rtdb.firebaseio.com';
const MUMOWATCH_BASE = 'https://mumowatch.ai.studio';
const FALLBACK_BASE = 'https://munowatch.ai.studio';

// In-memory cache for ultra-fast serverless reuse (sub-10ms response)
let cachedCatalog = null;
let cachedCatalogTime = 0;
const CACHE_TTL_MS = 5 * 60 * 1000; // 5 minutes

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

/**
 * Fetch raw catalog from Firebase RTDB with fast fallback
 */
export async function getFullCatalog(forceRefresh = false) {
  const now = Date.now();
  if (!forceRefresh && cachedCatalog && now - cachedCatalogTime < CACHE_TTL_MS) {
    return cachedCatalog;
  }

  let catalogMap = new Map();

  // 1. Fetch from Firebase RTDB (enriched catalog)
  try {
    const res = await fetch(`${RTDB_URL}/munowatch/catalog.json`, {
      headers: { 'Accept': 'application/json' },
    });
    if (res.ok) {
      const data = await res.json();
      if (data && typeof data === 'object') {
        const items = Array.isArray(data) ? data : Object.values(data);
        for (const item of items) {
          if (item && item.id) {
            const cleanObj = normalizeMovie(item);
            catalogMap.set(Number(cleanObj.id), cleanObj);
          }
        }
      }
    }
  } catch (err) {
    console.warn('⚠️ [CatalogService] Error fetching from RTDB:', err.message);
  }

  // 2. If RTDB had fewer than 10 items, fall back to MunoWatch live dashboard
  if (catalogMap.size < 10) {
    try {
      const urls = [
        `${MUMOWATCH_BASE}/dashboard`,
        `${FALLBACK_BASE}/dashboard`,
      ];
      for (const u of urls) {
        try {
          const res = await fetch(u, {
            headers: { 'User-Agent': 'FreeWatch/2.0 (Serverless)' },
          });
          if (res.ok) {
            const dash = await res.json();
            const rawMovies = [
              ...(Array.isArray(dash.movies) ? dash.movies : []),
              ...(Array.isArray(dash.dashboard) ? dash.dashboard.flatMap(d => d.movies || []) : []),
            ];
            for (const m of rawMovies) {
              if (m && (m.id || m.vid)) {
                const norm = normalizeMovie(m);
                if (!catalogMap.has(Number(norm.id))) {
                  catalogMap.set(Number(norm.id), norm);
                }
              }
            }
            if (catalogMap.size >= 10) break;
          }
        } catch (_) {}
      }
    } catch (err) {
      console.warn('⚠️ [CatalogService] Error fetching from MunoWatch live:', err.message);
    }
  }

  const list = Array.from(catalogMap.values());
  cachedCatalog = list;
  cachedCatalogTime = now;
  return list;
}

export function normalizeMovie(raw) {
  const id = Number(raw.id || raw.vid);
  const rawTitle = raw.title || raw.name || '';
  const rawVj = raw.vj || raw.vjName || '';
  const { title, vj } = extractTitleAndVj(rawTitle, rawVj);

  const cleanTitle = (title && title.toLowerCase() !== 'movie') ? title : `Luganda Action Release #${id}`;
  const poster = raw.poster_path || raw.image || raw.poster || 'https://apposters.b-cdn.net/laba/yo/naki/01d9.jpg';
  const backdrop = raw.backdrop_path || raw.backdrop || poster;
  const streamUrl = sanitizeStreamUrl(raw.streamUrl || raw.playingurl || raw.videoUrl || '');
  const category = (raw.category || 'Action').replace(/Munowatch/gi, 'FreeWatch').trim();
  const isSeries = Boolean(raw.isTv || raw.is_series || (raw.series_code && raw.series_code !== '0' && String(raw.series_code) !== String(id)));

  return {
    id,
    title: cleanTitle,
    vj: vj || 'Luganda Dubbed',
    category,
    category_id: raw.category_id || 10,
    poster,
    poster_path: poster,
    backdrop,
    backdrop_path: backdrop,
    image: poster,
    overview: raw.overview || raw.synopsis || raw.description || `Official Luganda translated cinema release presented by ${vj}.`,
    rating: raw.rating || raw.vote_average?.toString() || '8.5',
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
 * Compile high-speed dashboard data (Single request for the whole UI)
 */
export async function getDashboardData() {
  const catalog = await getFullCatalog();

  // 1. Featured Hero
  const candidateHeroes = catalog.filter(m => m.backdrop && m.streamUrl && m.overview && m.title.length > 3);
  const featured = candidateHeroes.find(m => m.title.toLowerCase().includes('spider') || m.vj.toLowerCase().includes('junior')) ||
                   candidateHeroes[0] ||
                   catalog[0] ||
                   null;

  // 2. VJs List with accurate dynamic counts
  const vjCounts = new Map();
  for (const m of catalog) {
    const vj = m.vj || 'Luganda Dubbed';
    vjCounts.set(vj, (vjCounts.get(vj) || 0) + 1);
  }

  const vjs = Array.from(vjCounts.entries())
    .map(([name, count]) => ({
      name,
      count,
      avatar: getVjAvatar(name),
    }))
    .sort((a, b) => b.count - a.count);

  // 3. Latest releases
  const latest = catalog
    .slice(0, 20)
    .sort((a, b) => b.id - a.id);

  // 4. Continue watching (widescreen 16:9 friendly)
  const continueWatching = catalog
    .filter(m => m.backdrop && m.streamUrl)
    .slice(0, 10)
    .map((m, idx) => ({
      ...m,
      progress: Math.min(95, 20 + ((idx * 17) % 70)),
      timeRemaining: `${15 + ((idx * 8) % 45)}m left`,
    }));

  // 5. Categorized Rails
  const categories = {};
  const standardCategories = ['Action', 'Sci-Fi', 'Romance', 'Horror', 'Drama', 'Animation', 'Series'];

  for (const cat of standardCategories) {
    const isSeriesCat = cat === 'Series';
    const matches = catalog.filter(m => {
      if (isSeriesCat) return m.isTv;
      return m.category && m.category.toLowerCase().includes(cat.toLowerCase());
    });
    categories[cat] = matches.slice(0, 15);
  }

  return {
    featured,
    vjs,
    latest,
    continueWatching,
    categories,
    totalMovies: catalog.length,
    timestamp: Date.now(),
  };
}

/**
 * Fetch full movie details with on-demand fallback
 */
export async function getMovieById(movieId) {
  const id = Number(movieId);
  if (!id) return null;

  // 1. Check RTDB directly first
  try {
    const res = await fetch(`${RTDB_URL}/munowatch/catalog/${id}.json`);
    if (res.ok) {
      const data = await res.json();
      if (data && data.id) {
        return normalizeMovie(data);
      }
    }
  } catch (_) {}

  // 2. Fallback to MunoWatch live /movie/:id
  try {
    const urls = [
      `${MUMOWATCH_BASE}/movie/${id}`,
      `${FALLBACK_BASE}/movie/${id}`,
    ];
    for (const u of urls) {
      try {
        const res = await fetch(u, {
          headers: { 'User-Agent': 'FreeWatch/2.0' },
        });
        if (res.ok) {
          const detail = await res.json();
          if (detail && (detail.title || detail.playingurl)) {
            return normalizeMovie(detail);
          }
        }
      } catch (_) {}
    }
  } catch (_) {}

  return null;
}

/**
 * Fetch series with all seasons & episodes pre-indexed
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

  // Fallback: If single movie has streamUrl, return episode 1
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

  const catalog = await getFullCatalog();
  const localMatches = catalog.filter(m =>
    m.title.toLowerCase().includes(cleanQ) ||
    m.vj.toLowerCase().includes(cleanQ) ||
    m.category.toLowerCase().includes(cleanQ)
  );

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
          if (Array.isArray(s.episodes)) {
            for (const ep of s.episodes) {
              const norm = normalizeMovie(ep);
              if (!seenIds.has(norm.id)) {
                seenIds.add(norm.id);
                combined.push(norm);
              }
            }
          }
        }
      }
      return combined.slice(0, 30);
    }
  } catch (_) {}

  return localMatches.slice(0, 30);
}
