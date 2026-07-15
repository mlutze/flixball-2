mod Rendering {
    import java.awt.BasicStroke
    import java.awt.Color
    import java.awt.Graphics
    import java.awt.Graphics2D
    import java.awt.RenderingHints
    import java.awt.geom.AffineTransform
    import java.awt.geom.Arc2D$Double
    import java.awt.geom.Ellipse2D$Double
    import java.awt.geom.Line2D
    import java.awt.geom.Line2D$Double
    import java.awt.geom.Rectangle2D$Double

    use Constants.pitchLength
    use Constants.pitchWidth
    use Constants.playerRadius
    use Constants.ballRadius

    pub def renderBackground(g: Graphics2D): Unit \ IO = {
        // grass: just do a huge background
        g.setColor((Color.GREEN).darker());
        g.fill(new Rectangle2D$Double(-1000.0, -1000.0, 2000.0, 2000.0));

        // lines
        g.setStroke(new BasicStroke(0.12f32));
        g.setColor(Color.WHITE);

        // outer rectangle
        let cornerX = -pitchLength() / 2.0;
        let cornerY = -pitchWidth() / 2.0;
        g.draw(new Rectangle2D$Double(cornerX, cornerY, pitchLength(), pitchWidth()));

        // halfway line
        g.draw(new Line2D$Double(0.0, -pitchWidth() / 2.0 , 0.0, pitchWidth() / 2.0));

        // center circle
        g.draw(new Ellipse2D$Double(-9.15, -9.15, 18.30, 18.30));

        // penalty boxes: 16.5 * 40.32
        g.draw(new Rectangle2D$Double(-pitchLength() / 2.0 , -20.16, 16.5, 40.32));
        g.draw(new Rectangle2D$Double(pitchLength() / 2.0 - 16.5, -20.16, 16.5, 40.32));

        // goal areas (6-yard boxes): 5.5 deep * 18.32 wide
        g.draw(new Rectangle2D$Double(-pitchLength() / 2.0, -9.16, 5.5, 18.32));
        g.draw(new Rectangle2D$Double(pitchLength() / 2.0 - 5.5, -9.16, 5.5, 18.32));

        // goals: 2 deep * 7.32 wide, drawn behind the goal line, with a net-like crosshatch
        g.draw(new Rectangle2D$Double(-pitchLength() / 2.0 - 2.0, -3.66, 2.0, 7.32));
        g.draw(new Rectangle2D$Double(pitchLength() / 2.0, -3.66, 2.0, 7.32));
        crosshatch(g, -pitchLength() / 2.0 - 2.0, -3.66, 2.0, 7.32);
        crosshatch(g, pitchLength() / 2.0, -3.66, 2.0, 7.32);

        // penalty spots: 11 m from goal line, filled dot
        g.fill(new Ellipse2D$Double(-pitchLength() / 2.0 + 11.0 - 0.15, -0.15, 0.30, 0.30));
        g.fill(new Ellipse2D$Double(pitchLength() / 2.0 - 11.0 - 0.15, -0.15, 0.30, 0.30));

        // penalty arcs: radius 9.15 m from penalty spot, portion outside the penalty box.
        // half-angle to where the arc meets the front of the penalty box: acos(5.5/9.15) ≈ 53°
        let leftSpotX = -pitchLength() / 2.0 + 11.0;
        let rightSpotX = pitchLength() / 2.0 - 11.0;
        // Arc2D.OPEN = 0
        // left arc opens toward +x: sweep from -53° through 0° to +53°
        g.draw(new Arc2D$Double(leftSpotX - 9.15, -9.15, 18.30, 18.30, -53.0, 106.0, 0));
        // right arc opens toward -x: sweep from 127° through 180° to 233°
        g.draw(new Arc2D$Double(rightSpotX - 9.15, -9.15, 18.30, 18.30, 127.0, 106.0, 0))
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