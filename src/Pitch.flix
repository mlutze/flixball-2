type alias Pitch = {
    players = Map[String, Player],
    ballLocation = Location,
    ballVelocity = Velocity,
    redScore = Int32,
    blueScore = Int32,
    state = GameState
}