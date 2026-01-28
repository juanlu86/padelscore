const admin = require('firebase-admin');

process.env.FIRESTORE_EMULATOR_HOST = '127.0.0.1:8080';
process.env.FIREBASE_AUTH_EMULATOR_HOST = '127.0.0.1:9099';

admin.initializeApp({
    projectId: 'demo-padel', // 'demo-' prefix triggers emulator mode automatically in some SDK versions, but env vars are safer
});

async function main() {
    const db = admin.firestore();

    console.log('Writing test document...');
    try {
        await db.collection('matches').doc('test-match').set({
            team1: 'Galán/Lebrón',
            team2: 'Coello/Tapia',
            score: {
                team1: '0',
                team2: '0'
            },
            status: 'live',
            timestamp: admin.firestore.FieldValue.serverTimestamp()
        });
        console.log('Successfully wrote to matches/test-match');
    } catch (e) {
        console.error('Error writing document:', e);
        process.exit(1);
    }
}

main();
