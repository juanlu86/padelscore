'use client';

import { useState, useEffect } from 'react';
import { signOut } from 'firebase/auth';
import { auth, db } from '../lib/firebase';
import { collection, onSnapshot, query, where } from 'firebase/firestore';
import { Court } from '../types/court';
import CourtList from '../components/CourtList';

export default function Home() {
  const [courts, setCourts] = useState<Court[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Check for logout request
    const params = new URLSearchParams(window.location.search);
    if (params.get('logout') === 'true') {
      signOut(auth).then(() => {
        // Clean URL
        window.history.replaceState({}, '', '/');
      });
    }

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

  if (loading) {
    return (
      <div className="flex min-h-screen items-center justify-center p-6 bg-background text-foreground font-sans">
        <div className="flex flex-col items-center gap-4">
          <div className="w-12 h-12 border-4 border-padel-yellow border-t-transparent rounded-full animate-spin"></div>
          <p className="text-zinc-500 animate-pulse font-medium tracking-wide">LOADING COURTS...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="flex min-h-screen flex-col p-4 md:p-8 bg-background text-foreground font-sans selection:bg-padel-yellow/30 relative overflow-hidden">

      {/* Dynamic Background Flare */}
      <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[600px] h-[600px] rounded-full blur-[120px] opacity-20 bg-padel-yellow/20 pointer-events-none"></div>

      <div className="max-w-4xl mx-auto w-full z-10 space-y-8">

        {/* Header Section */}
        <div className="flex justify-between items-end border-b border-white/5 pb-6">
          <div>
            <h1 className="text-4xl font-black tracking-tight text-white uppercase italic">Live Scores</h1>
            <p className="text-zinc-500 text-sm mt-1 font-medium italic">SELECT A COURT TO WATCH LIVE</p>
          </div>
          <div className="text-right flex flex-col items-end gap-2">
            <span className="text-[10px] font-black text-padel-yellow tracking-[0.2em] uppercase">Status: Online</span>
            <a
              href="/login"
              className="text-[10px] font-bold text-zinc-600 hover:text-white transition-colors uppercase tracking-widest border border-white/5 px-3 py-1 rounded-lg"
            >
              Admin Login
            </a>
          </div>
        </div>

        {/* Court List Component (Read Only) */}
        <CourtList
          courts={courts}
          isAdmin={false}
        />

        {/* Footer Info */}
        <div className="mt-12 text-center text-[10px] font-bold text-zinc-600 uppercase tracking-widest opacity-50">
          <span>Powered by PadelScore</span>
        </div>
      </div>

      {/* Decorative Elements */}
      <div className="fixed bottom-0 left-0 w-full opacity-5 pointer-events-none -z-10">
        <p className="text-[20vw] font-black text-white italic select-none text-center leading-[0.8]">PADEL</p>
      </div>
    </div>
  );
}
