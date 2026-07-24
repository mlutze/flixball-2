mod Simulation {

    import javax.swing.SwingUtilities
    import java.awt.BasicStroke
    import java.awt.Color
    import java.awt.Graphics
    import java.awt.Graphics2D
    import java.awt.RenderingHints
    import java.awt.geom.AffineTransform
    import java.awt.geom.Arc2D$Double
    import java.awt.geom.Ellipse2D$Double
    import java.awt.geom.Line2D
    import java.awt.geom.Line2D$Double
    import java.awt.geom.Rectangle2D$Double
    import java.awt.event.ActionListener
    import java.awt.event.ActionEvent
    import javax.swing.Timer
    import javax.swing.JFrame
    import javax.swing.JPanel
    import javax.swing.JSlider
    import javax.swing.BorderFactory
    import javax.swing.JButton
    import org.dyn4j.dynamics.Body
    import org.dyn4j.dynamics.BodyFixture
    import org.dyn4j.geometry.Geometry
    import org.dyn4j.geometry.MassType
    import org.dyn4j.geometry.Vector2
    import org.dyn4j.world.World
    import java.awt.BorderLayout
    import javax.swing.JLabel
    import javax.swing.JCheckBox

    import java.lang.{Math => JMath}
    import java.lang.{String => JString}

    use Constants.pitchLength
    use Constants.pitchWidth
    use Constants.ballRadius
    use Constants.playerRadius
    use Constants.ballDensity
    use Constants.playerDensity
    use Constants.ballFriction
    use Constants.playerFriction
    use Constants.ballRestitution
    use Constants.playerRestitution
    use Constants.ballLinearDamping
    use Constants.playerLinearDamping
    use Constants.angularDamping
    use Constants.restitutionVelocity
    use Constants.playerForce

    use Rendering.renderPitch

    use Math.Random
    pub def runHeadless(): Unit \ IO = {
        let box = init();
        discard runGame(box);
        let westScore = Ref.get(box#westScore);
        let eastScore = Ref.get(box#eastScore);
        println("${westScore},${eastScore}")
    }


    enum UserData {
        case Player(String)
        case _Ball
    }

    def _setUserData(data: UserData, b: Body): Unit \ IO = {
        b.setUserData(data)
    }

    def _getUserData(b: Body): UserData \ IO = {
        unchecked_cast(b.getUserData() as UserData)
    }

    def mkPlayer(world: World[Body], name: String, team: Team, bot: Bot): PhysicsPlayer \ IO = {
        let body = mkPlayerBody();
        body.setUserData(UserData.Player(name));
        world.addBody(body);
        {
            name = name,
            body = body,
            state = Ref.fresh(Static, 0i8),
            team = team,
            bot = bot
        }
    }

    pub def init(): MarshallBox \ IO = {
        let world = mkWorld();
        let ball = mkBall(world);
        addGoalWalls(world);

        let players = List#{
            mkPlayer(world, "West Striker", Team.West, Bots.mkBot(Bots.approachCircleAndShoot)),
            mkPlayer(world, "West Goalie", Team.West, Bots.mkBot(Bots.defend)),

            mkPlayer(world, "East Striker", Team.East, Bots.mkBot(Bots.approachCircleAndShootHard)),
            mkPlayer(world, "East Goalie", Team.East, Bots.mkBot(Bots.defend))
        } |> List.map(p -> (p#name, p)) |> List.toMap;

        // TODO add a check that names are unique

        // All the refs here are placeholders
        let box = {
            world = world,
            players = players,
            ball = ball,
            timeMs = Ref.fresh(Static, 0),
            state = Ref.fresh(Static, GameState.PreGame({ remainingMs = 0 })),
            preGameJunk = MutList.empty(Static),
            westScore = Ref.fresh(Static, 0),
            eastScore = Ref.fresh(Static, 0),
            lastContact = Ref.fresh(Static, None)
        };

        resetGame(box);
        box
    }

    def resetGame(box: MarshallBox): Unit \ IO = {
        box#ball.translateToOrigin();
        box#ball.setAtRest(true);

        foreach ((_name, player) <- box#players) {
            player#body.setAtRest(true);
            let loc = randomStartFor(player#team);
            player#body.translateToOrigin();
            player#body.translate(loc#x, loc#y)
        };

        Ref.put(-Constants.pregameMs(), box#timeMs);
        Ref.put(GameState.PreGame({ remainingMs = Constants.pregameMs() }), box#state);

        Ref.put(0, box#westScore);
        Ref.put(0, box#eastScore);

        // rebuild pre-game barriers
        MarshallBox.clearJunk(box);
        let preGameRing = mkRing(0.0, 0.0, Constants.centerCircleRadius(), 32);
        let (wallN, wallS) = mkCenterWalls();
        box#world.addBody(preGameRing);
        box#world.addBody(wallN);
        box#world.addBody(wallS);
        box#preGameJunk
            !> MutList.push(preGameRing)
            !> MutList.push(wallN)
            |> MutList.push(wallS)
    }

    def randomStartFor(team: Team): Location \ IO = match team {
        case Team.West => randomStartWest()
        case Team.East => randomStartEast()
    }

    def randomY(): Float64 \ IO = {
        run {
            (Random.randomFloat64() - 0.5) * (pitchWidth() - 2.0 * playerRadius())
        } with Random.runWithIO
    }

    def randomXEast(): Float64 \ IO = {
        run {
            Random.randomFloat64() * (pitchLength() / 2.0 - 2.0 * playerRadius())
        } with Random.runWithIO
    }

    def randomXWest(): Float64 \ IO = {
        run {
            -Random.randomFloat64() * (pitchLength() / 2.0 - 2.0 * playerRadius())
        } with Random.runWithIO
    }

    def randomStartWest(): Location \ IO = {
        let loc = {
            x = randomXWest(),
            y = randomY()
        };
        let distance = Location.distance(loc, Locations.center());
        let minDistance = Constants.centerCircleRadius() + Constants.playerRadius();
        // if it's too close then just try again
        if (distance < minDistance) {
            randomStartWest()
        } else {
            loc
        }
    }
    def randomStartEast(): Location \ IO = {
        let loc = {
            x = randomXEast(),
            y = randomY()
        };
        let distance = Location.distance(loc, Locations.center());
        let minDistance = Constants.centerCircleRadius() + Constants.playerRadius();
        // if it's too close then just try again
        if (distance < minDistance) {
            randomStartWest()
        } else {
            loc
        }
    }

    // runs one game tick; returns whether to keep going
    def tick(box: MarshallBox, deltaTs: Float64, deltaTms: Int32): Bool \ IO = {
        let dirs = getAiDirections(box);
        executeAi(box, dirs);
        adjustDampening(box);
        MarshallBox.addTimeMs(deltaTms, box);

        let continue = match Ref.get(box#state) {
            case GameState.PreGame({ remainingMs }) =>
                if (remainingMs < 0) {
                    Ref.put(GameState.Play, box#state);
                    MarshallBox.clearJunk(box)
                };
                true
            case GameState.Play =>
                match getBallLocationClass(box) {
                    // red has scored
                    case LocationClass.EastGoal =>
                        box#westScore |> Ref.transform(s -> s + 1);
                        let newState = GameState.PostGoal({
                            remainingMs = Constants.postGoalMs(),
                            team = Team.West
                        });
                        Ref.put(newState, box#state)

                    // blue has scored
                    case LocationClass.WestGoal =>
                        box#eastScore |> Ref.transform(s -> s + 1);
                        let newState = GameState.PostGoal({
                            remainingMs = Constants.postGoalMs(),
                            team = Team.East
                        });
                        Ref.put(newState, box#state)

                    // no one scored, just check if it's over
                    case LocationClass.InBounds =>
                        if (Ref.get(box#timeMs) > Constants.gameMs()) {
                            let newState = GameState.PostGame({
                                remainingMs = Constants.postGameMs()
                            });
                            Ref.put(newState, box#state)
                        }
                    case LocationClass.OutOfBounds =>
                        if (Ref.get(box#timeMs) > Constants.gameMs()) {
                            let newState = GameState.PostGame({
                                remainingMs = Constants.postGameMs()
                            });
                            Ref.put(newState, box#state)
                        }
                    };
                true
            case GameState.PostGoal({ remainingMs | _ }) =>
                if (remainingMs < 0) {
                    box#ball.translateToOrigin();
                    box#ball.setAtRest(true);
                    Ref.put(GameState.Play, box#state)
                };
                true
            case GameState.PostGame({ remainingMs }) =>
                if (remainingMs < 0) {
                    Ref.put(GameState.Exit, box#state)
                };
                true
            case GameState.Exit =>
                false
        };
        box#world.step(1, deltaTs);
        continue
    }

    pub def runGame(box: MarshallBox): Vector[Pitch] \ IO = {
        let deltaTs  = 1.0 / Int32.toFloat64(Constants.frameRate());
        let deltaTms = Float64.truncateToInt32(deltaTs * 1000.0);
        let frames = MutList.empty(Static);
        def loop() = {
            frames |> MutList.push(Marshall.makePitch(box));
            if (tick(box, deltaTs, deltaTms)) { 
                loop()
            }
        };
        loop();
        frames |> MutList.toVector
    }

    def executeAi(box: MarshallBox, forces: Map[String, Direction]): Unit \ IO = {
        foreach (
            (name, physPlayer) <- box#players
        ) {
            match Map.get(name, forces) {
                case None => unreachable!()
                case Some(dir) =>
                    let force_ = new Vector2(dir#ux, dir#uy).setMagnitude(playerForce());
                    discard physPlayer#body.applyForce(force_)
            }
        }
    }

    def getAiDirections(box: MarshallBox): Map[String, Direction] \ IO = {
        let pitch = Marshall.makePitch(box);
        def getAiForce(name, physPlayer): Direction = {
            let me = Marshall.makePlayer(name, physPlayer);
            run {
                physPlayer#bot(pitch, me)
            } with Logger.runWithIO
                with Random.runWithIO
                with BotState.runWithRef(physPlayer#state)
                
        };
        box#players |> Map.mapWithKey(getAiForce)
    }

    def adjustDampening(box: MarshallBox): Unit \ IO = {
        let locationClass = getBallLocationClass(box);
        let damping = match locationClass {
            case LocationClass.InBounds => ballLinearDamping()
            case LocationClass.OutOfBounds => ballLinearDamping() * 5.0
            case LocationClass.EastGoal => ballLinearDamping() * 10.0
            case LocationClass.WestGoal => ballLinearDamping() * 10.0
        };
        box#ball.setLinearDamping(damping)
    }

    def getBallLocationClass(box: MarshallBox): LocationClass \ IO = {
        let pitchRectangle = new Rectangle2D$Double(
            -pitchLength() / 2.0,
            -pitchWidth() / 2.0,
            pitchLength(),
            pitchWidth()
        );
        let ballCenter = box#ball.getWorldCenter();
        let ballShape = new Ellipse2D$Double(
            ballCenter.x - Constants.ballRadius(),
            ballCenter.y - Constants.ballRadius(),
            Constants.ballRadius() * 2.0,
            Constants.ballRadius() * 2.0
        );
        let westGoalRectangle = new Rectangle2D$Double(
            Locations.goalBackSW()#x,
            Locations.goalBackSW()#y,
            Constants.goalDepth(),
            Constants.goalWidth()
        );
        let eastGoalRectangle = new Rectangle2D$Double(
            Locations.goalpostSE()#x,
            Locations.goalpostSE()#y,
            Constants.goalDepth(),
            Constants.goalWidth()
        );
        let ballBounds = ballShape.getBounds2D();
        if (ballShape.intersects(pitchRectangle)) {
            LocationClass.InBounds
        } else if (eastGoalRectangle.contains(ballBounds)) {
            LocationClass.EastGoal
        } else if (westGoalRectangle.contains(ballBounds)) {
            LocationClass.WestGoal
        } else {
            LocationClass.OutOfBounds
        }
    }

    enum LocationClass with ToString {
        case InBounds
        case OutOfBounds
        case EastGoal
        case WestGoal
    }

    def mkWorld(): World[Body] \ IO = {
        let world = new World();
        world.setGravity(World.ZERO_GRAVITY);
        world
    }

    def mkBall(world: World[Body]): Body \ IO = {
        let body = mkBallBody();
        world.addBody(body);
        body 
    }
    def mkBallBody(): Body \ IO = {
        let shape = Geometry.createCircle(ballRadius());
        let body = new Body();
        let fixture = body.addFixture(shape, ballDensity(), ballFriction(), ballRestitution());
        fixture.setRestitutionVelocity(restitutionVelocity());
        body.setLinearDamping(ballLinearDamping());
        body.setAngularDamping(angularDamping());
        body.setMass(MassType.NORMAL);
        body.setBullet(true);
        body
    }

    def mkPlayerBody(): Body \ IO = {
        let shape = Geometry.createCircle(playerRadius());
        let body = new Body();
        let fixture = body.addFixture(shape, playerDensity(), playerFriction(), playerRestitution());
        fixture.setRestitutionVelocity(restitutionVelocity());
        body.setLinearDamping(playerLinearDamping());
        body.setAngularDamping(angularDamping());
        body.setMass(MassType.NORMAL);
        body.setBullet(false);
        body
    }

    // static infinite-mass wall as a line segment between two world points
    def mkWall(a: Location, b: Location): Body \ IO = {
        let start = new Vector2(a#x, a#y);
        let end   = new Vector2(b#x, b#y);
        let shape = Geometry.createSegment(start, end);
        let body  = new Body();
        // arbitrary density because infinite
        // restitution and friction just guessing for now
        discard body.addFixture(shape, 1.0, 0.3, 0.2);
        body.setMass(MassType.INFINITE);
        body
    }

    def addGoalWalls(world: World[Body]): Unit \ IO = {
        // west
        world.addBody(mkWall(Locations.goalpostNW(), Locations.goalBackNW()));   // top
        world.addBody(mkWall(Locations.goalpostSW(), Locations.goalBackSW()));   // bottom
        world.addBody(mkWall(Locations.goalBackNW(), Locations.goalBackSW()));   // back

        // east
        world.addBody(mkWall(Locations.goalpostNE(), Locations.goalBackNE()));   // top
        world.addBody(mkWall(Locations.goalpostSE(), Locations.goalBackSE()));   // bottom
        world.addBody(mkWall(Locations.goalBackNE(), Locations.goalBackSE()))    // back
    }

    def mkRing(cx: Float64, cy: Float64, radius: Float64, segments: Int32): Body \ IO = {
        let body = new Body();
        let n = Int32.toFloat64(segments);
        foreach (i <- List.range(0, segments)) {
            let a1 = 2.0 * Trig.pi() * Int32.toFloat64(i)     / n;
            let a2 = 2.0 * Trig.pi() * Int32.toFloat64(i + 1) / n;
            let p1 = new Vector2(cx + radius * Trig.cos(a1),
                                cy + radius * Trig.sin(a1));
            let p2 = new Vector2(cx + radius * Trig.cos(a2),
                                cy + radius * Trig.sin(a2));
            discard body.addFixture(Geometry.createSegment(p1, p2), 1.0, 0.3, 0.0)
        };
        body.setMass(MassType.INFINITE);
        body
    }

    def mkCenterWalls(): (Body, Body) \ IO = {
        let ringDispN = Displacement.inDirection(Direction.north(), Constants.centerCircleRadius());
        let ringN = Displacement.apply(ringDispN, Locations.center());

        let ringDispS = Displacement.inDirection(Direction.south(), Constants.centerCircleRadius());
        let ringS = Displacement.apply(ringDispS, Locations.center());

        let farNorth = Displacement.inDirection(Direction.north(), 1000.0);
        let farSouth = Displacement.inDirection(Direction.south(), 1000.0);

        (
            mkWall(ringN, Displacement.apply(farNorth, ringN)),
            mkWall(ringS, Displacement.apply(farSouth, ringS))
        )
    }
}