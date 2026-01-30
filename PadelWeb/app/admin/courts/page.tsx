'use client';

import { useState, useEffect } from 'react';
import { db } from '../../../lib/firebase';
import { collection, onSnapshot, addDoc, deleteDoc, doc, serverTimestamp } from 'firebase/firestore';
import { Court } from '../../../types/court';

export default function AdminCourts() {
    const [courts, setCourts] = useState<Court[]>([]);
    const [newCourtName, setNewCourtName] = useState('');
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        const unsub = onSnapshot(collection(db, 'courts'), (snapshot) => {
            const courtsData = snapshot.docs.map(doc => ({
                id: doc.id,
                ...doc.data()
            })) as Court[];
            setCourts(courtsData);
            setLoading(false);
        });
        return () => unsub();
    }, []);

    const addCourt = async (e: React.FormEvent) => {
        e.preventDefault();
        if (!newCourtName.trim()) return;

        try {
            await addDoc(collection(db, 'courts'), {
                name: newCourtName,
                isActive: true,
                updatedAt: serverTimestamp()
            });
            setNewCourtName('');
        } catch (error) {
            console.error("Error adding court: ", error);
        }
    };

    const deleteCourt = async (id: string) => {
        if (!confirm('Are you sure you want to delete this court? All live data will be lost.')) return;
        try {
            await deleteDoc(doc(db, 'courts', id));
        } catch (error) {
            console.error("Error deleting court: ", error);
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
                    <div className="text-right">
                        <span className="text-[10px] font-black text-padel-yellow tracking-[0.2em] uppercase">Status: Online</span>
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
                <div className="grid gap-4">
                    <h2 className="text-[10px] font-black text-zinc-500 uppercase tracking-widest px-1">Active Courts ({courts.length})</h2>
                    {courts.length === 0 ? (
                        <div className="p-12 text-center border-2 border-dashed border-white/5 rounded-2xl">
                            <p className="text-zinc-600 font-bold uppercase tracking-tight">No courts configured yet.</p>
                        </div>
                    ) : (
                        courts.map((court) => (
                            <div key={court.id} className="glass p-6 rounded-2xl border border-white/5 flex justify-between items-center group hover:border-white/10 transition-all">
                                <div className="flex items-center gap-6">
                                    <div className="w-12 h-12 bg-padel-yellow/10 rounded-xl flex items-center justify-center border border-padel-yellow/20">
                                        <span className="text-padel-yellow font-black text-xl italic">{court.name.charAt(0)}</span>
                                    </div>
                                    <div>
                                        <h3 className="text-white font-black text-lg uppercase italic tracking-tight">{court.name}</h3>
                                        <div className="flex items-center gap-3 mt-1">
                                            <code className="text-[10px] bg-white/5 px-2 py-0.5 rounded text-zinc-400 font-mono">ID: {court.id}</code>
                                            <span className="w-1 h-1 rounded-full bg-zinc-700"></span>
                                            <span className="text-[10px] font-bold text-zinc-500 uppercase tracking-widest">
                                                {court.liveMatch ? 'Match in Progress' : 'Idle'}
                                            </span>
                                        </div>
                                    </div>
                                </div>

                                <div className="flex items-center gap-4">
                                    <a
                                        href={`/court/${court.id}`}
                                        target="_blank"
                                        className="text-[10px] font-black text-zinc-400 uppercase tracking-widest hover:text-padel-yellow transition-colors border border-white/10 px-4 py-2 rounded-lg"
                                    >
                                        Open Dashboard
                                    </a>
                                    <button
                                        onClick={() => deleteCourt(court.id)}
                                        className="opacity-0 group-hover:opacity-100 transition-all p-2 hover:bg-red-500/10 rounded-lg text-red-500/50 hover:text-red-500"
                                    >
                                        <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                                        </svg>
                                    </button>
                                </div>
                            </div>
                        ))
                    )}
                </div>

            </div>
        </div>
    );
}
