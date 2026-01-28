import SwiftUI
import Observation
import PadelCore

@Observable
public class MatchViewModel {
    public var state: MatchState
    public var isMatchStarted: Bool = false
    
    private let logic = PadelLogic()
    private var history: [MatchState] = []
    
    public init(state: MatchState = MatchState()) {
        self.state = state
    }
    
    public func startMatch() {
        isMatchStarted = true
    }
    
    public func scorePoint(forTeam1: Bool) {
        // Automatically start match on first point if not already
        if !isMatchStarted { isMatchStarted = true }
        // Save current state to history before updating
        history.append(state)
        state = logic.scorePoint(forTeam1: forTeam1, currentState: state)
    }
    
    public func undoPoint() {
        guard !history.isEmpty else { return }
        state = history.removeLast()
    }
    
    public func finishMatch() {
        // Save state before termination
        history.append(state)
        
        // Record the current (incomplete) set games if any points/games played
        if state.team1Games > 0 || state.team2Games > 0 || state.team1Score != .zero || state.team2Score != .zero {
            state.completedSets.append(SetResult(team1Games: state.team1Games, team2Games: state.team2Games))
        }
        
        state.isMatchOver = true
    }
    
    public func resetMatch() {
        history.removeAll()
        state = MatchState()
        isMatchStarted = false
    }
    
    public var canUndo: Bool {
        return !history.isEmpty
    }
}
