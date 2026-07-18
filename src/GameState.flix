enum GameState {
    case PreGame({ remainingMs = Int32 })
    case Play
    case PostGoal({ team = Team, remainingMs = Int32})
    case PostGame({ remainingMs = Int32 })
    case Exit
}