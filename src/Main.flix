import java.awt.BasicStroke
import java.awt.Color
import java.awt.Graphics
import java.awt.Graphics2D
import java.awt.geom.AffineTransform
import java.awt.geom.Ellipse2D$Double
import java.awt.geom.Line2D
import java.awt.geom.Rectangle2D$Double
import java.lang.Math
import javax.swing.JPanel
import javax.swing.JFrame
import org.dyn4j.dynamics.Body
import org.dyn4j.dynamics.BodyFixture
import org.dyn4j.geometry.Geometry
import org.dyn4j.geometry.MassType
import org.dyn4j.world.World
import java.util.Timer
import java.util.TimerTask

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
                Int32.toFloat64(this.getWidth()) / length(),
                Int32.toFloat64(this.getHeight()) / width()
            );
            let tx = new AffineTransform();
            tx.translate(
                Int32.toFloat64(this.getWidth()) / 2.0,
                Int32.toFloat64(this.getHeight()) / 2.0
            );
            tx.scale(scale, -scale);
            g2.setTransform(tx);
            g2.setStroke(new BasicStroke(0.05f32));

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
    let cornerX = -length() / 2.0;
    let cornerY = -width() / 2.0;
    let rectangle = new Rectangle2D$Double(cornerX, cornerY, length(), width());
    g.setColor((Color.GREEN).darker());
    g.fill(rectangle)
}

def renderBall(g: Graphics2D, ball: Body): Unit \ IO = {
    let center = ball.getWorldCenter();
    let cornerX = center.x - ballRadius();
    let cornerY = center.y - ballRadius();
    let circle = new Ellipse2D$Double(cornerX, cornerY, ballRadius(), ballRadius());
    g.setColor(Color.WHITE);
    g.fill(circle)
}

def renderPlayer(g: Graphics2D, player: Body): Unit \ IO = {
    let center = player.getWorldCenter();
    let cornerX = center.x - playerRadius();
    let cornerY = center.y - playerRadius();
    let circle = new Ellipse2D$Double(cornerX, cornerY, playerRadius(), playerRadius());
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
    body.translate(-10.0, 0.0);
    body.setLinearVelocity(10.0, 0.0);
    body
}

def length(): Float64 = 100.0

def width(): Float64 = 50.0

def ballRadius(): Float64 = 0.11

def ballMass(): Float64 = 0.410

def playerMass(): Float64 = 80.0

def playerVolume(): Float64 = 4.0 / 3.0 * Math.PI * playerRadius() * playerRadius() * playerRadius() 

def playerDensity(): Float64 = playerMass() / playerVolume()

// revisit: this is 2-D
def ballVolume(): Float64 = 4.0 / 3.0 * Math.PI * ballRadius() * ballRadius() * ballRadius()

def ballDensity(): Float64 = ballMass() / ballVolume()

// random guess; this is against other bodies
def ballFriction(): Float64 = 0.08

// maybe make player friction higher than ball friction?
def playerFriction(): Float64 = 0.12

// like friction against the ground

// soccer ball on grass: light drag, coasts a while
def ballLinearDamping(): Float64 = 0.15

// running human: quick natural decay when AI isn't pushing
def playerLinearDamping(): Float64 = 2.0

def angularDamping(): Float64 = 0.8

// 0.82 - 0.88 apparently
def ballRestitution(): Float64 = 0.85

// players are less bouncy than the ball
def playerRestitution(): Float64 = 0.30

def playerRadius(): Float64 = 0.5

// minimum velocity for bounce 
def restitutionVelocity(): Float64 = 0.001