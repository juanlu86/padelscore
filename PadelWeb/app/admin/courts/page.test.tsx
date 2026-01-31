import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { expect, it, describe, vi, beforeEach } from 'vitest';
import AdminCourts from './page';
import { onSnapshot, addDoc, deleteDoc, updateDoc, setDoc } from 'firebase/firestore';

// Mock Dependencies
vi.mock('next/navigation', () => ({
    useRouter: () => ({
        push: vi.fn(),
    }),
}));

vi.mock('../../../hooks/useAuth', () => ({
    useAuth: () => ({
        user: { email: 'admin@padel.com' },
        loading: false,
    }),
}));

// Mock Firebase Firestore
vi.mock('firebase/firestore', () => ({
    collection: vi.fn(),
    doc: vi.fn((_db, _coll, id) => ({ id })), // Return a mock doc ref
    onSnapshot: vi.fn(() => () => { }),
    addDoc: vi.fn(),
    deleteDoc: vi.fn(),
    updateDoc: vi.fn(),
    setDoc: vi.fn(),
    serverTimestamp: vi.fn(() => 'timestamp'),
    deleteField: vi.fn(),
    getFirestore: vi.fn(),
    query: vi.fn((c) => c), // Pass-through collection
    where: vi.fn(),
}));

vi.mock('firebase/auth', () => ({
    signOut: vi.fn(),
    getAuth: vi.fn(),
}));

// Mock local firebase lib
vi.mock('../../../lib/firebase', () => ({
    db: {},
    auth: {}
}));

describe('AdminCourts Component', () => {
    beforeEach(() => {
        vi.clearAllMocks();
    });

    it('renders loading state initially', () => {
        render(<AdminCourts />);
        // The component renders "Court Management" even if empty state, 
        // effectively only blocked by Auth loading which we mocked to false.
        // The internal "loading" state (for Firestore) only displays the spinner.
        // BUT, our onSnapshot mock returns nothing immediately?
        // Actually, we mocked onSnapshot to return a function, but we didn't invoke the callback.
        // So `loading` stays true.

        const loader = document.querySelector('.animate-spin');
        expect(loader).toBeInTheDocument();
    });

    it('renders court list when data is available', async () => {
        const mockCourts = [
            { id: '1', name: 'COURT ALPHA', isActive: true },
            { id: '2', name: 'COURT BETA', isActive: true }
        ];

        (onSnapshot as any).mockImplementation((_coll: any, callback: any) => {
            callback({
                docs: mockCourts.map(c => ({
                    id: c.id,
                    data: () => ({ name: c.name, isActive: c.isActive })
                }))
            });
            return () => { };
        });

        render(<AdminCourts />);

        // Wait for the update to happen
        await waitFor(() => {
            expect(screen.getByText('COURT ALPHA')).toBeInTheDocument();
        });
        expect(screen.getByText('COURT BETA')).toBeInTheDocument();
        expect(screen.getByText(/Active Courts \(2\)/i)).toBeInTheDocument();
    });

    it('allows adding a new court', async () => {
        render(<AdminCourts />);

        const input = screen.getByPlaceholderText(/e.g. COURT CENTRAL/i);
        const button = screen.getByText(/Add Court/i);

        fireEvent.change(input, { target: { value: 'NEW COURT' } });
        fireEvent.click(button);

        await waitFor(() => {
            expect(setDoc).toHaveBeenCalled();
        });
    });

    it('confirms before deleting a court', async () => {
        const mockCourts = [{ id: '1', name: 'DELETE ME', isActive: true }];
        (onSnapshot as any).mockImplementation((_coll: any, callback: any) => {
            callback({
                docs: mockCourts.map(c => ({
                    id: c.id,
                    data: () => ({ name: c.name, isActive: c.isActive })
                }))
            });
            return () => { };
        });

        const confirmSpy = vi.spyOn(window, 'confirm').mockImplementation(() => true);

        render(<AdminCourts />);

        await waitFor(() => {
            expect(screen.getByText('DELETE ME')).toBeInTheDocument();
        });

        const deleteButtons = screen.getAllByRole('button');
        const deleteBtn = deleteButtons[deleteButtons.length - 1];

        fireEvent.click(deleteBtn);

        expect(confirmSpy).toHaveBeenCalled();
        expect(updateDoc).toHaveBeenCalledWith(expect.anything(), expect.objectContaining({ isActive: false }));
        expect(deleteDoc).not.toHaveBeenCalled();
    });

    it('allows editing an existing court', async () => {
        const mockCourts = [{ id: '1', name: 'OLD NAME', isActive: true }];
        (onSnapshot as any).mockImplementation((_coll: any, callback: any) => {
            callback({
                docs: mockCourts.map(c => ({
                    id: c.id,
                    data: () => ({ name: c.name, isActive: c.isActive })
                }))
            });
            return () => { };
        });

        render(<AdminCourts />);

        await waitFor(() => {
            expect(screen.getByText('OLD NAME')).toBeInTheDocument();
        });

        const editButton = screen.getByText(/Edit/i);
        fireEvent.click(editButton);

        const input = screen.getByDisplayValue('OLD NAME');
        fireEvent.change(input, { target: { value: 'UPDATED NAME' } });

        const saveButton = input.nextElementSibling;
        if (saveButton) {
            fireEvent.click(saveButton);
        }

        expect(updateDoc).toHaveBeenCalled();
    });
});
