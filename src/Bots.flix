mod Bots {
    import java.lang.Math

    pub def runAtBall(pitch: Pitch, me: Player): Direction = {
        Direction.fromTo(me#location, pitch#ballLocation)
    }

    // stands still forever
    pub def stayStill(_pitch: Pitch, _me: Player): Direction = {
        { ux = 0.0, uy = 0.0 }
    }

    // runs away from the ball
    pub def runFromBall(pitch: Pitch, me: Player): Direction = {
        Direction.fromTo(pitch#ballLocation, me#location)
    }

    // picks a random direction each tick — jittery but fun as a baseline
    pub def wander(_pitch: Pitch, _me: Player): Direction = {
        let dx = unsafe IO { Math.random() - 0.5 };
        let dy = unsafe IO { Math.random() - 0.5 };
        Displacement.getDirection({ dx = dx, dy = dy })
    }

    // chases where the ball will be ~0.5 s from now (uses ball velocity)
    pub def interceptBall(pitch: Pitch, me: Player): Direction = {
        let lookahead = 0.5;
        let future = {
            x = pitch#ballLocation#x + pitch#ballVelocity#dx * lookahead,
            y = pitch#ballLocation#y + pitch#ballVelocity#dy * lookahead
        };
        Direction.fromTo(me#location, future)
    }

    // stays halfway between own goal and the ball (Blue defends left, Red defends right)
    pub def defendOwnGoal(pitch: Pitch, me: Player): Direction = {
        let ownGoal = match me#team {
            case Team.Blue => Locations.goalCenterW()
            case Team.Red  => Locations.goalCenterE()
        };
        let target = {
            x = (ownGoal#x + pitch#ballLocation#x) / 2.0,
            y = pitch#ballLocation#y / 2.0
        };
        Direction.fromTo(me#location, target)
    }

    pub def shootEast(pitch: Pitch, me: Player): Direction = {
        shoot(Locations.goalCenterE(), pitch, me)
    }

    pub def shootWest(pitch: Pitch, me: Player): Direction = {
        shoot(Locations.goalCenterW(), pitch, me)
    }

    // go to the location where I'll be tangent to the ball,
    // and that tangent lines up with the goal
    def shoot(goal: Location, pitch: Pitch, me: Player): Direction = {
        let ball = pitch#ballLocation;
        let goalBallDir = Direction.fromTo(goal, ball);
        let centerCenterDist = Constants.playerRadius() + Constants.ballRadius();
        let ballTargetDisplacement = Displacement.inDirection(goalBallDir, centerCenterDist);
        let target = Displacement.apply(ballTargetDisplacement, ball);
        Direction.fromTo(me#location, target)
    }

    pub def defendEast(pitch: Pitch, me: Player): Direction = {
        defend(Locations.goalCenterE(), pitch, me)
    }

    pub def defendWest(pitch: Pitch, me: Player): Direction = {
        defend(Locations.goalCenterW(), pitch, me)
    }

    // stay 1 meter in front of goal
    // on the line between the center of the goal and the ball
    pub def defend(goal: Location, pitch: Pitch, me: Player): Direction = {
        let minY = Locations.goalpostSE()#y;
        let maxY = Locations.goalpostNE()#y;
        let targetY = pitch#ballLocation#y |> Float64.max(minY) |> Float64.min(maxY);
        let goalToBall = Direction.fromTo(goal, pitch#ballLocation);
        let disp = Displacement.inDirection(goalToBall, 1.0);
        let baseTarget = Displacement.apply(disp, goal);
        let targetX = baseTarget#x;
        let target = {
            x = targetX,
            y = targetY
        };
        Direction.fromTo(me#location, target)
    }

}
