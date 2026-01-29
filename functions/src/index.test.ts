import firebaseFunctionsTest from "firebase-functions-test";
import { expect } from "chai";
import * as myFunctions from "./index";

const test = firebaseFunctionsTest();

describe("Cloud Functions - validateMatchUpdate", () => {
    after(() => {
        test.cleanup();
    });

    it("should throw an error if teams are missing", async () => {
        const wrapped = test.wrap(myFunctions.validateMatchUpdate);
        try {
            await wrapped({ data: {} } as any);
            expect.fail("Should have thrown an error");
        } catch (error: any) {
            expect(error.code).to.equal("invalid-argument");
            expect(error.message).to.equal("Teams are required");
        }
    });

    it("should return valid: false if match should be finished", async () => {
        const wrapped = test.wrap(myFunctions.validateMatchUpdate);
        const data = {
            team1: "Team A",
            team2: "Team B",
            status: "live",
            completedSets: [
                { team1: 6, team2: 0 },
                { team1: 6, team2: 0 }
            ]
        };
        const result = await (wrapped({ data } as any) as any);
        expect(result.valid).to.be.false;
        expect(result.reason).to.equal("Match should be finished");
    });

    it("should return valid: true for broad consistency", async () => {
        const wrapped = test.wrap(myFunctions.validateMatchUpdate);
        const data = {
            team1: "Team A",
            team2: "Team B",
            status: "live",
            completedSets: [
                { team1: 6, team2: 4 }
            ]
        };
        const result = await (wrapped({ data } as any) as any);
        expect(result.valid).to.be.true;
    });
});
