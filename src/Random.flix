
eff Random {
    def randFloat64(): Float64
    def randInt32(): Int32
}

mod Random {
    import java.util.{Random => JRandom}
    pub def runWithIO(f: Unit -> a \ ef): a \ (ef - Random) + IO = {
        let rand = new JRandom();
        run f() with handler Random {
            def randFloat64(k) = k(rand.nextDouble())
            def randInt32(k) = k(rand.nextInt())
        }
    }
}