mod Gui {
    import javax.swing.SwingUtilities
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
    import java.awt.event.ActionListener
    import java.awt.event.ActionEvent
    import javax.swing.Timer
    import javax.swing.JFrame
    import javax.swing.JPanel
    import javax.swing.JSlider
    import javax.swing.BorderFactory
    import javax.swing.JButton
    import org.dyn4j.dynamics.Body
    import org.dyn4j.dynamics.BodyFixture
    import org.dyn4j.geometry.Geometry
    import org.dyn4j.geometry.MassType
    import org.dyn4j.geometry.Vector2
    import org.dyn4j.world.World
    import java.awt.BorderLayout
    import javax.swing.JLabel
    import javax.swing.JCheckBox
    import javax.swing.JTextField
    import javax.swing.JComboBox

    import java.lang.{Math => JMath}
    import java.lang.{String => JString}
    import java.lang.System

    pub def runWithGui(): Unit \ IO = {
        // split into two sides; east/west
        // add bot button -> adds a line with a dropdown to select a bot by name
        // also set bot name -> 

        let westPanel = new JPanel();
        let eastPanel = new JPanel();
        let westAddPlayerButton = new JButton("Add Player");
        ???
    }

    pub def mkBotLine(): JPanel \ IO = {
        let panel = new JPanel();
        let nameBox = new JTextField();
        let botNames = Map.keysOf(Bots.bots()) |> Set.toVector;
        let botBox = new JComboBox(botNames);
        ???
    }

    pub def _runWithGui(): Unit \ IO = {

        let box = Simulation.init();
        let frames = Simulation.runGame(box);
        let updatingSlider = Guard.fresh(Static);
        let anchor = Ref.fresh(Static, { frame = 0, epoch = Epoch.Absolute });


        let scorePanel = new JPanel();
        let timeLabel = new JLabel();
        timeLabel.setText("0.0");
        
        let westScoreLabel = new JLabel();
        westScoreLabel.setForeground(Color.RED);
        westScoreLabel.setText("0");
        let eastScoreLabel = new JLabel();
        eastScoreLabel.setForeground(Color.BLUE);
        eastScoreLabel.setText("0");

        scorePanel.add(westScoreLabel);
        scorePanel.add(timeLabel);
        scorePanel.add(eastScoreLabel);

        let forcesRef = Ref.fresh(Static, false);

        let pitchPanel = new JPanel {
            def paintComponent(this: JPanel, g: Graphics): Unit \ IO = {
                // super.paintComponent(g);
                let g2 = unchecked_cast(g as Graphics2D);
                g2.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);

                let scale = Float64.min(
                    Int32.toFloat64(this.getWidth()) / (Constants.pitchLength() + 10.0),
                    Int32.toFloat64(this.getHeight()) / (Constants.pitchWidth() + 10.0)
                );
                g2.translate(
                    Int32.toFloat64(this.getWidth()) / 2.0,
                    Int32.toFloat64(this.getHeight()) / 2.0
                );
                g2.scale(scale, -scale);
                g2.setStroke(new BasicStroke(0.05f32));

                let idx = getCurrentFrame(Ref.get(anchor));
                let pitch = Vector.get(idx, frames);
                // let dirs = if (Ref.get(forcesRef)) {
                //     Some(getAiDirections(marshallBox))
                // } else {
                //     None
                // };
                let dirs = None;
                Rendering.renderPitch(g2, pitch, dirs)
            }
        };

        let display = {
            pitch = pitchPanel,
            time = timeLabel,
            westScore = westScoreLabel,
            eastScore = eastScoreLabel
        };

        let lowerPanel = new JPanel();
        let slider = new JSlider(0, Vector.length(frames), 0);
        slider.setBorder(BorderFactory.createEmptyBorder(8, 8, 8, 8));

        let buttonPanel = new JPanel();
        let beginningButton = new JButton("⏮");
        let jumpBackwardButton = new JButton("⏪︎");
        let startButton = new JButton("▶");
        let jumpForwardButton = new JButton("⏩︎");
        let endButton = new JButton("⏭");
        let forcesButton = new JButton("Show Forces");

