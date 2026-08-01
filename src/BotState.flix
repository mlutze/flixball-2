/// An effect for maintaining a bot's state between simulation frames.
/// Bots can only store up to one byte of data.
/// Authors should generally use the getState and setState helper methods
/// instead of using the effect directly.
/// These methods allow the use of any data type that has a Byteable instance.
eff BotState {
    def getByte(): Int8
    def setByte(b: Int8): Unit
}

mod BotState {
    pub def getState(): a \ BotState with Byteable[a] = {
        Byteable.fromByte(BotState.getByte())
    }
    pub def setState(x: a): Unit \ BotState with Byteable[a]  = {
        BotState.setByte(Byteable.toByte(x))
    }

    pub def runWithRef(ref: Ref[Int8, r], f: Unit -> a \ ef): a \ (ef - BotState) + r = {
        run f() with handler BotState {
            def getByte(k) = k(Ref.get(ref))
            def setByte(b, k) = { Ref.put(b, ref); k() }
        }
    }
}