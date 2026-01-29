import { useState, useEffect } from 'react';
import { doc, onSnapshot } from 'firebase/firestore';
import { db } from '../lib/firebase';
import { MatchState } from '../types/match';

export const useMatch = (matchId: string = "test-match") => {
    const [matchData, setMatchData] = useState<MatchState | null>(null);

    useEffect(() => {
        let lastSeenVersion = -1;

        const unsub = onSnapshot(doc(db, "matches", matchId), (snapshot) => {
            if (snapshot.exists()) {
                const data = snapshot.data() as MatchState;
                const newVersion = Number(data.version ?? 0);

                // Update if:
                // 1. It's a newer version
                // 2. It's a reset (e.g. version 0 or 1 while we have a high version)
                // 3. We haven't seen any data yet
                if (newVersion > lastSeenVersion || newVersion <= 1) {
                    setMatchData(data);
                    lastSeenVersion = newVersion;
                }
            } else {
                console.log("No such document!");
            }
        });

        return () => unsub();
    }, [matchId]);

    return matchData;
};
