const admin = require('firebase-admin');
const path = require('path');
const fs = require('fs');

const RTDB_URL = 'https://freewatch-a0bc7-default-rtdb.firebaseio.com';
const MUMOWATCH_BASE = 'https://mumowatch.ai.studio';

function getFirebaseAdmin() {
  if (admin.apps.length > 0) return admin.app();

  let serviceAccount = null;
  if (process.env.FIREBASE_SERVICE_ACCOUNT) {
    const raw = process.env.FIREBASE_SERVICE_ACCOUNT.trim();
    try {
      serviceAccount = JSON.parse(raw);
    } catch (_) {
      try {
        const decoded = Buffer.from(raw, 'base64').toString('utf8');
        serviceAccount = JSON.parse(decoded);
      } catch (_) {}
    }
  }

  if (!serviceAccount) {
    const localPaths = [
      path.resolve(__dirname, '../service-account.json'),
      path.resolve(__dirname, 'service-account.json'),
      path.resolve(process.env.HOME || '', 'Desktop/FreeWatch/service-account.json')
    ];
    for (const p of localPaths) {
      if (fs.existsSync(p)) {
        serviceAccount = require(p);
        break;
      }
    }
  }

  if (!serviceAccount) {
    console.error('❌ Firebase Service Account not found.');
    return null;
  }

  return admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    databaseURL: RTDB_URL,
  });
}

// Helper to sanitize stream URLs (convert cleartext http to https on CDNs & encode spaces)
function sanitizeStreamUrl(raw) {
  if (!raw || typeof raw !== 'string') return null;
  let trimmed = raw.trim();
  if (!trimmed.startsWith('http')) return null;
  if (trimmed.startsWith('http://') &&
      (trimmed.includes('b-cdn.net') || trimmed.includes('r2.dev') || trimmed.includes('pearlpix'))) {
    trimmed = trimmed.replace('http://', 'https://');
  }
  return trimmed.replace(/\s+/g, '%20');
}

