import React from 'react';
import { SetResult } from '../types/match';

interface SetScoreProps {
    set: SetResult;
    isMatchOver: boolean;
    team: 1 | 2;
}

const SetScore: React.FC<SetScoreProps> = ({ set, isMatchOver, team }) => {
    const isCurrent = set.isCurrent && !isMatchOver;
    const isTeamWinner = team === 1 ? set.team1 > set.team2 : set.team2 > set.team1;
    const score = team === 1 ? set.team1 : set.team2;

    const colorClass = isCurrent
        ? 'text-padel-yellow'
        : isTeamWinner ? 'text-white' : 'text-zinc-600';

    return (
        <td className="text-center px-4">
            <span className={`text-2xl md:text-4xl font-black italic transition-all duration-500 ${colorClass}`}>
                {score}
            </span>
        </td>
    );
};

export default SetScore;
