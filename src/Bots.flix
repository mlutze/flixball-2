mod Bots {
    use Math.Random

    pub def mkBot(f: (Pitch, Player) -> Direction \ BotEffects - ef): Bot = {
        (pitch, player) -> eidentity(f(pitch, player))
    }


    pub def bots(): Map[String, Bot] = Map#{
        "Stay Still" => mkBot(stayStill),
        "Run at Ball" => mkBot(runAtBall),
        "Run from Ball" => mkBot(runFromBall),
        "Run at Future Ball" => mkBot(runAtFutureBall),
        "Wander" => mkBot(wander),
        "Intercept Ball" => mkBot(interceptBall),
        "Defend" => mkBot(defend),
        "Defend own Goal" => mkBot(defendOwnGoal),
        "Avoid Goalie" => mkBot(avoidGoalie),
        "Shoot" => mkBot(shoot),
        "Shoot Harder" => mkBot(shootHarder),
        "Shoot Smarter" => mkBot(shootSmarter),
        "Circle and Shoot" => mkBot(circleAndShoot),
        "Close Circle and Shoot" => mkBot(closeCircleAndShoot),
        "Close Circle and Shoot Hard" => mkBot(closeCircleAndShootHard),
        "Approach, Circle, and Shoot" => mkBot(approachCircleAndShoot)
    }

    def goalCenter(team: Team): Location = match team {
        case Team.East => Locations.goalCenterE()
        case Team.West => Locations.goalCenterW()
    }

    def goalposts(team: Team): (Location, Location) = match team {
        case Team.East => (Locations.goalpostNE(), Locations.goalpostSE())
        case Team.West => (Locations.goalpostNW(), Locations.goalpostSW())
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
    pub def wander(_pitch: Pitch, _me: Player): Direction \ Random = {
        let dx = Random.randomFloat64() - 0.5;
        let dy = Random.randomFloat64() - 0.5;
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

    // stays halfway between own goal and the ball
    pub def defendOwnGoal(pitch: Pitch, me: Player): Direction = {
        let ownGoal = goalCenter(me#team);
        let target = {
            x = (ownGoal#x + pitch#ballLocation#x) / 2.0,
            y = pitch#ballLocation#y / 2.0
        };
        Direction.fromTo(me#location, target)
    }

    pub def shoot(pitch: Pitch, me: Player): Direction = {
        let goal = goalCenter(Team.opp(me#team));
        shootAt(goal, pitch, me)
    }

    // go to the location where I'll be tangent to the ball,
    // and that tangent lines up with the goal
    def shootAt(goal: Location, pitch: Pitch, me: Player): Direction = {
        let ball = pitch#ballLocation;
        let goalBallDir = Direction.fromTo(goal, ball);
        let centerCenterDist = Constants.playerRadius() + Constants.ballRadius();
        let ballTargetDisplacement = Displacement.inDirection(goalBallDir, centerCenterDist);
        let target = Displacement.apply(ballTargetDisplacement, ball);
        Direction.fromTo(me#location, target)
    }

    pub def shootHarder(pitch: Pitch, me: Player): Direction = {
        let goal = goalCenter(Team.opp(me#team));
        shootHarderAt(goal, pitch, me)
    }

    // like shoot, but ram the ball if we're close enough to lined up
    def shootHarderAt(goal: Location, pitch: Pitch, me: Player): Direction = {
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

    pub def shootSmarter(pitch: Pitch, me: Player): Direction = {
        let goal = goalCenter(Team.opp(me#team));
        shootSmarterAt(goal, pitch, me)
    }

    // like shoot,
    // but if we are in front of the ball, go tangent to it instead
    def shootSmarterAt(goal: Location, pitch: Pitch, me: Player): Direction = {
        let ballToGoal = Direction.fromTo(pitch#ballLocation, goal);
        let ballToMe = Direction.fromTo(pitch#ballLocation, me#location);
        let angle = Direction.angle(ballToGoal, ballToMe);
        if (Float64.abs(angle) < Trig.pi() * 0.75) {
            // we are between the ball and the goal, go tangent
            let sign = angle / Float64.abs(angle);
            Direction.addAngle(ballToMe, sign * Trig.pi() * 0.5)
        } else {
            shootHarderAt(goal, pitch, me)
        }
    }

    pub def closeCircleAndShoot(pitch: Pitch, me: Player): Direction = {
        if (isBehindGoal(me#location) and not isBehindGoal(pitch#ballLocation)) {
            escapeBehindGoal(pitch, me)
        } else {
            let goal = goalCenter(Team.opp(me#team));
            closeCircleAndShootAt(goal, pitch, me)
        }
    }

    def closeCircleAndShootAt(goal: Location, pitch: Pitch, me: Player): Direction = {
        let disp = Displacement.fromTo(pitch#ballLocation, me#location);
        if (Displacement.distance(disp) > 5.0) {
            runAtBall(pitch, me)
        } else {
            circleAndShootAt(goal, pitch, me)
        }
    }

    pub def closeCircleAndShootHard(pitch: Pitch, me: Player): Direction = {
        let goal = goalCenter(Team.opp(me#team));
        closeCircleAndShootHardAt(goal, pitch, me)
    }

    def closeCircleAndShootHardAt(goal: Location, pitch: Pitch, me: Player): Direction = {
        let disp = Displacement.fromTo(pitch#ballLocation, me#location);
        // if I'm making contact with the ball, then keep going
        if (Displacement.distance(disp) < Constants.ballRadius() + Constants.playerRadius()) {
            me#velocity |> Velocity.toDirection
        } else {
            closeCircleAndShootAt(goal, pitch, me)
        }
    }

    pub def circleAndShoot(pitch: Pitch, me: Player): Direction = {
        let goal = goalCenter(Team.opp(me#team));
        circleAndShootAt(goal, pitch, me)
    }

    def circleAndShootAt(goal: Location, pitch: Pitch, me: Player): Direction = {
        // runs in a circle that is tangent to the proper shooting angle
        // bug: this isn't quite the proper shooting angle because it does not take into account player / ball radius

        let target = contactPoint(goal, pitch);
        let ballToGoal = Direction.fromTo(pitch#ballLocation, goal);
        let meToTarget = Direction.fromTo(me#location, target);

        let theta = Direction.angle(ballToGoal, meToTarget);
        let adjustedTheta = theta * 1.0;
        let boundedTheta = adjustedTheta |> Float64.max(-Trig.pi() / 2.0) |> Float64.min(Trig.pi() / 2.0);

        Direction.addAngle(meToTarget, boundedTheta)
    }

    pub def approachCircleAndShoot(pitch: Pitch, me: Player): Direction = {
        let goal = goalCenter(Team.opp(me#team));
        approachCircleAndShootAt(goal, pitch, me)
    }

    def approachCircleAndShootAt(goal: Location, pitch: Pitch, me: Player): Direction = {
        if (isBehindGoal(me#location) and not isBehindGoal(pitch#ballLocation)) {
            escapeBehindGoal(pitch, me)
        } else {
            let meToBall = Location.distance(me#location, pitch#ballLocation);
            if (meToBall <= 6.0) {
                circleAndShootAt(goal, pitch, me)
            } else {
                approachCircle(goal, pitch, me)
            }
        }
    }

    def approachCircle(goal: Location, pitch: Pitch, me: Player): Direction = {
        let radius = 2.75;
        let target = contactPoint(goal, pitch);
        let ballToGoal = Direction.fromTo(target, goal);

        let ballToCenterLeft = Direction.addAngle(ballToGoal, Trig.pi() / 2.0);
        let ballToCenterLeftDisp = Displacement.inDirection(ballToCenterLeft, radius);
        let centerLeft = Displacement.apply(ballToCenterLeftDisp, target);
        let centerLeftDist = Location.distance(me#location, centerLeft);

        let ballToCenterRight = Direction.addAngle(ballToGoal, -Trig.pi() / 2.0);
        let ballToCenterRightDisp = Displacement.inDirection(ballToCenterRight, radius);
        let centerRight = Displacement.apply(ballToCenterRightDisp, target);
        let centerRightDist = Location.distance(me#location, centerRight);

        // decide if we're circling left or right
        let (center, rot) = if (centerLeftDist < centerRightDist) {
            (centerLeft, -1.0)
        } else {
            (centerRight, 1.0)
        };
        let meToCenter = Displacement.fromTo(me#location, center);
        let d_c = Displacement.distance(meToCenter);
        let theta_t = rot * Trig.asin(radius / d_c);
        let meToCenterDir = Displacement.getDirection(meToCenter);
        Direction.addAngle(meToCenterDir, theta_t)
    }

    // the location one must be to strike the ball such that it will enter the goal (ignoring momentum)
    def contactPoint(goal: Location, pitch: Pitch): Location = {
        let ball = pitch#ballLocation;
        let goalToBall = Direction.fromTo(goal, ball);
        let centerCenterDist = Constants.playerRadius() + Constants.ballRadius();
        let ballTargetDisplacement = Displacement.inDirection(goalToBall, centerCenterDist);
        Displacement.apply(ballTargetDisplacement, ball)
    }

    pub def defend(pitch: Pitch, me: Player): Direction = {
        let goal = goalCenter(me#team);
        defendAt(goal, pitch, me)
    }

    // stay 1 meter in front of goal
    // on the line between the center of the goal and the ball
    def defendAt(goal: Location, pitch: Pitch, me: Player): Direction = {
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

    pub def avoidGoalie(pitch: Pitch, me: Player): Direction \ BotState = {
        let (goalpostN, goalpostS) = goalposts(Team.opp(me#team));
        avoidGoalieAt(goalpostN, goalpostS, pitch, me)
    }

    // see what edge the goalie is closer to and kick toward the opposite edge of the goal
    def avoidGoalieAt(goalpostN: Location, goalpostS: Location, pitch: Pitch, me: Player): Direction \ BotState = {
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

        // If I don't have a speed then I can't calculate
        // and if the ball doesn't have a speed then I might as well run at it.
        if (mySpeed < 0.01 or ballSpeed < 0.01) {
            runAtBall(pitch, me)
        } else {
            let theta = Trig.asin(ballSpeed / mySpeed * Trig.sin(epsilon));
            let meToBall = Direction.invert(ballToMe);
            Direction.addAngle(meToBall, theta)
        }
    }

    pub def isBehindGoal(loc: Location): Bool = {
        let xW = Locations.goalBackNW()#x;
        let xE = Locations.goalBackNE()#x;
        let yMax = Locations.goalBackNW()#y;
        let yMin = Locations.goalBackSW()#y;
        loc#y < yMax and loc#y > yMin and (loc#x < xW or loc#x > xE)
    }

    def escapeBehindGoal(_pitch: Pitch, me: Player): Direction = {
        // go to the closest corner of the goal
        let nw = Displacement.apply(
            Displacement.inDirection(Direction.northwest(), Constants.playerRadius()),
            Locations.goalBackNW()
        );
        let ne = Displacement.apply(
            Displacement.inDirection(Direction.northeast(), Constants.playerRadius()),
            Locations.goalBackNE()
        );
        let sw = Displacement.apply(
            Displacement.inDirection(Direction.southwest(), Constants.playerRadius()),
            Locations.goalBackSW()
        );
        let se = Displacement.apply(
            Displacement.inDirection(Direction.southeast(), Constants.playerRadius()),
            Locations.goalBackSE()
        );
        
        let locs = Nel(nw, List#{ne, sw, se});
        let cmp = Utils.mkCmp(loc -> Location.distance(me#location, loc));
        let best = locs |> Nel.minimumBy(cmp);

        Direction.fromTo(me#location, best)
    }
}
