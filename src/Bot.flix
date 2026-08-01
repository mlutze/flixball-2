/// The set of effects a bot is allowed to use.
type alias BotEffects = {Math.Random, Logger, BotState}

type alias Bot = (Pitch, Player) -> Direction \ BotEffects