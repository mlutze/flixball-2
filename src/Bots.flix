mod Bots {
    pub def runAtBall(pitch: Pitch, name: String): Direction = {
        run {
            let me = pitch#players[name];
            let desiredVelocity = {
                dx = pitch#ballLocation#x - me#location#x,
                dy = pitch#ballLocation#y - me#location#y
            };
            Velocity.toDirection(desiredVelocity)
        } with handler KeyNotFound {
            def keyNotFound(_msg, _k) = unreachable!()
        }
    }
}