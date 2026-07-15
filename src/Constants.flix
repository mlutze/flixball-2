mod Constants {
    import java.lang.Math

    // pitch dimensions in meters
    pub def pitchLength(): Float64 = 100.0

    pub def pitchWidth(): Float64 = 50.0

    // body radii in meters
    pub def ballRadius(): Float64 = 0.11

    pub def playerRadius(): Float64 = 0.5

    // masses in kg
    pub def ballMass(): Float64 = 0.410

    pub def playerMass(): Float64 = 80.0

    // revisit: this is 2-D
    pub def ballVolume(): Float64 = 4.0 / 3.0 * Math.PI * ballRadius() * ballRadius() * ballRadius()

    pub def ballDensity(): Float64 = ballMass() / ballVolume()

    pub def playerVolume(): Float64 = 4.0 / 3.0 * Math.PI * playerRadius() * playerRadius() * playerRadius()

    pub def playerDensity(): Float64 = playerMass() / playerVolume()

    // random guess; friction is against other bodies
    pub def ballFriction(): Float64 = 0.08

    // maybe make player friction higher than ball friction?
    pub def playerFriction(): Float64 = 0.12

    // linear damping stands in for friction against the ground

    // soccer ball on grass: light drag, coasts a while
    pub def ballLinearDamping(): Float64 = 0.15

    // running human: quick natural decay when AI isn't pushing
    pub def playerLinearDamping(): Float64 = 2.0

    pub def angularDamping(): Float64 = 0.8

    // 0.82 - 0.88 apparently
    pub def ballRestitution(): Float64 = 0.85

    // players are less bouncy than the ball
    pub def playerRestitution(): Float64 = 0.30

    // minimum velocity for bounce
    pub def restitutionVelocity(): Float64 = 0.001

    pub def playerForce(): Float64 = 1200.0

}