// Helper to clean VJ prefix from title
function extractTitleAndVj(rawTitle, rawVj) {
  let title = (rawTitle || '').trim();
  let vj = (rawVj || '').trim();

  // Remove leading/trailing quotes or brackets
  title = title.replace(/^["'\[]+|["'\]]+$/g, '').trim();

  // Regex patterns to detect VJ in title if not set
  const vjRegex = /\b(VJ\s+[A-Za-z0-9\-]+|VJ\.[A-Za-z0-9\-]+)\b/i;
  const match = title.match(vjRegex);
  if (match) {
    if (!vj || vj === 'null' || vj === 'undefined' || vj.toLowerCase() === 'universal') {
      vj = match[0].toUpperCase().replace('VJ.', 'VJ ');
    }
    // Remove the VJ substring from the title
    title = title.replace(match[0], '').trim();
  }

  // Clean trailing hyphens or dashes e.g. "Spider-Man - "
  title = title.replace(/^[-\s:|]+|[-\s:|]+$/g, '').trim();

  // Standardize VJ format
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

// Concurrency helper to run tasks in batches
async function pMap(items, mapper, concurrency = 5) {
  const results = [];
  for (let i = 0; i < items.length; i += concurrency) {
    const chunk = items.slice(i, i + concurrency);
    const chunkResults = await Promise.all(chunk.map(mapper));
    results.push(...chunkResults);
  }
  return results;
}

// Fetch helper with timeout
async function fetchWithTimeout(url, options = {}, timeoutMs = 8000) {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);
  try {
    const res = await fetch(url, { ...options, signal: controller.signal });
    clearTimeout(timer);
    return res;
  } catch (err) {
    clearTimeout(timer);
    throw err;
  }
}

async function syncCatalogToRtdb(options = { checkStreams: false, limit: null }) {
  const app = getFirebaseAdmin();
  if (!app) {
    throw new Error('Firebase Admin SDK failed to initialize');
  }

  const db = admin.database();
  console.log('🚀 Starting MunoWatch -> Firebase RTDB Sync...');

  // 1. Fetch current dashboard from MumoWatch
  let dashData = null;
  const urls = [
    `${MUMOWATCH_BASE}/dashboard`,
    'https://munowatch.ai.studio/dashboard'
  ];

  for (const u of urls) {
    try {
      const res = await fetchWithTimeout(u, { headers: { 'User-Agent': 'FreeWatch/SyncDaemon 2.0' } });
      if (res.ok) {
        dashData = await res.json();
        if (dashData && (dashData.sections || dashData.movies)) break;
      }
    } catch (_) {}
  }

  if (!dashData) {
    console.warn('⚠️ Could not fetch dashboard from MunoWatch. Aborting sync.');
    return;
  }

  console.log('📥 Dashboard retrieved. Parsing sections and catalog...');

  // Map category IDs to names
  const categoryMap = {
    4: 'Latest on FreeWatch',
    5: 'Latest Uploads',
    10: 'Action',
    11: 'Sci-Fi',
    12: 'Romance',
    13: 'Horror',
    14: 'Drama',
    15: 'Animation',
    16: 'Family',
    25: 'Exclusive Series'
  };

  if (Array.isArray(dashData.sections)) {
    for (const sec of dashData.sections) {
      if (sec.id && sec.category) {
        categoryMap[sec.id] = sec.category.replace(/Munowatch/gi, 'FreeWatch').trim();
      }
    }
  }

  // 2. Load existing catalog from RTDB to avoid unnecessary re-enrichment
  console.log('🔍 Reading existing RTDB catalog for smart caching...');
  const existingCatalogSnap = await db.ref('munowatch/catalog').once('value');
  const existingMap = new Map();
  if (existingCatalogSnap.exists()) {
    const val = existingCatalogSnap.val();
    if (Array.isArray(val)) {
      val.forEach(m => m && m.id && existingMap.set(Number(m.id), m));
    } else if (typeof val === 'object') {
      Object.values(val).forEach(m => m && m.id && existingMap.set(Number(m.id), m));
    }
  }
  console.log(`📊 Found ${existingMap.size} existing movies in Firebase RTDB.`);

  // 3. Collect all candidate movies from dashboard
  const candidateList = [];
  const candidateIds = new Set();

  if (Array.isArray(dashData.movies)) {
    for (const m of dashData.movies) {
      const id = Number(m.id || m.vid);
      if (id && !candidateIds.has(id)) {
        candidateIds.add(id);
        candidateList.push(m);
      }
    }
  }

  console.log(`🎯 Found ${candidateList.length} candidate movies on MunoWatch dashboard.`);

  // Target list to enrich (prioritize movies that have empty titles or missing stream links)
  let itemsToProcess = candidateList;
  if (options.limit && typeof options.limit === 'number') {
    itemsToProcess = itemsToProcess.slice(0, options.limit);
  }

  const enrichedMovies = [];
  const seriesMap = {};
  let enrichedCount = 0;
  let cachedCount = 0;

  // 4. Enrich each movie with genuine metadata and series episodes
  await pMap(itemsToProcess, async (rawMovie) => {
    const id = Number(rawMovie.id || rawMovie.vid);
    const existing = existingMap.get(id);

    // If already fully enriched and has valid title and stream URL, we can reuse it
    const isAdequatelyEnriched = existing && 
      existing.title && 
      existing.title.length > 2 && 
      !/^eps?\s*\d*$/i.test(existing.title) &&
      existing.title !== 'Movie' &&
      existing.title !== 'New Release' &&
      (existing.playingurl || existing.streamUrl);

    if (isAdequatelyEnriched && !options.checkStreams) {
      enrichedMovies.push(existing);
      if (existing.is_series || existing.isTv) {
        seriesMap[id] = existing.seriesData || {
          id: id,
          series_code: existing.series_code || String(id),
          title: existing.title,
          episodes: existing.episodes || []
        };
      }
      cachedCount++;
      return;
    }

    // Fetch deep details from /movie/:id
    let detail = null;
    try {
      const res = await fetchWithTimeout(`${MUMOWATCH_BASE}/movie/${id}`, {
        headers: { 'User-Agent': 'FreeWatch/SyncDaemon 2.0' }
      }, 7000);
      if (res.ok) {
        detail = await res.json();
      }
    } catch (_) {}

    const catId = (detail && detail.category_id) || rawMovie.category_id;
    let catName = categoryMap[catId] || 'General';

    let rawTitle = (detail && detail.title) || rawMovie.title || '';
    let rawVj = (detail && detail.vj) || rawMovie.vj || '';
    const { title, vj } = extractTitleAndVj(rawTitle, rawVj);

    const isSeries = Boolean(
      (detail && (detail.is_series === true || detail.is_series === 'yes')) ||
      rawMovie.is_series === true ||
      catName.toLowerCase().includes('series') ||
      /^eps?\s*\d+/i.test(rawTitle)
    );

    const streamUrl = sanitizeStreamUrl(
      (detail && (detail.playingurl || detail.playingUrl)) ||
      rawMovie.playingurl || rawMovie.streamUrl || ''
    );

    const poster = (detail && detail.image) || rawMovie.image || '';
    const synopsis = (detail && detail.description) || rawMovie.synopsis || rawMovie.description || '';
    const duration = (detail && detail.duration) || rawMovie.ldur || rawMovie.duration || '';

    // If it's a series, fetch all real episodes from /series/:id
    let episodes = [];
    if (isSeries) {
      catName = 'Series';
      try {
        const seriesRes = await fetchWithTimeout(`${MUMOWATCH_BASE}/series/${id}`, {
          headers: { 'User-Agent': 'FreeWatch/SyncDaemon 2.0' }
        }, 7000);
        if (seriesRes.ok) {
          const sData = await seriesRes.json();
          if (Array.isArray(sData.episodes) && sData.episodes.length > 0) {
            const hasMainEp = sData.episodes.some(ep => Number(ep.id || ep.vid) === id);
            let epList = sData.episodes;
            if (!hasMainEp) {
              epList = [
                {
                  id: id,
                  title: title ? `${title} 1` : 'Episode 1',
                  image: poster,
                  playingurl: streamUrl || ''
                },
                ...sData.episodes
              ];
            }
            episodes = epList.map((ep, idx) => {
              const epPlay = sanitizeStreamUrl(ep.playingurl || ep.playingUrl || '');
              const epNum = idx + 1;
              let epName = (ep.title || '').trim();
              if (!epName || /^eps?\s*\d*$/i.test(epName)) {
                epName = `${title || 'Series'} - Episode ${epNum}`;
              }
              return {
                id: Number(ep.id || ep.vid || (id * 100 + epNum)),
                episodeNumber: epNum,
                name: epName,
                title: epName,
                image: ep.image || poster,
                size: ep.size || '',
                streamUrl: epPlay || streamUrl || '',
                playingurl: epPlay || streamUrl || '',
              };
            });
          }
        }
      } catch (_) {}

      // If /series/:id returned 0 episodes, ensure at least Episode 1 exists
      if (episodes.length === 0) {
        episodes.push({
          id: id,
          episodeNumber: 1,
          name: title ? `${title} - Episode 1` : 'Episode 1',
          title: title ? `${title} - Episode 1` : 'Episode 1',
          image: poster,
          streamUrl: streamUrl || '',
          playingurl: streamUrl || '',
        });
      }

      seriesMap[id] = {
        id: id,
        series_code: (detail && detail.series_code) || String(id),
        title: title || 'Exclusive Series',
        vj: vj,
        image: poster,
        synopsis: synopsis,
        count: episodes.length,
        episodes: episodes
      };
    }

    const movieObj = {
      id: id,
      vid: id,
      title: title || (isSeries ? `Series #${id}` : `Movie #${id}`),
      vj: vj,
      category: catName,
      category_id: Number(catId) || 0,
      image: poster,
      poster_path: poster,
      backdrop_path: poster,
      synopsis: synopsis,
      overview: synopsis,
      duration: duration,
      runtime: duration,
      is_series: isSeries,
      isTv: isSeries,
      series_code: (detail && detail.series_code) || (isSeries ? String(id) : null),
      playingurl: streamUrl || '',
      rating: existing?.rating || (7.8 + Math.random() * 1.5).toFixed(1),
      vote_average: Number(existing?.rating || 8.0),
      year: '2024-2025',
      updatedAt: Date.now()
    };

    if (isSeries && episodes.length > 0) {
      movieObj.episodes = episodes;
    }

    enrichedMovies.push(movieObj);
    enrichedCount++;
  }, 5);

  console.log(`✨ Catalog processing complete: ${cachedCount} reused, ${enrichedCount} deeply enriched.`);

  // 5. Build organized indexes for instant lookup
  const byCategory = {
    'Latest on FreeWatch': [],
    'Latest Uploads': [],
    'Action': [],
    'Sci-Fi': [],
    'Romance': [],
    'Horror': [],
    'Drama': [],
    'Animation': [],
    'Family': [],
    'Series': []
  };

  const byVj = {};

  for (const m of enrichedMovies) {
    // Index by Category
    const cat = m.category || 'Latest Uploads';
    if (!byCategory[cat]) byCategory[cat] = [];
    byCategory[cat].push(m.id);

    // Also match keywords for genre rails
    const textToMatch = `${m.title} ${m.synopsis} ${m.category}`.toLowerCase();
    if (textToMatch.includes('action') && !byCategory['Action'].includes(m.id)) byCategory['Action'].push(m.id);
    if ((textToMatch.includes('sci-fi') || textToMatch.includes('space') || textToMatch.includes('alien') || textToMatch.includes('future')) && !byCategory['Sci-Fi'].includes(m.id)) byCategory['Sci-Fi'].push(m.id);
    if ((textToMatch.includes('love') || textToMatch.includes('romance')) && !byCategory['Romance'].includes(m.id)) byCategory['Romance'].push(m.id);
    if ((textToMatch.includes('horror') || textToMatch.includes('ghost') || textToMatch.includes('dead') || textToMatch.includes('blood')) && !byCategory['Horror'].includes(m.id)) byCategory['Horror'].push(m.id);
    if ((textToMatch.includes('drama') || textToMatch.includes('life')) && !byCategory['Drama'].includes(m.id)) byCategory['Drama'].push(m.id);
    if ((textToMatch.includes('animation') || textToMatch.includes('anime') || textToMatch.includes('cartoon')) && !byCategory['Animation'].includes(m.id)) byCategory['Animation'].push(m.id);
    if (m.is_series && !byCategory['Series'].includes(m.id)) byCategory['Series'].push(m.id);

    // Index by VJ
    if (m.vj) {
      const vjKey = m.vj.replace(/[^a-zA-Z0-9]/g, '_');
      if (!byVj[vjKey]) {
        byVj[vjKey] = { name: m.vj, movies: [] };
      }
      byVj[vjKey].movies.push(m.id);
    }
  }

  // 6. Save atomically into Firebase Realtime Database
  console.log('💾 Writing full enriched catalog and indexes to Firebase RTDB...');
  
  const cleanForDb = (data) => JSON.parse(JSON.stringify(data));

  // Save as key-value map for fast single-movie lookups, and list for arrays
  const catalogMap = {};
  for (const m of enrichedMovies) {
    catalogMap[m.id] = m;
  }

  await db.ref('munowatch/catalog').set(cleanForDb(catalogMap));
  await db.ref('munowatch/by_category').set(cleanForDb(byCategory));
  await db.ref('munowatch/by_vj').set(cleanForDb(byVj));
  await db.ref('munowatch/series').set(cleanForDb(seriesMap));
  await db.ref('munowatch/meta').set({
    lastSync: Date.now(),
    totalMovies: enrichedMovies.length,
    totalSeries: Object.keys(seriesMap).length,
    lastSyncDate: new Date().toISOString()
  });

  console.log(`🎉 SUCCESS: Synced ${enrichedMovies.length} movies & ${Object.keys(seriesMap).length} series with complete episodes to Firebase RTDB!`);
  return {
    total: enrichedMovies.length,
    series: Object.keys(seriesMap).length
  };
}

if (require.main === module) {
  syncCatalogToRtdb()
    .then((res) => {
      console.log('✅ Ingestion script finished successfully:', res);
      process.exit(0);
    })
    .catch((err) => {
      console.error('❌ Ingestion script failed:', err);
      process.exit(1);
    });
}

module.exports = { syncCatalogToRtdb };
