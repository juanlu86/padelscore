import React from 'react';
import { MatchState } from '../types/match';
import { getSetsToShow, isMatchFinished, calculateSetsWon } from '../lib/matchUtils';
import TeamRow from './TeamRow';
import SpecialPointBadge from './SpecialPointBadge';

interface ScoreBoardProps {
    matchData: MatchState;
}

const ScoreBoard: React.FC<ScoreBoardProps> = ({ matchData }) => {
    const setsToShow = getSetsToShow(matchData);
    const isOver = isMatchFinished(matchData);
    const { team1: t1Sets, team2: t2Sets } = calculateSetsWon(matchData);

    const team1Won = isOver && t1Sets > t2Sets;
    const team2Won = isOver && t2Sets > t1Sets;

    return (
        <div className="p-8 lg:p-12 overflow-x-auto overflow-y-hidden relative">
            <SpecialPointBadge matchData={matchData} />

            <table className="w-full border-collapse">
                <thead>
                    <tr className="border-b border-white/5">
                        <th className="text-left pb-4 text-[10px] font-black text-zinc-500 uppercase tracking-widest px-2">Teams</th>
                        {setsToShow.map((_, i) => (
                            <th key={i} className="pb-4 text-[10px] font-black text-zinc-500 uppercase tracking-widest text-center px-4">Set {i + 1}</th>
                        ))}
                        {!isOver && <th className="pb-4 text-[10px] font-black text-padel-yellow uppercase tracking-widest text-right px-4">Points</th>}
                    </tr>
                </thead>
                <tbody className="divide-y divide-white/5">
                    <TeamRow
                        team={1}
                        matchData={matchData}
                        setsToShow={setsToShow}
                        isMatchOver={isOver}
                        hasWon={team1Won}
                        otherTeamWon={team2Won}
                    />
                    <TeamRow
                        team={2}
                        matchData={matchData}
                        setsToShow={setsToShow}
                        isMatchOver={isOver}
                        hasWon={team2Won}
                        otherTeamWon={team1Won}
                    />
                </tbody>
            </table>
        </div>
    );
};

export default ScoreBoard;
