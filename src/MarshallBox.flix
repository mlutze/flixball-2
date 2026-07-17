import org.dyn4j.dynamics.Body
import org.dyn4j.world.World

type alias MarshallBox = {
    world = World[Body],
    players = Map[String, PhysicsPlayer],
    ball = Body,
    timeMs = Ref[Int32, Static]
}

mod MarshallBox {
    pub def addTimeMs(ms: Int32, box: MarshallBox): Unit \ IO = {
        box#timeMs |> Ref.transform(time -> time + ms)
    }
}