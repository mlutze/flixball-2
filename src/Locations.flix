
mod Locations {
    use Constants.goalWidth
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
}