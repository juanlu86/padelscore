
import { render, screen, waitFor } from '@testing-library/react';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import userEvent from '@testing-library/user-event';
import AdminCourts from './page';
import AdminLayout from '../layout';
import * as AuthHook from '../../../hooks/useAuth';

// Mocks
const pushMock = vi.fn();
vi.mock('next/navigation', () => ({
    useRouter: () => ({
        push: pushMock,
        refresh: vi.fn(),
    }),
}));

vi.mock('../../../lib/firebase', () => ({
    auth: {},
    db: {}
}));

vi.mock('firebase/firestore', () => ({
    collection: vi.fn(),
    query: vi.fn(),
    where: vi.fn(),
    onSnapshot: vi.fn((query, callback) => {
        callback({ docs: [] });
        return vi.fn();
    }),
    doc: vi.fn(),
    updateDoc: vi.fn(),
    setDoc: vi.fn(),
    deleteField: vi.fn(),
    serverTimestamp: vi.fn(),
}));

const signOutMock = vi.fn();
vi.mock('firebase/auth', () => ({
    signOut: (...args: any[]) => signOutMock(...args),
    getAuth: vi.fn(),
}));

describe('Admin Courts Logout Integration', () => {
    beforeEach(() => {
        vi.clearAllMocks();
    });

    it('should defer logout to the landing page (/?logout=true) and NOT sign out immediately', async () => {
        const mockUser = { email: 'admin@padel.com', uid: '123' };

        const useAuthMock = vi.spyOn(AuthHook, 'useAuth');
        useAuthMock.mockReturnValue({ user: mockUser as any, loading: false });

        render(
            <AdminLayout>
                <AdminCourts />
            </AdminLayout>
        );

        const logoutBtn = screen.getByText(/sign out/i);

        // Mock window.location.assign
        const assignMock = vi.fn();
        Object.defineProperty(window, 'location', {
            value: { assign: assignMock },
            writable: true
        });

        await userEvent.click(logoutBtn);

        // Expectation:
        // 1. Redirect to /?logout=true
        expect(assignMock).toHaveBeenCalledWith('/?logout=true');

        // 2. signOut MUST NOT be called here (AdminLayout will catch it if we do)
        expect(signOutMock).not.toHaveBeenCalled();
    });
});
