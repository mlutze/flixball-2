import java.awt.BasicStroke
import java.awt.Color
import java.awt.Graphics
import java.awt.Graphics2D
import java.awt.geom.AffineTransform
import java.awt.geom.Ellipse2D$Double
import java.awt.geom.Line2D
import java.awt.geom.Rectangle2D$Double
import javax.swing.JPanel
import javax.swing.JFrame
import org.dyn4j.dynamics.Body
import org.dyn4j.dynamics.BodyFixture
import org.dyn4j.geometry.Geometry
import org.dyn4j.geometry.MassType
import org.dyn4j.world.World
import java.util.Timer
import java.util.TimerTask
import org.dyn4j.geometry.Vector2
import java.lang.Math
import java.awt.geom.Line2D$Double
import java.awt.geom.Arc2D$Double
import java.awt.RenderingHints

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

// The main entry point.
def main(): Unit \ IO = {
    let marshallBox = init();

    let panel = new JPanel {
        def paintComponent(this: JPanel, g: Graphics): Unit \ IO = {
            // super.paintComponent(g);
            let g2 = unchecked_cast(g as Graphics2D);
            g2.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);

            let scale = Float64.min(
                Int32.toFloat64(this.getWidth()) / (pitchLength() + 10.0),
                Int32.toFloat64(this.getHeight()) / (pitchWidth() + 10.0)
            );
            let tx = new AffineTransform();
            tx.translate(
                Int32.toFloat64(this.getWidth()) / 2.0,
                Int32.toFloat64(this.getHeight()) / 2.0
            );
            tx.scale(scale, -scale);
            g2.setTransform(tx);
            g2.setStroke(new BasicStroke(0.05f32));

            // let playerForce = new Vector2(1200.0, 0.0);
            let pitch = Marshall.makePitch(marshallBox);
            renderPitch2(g2, pitch)
        }
    };
    let frame = new JFrame("Flixball 2");
    frame.setSize(1000, 600);
    frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
    frame.add(panel);
    frame.setVisible(true);

    startGameLoop(marshallBox, panel)
}

def init(): MarshallBox \ IO = {
    let world = mkWorld();
    let ball = mkBall();
    world.addBody(ball);

    // random point strictly inside the pitch, leaving room for the player radius
    let randomX = () -> (Math.random() - 0.5) * (pitchLength() - 2.0 * playerRadius());
    let randomY = () -> (Math.random() - 0.5) * (pitchWidth() - 2.0 * playerRadius());
    let bots = Vector#{Bots.runAtBall, Bots.runFromBall, Bots.wander, Bots.interceptBall, Bots.stayStill, Bots.defendOwnGoal};
    let randomBot = () -> Utils.randomChoice(bots);

    let mkOne = (num, team) -> {
        let body = mkPlayer();
        body.translate(randomX(), randomY());
        world.addBody(body);
        (Int32.toString(num), (team, body, randomBot()))
    };

    let blue = List.range(1, 12)  |> List.map(n -> mkOne(n, Team.Blue));
    let red  = List.range(12, 23) |> List.map(n -> mkOne(n, Team.Red));
    let players = List.toMap(List.append(blue, red));

    { world = world, players = players, ball = ball }
}

// fills the given rectangle (in world coords) with a diagonal crosshatch pattern
def crosshatch(g: Graphics2D, x: Float64, y: Float64, w: Float64, h: Float64): Unit \ IO = {
    let oldClip   = g.getClip();
    let oldStroke = g.getStroke();
    g.setClip(new Rectangle2D$Double(x, y, w, h));
    g.setStroke(new BasicStroke(0.04f32));
    let spacing = 0.5;
    let extent  = w + h;   // long enough for any diagonal to cross the rect fully
    foreach (i <- List.range(-40, 40)) {
        let off = Int32.toFloat64(i) * spacing;
        // ↗ diagonals
        g.draw(new Line2D$Double(x + off, y, x + off + extent, y + extent));
        // ↘ diagonals
        g.draw(new Line2D$Double(x + off, y + h, x + off + extent, y + h - extent))
    };
    g.setStroke(oldStroke);
    g.setClip(oldClip)
}

