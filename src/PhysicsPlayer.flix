import org.dyn4j.dynamics.Body

pub type alias PhysicsPlayer = {
    number = Int32,
    body = Body,
    team = Team,
    bot = Bot
}