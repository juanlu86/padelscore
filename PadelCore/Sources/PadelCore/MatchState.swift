import Foundation

public struct SetResult: Codable, Equatable {
    public let team1Games: Int
    public let team2Games: Int
    
    public init(team1Games: Int, team2Games: Int) {
        self.team1Games = team1Games
        self.team2Games = team2Games
    }
}

public enum Score: String, Codable, CaseIterable {
    case zero = "0"
    case fifteen = "15"
    case thirty = "30"
    case forty = "40"
    case advantage = "AD"
    case game = "GAME"
}

public enum ScoringSystem: String, Codable, CaseIterable {
    case standard = "Standard"
    case goldenPoint = "Golden Point"
    case starPoint = "Star Point"
}

public struct MatchState: Codable {
    public var team1Score: Score = .zero
    public var team2Score: Score = .zero
    
    public var team1Games: Int = 0
    public var team2Games: Int = 0
    
    public var team1Sets: Int = 0
    public var team2Sets: Int = 0
    
    public var team1TieBreakPoints: Int = 0
    public var team2TieBreakPoints: Int = 0
    
    public var scoringSystem: ScoringSystem = .standard
    public var deuceCount: Int = 0
    
    public var isTieBreak: Bool = false
    public var isMatchOver: Bool = false
    public var completedSets: [SetResult] = []
    
    public init(
        team1Score: Score = .zero,
        team2Score: Score = .zero,
        team1Games: Int = 0,
        team2Games: Int = 0,
        team1Sets: Int = 0,
        team2Sets: Int = 0,
        team1TieBreakPoints: Int = 0,
        team2TieBreakPoints: Int = 0,
        scoringSystem: ScoringSystem = .standard,
        deuceCount: Int = 0,
        isTieBreak: Bool = false,
        isMatchOver: Bool = false,
        completedSets: [SetResult] = []
    ) {
        self.team1Score = team1Score
        self.team2Score = team2Score
        self.team1Games = team1Games
        self.team2Games = team2Games
        self.team1Sets = team1Sets
        self.team2Sets = team2Sets
        self.team1TieBreakPoints = team1TieBreakPoints
        self.team2TieBreakPoints = team2TieBreakPoints
        self.scoringSystem = scoringSystem
        self.deuceCount = deuceCount
        self.isTieBreak = isTieBreak
        self.isMatchOver = isMatchOver
        self.completedSets = completedSets
    }
}
