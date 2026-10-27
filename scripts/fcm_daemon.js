const admin = require('firebase-admin');
const path = require('path');
const fs = require('fs');

// Look for service-account.json in project root or scripts folder
const possiblePaths = [
  path.resolve(__dirname, '../service-account.json'),
  path.resolve(__dirname, 'service-account.json'),
  path.resolve(process.env.HOME, 'Desktop/FreeWatch/service-account.json'),
  path.resolve(process.env.HOME, 'Downloads/service-account.json'),
];

let serviceAccountPath = possiblePaths.find((p) => fs.existsSync(p));

if (!serviceAccountPath) {
  // Also check if any freewatch admin SDK json exists in Downloads
  try {
    const downloadsDir = path.resolve(process.env.HOME, 'Downloads');
    const files = fs.readdirSync(downloadsDir);
    const match = files.find((f) => f.includes('freewatch') && f.endsWith('.json'));
    if (match) {
      serviceAccountPath = path.join(downloadsDir, match);
    }
  } catch (_) {}
}

if (!serviceAccountPath) {
  console.error('❌ service-account.json not found!');
  console.error('👉 Download it from Firebase Console > Project Settings > Service Accounts > Generate new private key');
  console.error('👉 Place it at: /Users/piustech/Desktop/FreeWatch/service-account.json');
  process.exit(1);
}

console.log(`🔑 Using Service Account from: ${serviceAccountPath}`);
const serviceAccount = require(serviceAccountPath);

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: 'https://freewatch-a0bc7-default-rtdb.firebaseio.com',
});

console.log('🚀 FreeWatch FCM Notification Daemon started.');
console.log('📡 Listening to Firebase RTDB at: /global_alerts/latest');

let initialLoadAlertsDone = false;
let lastDispatchedTimestamp = 0;