def renderBackground(g: Graphics2D): Unit \ IO = {
    // grass: just do a huge background
    g.setColor((Color.GREEN).darker());
    g.fill(new Rectangle2D$Double(-1000.0, -1000.0, 2000.0, 2000.0));

    // lines
    g.setStroke(new BasicStroke(0.12f32));
    g.setColor(Color.WHITE);

    // outer rectangle
    let cornerX = -pitchLength() / 2.0;
    let cornerY = -pitchWidth() / 2.0;
    g.draw(new Rectangle2D$Double(cornerX, cornerY, pitchLength(), pitchWidth()));

    // halfway line
    g.draw(new Line2D$Double(0.0, -pitchWidth() / 2.0 , 0.0, pitchWidth() / 2.0));

    // center circle
    g.draw(new Ellipse2D$Double(-9.15, -9.15, 18.30, 18.30));

    // penalty boxes: 16.5 * 40.32
    g.draw(new Rectangle2D$Double(-pitchLength() / 2.0 , -20.16, 16.5, 40.32));
    g.draw(new Rectangle2D$Double(pitchLength() / 2.0 - 16.5, -20.16, 16.5, 40.32));

    // goal areas (6-yard boxes): 5.5 deep * 18.32 wide
    g.draw(new Rectangle2D$Double(-pitchLength() / 2.0, -9.16, 5.5, 18.32));
    g.draw(new Rectangle2D$Double(pitchLength() / 2.0 - 5.5, -9.16, 5.5, 18.32));

    // goals: 2 deep * 7.32 wide, drawn behind the goal line, with a net-like crosshatch
    g.draw(new Rectangle2D$Double(-pitchLength() / 2.0 - 2.0, -3.66, 2.0, 7.32));
    g.draw(new Rectangle2D$Double(pitchLength() / 2.0, -3.66, 2.0, 7.32));
    crosshatch(g, -pitchLength() / 2.0 - 2.0, -3.66, 2.0, 7.32);
    crosshatch(g, pitchLength() / 2.0, -3.66, 2.0, 7.32);

    // penalty spots: 11 m from goal line, filled dot
    g.fill(new Ellipse2D$Double(-pitchLength() / 2.0 + 11.0 - 0.15, -0.15, 0.30, 0.30));
    g.fill(new Ellipse2D$Double(pitchLength() / 2.0 - 11.0 - 0.15, -0.15, 0.30, 0.30));

    // penalty arcs: radius 9.15 m from penalty spot, portion outside the penalty box.
    // half-angle to where the arc meets the front of the penalty box: acos(5.5/9.15) ≈ 53°
    let leftSpotX = -pitchLength() / 2.0 + 11.0;
    let rightSpotX = pitchLength() / 2.0 - 11.0;
    // Arc2D.OPEN = 0
    // left arc opens toward +x: sweep from -53° through 0° to +53°
    g.draw(new Arc2D$Double(leftSpotX - 9.15, -9.15, 18.30, 18.30, -53.0, 106.0, 0));
    // right arc opens toward -x: sweep from 127° through 180° to 233°
    g.draw(new Arc2D$Double(rightSpotX - 9.15, -9.15, 18.30, 18.30, 127.0, 106.0, 0))
}

def renderPlayer2(g: Graphics2D, player: Player): Unit \ IO = {
    let cornerX = player#location#x - playerRadius();
    let cornerY = player#location#y - playerRadius();
    let circle = new Ellipse2D$Double(cornerX, cornerY, playerRadius() * 2.0, playerRadius() * 2.0);
    let color = match player#team {
        case Team.Red => Color.RED
        case Team.Blue => Color.BLUE
    };
    g.setColor(color);
    g.fill(circle)
}

def renderBall2(g: Graphics2D, location: Location): Unit \ IO = {
    let cornerX = location#x - ballRadius();
    let cornerY = location#y - ballRadius();
    let circle = new Ellipse2D$Double(cornerX, cornerY, ballRadius() * 2.0, ballRadius() * 2.0);
    g.setColor(Color.WHITE);
    g.fill(circle)
}

def renderPitch2(g: Graphics2D, pitch: Pitch): Unit \ IO = {
    renderBackground(g);
    foreach (
        player <- Map.valuesOf(pitch#players)
    ) {
        renderPlayer2(g, player)
    };
    renderBall2(g, pitch#ballLocation)
}


def startGameLoop(box: MarshallBox, panel: JPanel): Unit \ IO = {
    let deltaT = 1.0 / 60.0;

    let timer = new Timer();
    let task = new TimerTask {
        def $run(_this: TimerTask): Unit \ IO = {
            executeAi(box);
            box#world.step(1, deltaT);   // dyn4j: (numSteps, elapsedTime)
            panel.repaint()
        }
    };
    timer.scheduleAtFixedRate(task, 0i64, 16i64)
}

def executeAi(box: MarshallBox): Unit \ IO = {
    let pitch = Marshall.makePitch(box);
    foreach (
        (name, (_, body, bot)) <- box#players
    ) {
        let dir = bot(pitch, name);
        let force_ = new Vector2(dir#ux, dir#uy).setMagnitude(playerForce());
        discard body.applyForce(force_)
    }
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

