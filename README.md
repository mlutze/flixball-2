# Flixball 2

Flixball 2 is a simple soccer simulation with basic 2-dimensional physics. The game runs autonomously. Simple AI controls the actions of the players.


## Making a bot

The interface for bots is defined in `Bot.flix`. A bot is a function: `(Pitch, Player) -> Direction \ BotEffects`, where `Pitch` contains information about the state of the game, and `BotEffects` is the set of effects the bot has access to: `Random, Logger, and BotState`.

Examples of bots can be found in `Bots.flix`. To make your bot available to the simulator, add it to the map returned by `Bots.bots`.
