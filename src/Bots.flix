mod Bots {
    import java.lang.Math
    use Constants.pitchLength

    pub def runAtBall(pitch: Pitch, name: String): Direction = {
        run {
            let me = pitch#players[name];
            let desiredVelocity = {
                dx = pitch#ballLocation#x - me#location#x,
                dy = pitch#ballLocation#y - me#location#y
            };
            Velocity.toDirection(desiredVelocity)
        } with handler KeyNotFound {
            def keyNotFound(_msg, _k) = unreachable!()
        }
    }

    // stands still forever
    pub def stayStill(_pitch: Pitch, _name: String): Direction = {
        { ux = 0.0, uy = 0.0 }
    }

    // runs away from the ball
    pub def runFromBall(pitch: Pitch, name: String): Direction = {
        run {
            let me = pitch#players[name];
            let desiredVelocity = {
                dx = me#location#x - pitch#ballLocation#x,
                dy = me#location#y - pitch#ballLocation#y
            };
            Velocity.toDirection(desiredVelocity)
        } with handler KeyNotFound {
            def keyNotFound(_msg, _k) = unreachable!()
        }
    }

    // picks a random direction each tick — jittery but fun as a baseline
    pub def wander(_pitch: Pitch, _name: String): Direction = {
        let dx = unsafe IO { Math.random() - 0.5 };
        let dy = unsafe IO { Math.random() - 0.5 };
        Velocity.toDirection({ dx = dx, dy = dy })
    }

    // chases where the ball will be ~0.5 s from now (uses ball velocity)
    pub def interceptBall(pitch: Pitch, name: String): Direction = {
        run {
            let me = pitch#players[name];
            let lookahead = 0.5;
            let futureX = pitch#ballLocation#x + pitch#ballVelocity#dx * lookahead;
            let futureY = pitch#ballLocation#y + pitch#ballVelocity#dy * lookahead;
            let desiredVelocity = {
                dx = futureX - me#location#x,
                dy = futureY - me#location#y
            };
            Velocity.toDirection(desiredVelocity)
        } with handler KeyNotFound {
            def keyNotFound(_msg, _k) = unreachable!()
        }
    }

    // stays halfway between own goal and the ball (Blue defends left, Red defends right)
    pub def defendOwnGoal(pitch: Pitch, name: String): Direction = {
        run {
            let me = pitch#players[name];
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
        } with handler KeyNotFound {
            def keyNotFound(_msg, _k) = unreachable!()
        }
    }
}