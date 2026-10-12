import { initializeApp } from 'firebase/app';
import { getDatabase } from 'firebase/database';
import { getAuth, signInAnonymously } from 'firebase/auth';

// Official FreeWatch Firebase Web Configuration
export const firebaseConfig = {
  apiKey: "AIzaSyBAWxF0RefJNdYm5fBImexTjwD-D0uH3mw",
  authDomain: "freewatch-a0bc7.firebaseapp.com",
  databaseURL: "https://freewatch-a0bc7-default-rtdb.firebaseio.com",
  projectId: "freewatch-a0bc7",
  storageBucket: "freewatch-a0bc7.firebasestorage.app",
  messagingSenderId: "211067099380",
  appId: "1:211067099380:web:c3256a4da1b27ae37fe6a1",
  measurementId: "G-76Z2VJHLTB"
};

// Web Push Certificate / VAPID Key pair generated in Firebase Cloud Messaging
export const VAPID_KEY = "BM1p9rgWrqZ8mT1a6KwcV3fA0H42BoHQKGu9Gb-X0IbgkITyBMgJHU8l6374qMvO6iDONzm5cmYqWDVJzETEYBg";

const app = initializeApp(firebaseConfig);
export const rtdb = getDatabase(app);
export const auth = getAuth(app);
export { signInAnonymously };
export default app;
