
pub type alias Velocity = {
    dx = Float64,
    dy = Float64
}

mod Velocity {
    pub def toDirection(v: Velocity): Direction = {
        let len = Math.sqrt(v#dx * v#dx + v#dy * v#dy);
        if (len == 0.0)
            ({ ux = 0.0, uy = 0.0 })
        else
            ({ ux = v#dx / len, uy = v#dy / len })
    }

    pub def speed(v: Velocity): Float64 = {
        Float64.pow(base = v#dx * v#dx + v#dy * v#dy, 0.5)
    }
}