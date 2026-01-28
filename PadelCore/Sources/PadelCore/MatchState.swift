import Foundation

public struct SetResult: Codable, Equatable {
    public let team1Games: Int
    public let team2Games: Int
    
    public init(team1Games: Int, team2Games: Int) {
        self.team1Games = team1Games
        self.team2Games = team2Games
    }
}

public struct MatchState: Codable, Equatable {
    public enum Point: String, Codable, Equatable {
        case zero = "0"
        case fifteen = "15"
        case thirty = "30"
        case forty = "40"
        case advantage = "AD"
        case game = "GAME"
    }

    // Current Game Score
    public var team1Score: Point
    public var team2Score: Point
    
    // Current Tie-break Score
    public var team1TieBreakPoints: Int
    public var team2TieBreakPoints: Int
    
    // Current Set Games
    public var team1Games: Int
    public var team2Games: Int
    
    // Set Score
    public var team1Sets: Int
    public var team2Sets: Int
    
    // History
    public var completedSets: [SetResult]
    
    // Flags
    public var isTieBreak: Bool
    public var isMatchOver: Bool
    
    public init(
        team1Score: Point = .zero,
        team2Score: Point = .zero,
        team1TieBreakPoints: Int = 0,
        team2TieBreakPoints: Int = 0,
        team1Games: Int = 0,
        team2Games: Int = 0,
        team1Sets: Int = 0,
        team2Sets: Int = 0,
        completedSets: [SetResult] = [],
        isTieBreak: Bool = false,
        isMatchOver: Bool = false
    ) {
        self.team1Score = team1Score
        self.team2Score = team2Score
        self.team1TieBreakPoints = team1TieBreakPoints
        self.team2TieBreakPoints = team2TieBreakPoints
        self.team1Games = team1Games
        self.team2Games = team2Games
        self.team1Sets = team1Sets
        self.team2Sets = team2Sets
        self.completedSets = completedSets
        self.isTieBreak = isTieBreak
        self.isMatchOver = isMatchOver
    }
}
