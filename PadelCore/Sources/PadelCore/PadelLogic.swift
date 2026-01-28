import Foundation

public class PadelLogic {
    public init() {}

    public func scorePoint(forTeam1: Bool, currentState: MatchState) -> MatchState {
        var newState = currentState
        
        if forTeam1 {
            newState = incrementScore(us: currentState.team1Score, them: currentState.team2Score, state: newState, isTeam1: true)
        } else {
            newState = incrementScore(us: currentState.team2Score, them: currentState.team1Score, state: newState, isTeam1: false)
        }
        
        return newState
    }
    
    private func incrementScore(us: MatchState.Point, them: MatchState.Point, state: MatchState, isTeam1: Bool) -> MatchState {
        var newState = state
        
        switch us {
        case .zero:
            if isTeam1 { newState.team1Score = .fifteen } else { newState.team2Score = .fifteen }
        case .fifteen:
            if isTeam1 { newState.team1Score = .thirty } else { newState.team2Score = .thirty }
        case .thirty:
            if isTeam1 { newState.team1Score = .forty } else { newState.team2Score = .forty }
        case .forty:
            if them == .forty {
                // Deuce -> Advantage
                if isTeam1 { newState.team1Score = .advantage } else { newState.team2Score = .advantage }
            } else if them == .advantage {
                // Back to Deuce
                if isTeam1 { newState.team2Score = .forty } else { newState.team1Score = .forty }
            } else {
                // Win Game
                newState = winGame(isTeam1: isTeam1, state: newState)
            }
        case .advantage:
            // Win Game
            newState = winGame(isTeam1: isTeam1, state: newState)
        case .game:
            break // Should not happen in this simple state machine effectively
        }
        
        return newState
    }
    
    private func winGame(isTeam1: Bool, state: MatchState) -> MatchState {
        var newState = state
        if isTeam1 {
            newState.team1Games += 1
        } else {
            newState.team2Games += 1
        }
        // Reset points
        newState.team1Score = .zero
        newState.team2Score = .zero
        return newState
    }
}
