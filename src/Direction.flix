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
}