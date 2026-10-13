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
    throw new Error('service-account.json not found in environment or disk');
  }

  return admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    databaseURL: RTDB_URL,
  });
}

async function run() {
  const app = getFirebaseAdmin();
  console.log('☁️ FreeWatch Cloud MunoWatch Checker started.');

  // 1. Fetch current MunoWatch dashboard
  const urls = [
    'https://munowatch.ai.studio/api/dashboard',
    'https://munowatch.ai.studio/dashboard',
    'https://mumowatch.ai.studio/dashboard'
  ];

  let data = null;
  for (const u of urls) {
    try {
      const res = await fetch(u, { headers: { 'User-Agent': 'FreeWatch/1.0 (Cloud)' } });
      if (res.ok) {
        data = await res.json();
        if (data && (data.dashboard || data.movies)) break;
      }
    } catch (_) {}
  }

  if (!data) {
    console.warn('⚠️ Could not fetch MunoWatch dashboard.');
    return;
  }

  // 2. Collect all movies
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

  // 3. Read known IDs from Firebase Realtime Database
  let knownIds = [];
  try {
    const knownRes = await fetch(`${RTDB_URL}/munowatch/known_movie_ids/list.json`);
    if (knownRes.ok) {
      const val = await knownRes.json();
      if (Array.isArray(val)) {
        knownIds = val;
      }
    }
  } catch (e) {
    console.warn('Notice reading known IDs from RTDB:', e.message);
  }

  const knownSet = new Set(knownIds.map(String));

  // If first run in cloud, initialize DB with current IDs
  if (knownSet.size === 0) {
    await fetch(`${RTDB_URL}/munowatch/known_movie_ids/list.json`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(currentIds)
    });
    console.log(`🍿 Initialized cloud registry with ${currentIds.length} existing movies.`);
    return;
  }

  // 4. Detect new movies
  const newMovies = allMovies.filter(m => !knownSet.has(String(m.id || m.vid)));

  if (newMovies.length === 0) {
    console.log(`✅ No new movies detected. Total active: ${currentIds.length}.`);
    return;
  }

  console.log(`✨ Discovered ${newMovies.length} NEW movie(s) on MunoWatch!`);

  // Update cloud registry immediately
  for (const m of newMovies) {
    knownSet.add(String(m.id || m.vid));
  }
  await fetch(`${RTDB_URL}/munowatch/known_movie_ids/list.json`, {
    method: 'PUT',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(Array.from(knownSet))
  });

  // 5. Broadcast up to 3 newest releases
  for (const movie of newMovies.slice(0, 3)) {
    const vj = movie.vj || movie.vjName || 'Luganda Dubbed';
    const title = movie.title || movie.name || 'New Release';
    const body = `New Release: ${title} translated by ${vj} is now streaming on FreeWatch!`;
    const imageUrl = movie.image || movie.poster || movie.backdrop || '';
    const movieId = String(movie.id || movie.vid || '');

    const message = {
      topic: 'all_users',
      notification: {
        title,
        body,
      },
      data: {
        title,
        body,
        imageUrl: imageUrl || '',
        movieId: movieId,
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
      apns: {
        payload: {
          aps: {
            alert: { title, body },
            sound: 'default',
            'mutable-content': 1,
          },
        },
        fcmOptions: {
          image: imageUrl || undefined,
        },
      },
    };

    try {
      const resp = await app.messaging().send(message);
      console.log(`🚀 [Cloud Poller] Auto-broadcasted new movie: "${title}" (FCM ID: ${resp})`);

      await fetch(`${RTDB_URL}/push_notifications/history.json`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          id: resp,
          title,
          body,
          imageUrl,
          movieId,
          targetTopic: 'all_users',
          timestamp: Date.now(),
          dispatchedBy: 'Cloud MunoWatch Poller'
        })
      });
    } catch (fcmErr) {
      console.error(`❌ Failed to broadcast "${title}":`, fcmErr);
    }
  }
}

run()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error('Fatal cloud poller error:', err);
    process.exit(1);
  });
