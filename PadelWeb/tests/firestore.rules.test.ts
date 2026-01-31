import {
    assertFails,
    assertSucceeds,
    initializeTestEnvironment,
    RulesTestEnvironment,
} from '@firebase/rules-unit-testing';
import { readFileSync } from 'fs';
import { describe, it, beforeAll, afterAll, beforeEach } from 'vitest';
import * as path from 'path';

let testEnv: RulesTestEnvironment;

describe('Firestore Rules - Courts', () => {
    beforeAll(async () => {
        // Load the rules file from the root directory
        const rulesPath = path.resolve(__dirname, '../../firestore.rules');
        const rules = readFileSync(rulesPath, 'utf8');

        testEnv = await initializeTestEnvironment({
            projectId: 'padelscore-hardening-tests',
            firestore: {
                rules: rules,
                host: '127.0.0.1',
                port: 8080,
            },
        });
    });

    afterAll(async () => {
        await testEnv.cleanup();
    });

    beforeEach(async () => {
        await testEnv.clearFirestore();
    });

    it('allows public read access to courts', async () => {
        const unauthed = testEnv.unauthenticatedContext();
        await assertSucceeds(unauthed.firestore().collection('courts').get());
    });

    it('denies unauthenticated users from creating courts', async () => {
        const unauthed = testEnv.unauthenticatedContext();
        await assertFails(
            unauthed.firestore().collection('courts').add({
                name: 'Hacker Court',
                isActive: true,
            })
        );
    });

    it('allows authenticated (admin) users to create courts', async () => {
        const authed = testEnv.authenticatedContext('admin_user');
        await assertSucceeds(
            authed.firestore().collection('courts').add({
                name: 'Official Court',
                isActive: true,
            })
        );
    });

    it('denies hard deletion even by admin users (Soft Delete Policy)', async () => {
        const authed = testEnv.authenticatedContext('admin_user');
        await testEnv.withSecurityRulesDisabled(async (context) => {
            await context.firestore().collection('courts').doc('delete_me').set({ name: 'Delete Me' });
        });

        await assertFails(
            authed.firestore().collection('courts').doc('delete_me').delete()
        );
    });

    it('allows authenticated (admin) users to soft delete (archive)', async () => {
        const authed = testEnv.authenticatedContext('admin_user');
        await testEnv.withSecurityRulesDisabled(async (context) => {
            await context.firestore().collection('courts').doc('archive_me').set({ name: 'Archive Me', isActive: true });
        });

        await assertSucceeds(
            authed.firestore().collection('courts').doc('archive_me').update({ isActive: false })
        );
    });

    it('allows unauthenticated "App" to update liveMatch', async () => {
        const unauthed = testEnv.unauthenticatedContext();

        await testEnv.withSecurityRulesDisabled(async (context) => {
            await context.firestore().collection('courts').doc('court_1').set({
                name: 'Central Court',
                liveMatch: null
            });
        });

        await assertSucceeds(
            unauthed.firestore().collection('courts').doc('court_1').update({
                'liveMatch': { 'score': '15-0' },
                'updatedAt': new Date()
            })
        );
    });

    it('denies unauthenticated users from changing court name', async () => {
        const unauthed = testEnv.unauthenticatedContext();

        await testEnv.withSecurityRulesDisabled(async (context) => {
            await context.firestore().collection('courts').doc('court_1').set({
                name: 'Central Court'
            });
        });

        await assertFails(
            unauthed.firestore().collection('courts').doc('court_1').update({
                'name': 'Hacker Court'
            })
        );
    });
});
