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

// The main entry point.
def main(): Unit \ IO = {
    let world = mkWorld();
    let ball = mkBall();
    let player = mkPlayer();
    world.addBody(ball);
    world.addBody(player);

    let panel = new JPanel {
        def paintComponent(this: JPanel, g: Graphics): Unit \ IO = {
            // super.paintComponent(g);
            let g2 = unchecked_cast(g as Graphics2D);

            let scale = Float64.min(
                Int32.toFloat64(this.getWidth()) / pitchLength(),
                Int32.toFloat64(this.getHeight()) / pitchWidth()
            );
            let tx = new AffineTransform();
            tx.translate(
                Int32.toFloat64(this.getWidth()) / 2.0,
                Int32.toFloat64(this.getHeight()) / 2.0
            );
            tx.scale(scale, -scale);
            g2.setTransform(tx);
            g2.setStroke(new BasicStroke(0.05f32));

            let playerForce = new Vector2(1200.0, 0.0);
            player.applyForce(playerForce); // TODO move to game loop
            renderPitch(g2);
            renderBall(g2, ball);
            renderPlayer(g2, player)
        }
    };
    let frame = new JFrame("Flixball 2");
    frame.setSize(1000, 600);
    frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
    frame.add(panel);
    frame.setVisible(true);

    startGameLoop(world, panel)
}


def startGameLoop(world: World[Body], panel: JPanel): Unit \ IO = {
    let deltaT = 1.0 / 60.0;

    let timer = new Timer();
    let task = new TimerTask {
        def $run(_this: TimerTask): Unit \ IO = {
            world.step(1, deltaT);   // dyn4j: (numSteps, elapsedTime)
            panel.repaint()
        }
    };
    timer.scheduleAtFixedRate(task, 0i64, 16i64)
}


def mkWorld(): World[Body] \ IO = {
    let world = new World();
    world.setGravity(World.ZERO_GRAVITY);
    world
}

def render(shapes: List[Body]): Unit \ IO = {
    foreach (
        shape <- shapes
    ) {
        let center = shape.getWorldCenter();
        let x = center.x;
        let y = center.y;
        ???
    } 
}

def renderPitch(g: Graphics2D): Unit \ IO = {
    let cornerX = -pitchLength() / 2.0;
    let cornerY = -pitchWidth() / 2.0;
    let rectangle = new Rectangle2D$Double(cornerX, cornerY, pitchLength(), pitchWidth());
    g.setColor((Color.GREEN).darker());
    g.fill(rectangle)
}

def renderBall(g: Graphics2D, ball: Body): Unit \ IO = {
    let center = ball.getWorldCenter();
    let cornerX = center.x - ballRadius();
    let cornerY = center.y - ballRadius();
    let circle = new Ellipse2D$Double(cornerX, cornerY, ballRadius() * 2.0, ballRadius() * 2.0);
    g.setColor(Color.WHITE);
    g.fill(circle)
}

def renderPlayer(g: Graphics2D, player: Body): Unit \ IO = {
    let center = player.getWorldCenter();
    let cornerX = center.x - playerRadius();
    let cornerY = center.y - playerRadius();
    let circle = new Ellipse2D$Double(cornerX, cornerY, playerRadius() * 2.0, playerRadius() * 2.0);
    g.setColor(Color.BLUE);
    g.fill(circle)
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
    body.translate(-50.0, 0.0);
    body
}

