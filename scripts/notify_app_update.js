const admin = require('firebase-admin');
const path = require('path');
const fs = require('fs');

const RTDB_URL = 'https://freewatch-a0bc7-default-rtdb.firebaseio.com';

const version = process.argv[2] || process.env.APP_VERSION || '1.0.66';
const build = process.argv[3] || process.env.APP_BUILD || '67';
const apkUrl = process.argv[4] || `https://github.com/piustech1/FreeWatch/releases/download/v${version}/FreeWatch-release.apk`;
const tvApkUrl = process.argv[5] || `https://github.com/piustech1/FreeWatch/releases/download/v${version}/FreeWatch-TV-release.apk`;

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
      path.resolve(process.env.HOME || '', 'Desktop/FreeWatch/service-account.json'),
      path.resolve(process.env.HOME || '', 'Downloads/service-account.json'),
    ];
    for (const p of localPaths) {
      if (fs.existsSync(p)) {
        try {
          serviceAccount = require(p);
          break;
        } catch (_) {}
      }
    }
  }

  if (!serviceAccount) {
    console.log('ℹ️ [Notice] Firebase Service Account not present in environment or secrets.');
    return null;
  }

  return admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    databaseURL: RTDB_URL,
  });
}

async function notifyUpdate() {
  console.log(`🚀 Preparing FreeWatch update broadcast for version ${version} (Build ${build})...`);
  const timestamp = Date.now();
  const title = `🚀 FreeWatch v${version} Released!`;
  const body = `A new version of FreeWatch (v${version}) is now ready! Tap to update and enjoy Android TV 16:9 UI, instant Guest auth & rich catalogs.`;
  const notes = '• Android TV 16:9 Landscape UI: Full Leanback support with glowing focus states and navigation sidebar\n• Continue as Guest: Instant streaming on Android TV without remote typing hassle\n• Responsive Grids: Dynamic multi-device columns adapting seamlessly from phones to 4K TVs\n• Coming Soon Web Portal: Minimalist official launch portal with direct store download links\n• Universal Device APKs: Dedicated builds for Phone, Android TV, Fire TV, and multi-architecture devices';

  // 1. Sync update config to Firebase RTDB via HTTP REST API
  try {
    const res = await fetch(`${RTDB_URL}/app_config/update.json`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        latest_version: version,
        latest_build: Number(build),
        direct_apk_url: apkUrl,
        tv_apk_url: tvApkUrl,
        store_url: 'https://freewatchug.online/store',
        show_banner: true,
        force_show: true,
        release_notes: notes,
        updated_at: timestamp,
      }),
    });
    if (res.ok) {
      console.log('✅ Synchronized app_config/update in Firebase RTDB.');
    }
  } catch (err) {
    console.warn('⚠️ REST sync notice:', err.message);
  }

  // 2. Post update record to Notification History in Firebase RTDB
  try {
    const res = await fetch(`${RTDB_URL}/push_notifications/history.json`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        id: `update_${version}_${timestamp}`,
        title,
        body,
        route: '/update',
        link: '/update',
        targetTopic: 'all_users',
        timestamp,
        dispatchedBy: 'GitHub Actions Release System',
      }),
    });
    if (res.ok) {
      console.log('✅ Recorded update notification in Firebase RTDB history.');
    }
  } catch (err) {
    console.warn('⚠️ Notification history record notice:', err.message);
  }

  // 3. Dispatch FCM push notification to topic all_users if Firebase Admin is available
  const app = getFirebaseAdmin();
  if (app) {
    try {
      const message = {
        topic: 'all_users',
        notification: {
          title,
          body,
        },
        data: {
          title,
          body,
          route: '/update',
          link: '/update',
          type: 'app_update',
          version,
          build: String(build),
          timestamp: String(timestamp),
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
        },
      };

      const resp = await app.messaging().send(message);
      console.log(`📱 [FCM] Broadcasted update push notification to "all_users" (ID: ${resp})`);
    } catch (fcmErr) {
      console.warn('⚠️ FCM send error:', fcmErr.message);
    }
  } else {
    console.log('ℹ️ Direct FCM push skipped (service account not configured in runner). RTDB update notification is active for all devices.');
  }

  console.log('🎉 Update notification pipeline complete.');
}

notifyUpdate()
  .then(() => process.exit(0))
  .catch((e) => {
    console.error('Fatal update notify error:', e);
    process.exit(0); // Exit 0 so CI doesn't fail if notification fails
  });
