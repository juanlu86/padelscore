import { render, screen, act } from '@testing-library/react';
import { expect, it, describe, vi, beforeEach } from 'vitest';
import Home from './page';
import { onSnapshot } from 'firebase/firestore';

// Mock Firebase Firestore
vi.mock('firebase/firestore', () => ({
    doc: vi.fn(),
    onSnapshot: vi.fn(() => () => { }),
    getFirestore: vi.fn(),
}));

// Mock the local firebase lib to avoid initialization issues
vi.mock('../lib/firebase', () => ({
    db: {}
}));

describe('Home Component', () => {
    beforeEach(() => {
        vi.clearAllMocks();
    });

    it('renders loading state initially', () => {
        // onSnapshot won't call the callback immediately in this test
        render(<Home />);
        expect(screen.getByText(/WAITING FOR COURT DATA.../i)).toBeInTheDocument();
    });

    it('renders match data when Firestore returns a document', async () => {
        const mockData = {
            team1: 'TEAM ALPHA',
            team2: 'TEAM BETA',
            servingTeam: 1,
            score: { team1: '30', team2: '15' },
            games: { team1: 2, team2: 1 },
            status: 'live',
            completedSets: []
        };

        // Cast to any to access mock implementation
        (onSnapshot as any).mockImplementation((_docRef: any, callback: any) => {
            callback({
                exists: () => true,
                data: () => mockData
            });
            return () => { };
        });

        render(<Home />);

        expect(screen.getByText('TEAM ALPHA')).toBeInTheDocument();
        expect(screen.getByText('TEAM BETA')).toBeInTheDocument();
        expect(screen.getByText('30')).toBeInTheDocument();
        expect(screen.getByText('15')).toBeInTheDocument();
    });

    it('renders winner badge when match is finished', () => {
        const mockData = {
            team1: 'WINNER TEAM',
            team2: 'LOSER TEAM',
            status: 'finished',
            completedSets: [
                { team1: 6, team2: 0 },
                { team1: 6, team2: 0 }
            ]
        };

        (onSnapshot as any).mockImplementation((_docRef: any, callback: any) => {
            callback({
                exists: () => true,
                data: () => mockData
            });
            return () => { };
        });

        render(<Home />);

        const winnerBadges = screen.getAllByText('WINNER');
        expect(winnerBadges.length).toBeGreaterThan(0);
        expect(screen.getByText('WINNER TEAM')).toBeInTheDocument();
        expect(screen.getByText('FINAL MATCH RESULT')).toBeInTheDocument();
    });
});
