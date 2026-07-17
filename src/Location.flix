pub type alias Location = {
    x = Float64,
    y = Float64
}

mod Location {
    pub def midpoint(l1: Location, l2: Location): Location = {
        {
            x = (l1#x + l2#x) / 2.0,
            y = (l1#y + l2#y) / 2.0
        }
    }

    pub def distance(l1: Location, l2: Location): Float64 = {
        Displacement.fromTo(l1, l2) |> Displacement.distance
    }
}