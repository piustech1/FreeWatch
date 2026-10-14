const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Cache initialized admin instance across serverless invocations
function getFirebaseAdmin() {
  if (admin.apps.length > 0) {
    return admin.app();
  }

  let serviceAccount = null;

  if (process.env.FIREBASE_SERVICE_ACCOUNT) {
    try {
      serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
    } catch (e) {
      console.error('Failed to parse FIREBASE_SERVICE_ACCOUNT env var:', e);
    }
  }

  if (!serviceAccount) {
    const localPath = path.resolve(__dirname, '../../service-account.json');
    if (fs.existsSync(localPath)) {
      serviceAccount = require(localPath);
    }
  }

  if (!serviceAccount) {
    throw new Error('Service account credentials not configured. Please add FIREBASE_SERVICE_ACCOUNT in Vercel settings or service-account.json in root.');
  }

  return admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    databaseURL: 'https://freewatch-a0bc7-default-rtdb.firebaseio.com',
  });
}

module.exports = async (req, res) => {
  // Set CORS headers
  res.setHeader('Access-Control-Allow-Credentials', true);
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET,OPTIONS,PATCH,DELETE,POST,PUT');
  res.setHeader(
    'Access-Control-Allow-Headers',
    'X-CSRF-Token, X-Requested-With, Accept, Accept-Version, Content-Length, Content-MD5, Content-Type, Date, X-Api-Version'
  );

  if (req.method === 'OPTIONS') {
    res.status(200).end();
    return;
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    const app = getFirebaseAdmin();
    const { 
      topic = 'all_users', 
      title = '🔥 New Luganda VJ Release!', 
      body = 'New translated blockbuster is now streaming in Full HD. Tap to watch!',
      imageUrl = '',
      movieId = '',
      route = '',
      type = 'notification',
    } = req.body || {};

    const cleanTopic = topic.replace(/[^a-zA-Z0-9-_.~%]/g, '_');
    const isSupportChat = route === '/developer-chat' || type === 'support_chat_reply';

    const message = {
      topic: cleanTopic,
      notification: {
        title,
        body,
      },
      data: {
        title,
        body,
        imageUrl: imageUrl || '',
        movieId: String(movieId || ''),
        route: route || (isSupportChat ? '/developer-chat' : ''),
        type: type || (isSupportChat ? 'support_chat_reply' : 'general'),
        timestamp: String(Date.now()),
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
      },
      android: {
        priority: 'high',
        notification: {
          channelId: isSupportChat ? 'freewatch_support_chat' : 'freewatch_alerts',
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

    const messageId = await app.messaging().send(message);
    return res.status(200).json({ 
      success: true, 
      messageId, 
      topic,
      timestamp: Date.now() 
    });
  } catch (error) {
    console.error('FCM send error:', error);
    return res.status(500).json({ 
      success: false, 
      error: error.message 
    });
  }
};