admin.database().ref('global_alerts/latest').on('value', async (snapshot) => {
  if (!initialLoadAlertsDone) {
    initialLoadAlertsDone = true;
    const initialData = snapshot.val();
    if (initialData && initialData.timestamp) {
      lastDispatchedTimestamp = initialData.timestamp;
    }
    console.log('👀 Connected to Firebase RTDB. Ready to broadcast whenever new movies/alerts are published!');
    return;
  }

  const data = snapshot.val();
  if (!data || !data.title) return;

  // Prevent duplicate broadcasts if same timestamp
  if (data.timestamp && data.timestamp <= lastDispatchedTimestamp) {
    return;
  }
  lastDispatchedTimestamp = data.timestamp || Date.now();

  const title = data.title || '🔥 New Luganda VJ Release!';
  const body = data.body || 'New translated blockbuster is now streaming in Full HD. Tap to watch!';
  const imageUrl = data.imageUrl || data.image_url || '';
  const movieId = data.movieId || '';
  const targetTopic = data.targetTopic || 'all_users';

  const message = {
    topic: targetTopic,
    notification: {
      title,
      body,
    },
    data: {
      title,
      body,
      imageUrl: imageUrl || '',
      movieId: String(movieId || ''),
      timestamp: String(data.timestamp || Date.now()),
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
          alert: {
            title,
            body,
          },
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
    const response = await admin.messaging().send(message);
    const timeStr = new Date().toLocaleTimeString();
    console.log(`✅ [${timeStr}] Sent high-priority FCM push to topic '${targetTopic}'! ID: ${response}`);
    console.log(`   Title: ${title}`);
    console.log(`   Body:  ${body}`);
  } catch (err) {
    console.error('❌ Error broadcasting FCM push notification:', err);
  }
});

// ===========================================================================
// MunoWatch Automated Server Poller (Every 15 minutes)
// Automatically detects newly released movies/translations from MunoWatch
// and broadcasts high-priority push notifications to ALL users even when closed!
// ===========================================================================
const KNOWN_MOVIES_FILE = path.resolve(__dirname, '.known_munowatch_ids.json');

function loadKnownMovieIds() {
  try {
    if (fs.existsSync(KNOWN_MOVIES_FILE)) {
      const data = JSON.parse(fs.readFileSync(KNOWN_MOVIES_FILE, 'utf8'));
      if (Array.isArray(data)) {
        return new Set(data);
      }
    }
  } catch (e) {
    console.warn('Notice loading known movie IDs:', e.message);
  }
  return null; // null means first run
}

function saveKnownMovieIds(idSet) {
  try {
    fs.writeFileSync(KNOWN_MOVIES_FILE, JSON.stringify(Array.from(idSet)), 'utf8');
  } catch (e) {
    console.warn('Notice saving known movie IDs:', e.message);
  }
}

async function checkMunowatchForNewMovies() {
  try {
    const urls = [
      'https://munowatch.ai.studio/api/dashboard',
      'https://munowatch.ai.studio/dashboard',
      'https://mumowatch.ai.studio/dashboard'
    ];

    let data = null;
    for (const u of urls) {
      try {
        const res = await fetch(u, { headers: { 'User-Agent': 'FreeWatch/1.0 (Daemon)' } });
        if (res.ok) {
          data = await res.json();
          if (data && (data.dashboard || data.movies)) break;
        }
      } catch (_) {}
    }

    if (!data) return;

    // Collect all movies currently on MunoWatch
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

    let knownIds = loadKnownMovieIds();
    const currentIds = new Set(allMovies.map(m => String(m.id || m.vid)));

    // On initial boot, cache all existing movie IDs so we don't spam 200 alerts
    if (!knownIds) {
      saveKnownMovieIds(currentIds);
      console.log(`🍿 [MunoWatch Poller] Initialized cache with ${currentIds.size} existing movies. Ready for new uploads!`);
      return;
    }

    // Detect new movie uploads
    const newMovies = allMovies.filter(m => !knownIds.has(String(m.id || m.vid)));

    if (newMovies.length > 0) {
      console.log(`✨ [MunoWatch Poller] Found ${newMovies.length} NEW movie(s) uploaded to MunoWatch!`);

      // Update cache immediately to prevent duplicate sends
      for (const m of newMovies) {
        knownIds.add(String(m.id || m.vid));
      }
      saveKnownMovieIds(knownIds);

      // Broadcast up to 3 newest releases
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
          const resp = await admin.messaging().send(message);
          const timeStr = new Date().toLocaleTimeString();
          console.log(`🚀 [${timeStr}] [MunoWatch Poller] Auto-broadcasted new movie: "${title}" (FCM ID: ${resp})`);

          // Also record in Realtime Database history
          admin.database().ref('push_notifications/history').push({
            id: resp,
            title,
            body,
            imageUrl,
            movieId,
            targetTopic: 'all_users',
            timestamp: Date.now(),
            dispatchedBy: 'MunoWatch Server Poller'
          }).catch(() => {});
        } catch (fcmErr) {
          console.error(`❌ [MunoWatch Poller] Failed to broadcast "${title}":`, fcmErr);
        }
      }
    }
  } catch (err) {
    console.warn('⚠️ [MunoWatch Poller] Error checking MunoWatch:', err.message);
  }
}

const { syncCatalogToRtdb } = require('./sync_munowatch_to_rtdb');

// Periodic catalog sync wrapper
async function runCatalogSyncSafely() {
  try {
    console.log('🔄 [Daemon] Running automated MunoWatch -> RTDB catalog sync...');
    await syncCatalogToRtdb({ checkStreams: false });
  } catch (err) {
    console.warn('⚠️ [Daemon] Background catalog sync error:', err.message);
  }
}

// Start polling on startup after 3 seconds, then every 15 minutes
setTimeout(checkMunowatchForNewMovies, 3000);
setInterval(checkMunowatchForNewMovies, 15 * 60 * 1000);

// Run full catalog sync on boot after 10s, then every 30 minutes
setTimeout(runCatalogSyncSafely, 10000);
setInterval(runCatalogSyncSafely, 30 * 60 * 1000);

