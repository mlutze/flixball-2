type alias Displacement = {
    dx = Float64,
    dy = Float64
}

mod Displacement {
    pub def inDirection(dir: Direction, dist: Float64): Displacement = {
        dx = dir#ux * dist,
        dy = dir#uy * dist
    }

    pub def apply(dis: Displacement, loc: Location): Location = {
        x = loc#x + dis#dx,
        y = loc#y + dis#dy
    }
}