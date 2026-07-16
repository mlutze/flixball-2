mod Bots {
    import java.lang.Math
    use Constants.pitchLength

    pub def runAtBall(pitch: Pitch, me: Player): Direction = {
        let desiredVelocity = {
            dx = pitch#ballLocation#x - me#location#x,
            dy = pitch#ballLocation#y - me#location#y
        };
        Velocity.toDirection(desiredVelocity)
    }

    // stands still forever
    pub def stayStill(_pitch: Pitch, _me: Player): Direction = {
        { ux = 0.0, uy = 0.0 }
    }

    // runs away from the ball
    pub def runFromBall(pitch: Pitch, me: Player): Direction = {
        let desiredVelocity = {
            dx = me#location#x - pitch#ballLocation#x,
            dy = me#location#y - pitch#ballLocation#y
        };
        Velocity.toDirection(desiredVelocity)
    }

    // picks a random direction each tick — jittery but fun as a baseline
    pub def wander(_pitch: Pitch, _me: Player): Direction = {
        let dx = unsafe IO { Math.random() - 0.5 };
        let dy = unsafe IO { Math.random() - 0.5 };
        Velocity.toDirection({ dx = dx, dy = dy })
    }

    // chases where the ball will be ~0.5 s from now (uses ball velocity)
    pub def interceptBall(pitch: Pitch, me: Player): Direction = {
        let lookahead = 0.5;
        let futureX = pitch#ballLocation#x + pitch#ballVelocity#dx * lookahead;
        let futureY = pitch#ballLocation#y + pitch#ballVelocity#dy * lookahead;
        let desiredVelocity = {
            dx = futureX - me#location#x,
            dy = futureY - me#location#y
        };
        Velocity.toDirection(desiredVelocity)
    }

    // stays halfway between own goal and the ball (Blue defends left, Red defends right)
    pub def defendOwnGoal(pitch: Pitch, me: Player): Direction = {
        let ownGoalX = match me#team {
            case Team.Blue => -pitchLength() / 2.0
            case Team.Red  =>  pitchLength() / 2.0
        };
        let targetX = (ownGoalX + pitch#ballLocation#x) / 2.0;
        let targetY = pitch#ballLocation#y / 2.0;
        let desiredVelocity = {
            dx = targetX - me#location#x,
            dy = targetY - me#location#y
        };
        Velocity.toDirection(desiredVelocity)
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

}
