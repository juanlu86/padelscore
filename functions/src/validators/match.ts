import { MatchUpdateData } from '../schemas/match';

/**
 * Validates match data for scoring consistency.
 * @param data The match data to validate
 * @returns { valid: boolean; reason?: string }
 */
export const validateMatchConsistency = (data: MatchUpdateData): { valid: boolean; reason?: string } => {
    // Basic consistency check: 
    // If team1 has 2 sets (Best of 3) or 3 sets (Best of 5), match must be over.
    const completedSets = data.completedSets || [];
    const team1Sets = completedSets.filter((s) => s.team1 > s.team2).length;
    const team2Sets = completedSets.filter((s) => s.team2 > s.team1).length;

    // We assume 2 sets is the threshold for standard matches
    // In Area 14 we added Grand Slam support (3 sets), 
    // but the backend logic here remains defensive.
    if ((team1Sets >= 2 || team2Sets >= 2) && data.status !== "finished") {
        return { valid: false, reason: "Match should be finished" };
    }

    return { valid: true };
};
