import { MatchState } from './match';

export interface Court {
    id: string;
    name: string;
    isActive: boolean;
    liveMatch?: MatchState;
    updatedAt?: {
        seconds: number;
        nanoseconds: number;
    };
}
