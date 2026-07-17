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

    import java.awt.RadialGradientPaint
    import java.awt.geom.Point2D$Double

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
    use Constants.cornerArcRadius

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
        g.draw(new Arc2D$Double(psxE - aRadius, psyE - aRadius, aDiameter, aDiameter, 180.0 - halfAngleDeg, fullAngleDeg, Arc2D.OPEN));

        // corner arcs: quarter circle at each pitch corner, bulging toward pitch interior
        let carc     = cornerArcRadius();
        let carcSize = carc * 2.0;
        let { x = neX, y = neY } = Locations.cornerNE();
        let { x = nwX, y = nwY } = Locations.cornerNW();
        let { x = seX, y = seY } = Locations.cornerSE();
        let { x = swX, y = swY } = Locations.cornerSW();
        // Starts chosen so each arc passes through the interior quadrant of its corner.
        // Y-flip mirrors Arc2D angles vs. world compass, hence the seemingly-swapped values.
        g.draw(new Arc2D$Double(neX - carc, neY - carc, carcSize, carcSize,  90.0, 90.0, Arc2D.OPEN));
        g.draw(new Arc2D$Double(nwX - carc, nwY - carc, carcSize, carcSize,   0.0, 90.0, Arc2D.OPEN));
        g.draw(new Arc2D$Double(seX - carc, seY - carc, carcSize, carcSize, 180.0, 90.0, Arc2D.OPEN));
        g.draw(new Arc2D$Double(swX - carc, swY - carc, carcSize, carcSize, 270.0, 90.0, Arc2D.OPEN))
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
        g.fill(circle);
        g.setColor(Color.BLACK);
        g.setStroke(new BasicStroke(0.05f32));
        g.draw(circle)
    }

    pub def renderForce(g: Graphics2D, source: Location, dir: Direction): Unit \ IO = {
        let length = 2.0;
        let disp = Displacement.inDirection(dir, length);
        let target = Displacement.apply(disp, source);
        let line = new Line2D$Double(
            source#x,
            source#y,
            target#x,
            target#y
        );

        g.setStroke(new BasicStroke(0.1f32));
        g.setColor(Color.PINK);
        g.draw(line)
    }

    pub def renderBall(g: Graphics2D, location: Location): Unit \ IO = {

        // highlight
        let hlRadius = ballRadius() * 5.0;
        let hlColor = Color.YELLOW;
        let transHlColor = new Color(hlColor.getRed(), hlColor.getGreen(), hlColor.getBlue(), 0);

        let hlCornerX = location#x - hlRadius;
        let hlCornerY = location#y - hlRadius;
        let hlCircle = new Ellipse2D$Double(hlCornerX, hlCornerY, hlRadius * 2.0, hlRadius * 2.0);
        let center = new Point2D$Double(location#x, location#y);
        g.setPaint(new RadialGradientPaint(center, Float64.truncateToFloat32(hlRadius), Vector#{0.0f32, 1.0f32}, Vector#{hlColor, transHlColor}));
        g.fill(hlCircle);

        // ball fill
        let cornerX = location#x - ballRadius();
        let cornerY = location#y - ballRadius();
        let circle = new Ellipse2D$Double(cornerX, cornerY, ballRadius() * 2.0, ballRadius() * 2.0);
        g.setColor(Color.WHITE);
        g.fill(circle);

        // ball border
        g.setColor(Color.BLACK);
        g.setStroke(new BasicStroke(0.05f32));
        g.draw(circle)
    }

    // renders the player forces if dirsOpt is not None
    pub def renderPitch(g: Graphics2D, pitch: Pitch, dirsOpt: Option[Map[String, Direction]]): Unit \ IO = {
        renderBackground(g);
        foreach (
            player <- Map.valuesOf(pitch#players)
        ) {
            renderPlayer(g, player);
            match dirsOpt {
                case None => ()
                case Some(dirs) =>
                    let dir = Utils.unsafeGetMap(player#name, dirs);
                    renderForce(g, player#location, dir)
            }
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