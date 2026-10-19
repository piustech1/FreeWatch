const admin = require('firebase-admin');
const path = require('path');
const fs = require('fs');

const RTDB_URL = 'https://freewatch-a0bc7-default-rtdb.firebaseio.com';

function getFirebaseAdmin() {
  if (admin.apps.length > 0) return admin.app();

  let serviceAccount = null;
  if (process.env.FIREBASE_SERVICE_ACCOUNT) {
    try {
      serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
    } catch (_) {}
  }

  if (!serviceAccount) {
    const localPaths = [
      path.resolve(__dirname, 'service-account.json'),
      path.resolve(__dirname, '../service-account.json'),
      path.resolve(__dirname, '../../service-account.json'),
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
    throw new Error('service-account.json not configured in FIREBASE_SERVICE_ACCOUNT or file');
  }

  return admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    databaseURL: RTDB_URL,
  });
}

module.exports = async (req, res) => {
  try {
    const app = getFirebaseAdmin();

    const urls = [
      'https://munowatch.ai.studio/api/dashboard',
      'https://munowatch.ai.studio/dashboard'
    ];

    let data = null;
    for (const u of urls) {
      try {
        const response = await fetch(u, { headers: { 'User-Agent': 'FreeWatch/1.0 (Vercel)' } });
        if (response.ok) {
          data = await response.json();
          if (data && (data.dashboard || data.movies)) break;
        }
      } catch (_) {}
    }

    if (!data) {
      return res.status(200).json({ status: 'skip', message: 'MunoWatch dashboard unavailable' });
    }

    const allMovies = [];
    const idMap = new Map();

    if (Array.isArray(data.dashboard)) {
      for (const cat of data.dashboard) {
        if (Array.isArray(cat.movies)) {
          for (const m of cat.movies) {
            const mId = m.id || m.vid;
            if (mId && !idMap.has(mId)) {
              idMap.set(mId, m);
              allMovies.push(m);
            }
          }
        }
      }
    }

    if (Array.isArray(data.movies)) {
      for (const m of data.movies) {
        const mId = m.id || m.vid;
        if (mId && !idMap.has(mId)) {
          idMap.set(mId, m);
          allMovies.push(m);
        }
      }
    }

    const currentIds = allMovies.map(m => String(m.id || m.vid));

    let knownIds = [];
    try {
      const knownRes = await fetch(`${RTDB_URL}/munowatch/known_movie_ids/list.json`);
      if (knownRes.ok) {
        const val = await knownRes.json();
        if (Array.isArray(val)) knownIds = val;
      }
    } catch (_) {}

    const knownSet = new Set(knownIds.map(String));

    if (knownSet.size === 0) {
      await fetch(`${RTDB_URL}/munowatch/known_movie_ids/list.json`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(currentIds)
      });
      return res.status(200).json({ status: 'initialized', total: currentIds.length });
    }

    const newMovies = allMovies.filter(m => !knownSet.has(String(m.id || m.vid)));

    if (newMovies.length === 0) {
      return res.status(200).json({ status: 'no_new_movies', activeTotal: currentIds.length });
    }

    for (const m of newMovies) {
      knownSet.add(String(m.id || m.vid));
    }
    await fetch(`${RTDB_URL}/munowatch/known_movie_ids/list.json`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(Array.from(knownSet))
    });

    const dispatched = [];
    for (const movie of newMovies.slice(0, 3)) {
      const movieId = String(movie.id || movie.vid || '');
      let title = (movie.title || movie.name || '').trim();
      let vj = (movie.vj || movie.vjName || '').trim();
      let imageUrl = movie.image || movie.poster || movie.backdrop || '';

      // Always enrich from /movie/:id to retrieve genuine title and VJ name
      try {
        const detailRes = await fetch(`https://mumowatch.ai.studio/movie/${movieId}`, {
          headers: { 'User-Agent': 'FreeWatch/1.0 (Vercel Cron)' }
        });
        if (detailRes.ok) {
          const detail = await detailRes.json();
          if (detail) {
            if (detail.title && detail.title.trim()) {
              title = detail.title.trim();
            }
            if (detail.vj && detail.vj.trim()) {
              vj = detail.vj.trim();
            }
            if (detail.image && detail.image.trim() && !imageUrl) {
              imageUrl = detail.image.trim();
            }
            if (detail.is_series && !title.toLowerCase().includes('episode') && !title.toLowerCase().includes('eps')) {
              title = `${title} (New Episode)`;
            }
          }
        }
      } catch (e) {
        console.warn(`[Vercel Cron] Metadata enrichment failed for ID ${movieId}:`, e.message);
      }

      // Format VJ name cleanly
      if (vj && vj !== 'null' && vj !== 'undefined') {
        if (!vj.toUpperCase().startsWith('VJ ') && !vj.toUpperCase().startsWith('VJ.')) {
          vj = `VJ ${vj}`;
        }
      } else {
        vj = 'Luganda Dubbed';
      }

      // Strict guard: Never broadcast blank, placeholder, or bare episode titles
      if (!title || title.toLowerCase() === 'new release' || title.toLowerCase() === 'movie') {
        console.log(`⚠️ [Vercel Cron] Suppressing notification for ID ${movieId}: Title could not be resolved ("${title}").`);
        continue;
      }
      if (/^eps?\s*\d*$/i.test(title)) {
        console.log(`⚠️ [Vercel Cron] Suppressing notification for ID ${movieId}: Bare episode tag with no series name ("${title}").`);
        continue;
      }

      const body = `New Release: ${title} translated by ${vj} is now streaming on FreeWatch!`;

      const message = {
        topic: 'all_users',
        notification: { title, body },
        data: {
          title,
          body,
          imageUrl: imageUrl || '',
          movieId,
          timestamp: String(Date.now()),
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
        },
        android: {
          priority: 'high',
          notification: {
            channelId: 'freewatch_alerts',
            priority: 'max',
            defaultSound: true,
            defaultVibrateTimings: true,
            icon: 'ic_notification',
            imageUrl: imageUrl || undefined,
          },
        },
      };

      const resp = await app.messaging().send(message);
      dispatched.push({ title, fcmId: resp });
    }

    return res.status(200).json({ status: 'broadcasted', count: dispatched.length, items: dispatched });
  } catch (err) {
    console.error('Vercel cron error:', err);
    return res.status(500).json({ error: err.message });
  }
};
