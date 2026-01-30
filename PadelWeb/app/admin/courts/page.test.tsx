import { render, screen, fireEvent, act } from '@testing-library/react';
import { expect, it, describe, vi, beforeEach } from 'vitest';
import AdminCourts from './page';
import { onSnapshot, addDoc, deleteDoc } from 'firebase/firestore';

// Mock Firebase Firestore
vi.mock('firebase/firestore', () => ({
    collection: vi.fn(),
    doc: vi.fn(),
    onSnapshot: vi.fn(() => () => { }),
    addDoc: vi.fn(),
    deleteDoc: vi.fn(),
    serverTimestamp: vi.fn(),
}));

// Mock the local firebase lib
vi.mock('../../../lib/firebase', () => ({
    db: {}
}));

describe('AdminCourts Component', () => {
    beforeEach(() => {
        vi.clearAllMocks();
    });

    it('renders loading state initially', () => {
        render(<AdminCourts />);
        // The loader is a div with a specific class in this case
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

        expect(screen.getByText('COURT ALPHA')).toBeInTheDocument();
        expect(screen.getByText('COURT BETA')).toBeInTheDocument();
        expect(screen.getByText(/Active Courts \(2\)/i)).toBeInTheDocument();
    });

    it('allows adding a new court', async () => {
        render(<AdminCourts />);

        const input = screen.getByPlaceholderText(/e.g. COURT CENTRAL/i);
        const button = screen.getByText(/Add Court/i);

        fireEvent.change(input, { target: { value: 'NEW COURT' } });
        fireEvent.click(button);

        expect(addDoc).toHaveBeenCalled();
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

        // Mock window.confirm
        const confirmSpy = vi.spyOn(window, 'confirm').mockImplementation(() => true);

        render(<AdminCourts />);

        // Find the button inside the court card (it's the only button with an svg/trash icon)
        const deleteButton = screen.getByRole('button', { name: '' });
        fireEvent.click(deleteButton);

        expect(confirmSpy).toHaveBeenCalled();
        expect(deleteDoc).toHaveBeenCalled();
    });
});