        buttonPanel.add(beginningButton);
        buttonPanel.add(jumpBackwardButton);
        buttonPanel.add(startButton);
        buttonPanel.add(jumpForwardButton);
        buttonPanel.add(endButton);
        buttonPanel.add(forcesButton);

        let gameLoop = makeGameLoop(frames, anchor, display, slider, updatingSlider);

        def onChangeSlider(_): Unit \ IO = {
            // ignore if we're advancing it
            updatingSlider |> Guard.ifOpen(
                () ->
                    let value = syncFromSlider(anchor, slider);
                    let pitch = Vector.get(value, frames);
                    refreshDisplay(pitch, display)
            )
        };

        slider.addChangeListener(Utils.mkChangeListener(onChangeSlider));


        def onClickBeginning(_): Unit = {
            updatingSlider |> Guard.withGuard(
                () -> {
                    let value = 0;
                    setAnchor(value, anchor);
                    discard syncToSlider(anchor, slider);
                    let pitch = Vector.get(value, frames);
                    refreshDisplay(pitch, display)
                }
            )
        };

        beginningButton.addActionListener(Utils.mkActionListener(onClickBeginning));


        def onClickJumpBackward(_): Unit = {
            updatingSlider |> Guard.withGuard(
                () ->
                    let oldValue = getCurrentFrame(Ref.get(anchor));
                    let newValue = Int32.max(0, oldValue - 10 * Constants.frameRate());
                    setAnchor(newValue, anchor);
                    discard syncToSlider(anchor, slider);
                    let pitch = Vector.get(newValue, frames);
                    refreshDisplay(pitch, display)
            )
        };

        jumpBackwardButton.addActionListener(Utils.mkActionListener(onClickJumpBackward));


        def onClickStartPause(_): Unit = {
            if (gameLoop.isRunning()) {
                startButton.setText("▶");
                gameLoop.stop();
                pauseAnchor(anchor)
            } else {
                startButton.setText("⏸");
                gameLoop.start();
                unpauseAnchor(anchor)
            }
        };

        startButton.addActionListener(Utils.mkActionListener(onClickStartPause));

        def onClickJumpForward(_): Unit = {
            updatingSlider |> Guard.withGuard(
                () ->
                    let oldValue = getCurrentFrame(Ref.get(anchor));
                    let newValue = Int32.min(Vector.length(frames) - 1, oldValue + 10 * Constants.frameRate());
                    setAnchor(newValue, anchor);
                    discard syncToSlider(anchor, slider);
                    let pitch = Vector.get(newValue, frames);
                    refreshDisplay(pitch, display)
            )
        };

        jumpForwardButton.addActionListener(Utils.mkActionListener(onClickJumpForward));

        def onClickEnd(_): Unit = {
            updatingSlider |> Guard.withGuard(
                () ->
                    let value = Vector.length(frames) - 1;
                    setAnchor(value, anchor);
                    discard syncToSlider(anchor, slider);
                    let pitch = Vector.get(value, frames);
                    refreshDisplay(pitch, display)
            )
        };

        def onClickForces(_): Unit = {
            let nowShowing = Ref.get(forcesRef);
            if (nowShowing) {
                Ref.put(false, forcesRef);
                forcesButton.setText("Show Forces");
                pitchPanel.repaint()
            } else {
                Ref.put(true, forcesRef);
                forcesButton.setText("Hide Forces");
                pitchPanel.repaint()
            }
        };

        endButton.addActionListener(Utils.mkActionListener(onClickEnd));

        forcesButton.addActionListener(Utils.mkActionListener(onClickForces));

        lowerPanel.setLayout(new BorderLayout(0, 0));
        lowerPanel.add(slider, BorderLayout.NORTH);
        lowerPanel.add(buttonPanel, BorderLayout.SOUTH);

