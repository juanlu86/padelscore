'use client';

import { useParams } from 'next/navigation';
import { useCourtMatch } from '../../../hooks/useCourtMatch';
import { isMatchFinished, calculateSetsWon } from '../../../lib/matchUtils';
import ScoreBoard from '../../../components/ScoreBoard';

export default function CourtDashboard() {
    const params = useParams();
    const courtId = params.courtId as string;
    const { matchData, courtName, loading } = useCourtMatch(courtId);

    if (loading) {
        return (
            <div className="flex min-h-screen items-center justify-center p-6 bg-background text-foreground font-sans">
                <div className="flex flex-col items-center gap-4">
                    <div className="w-12 h-12 border-4 border-padel-yellow border-t-transparent rounded-full animate-spin"></div>
                    <p className="text-zinc-500 animate-pulse font-medium tracking-wide italic">CONNECTING TO COURT...</p>
                </div>
            </div>
        );
    }

    if (!matchData) {
        return (
            <div className="flex min-h-screen flex-col items-center justify-center p-8 bg-background text-foreground font-sans relative overflow-hidden">
                <div className="absolute inset-0 bg-[radial-gradient(circle_at_center,rgba(234,255,0,0.05)_0%,transparent_70%)]"></div>
                <div className="glass p-12 rounded-[2.5rem] border border-white/5 shadow-2xl text-center max-w-lg w-full relative z-10">
                    <div className="w-20 h-20 bg-padel-yellow/10 rounded-3xl flex items-center justify-center border border-padel-yellow/20 mx-auto mb-8 animate-pulse">
                        <span className="text-padel-yellow font-black text-3xl italic">!</span>
                    </div>
                    <h1 className="text-2xl font-black text-white italic uppercase tracking-tight mb-3">{courtName || 'COURT'}</h1>
                    <p className="text-zinc-500 font-bold uppercase tracking-widest text-xs mb-8">Ready for next match</p>
                    <div className="bg-white/5 border border-white/5 py-4 px-6 rounded-2xl">
                        <p className="text-[10px] text-zinc-400 font-black uppercase tracking-[0.2em]">Scan QR on Net to Start</p>
                    </div>
                </div>
            </div>
        );
    }

    const isOver = isMatchFinished(matchData);
    const { team1: t1Sets, team2: t2Sets } = calculateSetsWon(matchData);
    const team1Won = isOver && t1Sets > t2Sets;
    const team2Won = isOver && t2Sets > t1Sets;

    return (
        <div className="flex min-h-screen flex-col items-center justify-center p-4 md:p-8 bg-background text-foreground font-sans selection:bg-padel-yellow/30 relative overflow-hidden">

            {/* Dynamic Background Flare */}
            <div className={`absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[600px] h-[600px] rounded-full blur-[120px] opacity-20 transition-all duration-1000 pointer-events-none ${team1Won ? 'bg-green-500/30' : team2Won ? 'bg-blue-500/30' : 'bg-padel-yellow/20'}`}></div>

            {/* Container with Glassmorphism */}
            <div className={`w-full max-w-3xl glass rounded-3xl overflow-hidden border border-white/5 shadow-2xl transition-all duration-700 ${isOver ? 'scale-[1.02] glow-white' : 'glow-yellow'}`}>

                {/* Header Section */}
                <div className="bg-white/5 border-b border-white/5 p-6 flex justify-between items-center">
                    <div className="flex flex-col">
                        <h1 className="text-sm font-black tracking-widest text-zinc-400 uppercase">PadelScore Pro</h1>
                        <div className="flex items-center gap-2 mt-1">
                            <span className={`w-2 h-2 rounded-full ${!isOver ? 'bg-padel-yellow pulse' : 'bg-red-500'}`}></span>
                            <p className="text-xs font-bold tracking-tight text-zinc-500 italic">
                                {!isOver ? 'LIVE FROM THE COURT' : 'FINAL MATCH RESULT'}
                            </p>
                        </div>
                    </div>
                    <div className="bg-padel-dark px-4 py-2 rounded-xl border border-white/5">
                        <span className="text-[10px] font-black text-padel-yellow uppercase tracking-widest">{courtName || 'COURT'}</span>
                    </div>
                </div>

                {/* Scoreboard Table Section */}
                <ScoreBoard matchData={matchData} />

                {/* Footer Info */}
                <div className="bg-white/2 p-6 border-t border-white/5">
                    <div className="flex justify-between items-center text-[10px] font-bold text-zinc-500 tracking-widest uppercase italic">
                        <span>Powered by PadelScore</span>
                        <span>Ref: {matchData.updatedAt?.seconds || '—'}</span>
                    </div>
                </div>
            </div>

            {/* Decorative Elements */}
            <div className="mt-12 opacity-20 hidden md:block">
                <p className="text-[12rem] font-black text-white/5 italic select-none pointer-events-none -mt-24">PADEL</p>
            </div>
        </div>
    );
}
