import { MatchState, SetResult } from '../types/match';

export const calculateSetsWon = (matchData: MatchState) => {
    const completedSets = matchData.completedSets || [];

    // Use 'sets' field if available, fallback to calculating from completedSets
    const team1SetsWon = matchData.sets?.team1 ?? completedSets.filter((s: SetResult) => s.team1 > s.team2).length;
    const team2SetsWon = matchData.sets?.team2 ?? completedSets.filter((s: SetResult) => s.team2 > s.team1).length;

    return { team1: team1SetsWon, team2: team2SetsWon };
};

export const isMatchFinished = (matchData: MatchState): boolean => {
    return matchData.status === 'finished' || matchData.isMatchOver === true;
};

export const getSetsToShow = (matchData: MatchState): SetResult[] => {
    const completedSets = matchData.completedSets || [];
    const finished = isMatchFinished(matchData);

    const sets = [...completedSets];
    if (!finished) {
        sets.push({
            team1: matchData.games?.team1 ?? 0,
            team2: matchData.games?.team2 ?? 0,
            isCurrent: true
        });
    }
    return sets;
};

export const getSpecialPointLabel = (matchData: MatchState): string | null => {
    const s1 = String(matchData.score?.team1 || '');
    const s2 = String(matchData.score?.team2 || '');
    const isDeuce = s1 === '40' && s2 === '40';

    if (!isDeuce) return null;

    const sys = matchData.scoringSystem;
    if (sys === 'Golden Point') return 'GOLDEN POINT';
    if (sys === 'Star Point' && matchData.deuceCount >= 3) return 'STAR POINT';

    return null;
};
