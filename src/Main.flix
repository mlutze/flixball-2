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
import java.util.Timer
import java.util.TimerTask
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

    let pitchPanel = new JPanel {
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

            let pitch = Marshall.makePitch(marshallBox);
            renderPitch(g2, pitch)
        }
    };

    let buttonPanel = new JPanel();
    let startButton = new JButton("Start");
    startButton.addActionListener(new ActionListener {
        def actionPerformed(_this: ActionListener, _e: ActionEvent): Unit \ IO = {
            startButton.setEnabled(false);
            startGameLoop(marshallBox, pitchPanel)
        }
    });
    buttonPanel.add(startButton);

    let frame = new JFrame("Flixball 2");
    frame.setSize(1000, 600);
    frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
    frame.add(pitchPanel, BorderLayout.CENTER);
    frame.add(buttonPanel, BorderLayout.SOUTH);
    frame.setVisible(true)
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

def startGameLoop(box: MarshallBox, panel: JPanel): Unit \ IO = {
    let deltaT = 1.0 / 60.0;

    let timer = new Timer();
    let task = new TimerTask {
        def $run(_this: TimerTask): Unit \ IO = {
            // stop if it's a goal
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

