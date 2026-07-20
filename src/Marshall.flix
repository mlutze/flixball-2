
mod Marshall {
    import org.dyn4j.dynamics.Body
    def getLocation(body: Body): Location \ IO = {
        let center = body.getWorldCenter();
        { x = center.x, y = center.y }
    }

    def getVelocity(body: Body): Velocity \ IO = {
        let velocity = body.getLinearVelocity();
        { dx = velocity.x, dy = velocity.y }
    }

    pub def makePlayer(name: String, p: PhysicsPlayer): Player \ IO = {
        team = p#team,
        name = name,
        location = getLocation(p#body),
        velocity = getVelocity(p#body)
    }

    pub def makePitch(box: MarshallBox): Pitch \ IO = {
        let players = box#players |> Map.mapWithKey(
            name -> match physPlayer ->
                makePlayer(name, physPlayer)
        );
        let ballLocation = getLocation(box#ball);
        let ballVelocity = getVelocity(box#ball);
        { 
            players = players,
            ballLocation = ballLocation,
            ballVelocity = ballVelocity,
            westScore = Ref.get(box#westScore),
            eastScore = Ref.get(box#eastScore),
            state = Ref.get(box#state)
        }
    }

}