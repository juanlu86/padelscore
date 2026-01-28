import SwiftUI
import Observation
import PadelCore

@Observable
public class MatchViewModel {
    public var state: MatchState
    private let logic = PadelLogic()
    private var history: [MatchState] = []
    
    public init(state: MatchState = MatchState()) {
        self.state = state
    }
    
    public func scorePoint(forTeam1: Bool) {
        // Save current state to history before updating
        history.append(state)
        state = logic.scorePoint(forTeam1: forTeam1, currentState: state)
    }
    
    public func undoPoint() {
        guard !history.isEmpty else { return }
        state = history.removeLast()
    }
    
    public func resetMatch() {
        history.removeAll()
        state = MatchState()
    }
    
    public var canUndo: Bool {
        return !history.isEmpty
    }
}
