import React from 'react';
import { MatchState, SetResult } from '../types/match';
import SetScore from './SetScore';

interface TeamRowProps {
    team: 1 | 2;
    matchData: MatchState;
    setsToShow: SetResult[];
    isMatchOver: boolean;
    hasWon: boolean;
    otherTeamWon: boolean;
}

const TeamRow: React.FC<TeamRowProps> = ({
    team,
    matchData,
    setsToShow,
    isMatchOver,
    hasWon,
    otherTeamWon
}) => {
    const teamName = team === 1 ? matchData.team1 : matchData.team2;
    const isServing = matchData.servingTeam === team && !isMatchOver;
    const pointScore = team === 1 ? matchData.score?.team1 : matchData.score?.team2;

    return (
        <tr className={`group transition-all duration-500 ${otherTeamWon ? 'opacity-40 grayscale-[0.5]' : ''}`}>
            <td className="py-8 px-2 min-w-[120px]">
                <div className="flex items-center gap-3">
                    {isServing && (
                        <div className="w-2.5 h-2.5 bg-padel-yellow rounded-full shadow-[0_0_8px_rgba(250,204,21,0.6)] animate-pulse shrink-0"></div>
                    )}
                    <div className="flex flex-col">
                        <span className={`text-xl md:text-3xl font-black tracking-tight group-hover:text-white transition-all duration-300 uppercase truncate block ${isServing || hasWon ? 'text-white' : 'text-zinc-400'}`}>
                            {teamName || (team === 1 ? 'Player 1' : 'Player 2')}
                        </span>
                        {hasWon && (
                            <span className="text-[10px] bg-padel-yellow text-black px-2 py-0.5 rounded-full font-black tracking-widest mt-2 w-fit animate-bounce">WINNER</span>
                        )}
                    </div>
                </div>
            </td>
            {setsToShow.map((set, i) => (
                <SetScore key={i} set={set} isMatchOver={isMatchOver} team={team} />
            ))}
            {!isMatchOver && (
                <td className="text-right px-4 py-8">
                    <div className="bg-padel-yellow inline-flex items-center justify-center min-w-[64px] h-12 rounded-xl shadow-[0_0_20px_rgba(250,204,21,0.3)] transition-transform hover:scale-105 duration-300">
                        <span className="font-black text-2xl text-black tabular-nums">{pointScore ?? '0'}</span>
                    </div>
                </td>
            )}
        </tr>
    );
};

export default TeamRow;
