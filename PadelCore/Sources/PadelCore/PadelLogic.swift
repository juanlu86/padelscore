import Foundation

public class PadelLogic {
    public init() {}

    public func scorePoint(forTeam1: Bool, currentState: MatchState) -> MatchState {
        if currentState.isMatchOver { return currentState }
        
        var newState = currentState
        
        if currentState.isTieBreak {
            newState = scoreTieBreakPoint(forTeam1: forTeam1, state: newState)
        } else {
            newState = scoreNormalPoint(forTeam1: forTeam1, state: newState)
        }
        
        return newState
    }
    
    private func scoreNormalPoint(forTeam1: Bool, state: MatchState) -> MatchState {
        var newState = state
        
        let us = forTeam1 ? state.team1Score : state.team2Score
        let them = forTeam1 ? state.team2Score : state.team1Score
        
        switch us {
        case .zero:
            if forTeam1 { newState.team1Score = .fifteen } else { newState.team2Score = .fifteen }
        case .fifteen:
            if forTeam1 { newState.team1Score = .thirty } else { newState.team2Score = .thirty }
        case .thirty:
            if forTeam1 { 
                newState.team1Score = .forty 
                if them == .forty { newState.deuceCount += 1 }
            } else { 
                newState.team2Score = .forty 
                if them == .forty { newState.deuceCount += 1 }
            }
        case .forty:
            if them == .forty {
                // We ARE at 40-40. Check for Golden Point / Star Point Sudden Death
                if newState.scoringSystem == .goldenPoint || (newState.scoringSystem == .starPoint && newState.deuceCount >= 3) {
                    newState = winGame(isTeam1: forTeam1, state: newState)
                } else {
                    // Standard deuce: Enter Advantage state
                    if forTeam1 { newState.team1Score = .advantage } else { newState.team2Score = .advantage }
                }
            } else if them == .advantage {
                // Return to Deuce from Advantage
                newState.team1Score = .forty
                newState.team2Score = .forty
                newState.deuceCount += 1
            } else {
                // Win Game
                newState = winGame(isTeam1: forTeam1, state: newState)
            }
        case .advantage:
            // Win Game normally
            newState = winGame(isTeam1: forTeam1, state: newState)
        case .game:
            break
        }
        
        return newState
    }
    
    private func scoreTieBreakPoint(forTeam1: Bool, state: MatchState) -> MatchState {
        var newState = state
        
        if forTeam1 {
            newState.team1TieBreakPoints += 1
        } else {
            newState.team2TieBreakPoints += 1
        }
        
        let usPoints = forTeam1 ? newState.team1TieBreakPoints : newState.team2TieBreakPoints
        let themPoints = forTeam1 ? newState.team2TieBreakPoints : newState.team1TieBreakPoints
        
        // 7 points and 2-point lead to win
        if usPoints >= 7 && (usPoints - themPoints >= 2) {
            newState = winGame(isTeam1: forTeam1, state: newState)
        }
        
        return newState
    }
    
    private func winGame(isTeam1: Bool, state: MatchState) -> MatchState {
        var newState = state
        let wasTieBreak = state.isTieBreak
        
        if isTeam1 {
            newState.team1Games += 1
        } else {
            newState.team2Games += 1
        }
        
        // Reset point scores
        newState.team1Score = .zero
        newState.team2Score = .zero
        newState.team1TieBreakPoints = 0
        newState.team2TieBreakPoints = 0
        newState.isTieBreak = false
        newState.deuceCount = 0
        
        // Check for Tie-break trigger (6-6)
        if newState.useTieBreak && !wasTieBreak && newState.team1Games == 6 && newState.team2Games == 6 {
            newState.isTieBreak = true
            return newState
        }
        
        // Check for Set win
        let usGames = isTeam1 ? newState.team1Games : newState.team2Games
        let themGames = isTeam1 ? newState.team2Games : newState.team1Games
        
        // Set win condition:
        // 1. Just won a tie-break (7-6)
        // 2. Won by 2 games and have at least 6 games (6-0..6-4, 7-5, 8-6, etc.)
        if wasTieBreak || (usGames >= 6 && (usGames - themGames >= 2)) {
            newState = winSet(isTeam1: isTeam1, state: newState)
        }
        
        return newState
    }
    
    private func winSet(isTeam1: Bool, state: MatchState) -> MatchState {
        var newState = state
        
        // Record set result
        newState.completedSets.append(SetResult(team1Games: state.team1Games, team2Games: state.team2Games))
        
        if isTeam1 {
            newState.team1Sets += 1
        } else {
            newState.team2Sets += 1
        }
        
        // Reset games for next set
        newState.team1Games = 0
        newState.team2Games = 0
        
        // Check for Match win (Best of 3)
        if newState.team1Sets == 2 || newState.team2Sets == 2 {
            newState.isMatchOver = true
        }
        
        return newState
    }
}
