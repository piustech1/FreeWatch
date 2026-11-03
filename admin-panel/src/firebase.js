import { initializeApp } from "firebase/app";
import { getAnalytics, isSupported, logEvent } from "firebase/analytics";
import { getDatabase } from "firebase/database";
import { 
  getAuth, 
  signInAnonymously,
  signInWithEmailAndPassword,
  createUserWithEmailAndPassword,
  sendPasswordResetEmail,
  signOut,
  updateProfile,
  setPersistence,
  browserLocalPersistence,
  browserSessionPersistence,
  onAuthStateChanged
} from "firebase/auth";

// Official FreeWatch Firebase Web Configuration
// For Firebase JS SDK v7.20.0 and later, measurementId is optional
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

// Initialize Firebase App
const app = initializeApp(firebaseConfig);

// Initialize Realtime Database
export const rtdb = getDatabase(app);

// Initialize Firebase Auth with Local Persistence for user session persistence
export const auth = getAuth(app);
if (typeof window !== "undefined") {
  setPersistence(auth, browserLocalPersistence).catch((err) => {
    console.warn("Auth persistence configuration notice:", err);
  });
}

// Initialize Firebase Analytics safely (SSR & browser check)
export let analytics = null;
if (typeof window !== "undefined") {
  isSupported()
    .then((supported) => {
      if (supported) {
        analytics = getAnalytics(app);
      }
    })
    .catch((err) => {
      console.warn("Analytics initialization notice:", err);
    });
}

export {
  signInAnonymously,
  signInWithEmailAndPassword,
  createUserWithEmailAndPassword,
  sendPasswordResetEmail,
  signOut,
  updateProfile,
  setPersistence,
  browserLocalPersistence,
  browserSessionPersistence,
  onAuthStateChanged,
  logEvent
};

export default app;
