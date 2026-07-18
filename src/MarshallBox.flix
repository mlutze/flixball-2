import org.dyn4j.dynamics.Body
import org.dyn4j.world.World

type alias MarshallBox = {
    world = World[Body],
    players = Map[String, PhysicsPlayer],
    ball = Body,
    state = Ref[GameState, Static],
    timeMs = Ref[Int32, Static],
    preGameJunk = MutList[Body, Static],
    redScore = Ref[Int32, Static],
    blueScore = Ref[Int32, Static]
}

mod MarshallBox {
    pub def addTimeMs(ms: Int32, box: MarshallBox): Unit \ IO = {
        box#timeMs |> Ref.transform(time -> time + ms);
        box#state |> Ref.transform(s -> match s {
            case GameState.Play => GameState.Play
            case GameState.PostGoal({ remainingMs, team }) =>
                GameState.PostGoal({ remainingMs = remainingMs - ms, team = team})
            case GameState.PreGame({ remainingMs }) =>
                GameState.PreGame({ remainingMs = remainingMs - ms})
            case GameState.PostGame({ remainingMs }) =>
                GameState.PostGame({ remainingMs = remainingMs - ms})
            case GameState.Exit => GameState.Exit
        })
    }

    pub def clearJunk(box: MarshallBox): Unit \ IO = {
        match MutList.pop(box#preGameJunk) {
            case None => () // done
            case Some(body) =>
                box#world.removeBody(body);
                clearJunk(box)
        }
    }
}