        let frame = new JFrame("Flixball 2");
        frame.setSize(1000, 600);
        frame.setExtendedState(JFrame.MAXIMIZED_BOTH);
        frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        frame.add(pitchPanel, BorderLayout.CENTER);
        frame.add(scorePanel, BorderLayout.NORTH);
        frame.add(lowerPanel, BorderLayout.SOUTH);
        frame.setVisible(true)
    }


    def syncToSlider(anchor: Ref[Anchor, Static], slider: JSlider): Int32 \ IO = {
        let value = getCurrentFrame(Ref.get(anchor));
        slider.setValue(value);
        value
    }

    def setAnchor(value: Int32, anchor: Ref[Anchor, Static]): Unit \ IO = {
        let epoch = Epoch.Relative(System.currentTimeMillis());
        Ref.put({ frame = value, epoch = epoch }, anchor)
    }

    def syncFromSlider(anchor: Ref[Anchor, Static], slider: JSlider): Int32 \ IO = {
        let value = slider.getValue();
        let epoch = match Ref.get(anchor)#epoch {
            case Epoch.Absolute => Epoch.Absolute
            case Epoch.Relative(_) => Epoch.Relative(System.currentTimeMillis())
        };
        Ref.put({ frame = value, epoch = epoch }, anchor);
        value
    }

    type alias Display = {
        pitch = JPanel,
        time = JLabel,
        westScore = JLabel,
        eastScore = JLabel
    }

    def refreshDisplay(
        pitch: Pitch,
        display: Display
    ): Unit \ IO = {
        display#pitch.repaint();
        display#time.setText(formatTimeMs(pitch#timeMs));
        display#westScore.setText("${pitch#westScore}");
        display#eastScore.setText("${pitch#eastScore}")
    }

    type alias Anchor = {
        frame = Int32,
        epoch = Epoch
    }

    enum Epoch {
        case Absolute
        case Relative(Int64)
    }

    def pauseAnchor(anchor: Ref[Anchor, Static]): Unit \ IO = {
        let frame = getCurrentFrame(Ref.get(anchor));
        Ref.put({ frame = frame, epoch = Epoch.Absolute }, anchor)
    }

    def unpauseAnchor(anchor: Ref[Anchor, Static]): Unit \ IO = {
        let frame = getCurrentFrame(Ref.get(anchor));
        let epoch = Epoch.Relative(System.currentTimeMillis());
        Ref.put({ frame = frame, epoch = epoch }, anchor)
    }

    def getCurrentFrame(anchor: Anchor): Int32 \ IO = {
        let now = System.currentTimeMillis();
        let diff = match anchor#epoch {
            case Epoch.Absolute => 0i64
            case Epoch.Relative(time) => now - time
        };
        let framesPassed = Int64.truncateToInt32(Int32.toInt64(Constants.frameRate()) * diff / 1000i64);
        anchor#frame + framesPassed
    }

    def makeGameLoop(
        frames: Vector[Pitch],
        anchor: Ref[Anchor, Static],
        display: Display,
        slider: JSlider,
        updatingSlider: Guard[Static]
    ): Timer \ IO = {
        let deltaTs  = 1.0 / Int32.toFloat64(Constants.frameRate());
        let deltaTms = Float64.truncateToInt32(deltaTs * 1000.0);

        def onTick(event: ActionEvent) = {
            // skip if the user is scrubbing
            if (not slider.getValueIsAdjusting()) {
                let i = getCurrentFrame(Ref.get(anchor));
                if (i >= Vector.length(frames)) {
                    // reached the end of the precomputed history: stop playback
                    let timer = unchecked_cast(event.getSource() as Timer);
                    timer.stop()
                } else {
                    updatingSlider |> Guard.withGuard(
                        () ->
                            slider.setValue(i)
                    );
                    let pitch = Vector.get(i, frames);
                    refreshDisplay(pitch, display)
                }
            }
        };

        new Timer(deltaTms, Utils.mkActionListener(onTick))
    }

    def formatTimeMs(ms: Int32): String = {
        let s = Int32.toFloat64(ms) / 1000.0;
        unsafe IO { JString.format("%.1f", Float64.valueOf(s)) }
    }

}