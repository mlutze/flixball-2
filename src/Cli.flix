mod Cli {

    type alias CliConfig = {
        numRuns = Int32,
        gameConfig = Gui.GameConfig
    }

    pub def parseHelper(args: List[String], config: CliConfig): CliConfig \ Abort = match args {
        case Nil => config
        case "-n" :: num :: tl =>
            let n = Int32.parse(10, num) |> Result.getOrAbort;
            let newConfig = { numRuns = n | config };
            parseHelper(tl, newConfig)
        case "-e" :: assignment :: tl =>
            let usedNames =
                (config#gameConfig#eastPlayers |> Map.keysOf) ++
                (config#gameConfig#westPlayers |> Map.keysOf);
            let (name, bot) =  parseAssignment(assignment, usedNames);
            let newEastPlayers = config#gameConfig#eastPlayers |> Map.insert(name, bot);
            let newGameConfig = { eastPlayers = newEastPlayers | config#gameConfig };
            let newConfig = { gameConfig = newGameConfig | config };
            parseHelper(tl, newConfig)
        case "-w" :: assignment :: tl =>
            let usedNames =
                (config#gameConfig#eastPlayers |> Map.keysOf) ++
                (config#gameConfig#westPlayers |> Map.keysOf);
            let (name, bot) =  parseAssignment(assignment, usedNames);
            let newWestPlayers = config#gameConfig#westPlayers |> Map.insert(name, bot);
            let newGameConfig = { westPlayers = newWestPlayers | config#gameConfig };
            let newConfig = { gameConfig = newGameConfig | config };
            parseHelper(tl, newConfig)
    }

    def parseAssignment(assignment: String, usedNames: Set[String]): (String, Bot) \ Abort = {
        let parts = String.splitOn(substr = "=", assignment);
        match parts {
            case name :: botName :: Nil =>
                if (Set.memberOf(name, usedNames)) {
                    Abort.abort(RichString.fromString("Repeated name"))
                };
                let bot = Bots.bots() |> Map.getOrAbort(botName);
                (name, bot)
            case _ => Abort.abort(RichString.fromString("Invalid assignment"))
        }
    }
}