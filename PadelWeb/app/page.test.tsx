
import { render, screen, waitFor } from '@testing-library/react';
import { expect, it, describe, vi, beforeEach } from 'vitest';
import Home from './page';
import { onSnapshot } from 'firebase/firestore';
import * as FirebaseAuth from 'firebase/auth';

// Mock Firebase Firestore
vi.mock('firebase/firestore', () => ({
    collection: vi.fn(),
    query: vi.fn(),
    where: vi.fn(),
    onSnapshot: vi.fn(() => vi.fn()),
    getFirestore: vi.fn(),
}));

// Mock Firebase Auth - Need to mock signOut for the "logout" test case
const signOutMock = vi.fn().mockResolvedValue(undefined);
vi.mock('firebase/auth', () => ({
    signOut: (...args: any[]) => signOutMock(...args),
    getAuth: vi.fn(),
}));

// Mock local firebase lib
vi.mock('../lib/firebase', () => ({
    auth: {},
    db: {}
}));

describe('Home Page (Public Court List)', () => {
    beforeEach(() => {
        vi.clearAllMocks();
        // Reset window location search
        Object.defineProperty(window, 'location', {
            value: {
                search: '',
                assign: vi.fn(),
            },
            writable: true
        });
        // Mock history.replaceState
        Object.defineProperty(window, 'history', {
            value: {
                replaceState: vi.fn(),
            },
            writable: true
        });
    });

    it('renders loading state initially', () => {
        render(<Home />);
        expect(screen.getByText(/LOADING COURTS.../i)).toBeInTheDocument();
    });

    it('renders court list when Firestore returns data', async () => {
        const mockCourts = [
            { id: '1', name: 'Center Court', isActive: true },
            { id: '2', name: 'Court 2', isActive: true, liveMatch: true }
        ];

        // Mock onSnapshot to return data
        (onSnapshot as any).mockImplementation((_query: any, callback: any) => {
            callback({
                docs: mockCourts.map(c => ({
                    id: c.id,
                    data: () => c
                }))
            });
            return () => { };
        });

        render(<Home />);

        // Wait for list to render
        // "Live Scores" header is always there
        expect(screen.getByText(/Live Scores/i)).toBeInTheDocument();

        // Check for Courts
        await waitFor(() => {
            expect(screen.getByText('Center Court')).toBeInTheDocument();
            expect(screen.getByText('Court 2')).toBeInTheDocument();
        });

        // Check for specific status badge logic (from CourtList)
        expect(screen.getByText('Match in Progress')).toBeInTheDocument();
    });

    it('triggers signOut if ?logout=true is present', async () => {
        // Set URL param
        Object.defineProperty(window, 'location', {
            value: {
                search: '?logout=true'
            },
            writable: true
        });

        render(<Home />);

        await waitFor(() => {
            expect(signOutMock).toHaveBeenCalled();
        });

        // Verify URL cleaning
        expect(window.history.replaceState).toHaveBeenCalledWith({}, '', '/');
    });
});
