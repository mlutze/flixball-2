
pub type alias Velocity = {
    dx = Float64,
    dy = Float64
}

mod Velocity {
    import java.lang.Math
    pub def toDirection(v: Velocity): Direction = {
        let len = unsafe IO { Math.sqrt(v#dx * v#dx + v#dy * v#dy) };
        if (len == 0.0)
            ({ ux = 0.0, uy = 0.0 })
        else
            ({ ux = v#dx / len, uy = v#dy / len })
    }
}