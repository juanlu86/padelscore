import { initializeApp, getApps } from 'firebase/app';
import { getFirestore, connectFirestoreEmulator } from 'firebase/firestore';
import { getAuth, connectAuthEmulator } from 'firebase/auth';

const firebaseConfig = {
    apiKey: process.env.NEXT_PUBLIC_FIREBASE_API_KEY,
    authDomain: process.env.NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN,
    projectId: process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID,
    storageBucket: process.env.NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET,
    messagingSenderId: process.env.NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID,
    appId: process.env.NEXT_PUBLIC_FIREBASE_APP_ID
};

const app = getApps().length === 0 ? initializeApp(firebaseConfig) : getApps()[0];
const db = getFirestore(app);
const auth = getAuth(app);

import { initializeAppCheck, ReCaptchaV3Provider } from 'firebase/app-check';

// Only connect to emulator if explicitly enabled
if (process.env.NEXT_PUBLIC_USE_FIREBASE_EMULATOR === 'true') {
    // Prevent multiple emulator connections on HMR
    // @ts-ignore
    if (!global._emulatorConnected) {
        connectFirestoreEmulator(db, '127.0.0.1', 8080);
        connectAuthEmulator(auth, 'http://127.0.0.1:9099');
        // @ts-ignore
        global._emulatorConnected = true;
    }
}

if (process.env.NODE_ENV === 'development') {
    // Enable App Check Debug Token in Development
    if (typeof window !== 'undefined') {
        // @ts-ignore
        self.FIREBASE_APPCHECK_DEBUG_TOKEN = true;
    }
}


// Initialize App Check (Client-Side Only)
if (typeof window !== 'undefined' && process.env.NEXT_PUBLIC_USE_FIREBASE_EMULATOR !== 'true') {
    initializeAppCheck(app, {
        provider: new ReCaptchaV3Provider(process.env.NEXT_PUBLIC_RECAPTCHA_SITE_KEY || 'NOT_CONFIGURED'),
        isTokenAutoRefreshEnabled: true
    });
}

export { db, auth };
