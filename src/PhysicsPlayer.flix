import org.dyn4j.dynamics.Body

pub type alias PhysicsPlayer = {
    body = Body,
    team = Team,
    bot = Bot,
    state = Ref[Int8, Static]
}