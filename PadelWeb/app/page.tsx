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

  if (!matchData) return <div className="p-10">Loading Padel Match...</div>;

  return (
    <div className="flex min-h-screen items-center justify-center p-10 font-sans">
      <div className="bg-white dark:bg-zinc-900 border dark:border-zinc-800 shadow-xl rounded-xl p-8 max-w-md w-full">
        <h1 className="text-2xl font-bold mb-6 text-center">PadelScore Live</h1>

        <div className="flex justify-between items-center bg-gray-50 dark:bg-zinc-800 p-4 rounded-lg">
          <div className="flex flex-col items-center">
            <span className="text-sm text-gray-500 mb-1">Team 1</span>
            <span className="font-semibold text-lg">{matchData.team1}</span>
            <span className="text-4xl font-bold text-blue-600 mt-2">{matchData.score?.team1 || '0'}</span>
          </div>

          <div className="h-12 w-px bg-gray-300 mx-4"></div>

          <div className="flex flex-col items-center">
            <span className="text-sm text-gray-500 mb-1">Team 2</span>
            <span className="font-semibold text-lg">{matchData.team2}</span>
            <span className="text-4xl font-bold text-red-600 mt-2">{matchData.score?.team2 || '0'}</span>
          </div>
        </div>

        <div className="mt-6 text-center">
          <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${matchData.status === 'live' ? 'bg-green-100 text-green-800' : 'bg-gray-100 text-gray-800'}`}>
            {matchData.status?.toUpperCase()}
          </span>
        </div>
      </div>
    </div>
  );
}
