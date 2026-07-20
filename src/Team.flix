mod Team {
    pub enum Team {
        case East
        case West
    }

    pub def opp(t: Team): Team = match t {
        case East => West
        case West => East
    }
}