
import { render, screen, waitFor } from '@testing-library/react';
import { expect, it, describe, vi, beforeEach } from 'vitest';
import CourtDashboard from './page';
import * as UseCourtMatchHook from '../../../hooks/useCourtMatch';

// Mock navigation
vi.mock('next/navigation', () => ({
    useParams: () => ({ courtId: 'court-123' })
}));

// Mock local firebase lib
vi.mock('../../../lib/firebase', () => ({
    db: {}
}));

describe('Court Dashboard', () => {
    beforeEach(() => {
        vi.clearAllMocks();
    });

    it('renders loading state initially', () => {
        vi.spyOn(UseCourtMatchHook, 'useCourtMatch').mockReturnValue({
            matchData: null,
            courtName: '',
            loading: true // Forced loading
        });

        render(<CourtDashboard />);
        expect(screen.getByText(/CONNECTING TO COURT.../i)).toBeInTheDocument();
    });

    it('renders idle state (QR Code) when no match data exists', () => {
        vi.spyOn(UseCourtMatchHook, 'useCourtMatch').mockReturnValue({
            matchData: null,
            courtName: 'Center Court',
            loading: false
        });

        render(<CourtDashboard />);
        expect(screen.getByText(/Waiting for players.../i)).toBeInTheDocument();
        expect(screen.getByText(/Scan to Start Match/i)).toBeInTheDocument();
    });

    it('renders match scoreboard when data exists', () => {
        const mockMatch = {
            team1: 'Federer',
            team2: 'Nadal',
            score: { team1: '15', team2: '0' },
            sets: { team1: 0, team2: 0 },
            games: { team1: 0, team2: 0 },
            status: 'live'
        };

        vi.spyOn(UseCourtMatchHook, 'useCourtMatch').mockReturnValue({
            matchData: mockMatch as any,
            courtName: 'Center Court',
            loading: false
        });

        render(<CourtDashboard />);
        expect(screen.getByText('Federer')).toBeInTheDocument();
        expect(screen.getByText('Nadal')).toBeInTheDocument();
        expect(screen.getByText('15')).toBeInTheDocument();
    });

    it('renders winner badge (Final Result) when match is finished', () => {
        const mockMatch = {
            team1: 'Federer',
            team2: 'Nadal',
            status: 'finished',
            completedSets: [
                { team1: 6, team2: 0 },
                { team1: 6, team2: 0 }
            ],
            sets: { team1: 2, team2: 0 }
        };

        vi.spyOn(UseCourtMatchHook, 'useCourtMatch').mockReturnValue({
            matchData: mockMatch as any,
            courtName: 'Center Court',
            loading: false
        });

        render(<CourtDashboard />);
        expect(screen.getByText(/FINAL MATCH RESULT/i)).toBeInTheDocument();
    });
});
