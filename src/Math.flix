mod Math {
    import java.lang.{Math => JMath}

    pub def pi(): Float64 = JMath.PI

    pub def asin(x: Float64): Float64 = unsafe IO { JMath.asin(x) }

    pub def sin(x: Float64): Float64 = unsafe IO { JMath.sin(x) }

    pub def cos(x: Float64): Float64 = unsafe IO { JMath.cos(x) }
    pub def acos(x: Float64): Float64 = unsafe IO { JMath.acos(x) }

    pub def atan2(x: Float64, y: Float64): Float64 = unsafe IO { JMath.atan2(x, y) }

    pub def toDegrees(x: Float64): Float64 = unsafe IO { JMath.toDegrees(x) }

    pub def sqrt(x: Float64): Float64 = unsafe IO { JMath.sqrt(x) }

}