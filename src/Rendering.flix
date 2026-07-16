mod Rendering {
    import java.awt.BasicStroke
    import java.awt.Color
    import java.awt.Graphics
    import java.awt.Graphics2D
    import java.awt.RenderingHints
    import java.awt.geom.AffineTransform
    import java.awt.geom.Arc2D
    import java.awt.geom.Arc2D$Double
    import java.awt.geom.Ellipse2D$Double
    import java.awt.geom.Line2D
    import java.awt.geom.Line2D$Double
    import java.awt.geom.Rectangle2D$Double

    import java.lang.Math

    use Constants.pitchLength
    use Constants.pitchWidth
    use Constants.playerRadius
    use Constants.ballRadius
    use Constants.goalWidth
    use Constants.goalDepth
    use Constants.goalAreaWidth
    use Constants.goalAreaDepth
    use Constants.penaltyBoxWidth
    use Constants.penaltyBoxDepth
    use Constants.penaltySpotDist
    use Constants.penaltySpotRadius
    use Constants.penaltyArcDist
    use Constants.centerCircleRadius

    pub def renderBackground(g: Graphics2D): Unit \ IO = {
        // grass: just do a huge background
        g.setColor((Color.GREEN).darker());
        g.fill(new Rectangle2D$Double(-1000.0, -1000.0, 2000.0, 2000.0));

        // lines
        g.setStroke(new BasicStroke(0.12f32));
        g.setColor(Color.WHITE);

        // outer rectangle
        let { x = cornerX, y = cornerY } = Locations.cornerSW();
        g.draw(new Rectangle2D$Double(cornerX, cornerY, pitchLength(), pitchWidth()));

        // halfway line
        g.draw(new Line2D$Double(0.0, -pitchWidth() / 2.0 , 0.0, pitchWidth() / 2.0));

        // center circle
        let cRadius = centerCircleRadius();
        let { x = x0, y = y0 } = Locations.center();
        g.draw(new Ellipse2D$Double(x0 - cRadius, y0 - cRadius, cRadius * 2.0, cRadius * 2.0));

        // penalty boxes
        let { x = pbxW, y = pbyW } = Locations.penaltyBoxW();
        let { x = pbxE, y = pbyE } = Locations.penaltyBoxE();
        g.draw(new Rectangle2D$Double(pbxW, pbyW, penaltyBoxDepth(), penaltyBoxWidth()));
        g.draw(new Rectangle2D$Double(pbxE, pbyE, penaltyBoxDepth(), penaltyBoxWidth()));

        // goal areas (6-yard boxes)
        let { x = gaxW, y = gayW } = Locations.goalAreaW();
        let { x = gaxE, y = gayE } = Locations.goalAreaE();
        g.draw(new Rectangle2D$Double(gaxW, gayW, goalAreaDepth(), goalAreaWidth()));
        g.draw(new Rectangle2D$Double(gaxE, gayE, goalAreaDepth(), goalAreaWidth()));

        // goals: drawn behind the goal line, with a net-like crosshatch
        let { x = gxW, y = gyW } = Locations.goalW();
        let { x = gxE, y = gyE } = Locations.goalE();
        g.draw(new Rectangle2D$Double(gxW, gyW, goalDepth(), goalWidth()));
        g.draw(new Rectangle2D$Double(gxE, gyE, goalDepth(), goalWidth()));
        crosshatch(g, gxW, gyW, goalDepth(), goalWidth());
        crosshatch(g, gxE, gyE, goalDepth(), goalWidth());

        // penalty spots
        let dotSize = penaltySpotRadius() * 2.0;
        let { x = psxW, y = psyW } = Locations.penaltySpotW();
        let { x = psxE, y = psyE } = Locations.penaltySpotE();
        g.fill(new Ellipse2D$Double(psxW - penaltySpotRadius(), psyW - penaltySpotRadius(), dotSize, dotSize));
        g.fill(new Ellipse2D$Double(psxE - penaltySpotRadius(), psyE - penaltySpotRadius(), dotSize, dotSize));

        // penalty arcs: radius penaltyArcDist from penalty spot, portion outside the penalty box.
        // half-angle is where the arc meets the front of the penalty box.
        let aRadius = penaltyArcDist();
        let aDiameter = aRadius * 2.0;
        let halfChord = penaltyBoxDepth() - penaltySpotDist();
        let halfAngleDeg = unsafe IO { Math.toDegrees(Math.acos(halfChord / aRadius)) };
        let fullAngleDeg = 2.0 * halfAngleDeg;
        // west arc opens toward +x (through 0°); east arc opens toward -x (through 180°)
        g.draw(new Arc2D$Double(psxW - aRadius, psyW - aRadius, aDiameter, aDiameter, -halfAngleDeg, fullAngleDeg, Arc2D.OPEN));
        g.draw(new Arc2D$Double(psxE - aRadius, psyE - aRadius, aDiameter, aDiameter, 180.0 - halfAngleDeg, fullAngleDeg, Arc2D.OPEN))
    }

    pub def renderPlayer(g: Graphics2D, player: Player): Unit \ IO = {
        let cornerX = player#location#x - playerRadius();
        let cornerY = player#location#y - playerRadius();
        let circle = new Ellipse2D$Double(cornerX, cornerY, playerRadius() * 2.0, playerRadius() * 2.0);
        let color = match player#team {
            case Team.Red => Color.RED
            case Team.Blue => Color.BLUE
        };
        g.setColor(color);
        g.fill(circle)
    }

    pub def renderBall(g: Graphics2D, location: Location): Unit \ IO = {
        let cornerX = location#x - ballRadius();
        let cornerY = location#y - ballRadius();
        let circle = new Ellipse2D$Double(cornerX, cornerY, ballRadius() * 2.0, ballRadius() * 2.0);
        g.setColor(Color.WHITE);
        g.fill(circle)
    }

    pub def renderPitch(g: Graphics2D, pitch: Pitch): Unit \ IO = {
        renderBackground(g);
        foreach (
            player <- Map.valuesOf(pitch#players)
        ) {
            renderPlayer(g, player)
        };
        renderBall(g, pitch#ballLocation)
    }

    // fills the given rectangle (in world coords) with a diagonal crosshatch pattern
    def crosshatch(g: Graphics2D, x: Float64, y: Float64, w: Float64, h: Float64): Unit \ IO = {
        let oldClip   = g.getClip();
        let oldStroke = g.getStroke();
        g.setClip(new Rectangle2D$Double(x, y, w, h));
        g.setStroke(new BasicStroke(0.04f32));
        let spacing = 0.5;
        let extent  = w + h;   // long enough for any diagonal to cross the rect fully
        foreach (i <- List.range(-40, 40)) {
            let off = Int32.toFloat64(i) * spacing;
            // ↗ diagonals
            g.draw(new Line2D$Double(x + off, y, x + off + extent, y + extent));
            // ↘ diagonals
            g.draw(new Line2D$Double(x + off, y + h, x + off + extent, y + h - extent))
        };
        g.setStroke(oldStroke);
        g.setClip(oldClip)
    }
}