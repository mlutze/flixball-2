
mod Locations {
    use Constants.goalWidth
    use Constants.goalDepth
    use Constants.goalAreaWidth
    use Constants.goalAreaDepth
    use Constants.penaltyBoxWidth
    use Constants.penaltyBoxDepth
    use Constants.penaltySpotDist
    use Constants.pitchLength
    use Constants.pitchWidth
    
    pub def cornerNE(): Location = {
        x =  pitchLength() / 2.0,
        y =  pitchWidth() / 2.0
    }

    pub def cornerNW(): Location = {
        x = -pitchLength() / 2.0,
        y =  pitchWidth() / 2.0
    }

    pub def cornerSE(): Location = {
        x =  pitchLength() / 2.0,
        y = -pitchWidth() / 2.0
    }

    pub def cornerSW(): Location = {
        x = -pitchLength() / 2.0,
        y = -pitchWidth() / 2.0
    }

    pub def center(): Location = {
        x = 0.0,
        y = 0.0
    }

    pub def goalpostNE(): Location = {
        x =  pitchLength() / 2.0,
        y =  goalWidth() / 2.0
    }

    pub def goalpostNW(): Location = {
        x = -pitchLength() / 2.0,
        y =  goalWidth() / 2.0
    }

    pub def goalpostSE(): Location = {
        x =  pitchLength() / 2.0,
        y = -goalWidth() / 2.0
    }

    pub def goalpostSW(): Location = {
        x = -pitchLength() / 2.0,
        y = -goalWidth() / 2.0
    }

    // SW corners (bottom-left in world coords) of each rectangular region — what Rectangle2D wants
    pub def penaltyBoxW(): Location = {
        x = -pitchLength() / 2.0,
        y = -penaltyBoxWidth() / 2.0
    }

    pub def penaltyBoxE(): Location = {
        x =  pitchLength() / 2.0 - penaltyBoxDepth(),
        y = -penaltyBoxWidth() / 2.0
    }

    pub def goalAreaW(): Location = {
        x = -pitchLength() / 2.0,
        y = -goalAreaWidth() / 2.0
    }

    pub def goalAreaE(): Location = {
        x =  pitchLength() / 2.0 - goalAreaDepth(),
        y = -goalAreaWidth() / 2.0
    }

    // goal net rectangle sits behind the goal line
    pub def goalW(): Location = {
        x = -pitchLength() / 2.0 - goalDepth(),
        y = -goalWidth() / 2.0
    }

    pub def goalE(): Location = {
        x =  pitchLength() / 2.0,
        y = -goalWidth() / 2.0
    }

    // centres of the penalty spots
    pub def penaltySpotW(): Location = {
        x = -pitchLength() / 2.0 + penaltySpotDist(),
        y = 0.0
    }

    pub def penaltySpotE(): Location = {
        x =  pitchLength() / 2.0 - penaltySpotDist(),
        y = 0.0
    }
}