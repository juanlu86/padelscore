import {
    assertFails,
    assertSucceeds,
    initializeTestEnvironment,
    RulesTestEnvironment,
} from "@firebase/rules-unit-testing";
import { readFileSync } from "fs";
import { expect } from "chai";
import path from "path";

describe("Firestore Security Rules", () => {
    let testEnv: RulesTestEnvironment;

    before(async () => {
        testEnv = await initializeTestEnvironment({
            projectId: "padelscore-test",
            firestore: {
                rules: readFileSync(path.resolve(__dirname, "../firestore.rules"), "utf8"),
                host: "127.0.0.1",
                port: 8080,
            },
        });
    });

    after(async () => {
        await testEnv.cleanup();
    });

    beforeEach(async () => {
        await testEnv.clearFirestore();
    });

    it("should allow public read access to matches", async () => {
        const unauthedDb = testEnv.unauthenticatedContext().firestore();
        await assertSucceeds(unauthedDb.collection("matches").get());
    });

    it("should deny write access to matches for unauthenticated users (except test-match)", async () => {
        const unauthedDb = testEnv.unauthenticatedContext().firestore();
        await assertFails(
            unauthedDb.collection("matches").add({
                team1: "A",
                team2: "B",
                status: "live"
            })
        );
    });

    it("should allow unauthenticated write access to the specific test-match document", async () => {
        const unauthedDb = testEnv.unauthenticatedContext().firestore();
        await assertSucceeds(
            unauthedDb.collection("matches").doc("test-match").set({
                team1: "A",
                team2: "B",
                status: "live"
            })
        );
    });

    it("should allow write access to matches for authenticated users", async () => {
        const authedDb = testEnv.authenticatedContext("alice").firestore();
        await assertSucceeds(
            authedDb.collection("matches").add({
                team1: "A",
                team2: "B",
                status: "live"
            })
        );
    });

    it("should deny write if team names are missing even for authed users", async () => {
        const authedDb = testEnv.authenticatedContext("alice").firestore();
        await assertFails(
            authedDb.collection("matches").add({
                status: "live"
            })
        );
    });

    it("should deny version rollbacks", async () => {
        const authedDb = testEnv.authenticatedContext("alice").firestore();
        const matchRef = authedDb.collection("matches").doc("version-test");

        // Initial setup
        await testEnv.withSecurityRulesDisabled(async (context) => {
            await context.firestore().collection("matches").doc("version-test").set({
                team1: "A",
                team2: "B",
                status: "live",
                version: 10
            });
        });

        // Try to rollback to version 9
        await assertFails(
            matchRef.update({
                version: 9
            })
        );

        // Try to update to version 11 (should succeed)
        await assertSucceeds(
            matchRef.update({
                version: 11
            })
        );
    });
});
