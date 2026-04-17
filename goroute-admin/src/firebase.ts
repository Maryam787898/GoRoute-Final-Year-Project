// src/firebase.ts

import { initializeApp } from "firebase/app";
import { getAuth } from "firebase/auth";
import { getFirestore } from "firebase/firestore";

const firebaseConfig = {
  apiKey: "AIzaSyAuNkSg7AtXDqd5JmYzeSMSuVRz6KITRzg",
  authDomain: "goroute-4ff4c.firebaseapp.com",
  projectId: "goroute-4ff4c",
  storageBucket: "goroute-4ff4c.firebasestorage.app",
  messagingSenderId: "953453444633",
  appId: "1:953453444633:web:bd5e3e75df75e5e83c7488",
  measurementId: "G-SMKEMKXYLY"
};

const app = initializeApp(firebaseConfig);

export const auth = getAuth(app);
export const db = getFirestore(app);

export default app;