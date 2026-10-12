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
