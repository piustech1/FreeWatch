import { initializeApp } from 'firebase/app';
import { getDatabase } from 'firebase/database';
import { getAuth } from 'firebase/auth';

const firebaseConfig = {
  apiKey: "AIzaSyA7GoAsmMBX0gLlrLr7bb2__AMr8jUehys",
  authDomain: "freewatch-a0bc7.firebaseapp.com",
  databaseURL: "https://freewatch-a0bc7-default-rtdb.firebaseio.com",
  projectId: "freewatch-a0bc7",
  storageBucket: "freewatch-a0bc7.firebasestorage.app",
  messagingSenderId: "211067099380",
  appId: "1:211067099380:web:5f633520cef7cf177fe6a1"
};

const app = initializeApp(firebaseConfig);
export const rtdb = getDatabase(app);
export const auth = getAuth(app);
export default app;
