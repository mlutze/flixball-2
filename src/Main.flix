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

// The main entry point.
def main(): Unit \ IO = {
    let args = run Sys.Env.getArgs() with Sys.Env.runWithIO;
    if (args == List#{"-H"}) {
        let box = init();
        runGame(box);
        let westScore = Ref.get(box#westScore);
        let eastScore = Ref.get(box#eastScore);
        println("${westScore},${eastScore}")
    } else {

        let marshallBox = init();

        let scorePanel = new JPanel();
        let timeLabel = new JLabel();
        timeLabel.setText("0.0");
        
        let westScoreLabel = new JLabel();
        westScoreLabel.setForeground(Color.RED);
        westScoreLabel.setText("0");
        let eastScoreLabel = new JLabel();
        eastScoreLabel.setForeground(Color.BLUE);
        eastScoreLabel.setText("0");

        scorePanel.add(westScoreLabel);
        scorePanel.add(timeLabel);
        scorePanel.add(eastScoreLabel);

        let forcesRef = Ref.fresh(Static, false);

        let pitchPanel = new JPanel {
            def paintComponent(this: JPanel, g: Graphics): Unit \ IO = {
                // super.paintComponent(g);
                let g2 = unchecked_cast(g as Graphics2D);
                g2.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);

                let scale = Float64.min(
                    Int32.toFloat64(this.getWidth()) / (pitchLength() + 10.0),
                    Int32.toFloat64(this.getHeight()) / (pitchWidth() + 10.0)
                );
                g2.translate(
                    Int32.toFloat64(this.getWidth()) / 2.0,
                    Int32.toFloat64(this.getHeight()) / 2.0
                );
                g2.scale(scale, -scale);
                g2.setStroke(new BasicStroke(0.05f32));

                let pitch = Marshall.makePitch(marshallBox);
                let dirs = if (Ref.get(forcesRef)) {
                    Some(getAiDirections(marshallBox))
                } else {
                    None
                };
                renderPitch(g2, pitch, dirs)
            }
        };

        let gameLoop = makeGameLoop(marshallBox, pitchPanel, timeLabel, westScoreLabel, eastScoreLabel);

        let buttonPanel = new JPanel();
        let startButton = new JButton("Start");
        let resetButton = new JButton("Reset");
        let forcesButton = new JButton("Show Forces");

        def onClickStartPause(_): Unit = {
            if (gameLoop.isRunning()) {
                startButton.setText("Start");
                gameLoop.stop();
                resetButton.setEnabled(true)
            } else {
                startButton.setText("Pause");
                gameLoop.start();
                resetButton.setEnabled(false)
            }
        };

        startButton.addActionListener(Utils.mkActionListener(onClickStartPause));

        def onClickReset(_): Unit = {
            resetGame(marshallBox);
            refreshDisplay(marshallBox, pitchPanel, timeLabel, westScoreLabel, eastScoreLabel)
        };

        resetButton.addActionListener(Utils.mkActionListener(onClickReset));

        def onClickForces(_): Unit = {
            let nowShowing = Ref.get(forcesRef);
            if (nowShowing) {
                Ref.put(false, forcesRef);
                forcesButton.setText("Show Forces");
                pitchPanel.repaint()
            } else {
                Ref.put(true, forcesRef);
                forcesButton.setText("Hide Forces");
                pitchPanel.repaint()
            }
        };

        forcesButton.addActionListener(Utils.mkActionListener(onClickForces));

        buttonPanel.add(startButton);
        buttonPanel.add(resetButton);
        buttonPanel.add(forcesButton);

        let frame = new JFrame("Flixball 2");
        frame.setSize(1000, 600);
        frame.setExtendedState(JFrame.MAXIMIZED_BOTH);
        frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        frame.add(pitchPanel, BorderLayout.CENTER);
        frame.add(scorePanel, BorderLayout.NORTH);
        frame.add(buttonPanel, BorderLayout.SOUTH);
        frame.setVisible(true)
    }
}

def init(): MarshallBox \ IO = {
    let world = mkWorld();
    let ball = mkBall();
    world.addBody(ball);
    addGoalWalls(world);

    let bodySR = mkPlayer();
    world.addBody(bodySR);

    // let bodyGR = mkPlayer();
    // world.addBody(bodyGR);

    let bodySB = mkPlayer();
    world.addBody(bodySB);

    // let bodyGB = mkPlayer();
    // world.addBody(bodyGB);

    let playerSR = { state = Ref.fresh(Static, 0i8), team = Team.West, body = bodySR, bot = Bots.mkBot(Bots.approachCircleAndShoot) };
    // let playerGR = { state = Ref.fresh(Static, 0i8), team = Team.West, body = bodyGR, bot = Bots.mkBot(Bots.defend) };
    let playerSB = { state = Ref.fresh(Static, 0i8), team = Team.East, body = bodySB, bot = Bots.mkBot(Bots.closeCircleAndShoot) };
    // let playerGB = { state = Ref.fresh(Static, 0i8), team = Team.East, body = bodyGB, bot = Bots.mkBot(Bots.defend) };
    let players = Map#{
        "Red Striker" => playerSR,
        "Blue Striker" => playerSB
        // "Red Goalie" => playerGR,
        // "Blue Goalie" => playerGB
    };

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
        eastScore = Ref.fresh(Static, 0)
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

def runGame(box: MarshallBox): Unit \ IO = {
    let deltaTs  = 1.0 / 60.0;
    let deltaTms = Float64.truncateToInt32(deltaTs * 1000.0);
    def loop() = {
        if (tick(box, deltaTs, deltaTms)) { 
            loop()
        }
    };
    loop()
}

def refreshDisplay(box: MarshallBox, pitchPanel: JPanel, timeLabel: JLabel, westScoreLabel: JLabel, eastScoreLabel: JLabel): Unit \ IO = {
    pitchPanel.repaint();
    timeLabel.setText(formatTimeMs(Ref.get(box#timeMs)));
    westScoreLabel.setText("${Ref.get(box#westScore)}");
    eastScoreLabel.setText("${Ref.get(box#eastScore)}")
}

def makeGameLoop(
    box: MarshallBox, pitchPanel: JPanel,
    timeLabel: JLabel, westScoreLabel: JLabel, eastScoreLabel: JLabel
): Timer \ IO = {
    let deltaTs  = 1.0 / 60.0;
    let deltaTms = Float64.truncateToInt32(deltaTs * 1000.0);

    def onTick(event: ActionEvent) = {
        let continue = tick(box, deltaTs, deltaTms);
        refreshDisplay(box, pitchPanel, timeLabel, westScoreLabel, eastScoreLabel);
        pitchPanel.repaint();
        timeLabel.setText(formatTimeMs(Ref.get(box#timeMs)));
        westScoreLabel.setText("${Ref.get(box#westScore)}");
        eastScoreLabel.setText("${Ref.get(box#eastScore)}");
        if (not continue) {
            let timer = unchecked_cast(event.getSource() as Timer);
            timer.stop()
        }
    };

    new Timer(deltaTms, Utils.mkActionListener(onTick))
}

def formatTimeMs(ms: Int32): String = {
    let whole = ms / 1000;
    let tenth = ms / 100 - (whole * 10);
    "${whole}.${tenth}"
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
def mkBall(): Body \ IO = {
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

def mkPlayer(): Body \ IO = {
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

