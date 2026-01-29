import { useState, useEffect } from 'react';
import { doc, onSnapshot } from 'firebase/firestore';
import { db } from '../lib/firebase';
import { MatchState } from '../types/match';

export const useMatch = (matchId: string = "test-match") => {
    const [matchData, setMatchData] = useState<MatchState | null>(null);
    const [lastVersion, setLastVersion] = useState<number>(-1);

    useEffect(() => {
        const unsub = onSnapshot(doc(db, "matches", matchId), (doc) => {
            if (doc.exists()) {
                const data = doc.data() as MatchState;
                const newVersion = Number(data.version ?? 0);

                // Only update if the version is newer or if we don't have a version yet
                if (newVersion >= lastVersion) {
                    setMatchData(data);
                    setLastVersion(newVersion);
                }
            } else {
                console.log("No such document!");
            }
        });

        return () => unsub();
    }, [matchId, lastVersion]);

    return matchData;
};
