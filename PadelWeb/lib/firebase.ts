import { initializeApp, getApps } from 'firebase/app';
import { getFirestore, connectFirestoreEmulator } from 'firebase/firestore';

const firebaseConfig = {
    // Config not needed for emulators, but typically:
    apiKey: "demo-key",
    authDomain: "demo-project.firebaseapp.com",
    projectId: "demo-padel",
    storageBucket: "demo-project.appspot.com",
    messagingSenderId: "123456789",
    appId: "1:123456789:web:abcdef"
};

const app = getApps().length === 0 ? initializeApp(firebaseConfig) : getApps()[0];
const db = getFirestore(app);

if (process.env.NODE_ENV === 'development') {
    // Prevent multiple emulator connections on HMR
    // @ts-ignore
    if (!global._emulatorConnected) {
        connectFirestoreEmulator(db, '127.0.0.1', 8080);
        // @ts-ignore
        global._emulatorConnected = true;
    }
}

export { db };
