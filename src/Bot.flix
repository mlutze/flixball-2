type alias BotEffects = {Random, Logger}

type alias Bot = (Int8, Pitch, Player) -> (Int8, Direction) \ BotEffects

type alias StatefulPrebot[ef: Eff, s: Type] = (s, Pitch, Player) -> (s, Direction) \ BotEffects - ef

type alias StatelessPrebot[ef: Eff] = (Pitch, Player) -> Direction \ BotEffects - ef