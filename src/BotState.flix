trait BotState[a] {
    pub def toByte(state: a): Int8

    pub def fromByte(b: Int8): a
}

instance BotState[Bool] {

    pub def toByte(state: Bool): Int8 = {
        if (state) 1i8 else 0i8
    }

    pub def fromByte(b: Int8): Bool = {
        b != 0i8
    }

}

instance BotState[Int8] {

    pub def toByte(state: Int8): Int8 = state

    pub def fromByte(b: Int8): Int8 = b

}
