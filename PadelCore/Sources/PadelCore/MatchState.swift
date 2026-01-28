import Foundation

public struct MatchState: Codable, Equatable {
    public enum Point: String, Codable, Equatable, CaseIterable {
        case zero = "0"
        case fifteen = "15"
        case thirty = "30"
        case forty = "40"
        case advantage = "AD"
        case game = "GAME"
    }

    public var team1Score: Point
    public var team2Score: Point
    
    // For now, simple game tracking. 
    // We can expand to Sets and tie-breaks later.
    public var team1Games: Int
    public var team2Games: Int
    
    public init(team1Score: Point = .zero, team2Score: Point = .zero, team1Games: Int = 0, team2Games: Int = 0) {
        self.team1Score = team1Score
        self.team2Score = team2Score
        self.team1Games = team1Games
        self.team2Games = team2Games
    }
}
