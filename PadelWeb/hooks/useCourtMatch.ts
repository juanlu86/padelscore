import { useState, useEffect } from 'react';
import { doc, onSnapshot } from 'firebase/firestore';
import { db } from '../lib/firebase';
import { MatchState } from '../types/match';
import { Court } from '../types/court';

export const useCourtMatch = (courtId: string) => {
    const [matchData, setMatchData] = useState<MatchState | null>(null);
    const [courtName, setCourtName] = useState<string>('');
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        let lastSeenVersion = -1;

        const unsub = onSnapshot(doc(db, "courts", courtId), (snapshot) => {
            if (snapshot.exists()) {
                const courtData = snapshot.data() as Court;
                setCourtName(courtData.name);

                if (courtData.liveMatch) {
                    const data = courtData.liveMatch;
                    const newVersion = Number(data.version ?? 0);

                    if (newVersion > lastSeenVersion || newVersion <= 1) {
                        setMatchData(data);
                        lastSeenVersion = newVersion;
                    }
                } else {
                    setMatchData(null);
                    lastSeenVersion = -1;
                }
                setLoading(false);
            } else {
                console.log("No such court!");
                setLoading(false);
            }
        });

        return () => unsub();
    }, [courtId]);

    return { matchData, courtName, loading };
};
