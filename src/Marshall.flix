
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

    pub def makePlayer(body: Body, name: String, team: Team): Player \ IO = {
        {
            name = name,
            team = team,
            location = getLocation(body),
            velocity = getVelocity(body)
        }
    }

    pub def makePitch(box: MarshallBox): Pitch \ IO = {
        let players = box#players |> Map.mapWithKey(
            name -> match (team, body, _) ->
                makePlayer(body, name, team)
        );
        let ballLocation = getLocation(box#ball);
        let ballVelocity = getVelocity(box#ball);
        { 
            players = players,
            ballLocation = ballLocation,
            ballVelocity = ballVelocity
        }
    }

}