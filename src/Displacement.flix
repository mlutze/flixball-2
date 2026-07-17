type alias Displacement = {
    dx = Float64,
    dy = Float64
}

mod Displacement {
    pub def inDirection(dir: Direction, dist: Float64): Displacement = {
        dx = dir#ux * dist,
        dy = dir#uy * dist
    }

    pub def fromTo(l1: Location, l2: Location): Displacement = {
        dx = l2#x - l1#x,
        dy = l2#y - l1#y
    }

    pub def apply(dis: Displacement, loc: Location): Location = {
        x = loc#x + dis#dx,
        y = loc#y + dis#dy
    }

    pub def distance(dis: Displacement): Float64 = {
        Float64.pow(base = dis#dx * dis#dx + dis#dy * dis#dy, 0.5)
    }

    pub def getDirection(dis: Displacement): Direction = {
        let len = distance(dis);
        if (len == 0.0)
            ({ ux = 0.0, uy = 0.0 })
        else
            ({ ux = dis#dx / len, uy = dis#dy / len })
    }
}