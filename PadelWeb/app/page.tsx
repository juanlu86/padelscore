'use client';

import { useEffect, useState } from 'react';
import { doc, onSnapshot } from 'firebase/firestore';
import { db } from '../lib/firebase';

export default function Home() {
  const [matchData, setMatchData] = useState<any>(null);

  useEffect(() => {
    const unsub = onSnapshot(doc(db, "matches", "test-match"), (doc) => {
      if (doc.exists()) {
        setMatchData(doc.data());
      } else {
        console.log("No such document!");
      }
    });

    return () => unsub();
  }, []);

  if (!matchData) {
    return (
      <div className="flex min-h-screen items-center justify-center p-6 bg-background text-foreground font-sans">
        <div className="flex flex-col items-center gap-4">
          <div className="w-12 h-12 border-4 border-padel-yellow border-t-transparent rounded-full animate-spin"></div>
          <p className="text-zinc-500 animate-pulse font-medium tracking-wide">WAITING FOR COURT DATA...</p>
        </div>
      </div>
    );
  }

  const completedSets = matchData.completedSets || [];
  const isMatchOver = matchData.status === 'finished' || matchData.isMatchOver === true;

  // Who won?
  const team1SetsWon = completedSets.filter((s: any) => s.team1 > s.team2).length;
  const team2SetsWon = completedSets.filter((s: any) => s.team2 > s.team1).length;
  const team1Won = isMatchOver && team1SetsWon > team2SetsWon;
  const team2Won = isMatchOver && team2SetsWon > team1SetsWon;

  // Decide which sets to show
  // If match is over, we don't need to show an empty "current" set if it has no points
  const hasCurrentGamePoints = matchData.games?.team1 > 0 || matchData.games?.team2 > 0;
  const setsToShow = [...completedSets];
  if (!isMatchOver || hasCurrentGamePoints) {
    setsToShow.push({
      team1: matchData.games?.team1 ?? 0,
      team2: matchData.games?.team2 ?? 0,
      isCurrent: true
    });
  }

  // Helper to safely get point score
  const getPointScore = (team: 'team1' | 'team2') => {
    const s = matchData.score?.[team];
    if (s === undefined || s === null) return '0';
    return String(s);
  };

  return (
    <div className="flex min-h-screen flex-col items-center justify-center p-4 md:p-8 bg-background text-foreground font-sans selection:bg-padel-yellow/30 relative overflow-hidden">

      {/* Dynamic Background Flare */}
      <div className={`absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[600px] h-[600px] rounded-full blur-[120px] opacity-20 transition-all duration-1000 pointer-events-none ${team1Won ? 'bg-green-500/30' : team2Won ? 'bg-blue-500/30' : 'bg-padel-yellow/20'}`}></div>

      {/* Container with Glassmorphism */}
      <div className={`w-full max-w-3xl glass rounded-3xl overflow-hidden border border-white/5 shadow-2xl transition-all duration-700 ${isMatchOver ? 'scale-[1.02] glow-white' : 'glow-yellow'}`}>

        {/* Header Section */}
        <div className="bg-white/5 border-b border-white/5 p-6 flex justify-between items-center">
          <div className="flex flex-col">
            <h1 className="text-sm font-black tracking-widest text-zinc-400 uppercase">PadelScore Pro</h1>
            <div className="flex items-center gap-2 mt-1">
              <span className={`w-2 h-2 rounded-full ${!isMatchOver ? 'bg-padel-yellow pulse' : 'bg-red-500'}`}></span>
              <p className="text-xs font-bold tracking-tight text-zinc-500">
                {!isMatchOver ? 'LIVE FROM THE COURT' : 'FINAL MATCH RESULT'}
              </p>
            </div>
          </div>
          <div className="bg-padel-dark px-4 py-2 rounded-xl border border-white/5">
            <span className="text-[10px] font-black text-padel-yellow uppercase tracking-widest">Court 1</span>
          </div>
        </div>

        {/* Scoreboard Table */}
        <div className="p-8 lg:p-12 overflow-x-auto overflow-y-hidden">
          <table className="w-full border-collapse">
            <thead>
              <tr className="border-b border-white/5">
                <th className="text-left pb-4 text-[10px] font-black text-zinc-500 uppercase tracking-widest px-2">Teams</th>
                {setsToShow.map((_, i) => (
                  <th key={i} className="pb-4 text-[10px] font-black text-zinc-500 uppercase tracking-widest text-center px-4">Set {i + 1}</th>
                ))}
                {!isMatchOver && <th className="pb-4 text-[10px] font-black text-padel-yellow uppercase tracking-widest text-right px-4">Points</th>}
              </tr>
            </thead>
            <tbody className="divide-y divide-white/5">
              {/* Team 1 Row */}
              <tr className={`group transition-all duration-500 ${team2Won ? 'opacity-40 grayscale-[0.5]' : ''}`}>
                <td className="py-8 px-2 min-w-[120px]">
                  <div className="flex items-center gap-3">
                    {matchData.servingTeam === 1 && !isMatchOver && (
                      <div className="w-2.5 h-2.5 bg-padel-yellow rounded-full shadow-[0_0_8px_rgba(250,204,21,0.6)] animate-pulse shrink-0"></div>
                    )}
                    <div className="flex flex-col">
                      <span className={`text-xl md:text-3xl font-black tracking-tight group-hover:text-white transition-all duration-300 uppercase truncate block ${matchData.servingTeam === 1 || team1Won ? 'text-white' : 'text-zinc-400'}`}>
                        {matchData.team1 || 'Player 1'}
                      </span>
                      {team1Won && (
                        <span className="text-[10px] bg-padel-yellow text-black px-2 py-0.5 rounded-full font-black tracking-widest mt-2 w-fit animate-bounce">WINNER</span>
                      )}
                    </div>
                  </div>
                </td>
                {setsToShow.map((set, i) => (
                  <td key={i} className="text-center px-4">
                    <span className={`text-2xl md:text-4xl font-black ${set.isCurrent && !isMatchOver ? 'text-padel-yellow' : set.team1 > set.team2 ? 'text-white' : 'text-zinc-600'} italic transition-all duration-500`}>
                      {set.team1}
                    </span>
                  </td>
                ))}
                {!isMatchOver && (
                  <td className="text-right px-4 py-8">
                    <div className="bg-padel-yellow inline-flex items-center justify-center min-w-[64px] h-12 rounded-xl shadow-[0_0_20px_rgba(250,204,21,0.3)] transition-transform hover:scale-105 duration-300">
                      <span className="font-black text-2xl text-black tabular-nums">{getPointScore('team1')}</span>
                    </div>
                  </td>
                )}
              </tr>

              {/* Team 2 Row */}
              <tr className={`group transition-all duration-500 ${team1Won ? 'opacity-40 grayscale-[0.5]' : ''}`}>
                <td className="py-8 px-2">
                  <div className="flex items-center gap-3">
                    {matchData.servingTeam === 2 && !isMatchOver && (
                      <div className="w-2.5 h-2.5 bg-padel-yellow rounded-full shadow-[0_0_8px_rgba(250,204,21,0.6)] animate-pulse shrink-0"></div>
                    )}
                    <div className="flex flex-col">
                      <span className={`text-xl md:text-3xl font-black tracking-tight group-hover:text-white transition-all duration-300 uppercase truncate block ${matchData.servingTeam === 2 || team2Won ? 'text-white' : 'text-zinc-400'}`}>
                        {matchData.team2 || 'Player 2'}
                      </span>
                      {team2Won && (
                        <span className="text-[10px] bg-padel-yellow text-black px-2 py-0.5 rounded-full font-black tracking-widest mt-2 w-fit animate-bounce">WINNER</span>
                      )}
                    </div>
                  </div>
                </td>
                {setsToShow.map((set, i) => (
                  <td key={i} className="text-center px-4">
                    <span className={`text-2xl md:text-4xl font-black ${set.isCurrent && !isMatchOver ? 'text-padel-yellow' : set.team2 > set.team1 ? 'text-white' : 'text-zinc-600'} italic transition-all duration-500`}>
                      {set.team2}
                    </span>
                  </td>
                ))}
                {!isMatchOver && (
                  <td className="text-right px-4 py-8">
                    <div className="bg-padel-yellow inline-flex items-center justify-center min-w-[64px] h-12 rounded-xl shadow-[0_0_20px_rgba(250,204,21,0.3)] transition-transform hover:scale-105 duration-300">
                      <span className="font-black text-2xl text-black tabular-nums">{getPointScore('team2')}</span>
                    </div>
                  </td>
                )}
              </tr>
            </tbody>
          </table>
        </div>

        {/* Footer Info */}
        <div className="bg-white/2 p-6 border-t border-white/5">
          <div className="flex justify-between items-center text-[10px] font-bold text-zinc-500 tracking-widest uppercase">
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
