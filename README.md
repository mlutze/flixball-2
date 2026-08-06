# Flixball 2

Flixball 2 is a simple soccer simulation with basic 2-dimensional physics. The game runs autonomously. Simple AI controls the actions of the players.


## Making a bot

The interface for bots is defined in `Bot.flix`. A bot is a function: `(Pitch, Player) -> Direction \ BotEffects`, where `Pitch` contains information about the state of the game, and `BotEffects` is the set of effects the bot has access to: `Random, Logger, and BotState`.

Examples of bots can be found in `Bots.flix`. To make your bot available to the simulator, add it to the map returned by `Bots.bots`.

## Testing a bot

Bots can be tested quickly via command line arguments. This avoids bringing up the GUI and simply reports the result of a simulated game as `<westScore>,<eastScore>`.

```
-n                       number of games to simulate
-w <playername=botname>  add a player to the west team
-e <playername=botname>  add a player to the east team
```

For example, the following command simulates 10 games between two teams, each with two players.

```
$ java -jar artifact/flixball-2.jar -n 10 -w "w1=Defend" -w "w2=AvoidGoalie" -e "e1=ApproachCircleShoot" -e "e2=BetweenBallAndGoal"
0,0
0,0
0,0
0,0
0,0
1,0
1,0
0,0
0,0
1,0
```