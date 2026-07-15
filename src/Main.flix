import org.dyn4j.world.World
import org.dyn4j.geometry.Geometry
import org.dyn4j.dynamics.BodyFixture
import org.dyn4j.dynamics.Body
import java.lang.Math
import org.dyn4j.geometry.MassType

// The main entry point.
def main(): Unit \ IO =
    println("Hello World!")

def mkWorld(): World[String] \ IO = {
    let world = new World();
    world.setGravity(World.ZERO_GRAVITY);
    world
}

def mkBall(): Body \ IO = {
    let shape = Geometry.createCircle(ballRadius());
    let body = new Body();
    let fixture = body.addFixture(shape, ballDensity(), ballFriction(), ballRestitution());
    fixture.setRestitutionVelocity(restitutionVelocity());
    body.setLinearDamping(linearDamping());
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
    body.setLinearDamping(linearDamping());
    body.setAngularDamping(angularDamping());
    body.setMass(MassType.NORMAL);
    body.setBullet(false);
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
def linearDamping(): Float64 = 0.8

def angularDamping(): Float64 = 0.8

// 0.82 - 0.88 apparently
def ballRestitution(): Float64 = 0.85

// players are less bouncy than the ball
def playerRestitution(): Float64 = 0.30

def playerRadius(): Float64 = 0.5

// minimum velocity for bounce 
def restitutionVelocity(): Float64 = 0.001