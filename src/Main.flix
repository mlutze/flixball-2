
// The main entry point.
def main(): Unit \ Sys.Env + IO + Sys.Console = {
    let args = Sys.Env.getArgs();
    run 
        match args {
            case Nil => Gui.runWithGui()
            case _ => 
                let config = Cli.parse(args);
                runAll(config#gameConfig, config#numRuns)
        }
    with handler Cli.Error {
        def error(msg, _) = Sys.Console.println("Command error: ${msg}")
    }
}

def runAll(config: GameConfig, num: Int32): Unit \ IO + Sys.Console = {
    if (num <= 0) {
        ()
    } else {
        let frames = Simulation.simulate(config);
        let lastFrame = frames |> Vector.get(Vector.length(frames) - 1);
        let westScore = lastFrame#pitch#westScore;
        let eastScore = lastFrame#pitch#eastScore;
        Sys.Console.println("${westScore},${eastScore}");
        runAll(config, num - 1)
    }
}
