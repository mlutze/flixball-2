pub type alias Direction = {
    ux = Float64,
    uy = Float64
}

mod Direction {

    pub def fromTo(l1: Location, l2: Location): Direction = {
        let dis = {
            dx = l2#x - l1#x,
            dy = l2#y - l1#y
        };
        Displacement.getDirection(dis)
    }

    // signed angle in radians, in (-π, π].
    // positive = counterclockwise rotation from d1 to d2 (Y-up convention).
    pub def angle(d1: Direction, d2: Direction): Float64 = {
        let dot   = d1#ux * d2#ux + d1#uy * d2#uy;
        let cross = d1#ux * d2#uy - d1#uy * d2#ux;
        Trig.atan2(cross, dot)
    }

    // rotate d counterclockwise by angle (radians, Y-up convention)
    pub def addAngle(d: Direction, angle: Float64): Direction = {
        let c = Trig.cos(angle);
        let s = Trig.sin(angle);
        {
            ux = d#ux * c - d#uy * s,
            uy = d#ux * s + d#uy * c
        }
    }

    pub def north(): Direction = {
        ux = 0.0,
        uy = 1.0
    }

    pub def south(): Direction = {
        ux = 0.0,
        uy = -1.0
    }

    pub def east(): Direction = {
        ux = 1.0,
        uy = 0.0
    }

    pub def west(): Direction = {
        ux = -1.0,
        uy = 0.0
    }

    pub def northeast(): Direction = {
        ux =  Trig.sqrt(2.0) / 2.0,
        uy =  Trig.sqrt(2.0) / 2.0
    }

    pub def northwest(): Direction = {
        ux = -Trig.sqrt(2.0) / 2.0,
        uy = Trig.sqrt(2.0) / 2.0
    }

    pub def southeast(): Direction = {
        ux = Trig.sqrt(2.0) / 2.0,
        uy = -Trig.sqrt(2.0) / 2.0
    }

    pub def southwest(): Direction = {
        ux = -Trig.sqrt(2.0) / 2.0,
        uy = -Trig.sqrt(2.0) / 2.0
    }

    pub def invert(dir: Direction): Direction = {
        ux = -dir#ux,
        uy = -dir#uy
    }
}