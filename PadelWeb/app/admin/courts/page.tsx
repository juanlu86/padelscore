'use client';

import { useState, useEffect } from 'react';
import { db, auth } from '../../../lib/firebase';
import { collection, onSnapshot, doc, updateDoc, setDoc, serverTimestamp, deleteDoc, deleteField, query, where } from 'firebase/firestore';
import { signOut } from 'firebase/auth';
import { Court } from '../../../types/court';
import { useAuth } from '../../../hooks/useAuth';
import { useRouter } from 'next/navigation';

import CourtList from '../../../components/CourtList';

export default function AdminCourts() {
    const [courts, setCourts] = useState<Court[]>([]);
    const [newCourtName, setNewCourtName] = useState('');
    const [loading, setLoading] = useState(true);
    // Removed local editing state as it's now in CourtList

    // Auth
    const { user } = useAuth();
    const router = useRouter();

    useEffect(() => {
        // Query only active courts
        const q = query(collection(db, 'courts'), where('isActive', '==', true));

        const unsub = onSnapshot(q, (snapshot) => {
            const courtsData = snapshot.docs.map(doc => ({
                id: doc.id,
                ...doc.data()
            })) as Court[];
            setCourts(courtsData);
            setLoading(false);
        });
        return () => unsub();
    }, []);

    const handleLogout = () => {
        // Defer logout to the public page to avoid AdminLayout race conditions
        window.location.assign('/?logout=true');
    };

    const addCourt = async (e: React.FormEvent) => {
        e.preventDefault();
        if (!newCourtName.trim()) return;

        try {
            const shortId = Array.from({ length: 6 }, () => "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789".charAt(Math.floor(Math.random() * 36))).join("");
            await setDoc(doc(db, 'courts', shortId), {
                name: newCourtName,
                isActive: true,
                updatedAt: serverTimestamp()
            });
            setNewCourtName('');
        } catch (error) {
            console.error("Error adding court: ", error);
        }
    };

    const resetCourt = async (id: string) => {
        if (!confirm('Are you sure you want to reset this court? This will unlink players and clear the match.')) return;
        try {
            await updateDoc(doc(db, 'courts', id), {
                liveMatch: deleteField(),
                updatedAt: serverTimestamp()
            });
        } catch (error) {
            console.error("Error resetting court: ", error);
        }
    };

    const updateCourt = async (id: string, newName: string) => {
        try {
            await updateDoc(doc(db, 'courts', id), {
                name: newName,
                updatedAt: serverTimestamp()
            });
        } catch (error) {
            console.error("Error updating court: ", error);
        }
    };

    const deleteCourt = async (id: string) => {
        if (!confirm('Are you sure you want to archive this court?')) return;
        try {
            // Soft delete
            await updateDoc(doc(db, 'courts', id), {
                isActive: false,
                updatedAt: serverTimestamp()
            });
        } catch (error) {
            console.error("Error archiving court: ", error);
            alert("Failed to archive court. Check console.");
        }
    };

    if (loading) {
        return (
            <div className="flex min-h-screen items-center justify-center bg-background text-foreground">
                <div className="w-8 h-8 border-4 border-padel-yellow border-t-transparent rounded-full animate-spin"></div>
            </div>
        );
    }

    return (
        <div className="min-h-screen bg-background text-foreground p-6 font-sans">
            <div className="max-w-4xl mx-auto space-y-8">

                {/* Header */}
                <div className="flex justify-between items-end border-b border-white/5 pb-6">
                    <div>
                        <h1 className="text-3xl font-black tracking-tight text-white uppercase italic">Court Management</h1>
                        <p className="text-zinc-500 text-sm mt-1 font-medium italic">ADMIN PANEL // PADELCORE PRO</p>
                    </div>
                    <div className="text-right flex flex-col items-end gap-2">
                        <span className="text-[10px] font-black text-padel-yellow tracking-[0.2em] uppercase">Status: Online</span>
                        <div className="flex items-center gap-3">
                            <span className="text-xs text-zinc-400">{user?.email}</span>
                            <button
                                onClick={handleLogout}
                                className="text-[10px] font-black text-red-500 uppercase tracking-widest hover:text-red-400 transition-colors border border-white/10 px-3 py-1 rounded-lg"
                            >
                                Sign Out
                            </button>
                        </div>
                    </div>
                </div>

                {/* Add Court Form */}
                <form onSubmit={addCourt} className="glass p-6 rounded-2xl border border-white/5 flex gap-4 items-center">
                    <div className="flex-1">
                        <label className="text-[10px] font-black text-zinc-500 uppercase tracking-widest mb-2 block">Create New Court</label>
                        <input
                            type="text"
                            value={newCourtName}
                            onChange={(e) => setNewCourtName(e.target.value)}
                            placeholder="e.g. COURT CENTRAL"
                            className="w-full bg-white/5 border border-white/10 rounded-xl px-4 py-3 text-white placeholder:text-zinc-600 focus:outline-none focus:border-padel-yellow/50 transition-all font-bold uppercase tracking-tight"
                        />
                    </div>
                    <button
                        type="submit"
                        className="mt-6 bg-padel-yellow text-black font-black px-8 py-3.5 rounded-xl hover:scale-[1.02] active:scale-[0.98] transition-all uppercase text-sm tracking-tight shadow-[0_0_20px_rgba(234,255,0,0.2)]"
                    >
                        Add Court
                    </button>
                </form>

                {/* Court List */}
                <CourtList
                    courts={courts}
                    isAdmin={true}
                    onEdit={updateCourt}
                    onDelete={deleteCourt}
                    onReset={resetCourt}
                />

            </div>
        </div>
    );
}
