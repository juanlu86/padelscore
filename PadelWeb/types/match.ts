export type ScoringSystem = 'Standard' | 'Golden Point' | 'Star Point';

export interface SetResult {
    team1: number;
    team2: number;
    isCurrent?: boolean;
}

export interface MatchScore {
    team1: string;
    team2: string;
}

export interface MatchGames {
    team1: number;
    team2: number;
}

export interface MatchState {
    team1: string;
    team2: string;
    servingTeam: 1 | 2;
    score: MatchScore;
    games: MatchGames;
    sets?: {
        team1: number;
        team2: number;
    };
    completedSets: SetResult[];
    status: 'live' | 'finished';
    isMatchOver?: boolean;
    scoringSystem: ScoringSystem;
    deuceCount: number;
    version: number;
    updatedAt?: {
        seconds: number;
        nanoseconds: number;
    };
}
