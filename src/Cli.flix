mod Cli {

    pub eff Error {
        def error(s: String): Void
    }

    def resultToError(msg: String, r: Result[e, a]): a \ Error = match r {
        case Ok(x) => x
        case Err(_) => Error.error(msg)
    }

    def optionToError(msg: String, r: Option[a]): a \ Error = match r {
        case Some(x) => x
        case None => Error.error(msg)
    }

    type alias CliConfig = {
        numRuns = Int32,
        gameConfig = GameConfig
    }

    def defaultConfig(): CliConfig = {
        numRuns = 1,
        gameConfig = {
            westPlayers = Map#{},
            eastPlayers = Map#{}
        }
    }

    pub def parse(args: List[String]): CliConfig \ Error = parseHelper(args, defaultConfig())

    def parseHelper(args: List[String], config: CliConfig): CliConfig \ Error = match args {
        case Nil => config
        case "-n" :: num :: tl =>
            let n = Int32.parse(10, num) |> resultToError("Invalid number: ${num}");
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
        case opt => Error.error("Unrecognized option: ${opt}")
    }

    def parseAssignment(assignment: String, usedNames: Set[String]): (String, Bot) \ Error = {
        let parts = String.splitOn(substr = "=", assignment);
        match parts {
            case name :: botName :: Nil =>
                if (Set.memberOf(name, usedNames)) {
                    Error.error("Repeated name: ${name}")
                };
                let bot = Bots.bots() |> Map.get(botName) |> optionToError("Unknown bot: ${botName}");
                (name, bot)
            case _ => Error.error("Invalid assignment")
        }
    }
}