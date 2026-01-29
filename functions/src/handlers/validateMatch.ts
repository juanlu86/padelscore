import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import { MatchUpdateSchema } from '../schemas/match';
import { validateMatchConsistency } from '../validators/match';

/**
 * Validates match data for scoring consistency.
 */
export const validateMatchUpdateHandler = onCall((request) => {
    logger.info("Validating match update", { data: request.data });

    // 1. Schema Validation with Zod
    const parseResult = MatchUpdateSchema.safeParse(request.data);

    if (!parseResult.success) {
        const errorMsg = parseResult.error.errors.map(e => `${e.path.join('.')}: ${e.message}`).join(', ');
        throw new HttpsError("invalid-argument", `Invalid match data: ${errorMsg}`);
    }

    const data = parseResult.data;

    // 2. Logical Consistency Validation
    const consistencyResult = validateMatchConsistency(data);

    if (!consistencyResult.valid) {
        return { valid: false, reason: consistencyResult.reason };
    }

    return { valid: true };
});
