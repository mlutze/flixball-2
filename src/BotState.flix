

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