mod Utils {
    import java.lang.Math
    pub def randomChoice(l: Vector[a]): a \ IO = {
        let idx = Float64.truncateToInt32(Math.random() * Int32.toFloat64(Vector.length(l)));
        run {
            l[idx]
        } with handler OutOfBounds {
            def outOfBounds(_, _) = unreachable!()
        }
    }
}