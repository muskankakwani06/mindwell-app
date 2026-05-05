import { initializeApp } from "firebase/app";
import { getAuth } from "firebase/auth";
import { getFirestore } from "firebase/firestore";

// TODO: Replace with your Firebase project configuration from the Firebase Console
const firebaseConfig = {
  apiKey: "AIzaSyDFTe3oS36a99FrlYtRVZRoeZJCYEBrP1U",
  authDomain: "mindwell-c1b91.firebaseapp.com",
  projectId: "mindwell-c1b91",
  storageBucket: "mindwell-c1b91.firebasestorage.app",
  messagingSenderId: "684917998131",
  appId: "1:684917998131:web:c05e50781294eea1169946",
  measurementId: "G-GQN6RSCVZG"
};

const app = initializeApp(firebaseConfig);
export const auth = getAuth(app);
export const db = getFirestore(app);
export default app;
