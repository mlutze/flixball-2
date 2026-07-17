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
import java.lang.Math
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

// The main entry point.
def main(): Unit \ IO = {
    let marshallBox = init();

    let timePanel = new JPanel();
    let timeLabel = new JLabel();
    timePanel.add(timeLabel);
    timeLabel.setText("0.0");

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
            let dirs = getAiDirections(marshallBox);
            renderPitch(g2, pitch, dirs)
        }
    };

    let gameLoop = makeGameLoop(marshallBox, pitchPanel, timeLabel);

    let buttonPanel = new JPanel();
    let startButton = new JButton("Start");
    let resetButton = new JButton("Reset");

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
        reset(marshallBox, pitchPanel, timeLabel)
    };

    resetButton.addActionListener(Utils.mkActionListener(onClickReset));
    buttonPanel.add(startButton);
    buttonPanel.add(resetButton);

    let frame = new JFrame("Flixball 2");
    frame.setSize(1000, 600);
    frame.setExtendedState(JFrame.MAXIMIZED_BOTH);
    frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
    frame.add(pitchPanel, BorderLayout.CENTER);
    frame.add(timePanel, BorderLayout.NORTH);
    frame.add(buttonPanel, BorderLayout.SOUTH);
    frame.setVisible(true)
}

def init(): MarshallBox \ IO = {
    let world = mkWorld();
    let ball = mkBall();
    world.addBody(ball);
    addGoalWalls(world);

    // random point strictly inside the pitch, leaving room for the player radius
    // let randomX = () -> (Math.random() - 0.5) * (pitchLength() - 2.0 * playerRadius());
    let randomY = () -> (Math.random() - 0.5) * (pitchWidth() - 2.0 * playerRadius());
    let randomXEast = () -> Math.random() * (pitchLength() / 2.0 - 2.0 * playerRadius());
    let randomXWest = () -> -Math.random() * (pitchLength() / 2.0 - 2.0 * playerRadius());
    // let bots = Vector#{Bots.runAtBall, Bots.runFromBall, Bots.wander, Bots.interceptBall, Bots.stayStill, Bots.defendOwnGoal};
    // let randomBot = () -> Utils.randomChoice(bots);

    // let mkOne = (num, team) -> {
    //     let body = mkPlayer();
    //     body.translate(randomX(), randomY());
    //     world.addBody(body);
    //     (Int32.toString(num), (team, body, randomBot()))
    // };

    // let blue = List.range(1, 12)  |> List.map(n -> mkOne(n, Team.Blue));
    // let red  = List.range(12, 23) |> List.map(n -> mkOne(n, Team.Red));
    // let players = List.toMap(List.append(blue, red));

    let bodySR = mkPlayer();
    bodySR.translate(randomXWest(), randomY());
    world.addBody(bodySR);

    let bodyGR = mkPlayer();
    bodyGR.translate(randomXWest(), randomY());
    world.addBody(bodyGR);

    let bodySB = mkPlayer();
    bodySB.translate(randomXEast(), randomY());
    world.addBody(bodySB);

    let bodyGB = mkPlayer();
    bodyGB.translate(randomXEast(), randomY());
    world.addBody(bodyGB);

    let playerSR = { team = Team.Red, body = bodySR, bot = Bots.closeCircleAndShootEast };
    let playerGR = { team = Team.Red, body = bodyGR, bot = Bots.defendWest };
    let playerSB = { team = Team.Blue, body = bodySB, bot = Bots.closeCircleAndShootWest };
    let playerGB = { team = Team.Blue, body = bodyGB, bot = Bots.defendEast };
    let players = Map#{
        "Red Striker" => playerSR,
        "Blue Striker" => playerSB,
        "Red Goalie" => playerGR,
        "Blue Goalie" => playerGB
    };

    { world = world, players = players, ball = ball, timeMs = Ref.fresh(Static, 0)}
}

def randomY(): Float64 \ IO = {
    (Math.random() - 0.5) * (pitchWidth() - 2.0 * playerRadius())
}

def randomXEast(): Float64 \ IO = {
     Math.random() * (pitchLength() / 2.0 - 2.0 * playerRadius())
}

def randomXWest(): Float64 \ IO = {
    -Math.random() * (pitchLength() / 2.0 - 2.0 * playerRadius())
}

def reset(box: MarshallBox, pitchPanel: JPanel, timeLabel: JLabel): Unit \ IO = {
    box#ball.translateToOrigin();
    box#ball.setAtRest(true);
    foreach (
        (_name, player) <- box#players
    ) {
        player#body.setAtRest(true);
        let y = randomY();
        let x = match player#team {
            case Team.Red => randomXWest()
            case Team.Blue => randomXEast()
        };
        player#body.translateToOrigin();
        player#body.translate(x, y)
    };
    Ref.put(0, box#timeMs);
    pitchPanel.repaint();
    timeLabel.setText(formatTimeMs(Ref.get(box#timeMs)))
}

def makeGameLoop(box: MarshallBox, pitchPanel: JPanel, timeLabel: JLabel): Timer \ IO = {
    let deltaTs = 1.0 / 60.0;
    let deltaTms = Float64.truncateToInt32(deltaTs * 1000.0);

    def go(_) = {
        let dirs = getAiDirections(box);
        executeAi(box, dirs);
        adjustDampening(box);
        MarshallBox.addTimeMs(deltaTms, box);
        box#world.step(1, deltaTs);
        pitchPanel.repaint();
        timeLabel.setText(formatTimeMs(Ref.get(box#timeMs)))
    };

    new Timer(deltaTms, Utils.mkActionListener(go))
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
        physPlayer#bot(pitch, me)
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
    if (ballShape.intersects(pitchRectangle)) {
        LocationClass.InBounds
    } else if (ballShape.intersects(eastGoalRectangle)) {
        LocationClass.EastGoal
    } else if (ballShape.intersects(westGoalRectangle)) {
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

