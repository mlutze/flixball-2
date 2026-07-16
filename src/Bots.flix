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

    pub def shootHarderEast(pitch: Pitch, me: Player): Direction = {
        shootHarder(Locations.goalCenterE(), pitch, me)
    }

    pub def shootHarderWest(pitch: Pitch, me: Player): Direction = {
        shootHarder(Locations.goalCenterW(), pitch, me)
    }

    // like shoot, but ram the ball if we're close enough to lined up
    def shootHarder(goal: Location, pitch: Pitch, me: Player): Direction = {
        let ball = pitch#ballLocation;
        let goalBallDir = Direction.fromTo(goal, ball);
        let centerCenterDist = Constants.playerRadius() + Constants.ballRadius();
        let ballTargetDisplacement = Displacement.inDirection(goalBallDir, centerCenterDist);
        let target = Displacement.apply(ballTargetDisplacement, ball);
        let dis = Displacement.fromTo(me#location, target);
        let dist = Displacement.distance(dis);
        if (dist > 0.1) {
            // must line up
            Direction.fromTo(me#location, target)
        } else {
            // ram the ball
            Direction.fromTo(me#location, ball)
        }
    }

    pub def shootSmarterEast(pitch: Pitch, me: Player): Direction = {
        shootSmarter(Locations.goalCenterE(), pitch, me)
    }

    pub def shootSmarterWest(pitch: Pitch, me: Player): Direction = {
        shootSmarter(Locations.goalCenterW(), pitch, me)
    }

    // like shoot,
    // but if we are in front of the ball, go tangent to it instead
    pub def shootSmarter(goal: Location, pitch: Pitch, me: Player): Direction = {
        let ballToGoal = Direction.fromTo(pitch#ballLocation, goal);
        let ballToMe = Direction.fromTo(pitch#ballLocation, me#location);
        let angle = Direction.angle(ballToGoal, ballToMe);
        if (Float64.abs(angle) < Math.PI * 0.75) {
            // we are between the ball and the goal, go tangent
            let sign = angle / Float64.abs(angle);
            Direction.addAngle(ballToMe, sign * Math.PI * 0.5)
        } else {
            shootHarder(goal, pitch, me)
        }
    }

    pub def shoot4East(pitch: Pitch, me: Player): Direction =
        shoot4(Locations.goalpostNE(), Locations.goalpostSE(), pitch, me)

    pub def shoot4West(pitch: Pitch, me: Player): Direction =
        shoot4(Locations.goalpostNW(), Locations.goalpostSW(), pitch, me)

    // approach the lining-up spot (2 m behind the ball) until within 2 m of the ball,
    // then circle to line up a kick between the two goalposts; once lined up, ram the ball
    pub def shoot4(goalN: Location, goalS: Location, pitch: Pitch, me: Player): Direction = {
        let ball = pitch#ballLocation;
        let goalCenter = {
            x = (goalN#x + goalS#x) / 2.0,
            y = (goalN#y + goalS#y) / 2.0
        };
        let goalToBall = Direction.fromTo(goalCenter, ball);
        let distToBall = Displacement.distance(Displacement.fromTo(me#location, ball));

        if (distToBall > 2.0) {
            // approach the lining-up spot: 2 m behind the ball on the far side from the goal
            let approachDisp   = Displacement.inDirection(goalToBall, 2.0);
            let approachTarget = Displacement.apply(approachDisp, ball);
            Direction.fromTo(me#location, approachTarget)
        } else {
            // kickDir = direction the ball will travel after we ram it
            let kickDir  = Direction.fromTo(me#location, ball);
            let ballToN  = Direction.fromTo(ball, goalN);
            let ballToS  = Direction.fromTo(ball, goalS);

            // is kickDir inside the arc from ballToN to ballToS (short arc)?
            let goalSpan = Direction.angle(ballToN, ballToS);
            let fromN    = Direction.angle(ballToN, kickDir);

            let lined = fromN * goalSpan >= 0.0 and Float64.abs(fromN) <= Float64.abs(goalSpan);
            if (lined) {
                // lined up — kick it
                Direction.fromTo(me#location, ball)
            } else {
                // need to circle. Rotate kickDir toward the goal centre.
                let ballToCenter = Direction.fromTo(ball, goalCenter);
                let toCenter     = Direction.angle(kickDir, ballToCenter);
                // to rotate kickDir CCW (positive toCenter), we must move in the
                // direction perpendicular-CW to kickDir; hence -sign
                let sign = if (toCenter > 0.0) 1.0 else -1.0;
                Direction.addAngle(kickDir, -sign * Math.PI / 2.0)
            }
        }
    }

    pub def circleAndShootEast(pitch: Pitch, me: Player): Direction = {
        circleAndShoot(Locations.goalCenterE(), pitch, me)
    }

    pub def circleAndShootWest(pitch: Pitch, me: Player): Direction = {
        circleAndShoot(Locations.goalCenterW(), pitch, me)
    }

    def circleAndShoot(goal: Location, pitch: Pitch, me: Player): Direction = {
        // runs in a circle that is tangent to the proper shooting angle

        let ballToGoal = Direction.fromTo(pitch#ballLocation, goal);
        let meToBall = Direction.fromTo(me#location, pitch#ballLocation);

        let theta = Direction.angle(ballToGoal, meToBall);
        let adjustedTheta = theta * 2.0;
        let boundedTheta = adjustedTheta |> Float64.max(-Math.PI / 2.0) |> Float64.min(Math.PI / 2.0);

        Direction.addAngle(meToBall, boundedTheta)
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
