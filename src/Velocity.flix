
pub type alias Velocity = {
    dx = Float64,
    dy = Float64
}

mod Velocity {
    import java.lang.Math
    pub def toDirection(v: Velocity): Direction = {
        unsafe IO { Math.tan(v#dy / v#dx) }
    }
}