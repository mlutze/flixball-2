mod Bots {
    import java.lang.Math

    pub def mkBot(f: (Pitch, Player) -> Direction \ BotEffects - ef): Bot = {
        (pitch, player) -> eidentity(f(pitch, player))
    }


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

    pub def closeCircleAndShootEast(pitch: Pitch, me: Player): Direction = {
        closeCircleAndShoot(Locations.goalCenterE(), pitch, me)
    }

    pub def closeCircleAndShootWest(pitch: Pitch, me: Player): Direction = {
        closeCircleAndShoot(Locations.goalCenterW(), pitch, me)
    }

    def closeCircleAndShoot(goal: Location, pitch: Pitch, me: Player): Direction = {
        let disp = Displacement.fromTo(pitch#ballLocation, me#location);
        if (Displacement.distance(disp) > 5.0) {
            runAtBall(pitch, me)
        } else {
            circleAndShoot(goal, pitch, me)
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
        // bug: this isn't quite the proper shooting angle because it does not take into account player / ball radius

        let target = contactPoint(goal, pitch);
        let ballToGoal = Direction.fromTo(pitch#ballLocation, goal);
        let meToTarget = Direction.fromTo(me#location, target);

        let theta = Direction.angle(ballToGoal, meToTarget);
        let adjustedTheta = theta * 1.0;
        let boundedTheta = adjustedTheta |> Float64.max(-Math.PI / 2.0) |> Float64.min(Math.PI / 2.0);

        Direction.addAngle(meToTarget, boundedTheta)
    }

    // the location one must be to strike the ball such that it will enter the goal (ignoring momentum)
    def contactPoint(goal: Location, pitch: Pitch): Location = {
        let ball = pitch#ballLocation;
        let goalToBall = Direction.fromTo(goal, ball);
        let centerCenterDist = Constants.playerRadius() + Constants.ballRadius();
        let ballTargetDisplacement = Displacement.inDirection(goalToBall, centerCenterDist);
        Displacement.apply(ballTargetDisplacement, ball)
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

    pub def avoidGoalieEast(pitch: Pitch, me: Player): Direction \ BotState = {
        avoidGoalie(Locations.goalpostNE(), Locations.goalpostSE(), pitch, me)
    }

    pub def avoidGoalieWest(pitch: Pitch, me: Player): Direction \ BotState = {
        avoidGoalie(Locations.goalpostNW(), Locations.goalpostSW(), pitch, me)
    }

    // see what edge the goalie is closer to and kick toward the opposite edge of the goal
    pub def avoidGoalie(goalpostN: Location, goalpostS: Location, pitch: Pitch, me: Player): Direction \ BotState = {
        let ball = pitch#ballLocation;

        // We assume the goalie is the closest player to the goal
        let goalCenter = Location.midpoint(goalpostN, goalpostS);
        let (_, goalie) = pitch#players
            |> Map.minimumValueBy(Utils.mkCmp(p -> Location.distance(p#location, goalCenter)))
            |> Utils.unsafeGetOpt; // we know there's at least one player, which is the one associated with the bot
        
        // See which side the goalie is closer to
        let distN = Location.distance(goalie#location, goalpostN);
        let distS = Location.distance(goalie#location, goalpostS);
        
        // if the goalie is significantly closer to the north side, then we will look south
        let newLookingNorth = if (distS - distN > 2.0) {
            false
        } else if (distN - distS > 2.0){
            true
        } else {
            // if it's in the middle then we don't change
            BotState.getState()
        };
        BotState.setState(newLookingNorth);

        let goal = if (newLookingNorth) {
            // Goalie is north; aim south (adding space for the ball)
            let disp = Displacement.inDirection(Direction.north(), Constants.ballRadius());
            Displacement.apply(disp, goalpostS)
        } else {
            // Goalie is south; aim north (adding space for the ball)
            let disp = Displacement.inDirection(Direction.south(), Constants.ballRadius());
            Displacement.apply(disp, goalpostN)
        };

        let goalBallDir = Direction.fromTo(goal, ball);
        let centerCenterDist = Constants.playerRadius() + Constants.ballRadius();
        let ballTargetDisplacement = Displacement.inDirection(goalBallDir, centerCenterDist);
        let target = Displacement.apply(ballTargetDisplacement, ball);
        Direction.fromTo(me#location, target)
    }

    pub def runAtFutureBall(pitch: Pitch, me: Player): Direction = {
        let ballVelocity = pitch#ballVelocity;
        let ballDirection = Velocity.toDirection(ballVelocity);
        let ballToMe = Direction.fromTo(pitch#ballLocation, me#location);
        let epsilon = Direction.angle(ballDirection, ballToMe);

        let ballSpeed = Velocity.speed(ballVelocity);
        let mySpeed = Velocity.speed(me#velocity);

        let theta = unsafe IO { Math.acos(ballSpeed / mySpeed * Math.sin(epsilon)) };

        let meToBall = Direction.invert(ballToMe);
        Direction.addAngle(meToBall, theta)
    }

}
