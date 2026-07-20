mod Constants {
    // pitch dimensions in meters; taken from https://commons.wikimedia.org/wiki/File:Association_Football_field_diagram_-en.svg
    pub def pitchLength(): Float64 = 105.0

    pub def pitchWidth(): Float64 = 70.0

    pub def centerCircleRadius(): Float64 = 9.15

    pub def cornerArcRadius(): Float64 = 1.0

    pub def goalWidth(): Float64 = 7.32

    // net depth: arbitrary rendering value, not a FIFA spec
    pub def goalDepth(): Float64 = 2.0

    pub def goalAreaWidth(): Float64 = 18.32

    pub def goalAreaDepth(): Float64 = 5.5

    pub def penaltyBoxWidth(): Float64 = 40.32

    pub def penaltyBoxDepth(): Float64 = 16.5

    pub def penaltySpotDist(): Float64 = 11.0

    // rendering size of the painted penalty spot; not a FIFA spec
    pub def penaltySpotRadius(): Float64 = 0.15

    pub def penaltyArcDist(): Float64 = 9.15

    // body radii in meters
    pub def ballRadius(): Float64 = 0.11

    pub def playerRadius(): Float64 = 0.5

    // masses in kg
    pub def ballMass(): Float64 = 0.410

    pub def playerMass(): Float64 = 80.0

    // revisit: this is 2-D
    pub def ballVolume(): Float64 = 4.0 / 3.0 * Trig.pi() * ballRadius() * ballRadius() * ballRadius()

    pub def ballDensity(): Float64 = ballMass() / ballVolume()

    pub def playerVolume(): Float64 = 4.0 / 3.0 * Trig.pi() * playerRadius() * playerRadius() * playerRadius()

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

    pub def pregameMs(): Int32 = 10_000

    pub def gameMs(): Int32 = 300_000

    pub def postGoalMs(): Int32 = 10_000

    pub def postGameMs(): Int32 = 30_000

}
