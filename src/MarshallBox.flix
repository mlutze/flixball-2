import org.dyn4j.dynamics.Body
import org.dyn4j.world.World

type alias MarshallBox = {
    world = World[Body],
    players = Map[String, (Team, Body, Bot)],
    ball = Body
}