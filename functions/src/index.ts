/**
 * Import function triggers from their respective submodules:
 *
 * import {onCall} from "firebase-functions/v2/https";
 * import {onDocumentWritten} from "firebase-functions/v2/firestore";
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

import { setGlobalOptions } from "firebase-functions";
// import {onRequest} from "firebase-functions/https";
// import * as logger from "firebase-functions/logger";

// Start writing functions
// https://firebase.google.com/docs/functions/typescript

// For cost control, you can set the maximum number of containers that can be
// running at the same time. This helps mitigate the impact of unexpected
// traffic spikes by instead downgrading performance. This limit is a
// per-function limit. You can override the limit for each function using the
// `maxInstances` option in the function's options, e.g.
// `onRequest({ maxInstances: 5 }, (req, res) => { ... })`.
// NOTE: setGlobalOptions does not apply to functions using the v1 API. V1
// functions should each use functions.runWith({ maxInstances: 10 }) instead.
// In the v1 API, each function can only serve one request per container, so
// this will be the maximum concurrent request count.
import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";

setGlobalOptions({ maxInstances: 10 });

/**
 * Validates match data for scoring consistency.
 */
export const validateMatchUpdate = onCall((request) => {
    const data = request.data;
    logger.info("Validating match update", { data });

    if (!data.team1 || !data.team2) {
        throw new HttpsError("invalid-argument", "Teams are required");
    }

    // Basic consistency check: 
    // If team1 has 3 sets, match must be over.
    const completedSets = data.completedSets || [];
    const team1Sets = completedSets.filter((s: any) => s.team1 > s.team2).length;
    const team2Sets = completedSets.filter((s: any) => s.team2 > s.team1).length;

    if ((team1Sets >= 2 || team2Sets >= 2) && data.status !== "finished") {
        return { valid: false, reason: "Match should be finished" };
    }

    return { valid: true };
});
