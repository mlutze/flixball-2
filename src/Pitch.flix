type alias Pitch = {
    players = Map[String, Player],
    ballLocation = Location,
    ballVelocity = Velocity,
    westScore = Int32,
    eastScore = Int32,
    timeMs = Int32,
    state = GameState
}