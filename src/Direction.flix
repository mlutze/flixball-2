pub type alias Direction = {
    ux = Float64,
    uy = Float64
}

mod Direction {
    import java.lang.Math

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
        unsafe IO { Math.atan2(cross, dot) }
    }

    // rotate d counterclockwise by angle (radians, Y-up convention)
    pub def addAngle(d: Direction, angle: Float64): Direction = {
        let c = unsafe IO { Math.cos(angle) };
        let s = unsafe IO { Math.sin(angle) };
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
}