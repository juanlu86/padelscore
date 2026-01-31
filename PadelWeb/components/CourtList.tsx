import { Court } from '../types/court';
import { useState } from 'react';

interface CourtListProps {
    courts: Court[];
    isAdmin: boolean;
    onEdit?: (id: string, newName: string) => void;
    onDelete?: (id: string) => void;
    onReset?: (id: string) => void;
}

export default function CourtList({ courts, isAdmin, onEdit, onDelete, onReset }: CourtListProps) {
    const [editingCourtId, setEditingCourtId] = useState<string | null>(null);
    const [editingName, setEditingName] = useState('');

    const handleUpdate = (id: string) => {
        if (editingName.trim() && onEdit) {
            onEdit(id, editingName);
            setEditingCourtId(null);
            setEditingName('');
        }
    };

    return (
        <div className="grid gap-4">
            <h2 className="text-[10px] font-black text-zinc-500 uppercase tracking-widest px-1">
                Active Courts ({courts.length})
            </h2>

            {courts.length === 0 ? (
                <div className="p-12 text-center border-2 border-dashed border-white/5 rounded-2xl">
                    <p className="text-zinc-600 font-bold uppercase tracking-tight">No courts active.</p>
                </div>
            ) : (
                courts.map((court) => (
                    <div key={court.id} className="glass p-6 rounded-2xl border border-white/5 flex justify-between items-center group hover:border-white/10 transition-all">
                        <div className="flex items-center gap-6">
                            <div className="w-12 h-12 bg-padel-yellow/10 rounded-xl flex items-center justify-center border border-padel-yellow/20">
                                <span className="text-padel-yellow font-black text-xl italic">
                                    {(court.name || 'C').charAt(0)}
                                </span>
                            </div>
                            <div>
                                {isAdmin && editingCourtId === court.id ? (
                                    <div className="flex items-center gap-2">
                                        <input
                                            type="text"
                                            value={editingName}
                                            onChange={(e) => setEditingName(e.target.value)}
                                            className="bg-white/5 border border-padel-yellow/50 rounded-lg px-3 py-1 text-white font-black uppercase italic text-lg outline-none w-48"
                                            autoFocus
                                            onKeyDown={(e) => {
                                                if (e.key === 'Enter') handleUpdate(court.id);
                                                if (e.key === 'Escape') setEditingCourtId(null);
                                            }}
                                        />
                                        <button
                                            onClick={() => handleUpdate(court.id)}
                                            className="bg-padel-yellow text-black p-1.5 rounded-lg hover:scale-105 active:scale-95 transition-all"
                                        >
                                            <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={3} d="M5 13l4 4L19 7" />
                                            </svg>
                                        </button>
                                        <button
                                            onClick={() => setEditingCourtId(null)}
                                            className="bg-white/10 text-white p-1.5 rounded-lg hover:bg-white/20 transition-all"
                                        >
                                            <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={3} d="M6 18L18 6M6 6l12 12" />
                                            </svg>
                                        </button>
                                    </div>
                                ) : (
                                    <h3 className="text-white font-black text-lg uppercase italic tracking-tight">
                                        {court.name || 'Unnamed Court'}
                                    </h3>
                                )}
                                <div className="flex items-center gap-3 mt-1">
                                    {isAdmin && (
                                        <code className="text-[10px] bg-white/5 px-2 py-0.5 rounded text-zinc-400 font-mono">ID: {court.id}</code>
                                    )}
                                    {!isAdmin && (
                                        <span className="text-[10px] font-bold text-zinc-600 uppercase tracking-wide">PadelScore Pro</span>
                                    )}
                                    <span className={`w-1 h-1 rounded-full ${court.liveMatch ? 'bg-red-500 animate-pulse' : 'bg-zinc-700'}`}></span>
                                    <span className={`text-[10px] font-bold uppercase tracking-widest ${court.liveMatch ? 'text-red-500' : 'text-zinc-500'}`}>
                                        {court.liveMatch ? 'Match in Progress' : 'Idle'}
                                    </span>
                                </div>
                            </div>
                        </div>

                        <div className="flex items-center gap-4">
                            {isAdmin && editingCourtId !== court.id && (
                                <>
                                    <button
                                        onClick={() => {
                                            setEditingCourtId(court.id);
                                            setEditingName(court.name || '');
                                        }}
                                        className="text-[10px] font-black text-zinc-400 uppercase tracking-widest hover:text-padel-yellow transition-colors border border-white/10 px-4 py-2 rounded-lg"
                                    >
                                        Edit
                                    </button>
                                    <button
                                        onClick={() => onReset && onReset(court.id)}
                                        className="text-[10px] font-black text-red-400/70 uppercase tracking-widest hover:text-red-400 transition-colors border border-red-500/10 px-4 py-2 rounded-lg"
                                    >
                                        Reset Match
                                    </button>
                                </>
                            )}

                            <a
                                href={`/court/${court.id}`}
                                className={`text-[10px] font-black uppercase tracking-widest transition-colors border px-4 py-2 rounded-lg flex items-center gap-2
                  ${!isAdmin ? 'bg-padel-yellow text-black border-padel-yellow hover:scale-105' : 'text-zinc-400 border-white/10 hover:text-padel-yellow'}
                `}
                            >
                                Open Dashboard
                                {!isAdmin && (
                                    <svg className="w-3 h-3" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={3} d="M14 5l7 7m0 0l-7 7m7-7H3" />
                                    </svg>
                                )}
                            </a>

                            {isAdmin && (
                                <button
                                    onClick={() => onDelete && onDelete(court.id)}
                                    className="opacity-0 group-hover:opacity-100 transition-all p-2 hover:bg-red-500/10 rounded-lg text-red-500/50 hover:text-red-500"
                                >
                                    <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                                    </svg>
                                </button>
                            )}
                        </div>
                    </div>
                ))
            )}
        </div>
    );
}
