import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import LoginPage from './page';
import { signInWithEmailAndPassword } from 'firebase/auth';
import { useRouter } from 'next/navigation';
import { vi } from 'vitest';

// Mock dependencies
vi.mock('firebase/auth', () => ({
    getAuth: vi.fn(),
    signInWithEmailAndPassword: vi.fn(),
}));

vi.mock('../../lib/firebase', () => ({
    auth: {},
}));

vi.mock('next/navigation', () => ({
    useRouter: vi.fn(),
}));

describe('LoginPage', () => {
    const mockPush = vi.fn();

    beforeEach(() => {
        vi.clearAllMocks();
        (useRouter as any).mockReturnValue({
            push: mockPush,
        });
    });

    it('renders login form correctly', () => {
        render(<LoginPage />);
        expect(screen.getByText(/Admin Login/i)).toBeInTheDocument();
        expect(screen.getByLabelText(/Email address/i)).toBeInTheDocument();
        expect(screen.getByLabelText(/Password/i)).toBeInTheDocument();
        expect(screen.getByRole('button', { name: /Sign in/i })).toBeInTheDocument();
    });

    it('handles successful login', async () => {
        (signInWithEmailAndPassword as any).mockResolvedValueOnce({ user: { email: 'test@padel.com' } });

        render(<LoginPage />);

        fireEvent.change(screen.getByLabelText(/Email address/i), { target: { value: 'test@padel.com' } });
        fireEvent.change(screen.getByLabelText(/Password/i), { target: { value: 'password123' } });
        fireEvent.click(screen.getByRole('button', { name: /Sign in/i }));

        await waitFor(() => {
            expect(signInWithEmailAndPassword).toHaveBeenCalledWith(expect.anything(), 'test@padel.com', 'password123');
            expect(mockPush).toHaveBeenCalledWith('/admin/courts');
        });
    });

    it('handles failed login', async () => {
        (signInWithEmailAndPassword as any).mockRejectedValueOnce(new Error('Invalid credentials'));

        render(<LoginPage />);

        fireEvent.change(screen.getByLabelText(/Email address/i), { target: { value: 'wrong@padel.com' } });
        fireEvent.change(screen.getByLabelText(/Password/i), { target: { value: 'wrongpass' } });
        fireEvent.click(screen.getByRole('button', { name: /Sign in/i }));

        await waitFor(() => {
            expect(screen.getByText(/Failed to login/i)).toBeInTheDocument();
            expect(mockPush).not.toHaveBeenCalled();
        });
    });
});
