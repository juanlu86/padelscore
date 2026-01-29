import React from 'react';
import { MatchState } from '../types/match';
import { getSpecialPointLabel } from '../lib/matchUtils';

interface SpecialPointBadgeProps {
    matchData: MatchState;
}

const SpecialPointBadge: React.FC<SpecialPointBadgeProps> = ({ matchData }) => {
    const label = getSpecialPointLabel(matchData);
    if (!label) return null;

    const isStarPoint = label === 'STAR POINT';
    const themeColor = isStarPoint ? 'from-orange-500 to-yellow-500' : 'from-yellow-400 to-yellow-600';

    return (
        <div className="absolute top-2 left-1/2 -translate-x-1/2 z-50 animate-float pointer-events-none">
            <div className="relative group scale-90 md:scale-100">
                <div className={`absolute inset-0 rounded-full blur-2xl animate-special-glow ${isStarPoint ? 'bg-orange-500/60' : 'bg-yellow-500/60'}`}></div>
                <div className="relative flex items-center gap-3 px-6 py-2 glass rounded-full border border-white/30 shadow-[0_0_30px_rgba(0,0,0,0.5)]">
                    <div className={`w-2 h-2 rounded-full bg-gradient-to-r ${themeColor} animate-pulse shadow-sm`}></div>
                    <span className="text-xs font-black tracking-[0.3em] text-white whitespace-nowrap uppercase drop-shadow-sm">
                        {label}
                    </span>
                    <div className={`w-2 h-2 rounded-full bg-gradient-to-r ${themeColor} animate-pulse shadow-sm`}></div>
                </div>
            </div>
        </div>
    );
};

export default SpecialPointBadge;
