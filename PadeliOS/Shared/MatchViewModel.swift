import SwiftUI
import Observation
import PadelCore

@Observable
public class MatchViewModel {
    public var state: MatchState
    private let logic = PadelLogic()
    
    public init(state: MatchState = MatchState()) {
        self.state = state
    }
    
    public func scorePoint(forTeam1: Bool) {
        state = logic.scorePoint(forTeam1: forTeam1, currentState: state)
    }
    
    public func resetMatch() {
        state = MatchState()
    }
}
